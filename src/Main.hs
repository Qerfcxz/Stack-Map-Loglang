{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Main where

import Control.Applicative ((<|>))
import Control.Monad (unless)
import Data.Char (isDigit, isSpace)
import Data.List (intercalate, isPrefixOf, isSuffixOf)
import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import System.IO (BufferMode(NoBuffering), hSetBuffering, stdout)
import Text.ParserCombinators.ReadP
    ( ReadP
    , char
    , eof
    , munch1
    , optional
    , pfail
    , readP_to_S
    , sepBy
    , skipSpaces
    , string
    )

data Token
    = TSym String
    | TBool Bool
    | TDummy
    | TNot Token
    | TOmega String
    | TLam String Token
    | TApp Token Token
    | TAnd Token Token
    | TRel String Token Token
    | TBuild String String String String Token Token
    | TList [Token]
    | TOp String
    | TSet String
    | TRelName String
    | TQuant String
    | TConn String
    | TUpload String
    | TDownload String
    | TPerm [Int]
    deriving (Eq)

data State = State
    { input_stack       :: [Token]
    , var_upper_stack   :: [String]
    , var_middle_stack  :: [Token]
    , var_lower_stack   :: [String]
    , output_stack      :: [Token]
    , modifier_stack    :: [Token]
    , emap              :: Map String String
    , qmap              :: Map String String
    , smap              :: Map String String
    , fmap              :: Map String Token
    , amap              :: Map String String
    }

type MacroEnv = [(String, Token)]

smart_and :: Token -> Token -> Token
smart_and TDummy b = b
smart_and a TDummy = a
smart_and a b      = TAnd a b

subst_var :: String -> Token -> Token -> Token
subst_var var val token = case token of
    TSym s ->
        if s == var
            then val
            else TSym s
    TBool b -> TBool b
    TDummy  -> TDummy
    TNot t  -> TNot (subst_var var val t)
    TOmega s ->
        if s == var
            then case val of
                TSym v -> TOmega v
                _      -> TOmega s
            else TOmega s
    TLam v b ->
        if v == var
            then TLam v b
            else TLam v (subst_var var val b)
    TApp f x -> TApp (subst_var var val f) (subst_var var val x)
    TAnd a b -> smart_and (subst_var var val a) (subst_var var val b)
    TRel r a b -> TRel r (subst_var var val a) (subst_var var val b)
    TBuild q a b s f d ->
        let new_a = if a == var then case val of TSym v -> v; _ -> a else a
            new_b = if b == var then case val of TSym v -> v; _ -> b else b
            new_s = if s == var then case val of TSym v -> v; _ -> s else s
            new_f = subst_var var val f
            new_d = subst_var var val d
        in TBuild q new_a new_b new_s new_f new_d
    TList ts -> TList (map (subst_var var val) ts)
    _ -> token

eval_app :: Token -> Token -> Token
eval_app (TLam v body) arg = subst_var v arg body
eval_app f arg             = TApp f arg

start_rule :: State -> Maybe State
start_rule state = case state.input_stack of
    [] -> Nothing
    TList [] : is_rest ->
        Just state { input_stack = is_rest }
    TList (t : ts) : is_rest ->
        Just state { input_stack = TList ts : is_rest, output_stack = t : state.output_stack }
    t : is_rest ->
        Just state { input_stack = is_rest, output_stack = t : state.output_stack }

loop_rule :: State -> Maybe State
loop_rule state = case ( state.input_stack
                       , state.var_upper_stack
                       , state.var_middle_stack
                       , state.var_lower_stack
                       , state.output_stack
                       , state.modifier_stack
                       ) of

    ( _, a : vus_rest, _, _, TOp "New" : os_rest, _ ) ->
        Just state
            { var_upper_stack = vus_rest
            , output_stack    = TSym a : os_rest
            , fmap            = Map.insert a TDummy state.fmap
            }

    ( _, a : vus_rest, _, _, TOp "Get" : os_rest, _ ) ->
        Just state
            { var_upper_stack = vus_rest
            , output_stack    = TSym a : TDummy : os_rest
            }

    ( _, _, a : big_a : vms_rest, _, TOp "Use" : os_rest, _ ) ->
        Just state
            { var_middle_stack = vms_rest
            , output_stack     = a : TDummy : big_a : os_rest
            }

    ( _, a : vus_rest, _, _, TOp "Bubble" : TSym b : os_rest, _ ) ->
        Just state
            { var_upper_stack = a : b : vus_rest
            , output_stack    = os_rest
            }

    ( _, _, TSym a : _, _, TUpload b : os_rest, _ ) ->
        Just state
            { emap         = Map.insert b a state.emap
            , output_stack = os_rest
            }

    ( _, _, _, _, TOp "Judge" : TSym a : TOp "Not" : os_rest, _ ) ->
        Just state
            { var_middle_stack = TSym a : TBool False : state.var_middle_stack
            , output_stack     = os_rest
            }

    ( _, _, _, _, TOp "Judge" : TSym a : os_rest, _ ) ->
        Just state
            { var_middle_stack = TSym a : TBool True : state.var_middle_stack
            , output_stack     = os_rest
            }

    ( is_rest, _, _, _, TDownload a : os_rest, _ ) ->
        case Map.lookup a state.emap of
            Just val -> Just state
                { input_stack  = TSym val : TOp "Judge" : is_rest
                , output_stack = os_rest
                }
            Nothing -> Nothing

    ( _, _, _, _, TOp "Drop" : _ : os_rest, _ ) ->
        Just state
            { output_stack = os_rest
            }

    ( _, _, _, _, TOp "Formula" : TSym a : big_a : os_rest, _ ) ->
        Just state
            { output_stack = os_rest
            , fmap         = Map.insert a big_a state.fmap
            }

    ( is_rest, _, _, _, TOp "Apply" : TLam a big_a : big_b : os_rest, _ ) ->
        Just state
            { input_stack  = subst_var a big_b big_a : is_rest
            , output_stack = os_rest
            }

    ( _, _, _, _, TOp "Substitute" : TSym a : big_a : big_b : os_rest, _ ) ->
        Just state
            { output_stack = subst_var a big_b big_a : os_rest
            }

    ( _, _, _, _, TOp "∧" : big_a : big_b : os_rest, _ ) ->
        Just state
            { output_stack = smart_and big_a big_b : os_rest
            }

    ( _, _, _, _, TOp "Negation" : big_a : os_rest, _ ) ->
        Just state
            { output_stack = TNot big_a : os_rest
            }

    ( _, a : _, _, _, TQuant q : os_rest, _ ) ->
        Just state
            { qmap         = Map.insert a q state.qmap
            , output_stack = os_rest
            }

    ( _, _, _, _, TOp "Stop" : os_rest, _ ) ->
        Just state
            { output_stack   = os_rest
            , modifier_stack = TOp "Stop" : state.modifier_stack
            }

    ( is_rest, a : b : vus_rest, _, _, TSet set_name : os_rest, [] ) ->
        Just state
            { input_stack     = TSym a : TOp "Judge" : is_rest
            , var_upper_stack = vus_rest
            , var_lower_stack = a : state.var_lower_stack
            , output_stack    = os_rest
            , amap            = Map.insert a b state.amap
            , smap            = Map.insert b set_name state.smap
            , fmap            = Map.insert b TDummy state.fmap
            }

    ( is_rest, a : b : vus_rest, _, _, TSet set_name : os_rest, TOp "Stop" : mds_rest ) ->
        Just state
            { input_stack     = TSym a : TOp "Judge" : is_rest
            , var_upper_stack = vus_rest
            , var_lower_stack = a : state.var_lower_stack
            , output_stack    = os_rest
            , modifier_stack  = mds_rest
            , amap            = Map.insert a b state.amap
            , smap            = Map.insert b set_name state.smap
            , fmap            = Map.insert b TDummy state.fmap
            }

    ( is_rest, a : b : vus_rest, _, _, TSet set_name : os_rest, TSym c : big_b : mds_rest ) ->
        let c_fmap  = Map.findWithDefault TDummy c state.fmap
            applied = eval_app (eval_app (eval_app big_b (TSym b)) (TSym c)) c_fmap
            new_ips = [ TSym a, TOp "Judge", applied, TOp "Drop", TSym b, TOp "Formula" ] ++ is_rest
        in Just state
            { input_stack     = new_ips
            , var_upper_stack = vus_rest
            , var_lower_stack = a : state.var_lower_stack
            , output_stack    = os_rest
            , modifier_stack  = mds_rest
            , amap            = Map.insert a b state.amap
            , smap            = Map.insert b set_name state.smap
            }

    ( _, _, _, _, TRelName r_name : TSym a : b_val : c_bool : TSym b : d_val : os_rest, _ ) ->
        let is_pos = case c_bool of
                TBool True -> True
                TSym "True" -> True
                _ -> False
            rel   = TRel r_name (TSym b) (TSym a)
            e_val = if is_pos then rel else TNot rel
            res   = smart_and (smart_and b_val d_val) e_val
        in Just state
            { output_stack = TSym b : res : os_rest
            }

    ( _, a : vus_rest, _, _, TConn conn_name : TSym b : b_val : TSym c : c_val : os_rest, _ ) ->
        let res = smart_and (TRel (conn_name ++ "_consequent") (TSym a) (TSym b))
                    (smart_and (TRel (conn_name ++ "_antecedent") (TSym a) (TSym c))
                        (smart_and b_val c_val))
        in Just state
            { var_upper_stack = vus_rest
            , output_stack    = TSym a : res : os_rest
            }

    ( _, _, _, _, TPerm idxs : os_rest, _ ) ->
        let n = length idxs
        in if length state.var_lower_stack >= n
            then
                let (top_n, rest) = splitAt n state.var_lower_stack
                    permuted = map (\i -> top_n !! (i - 1)) idxs
                in Just state
                    { var_lower_stack = permuted ++ rest
                    , output_stack    = os_rest
                    }
            else Nothing

    ( _, _, _, a : b : vls_rest, TOp "Swap" : os_rest, _ ) ->
        Just state
            { var_lower_stack = b : a : vls_rest
            , output_stack    = os_rest
            }

    ( _, _, _, a : vls_rest, TOp "Go" : os_rest, _ ) ->
        Just state
            { var_lower_stack = vls_rest
            , output_stack    = TSym a : os_rest
            }

    ( _, _, _, _, TOp "Back" : TSym a : os_rest, _ ) ->
        Just state
            { var_lower_stack = a : state.var_lower_stack
            , output_stack    = os_rest
            }

    ( _, _, _, a : vls_rest, TOp "Build" : TSym b : big_a : os_rest, _ ) ->
        case Map.lookup a state.amap of
            Just c ->
                let q     = Map.findWithDefault "Exist" a state.qmap
                    s     = Map.findWithDefault "全集" c state.smap
                    f     = Map.findWithDefault TDummy c state.fmap
                    built = TBuild q a c s f big_a
                in Just state
                    { var_lower_stack = vls_rest
                    , output_stack    = TSym b : built : os_rest
                    }
            Nothing -> Nothing

    ( _, _, _, _, TOp "Event" : TSym a : big_a : os_rest, _ ) ->
        let res = smart_and (TOmega a) big_a
        in Just state
            { output_stack = TSym a : res : os_rest
            }

    ( is_rest, _, _, [], TOp "End" : os_rest, _ ) ->
        Just state
            { input_stack  = TOp "Event" : is_rest
            , output_stack = os_rest
            }

    ( is_rest, _, _, _ : _, TOp "End" : os_rest, _ ) ->
        Just state
            { input_stack  = TOp "Build" : TOp "End" : is_rest
            , output_stack = os_rest
            }

    ( _, _, _, _, TOp "For" : os_rest, _ ) ->
        Just state
            { output_stack   = os_rest
            , modifier_stack = TOp "For" : state.modifier_stack
            }

    ( _, _, _, _, TOp "Cancel" : os_rest, TOp "For" : mds_rest ) ->
        Just state
            { output_stack   = os_rest
            , modifier_stack = mds_rest
            }

    ( is_rest, _, _, _, TOp "Exchange" : os_rest, TOp "For" : TSym a : big_a : TSym b : big_b : mds_rest ) ->
        Just state
            { input_stack    = TOp "Modify" : is_rest
            , output_stack   = TSym b : big_b : os_rest
            , modifier_stack = TOp "For" : TSym a : big_a : mds_rest
            }

    ( _, _, _, _, TOp "Merge" : TSym _ : big_a : TSym b : big_b : os_rest, _ ) ->
        let old_b = Map.findWithDefault TDummy b state.fmap
            new_b = smart_and old_b big_a
        in Just state
            { output_stack   = os_rest
            , modifier_stack = TSym b : big_b : state.modifier_stack
            , fmap           = Map.insert b new_b state.fmap
            }

    ( is_rest, _, _, _, TOp "Modify" : TSym a : big_a : os_rest, TOp "For" : TSym b : big_b : mds_rest ) ->
        let b_fmap  = Map.findWithDefault TDummy b state.fmap
            applied = eval_app (eval_app (eval_app big_b (TSym a)) (TSym b)) b_fmap
        in Just state
            { input_stack    = applied : TOp "Merge" : is_rest
            , output_stack   = TSym a : big_a : os_rest
            , modifier_stack = mds_rest
            }

    ( _, _, _, _, TOp "Modify" : TSym a : big_a : os_rest, _ ) ->
        Just state
            { output_stack   = os_rest
            , modifier_stack = TSym a : big_a : state.modifier_stack
            }

    ( _, a : vus_rest, _, _, TOp "Combine" : os_rest, TSym b : big_a : TSym c : big_b : mds_rest ) ->
        let c_fmap = Map.findWithDefault TDummy c state.fmap
            b_fmap = Map.findWithDefault TDummy b state.fmap
            body = TList
                [ TSym b, TSym "z", TSym "y", TOp "Substitute"
                , b_fmap, TOp "∧"
                , TSym b, TSym "x", big_a, TOp "Apply", TOp "Apply", TOp "Apply"
                , TSym c, TSym "z", TSym "y", TOp "Substitute"
                , c_fmap, TOp "∧"
                , TSym c, TSym "x", big_b, TOp "Apply", TOp "Apply", TOp "Apply"
                , TConn "And"
                ]
            combined = TLam "x" (TLam "y" (TLam "z" body))
        in Just state
            { var_upper_stack = vus_rest
            , output_stack    = os_rest
            , modifier_stack  = TSym a : combined : mds_rest
            , fmap            = Map.insert a TDummy state.fmap
            }

    ( _, _, _, _, TOp "Combine" : os_rest, _ ) ->
        Just state
            { output_stack = os_rest
            }

    _ -> Nothing

is_var_char :: Char -> Bool
is_var_char c = c `elem` (['a'..'z'] ++ ['A'..'Z'] ++ ['0'..'9'] ++ "_")

token_parser :: MacroEnv -> ReadP Token
token_parser env = skipSpaces *> (upload_p <|> download_p <|> perm_p <|> list_p env <|> lambda_p env <|> atom_p env)

upload_p :: ReadP Token
upload_p = string "Upload" *> skipSpaces *> (TUpload <$> munch1 is_var_char)

download_p :: ReadP Token
download_p = string "Download" *> skipSpaces *> (TDownload <$> munch1 is_var_char)

perm_p :: ReadP Token
perm_p = do
    _ <- char '('
    skipSpaces
    nums <- sepBy (munch1 isDigit) (skipSpaces *> char ',' <* skipSpaces)
    skipSpaces
    _ <- char ')'
    if null nums
        then pfail
        else return (TPerm (map read nums))

list_p :: MacroEnv -> ReadP Token
list_p env = do
    _ <- char '['
    skipSpaces
    tokens <- sepBy (token_parser env) (skipSpaces *> optional (char ',') <* skipSpaces)
    skipSpaces
    _ <- char ']'
    return (TList (reverse tokens))

lambda_p :: MacroEnv -> ReadP Token
lambda_p env = do
    _ <- char 'λ' <|> char '\\'
    skipSpaces
    v <- munch1 is_var_char
    skipSpaces
    _ <- char '.'
    skipSpaces
    body <- token_parser env <|> raw_expr_p
    return (TLam v body)

raw_expr_p :: ReadP Token
raw_expr_p = do
    s <- munch1 (\c -> not (isSpace c || c `elem` "[],()"))
    return (parse_atom s)

atom_p :: MacroEnv -> ReadP Token
atom_p env = do
    s <- munch1 (\c -> not (isSpace c || c `elem` "[],()"))
    case lookup s env of
        Just tok -> return tok
        Nothing  -> return (parse_atom s)

parse_atom :: String -> Token
parse_atom s
    | s == "#"                                    = TDummy
    | s == "True"                                 = TBool True
    | s == "False"                                = TBool False
    | s `elem` [ "New", "Get", "Use", "Bubble", "Judge", "Drop", "Formula"
               , "Apply", "Substitute", "∧", "Negation", "Stop", "Swap"
               , "Go", "Back", "Build", "Event", "End", "For", "Cancel"
               , "Exchange", "Merge", "Modify", "Combine", "Not"
               ]                                  = TOp s
    | s `elem` ["Exist", "∃"]                     = TQuant "Exist"
    | s `elem` ["All", "∀"]                       = TQuant "All"
    | ":S" `isSuffixOf` s                         = TSet (take (length s - 2) s)
    | ":R" `isSuffixOf` s                         = TRelName (take (length s - 2) s)
    | ":Q" `isSuffixOf` s                         =
        let q = take (length s - 2) s
        in if q `elem` ["All", "∀"] then TQuant "All" else TQuant "Exist"
    | ":C" `isSuffixOf` s                         = TConn (take (length s - 2) s)
    | otherwise                                   = TSym s

parse_input :: MacroEnv -> String -> Maybe [Token]
parse_input env str =
    case readP_to_S (skipSpaces *> sepBy (token_parser env) skipSpaces <* skipSpaces <* eof) str of
        ((tokens, "") : _) -> Just (reverse tokens)
        _                  -> Nothing

parse_define_cmd :: String -> Maybe (String, String)
parse_define_cmd s = case break (==':') s of
    (name_part, ':':'=':rest) ->
        let name = strip_define (trim name_part)
            def  = trim rest
        in if not (null name) && not (null def) then Just (name, def) else Nothing
    _ -> Nothing
  where
    strip_define str
        | "define " `isPrefixOf` str = trim (drop 7 str)
        | "define"  `isPrefixOf` str = trim (drop 6 str)
        | otherwise                  = str

show_token :: Token -> String
show_token token = case token of
    TSym s             -> s
    TBool b            -> show b
    TDummy             -> "#"
    TNot t             -> "Not " ++ show_token_nested t
    TOmega a           -> "Ω(" ++ a ++ ")"
    TLam v b           -> "λ" ++ v ++ "." ++ show_token b
    TApp f x           -> "(" ++ show_token f ++ " " ++ show_token x ++ ")"
    TAnd x y           -> show_token x ++ "∧" ++ show_token y
    TRel r x y         -> r ++ "(" ++ show_token x ++ "," ++ show_token y ++ ")"
    TBuild q a b s f d ->
        let set_str = case f of
                TDummy -> s
                _      -> "{" ++ b ++ "∈" ++ s ++ "|" ++ show_token f ++ "}"
            quant_str = q ++ " " ++ a ++ "∈" ++ set_str
        in case d of
            TDummy -> quant_str
            _      -> "(" ++ quant_str ++ " " ++ show_token d ++ ")"
    TList ts           -> "[" ++ intercalate ", " (map show_token (reverse ts)) ++ "]"
    TOp s              -> s
    TSet s             -> s ++ ":S"
    TRelName s         -> s ++ ":R"
    TQuant s           -> s ++ ":Q"
    TConn s            -> s ++ ":C"
    TUpload s          -> "Upload " ++ s
    TDownload s        -> "Download " ++ s
    TPerm idxs         -> "(" ++ intercalate "," (map show idxs) ++ ")"
  where
    show_token_nested t@(TAnd _ _) = "(" ++ show_token t ++ ")"
    show_token_nested t            = show_token t

show_stack :: [Token] -> String
show_stack ts = unwords (map show_token (reverse ts))

show_var_stack :: [String] -> String
show_var_stack vs = unwords (reverse vs)

show_vus :: [String] -> String
show_vus vs = "... " ++ unwords (reverse (take 6 vs))

show_map :: Map String String -> String
show_map m = "[" ++ intercalate ", " ["(\"" ++ k ++ "\", \"" ++ v ++ "\")" | (k, v) <- Map.toList m] ++ "]"

show_map_f :: Map String Token -> String
show_map_f m = "[" ++ intercalate ", " ["(\"" ++ k ++ "\", \"" ++ show_token v ++ "\")" | (k, v) <- Map.toList m] ++ "]"

print_state :: State -> IO ()
print_state s = do
    putStrLn "==================== Machine State ===================="
    putStrLn $ "Input Stack (IP):       " ++ show_stack s.input_stack
    putStrLn $ "Var Upper Stack (VU):   " ++ show_vus s.var_upper_stack
    putStrLn $ "Var Middle Stack (VM):  " ++ show_stack s.var_middle_stack
    putStrLn $ "Var Lower Stack (VL):   " ++ show_var_stack s.var_lower_stack
    putStrLn $ "Output Stack (OP):      " ++ show_stack s.output_stack
    putStrLn $ "Modifier Stack (MD):    " ++ show_stack s.modifier_stack
    putStrLn "------------------------- Maps -------------------------"
    putStrLn $ "Emap (Environment):     " ++ show_map s.emap
    putStrLn $ "Qmap (Quantifiers):     " ++ show_map s.qmap
    putStrLn $ "Smap (Sets):            " ++ show_map s.smap
    putStrLn $ "Fmap (Filters):         " ++ show_map_f s.fmap
    putStrLn $ "Amap (Associations):    " ++ show_map s.amap
    putStrLn "========================================================"

trim :: String -> String
trim = dropWhile isSpace . reverse . dropWhile isSpace . reverse

run_loop :: Bool -> Int -> State -> IO (State, Int)
run_loop silent step state = case loop_rule state of
    Nothing -> return (state, step)
    Just next_state ->
        if silent
            then run_loop silent (step + 1) next_state
            else do
                putStrLn $ "\n[-> Loop Rule Triggered (Step " ++ show step ++ ")]"
                print_state next_state
                run_loop silent (step + 1) next_state

run_machine :: Bool -> Int -> State -> IO (State, Int)
run_machine silent step state = case start_rule state of
    Nothing -> do
        unless silent (putStrLn "\n[Execution Finished / Halted]")
        return (state, step)
    Just next_state -> do
        let next_step = step + 1
        if silent
            then do
                (loop_state, final_step) <- run_loop silent next_step next_state
                run_machine silent final_step loop_state
            else do
                putStrLn $ "\n[-> Start Rule Triggered (Step " ++ show step ++ ")]"
                print_state next_state
                (loop_state, final_step) <- run_loop silent next_step next_state
                run_machine silent final_step loop_state

initial_state :: State
initial_state = State
    { input_stack       = []
    , var_upper_stack   = ["v" ++ show i | i <- [(1 :: Int)..]]
    , var_middle_stack  = []
    , var_lower_stack   = []
    , output_stack      = []
    , modifier_stack    = []
    , emap              = Map.empty
    , qmap              = Map.empty
    , smap              = Map.empty
    , fmap              = Map.empty
    , amap              = Map.empty
    }

repl :: MacroEnv -> State -> IO ()
repl env state = do
    putStrLn "\nReady for input (:q to quit, :r to reset, // for trace mode, define <name> := <expr>):"
    input_str <- getLine
    let trimmed = trim input_str
    case trimmed of
        ":q" -> putStrLn "Exiting Deduction Engine."
        ":r" -> do
            putStrLn "System reset. Stacks and maps cleared (macros preserved)."
            repl env initial_state
        "" -> repl env state
        _ -> case parse_define_cmd trimmed of
            Just (name, def_str) -> case parse_input env def_str of
                Just [tok] -> do
                    putStrLn $ "Macro defined: " ++ name ++ " := " ++ show_token tok
                    repl ((name, tok) : env) state
                _ -> do
                    putStrLn "Error: Failed to parse macro definition."
                    repl env state
            Nothing -> do
                let (silent, expr_str) =
                        if "//" `isPrefixOf` trimmed
                            then (False, trim (drop 2 trimmed))
                            else (True, trimmed)
                case parse_input env expr_str of
                    Nothing -> do
                        putStrLn "Error: Syntax parse failed."
                        repl env state
                    Just tokens -> do
                        let state_to_run = state { input_stack = tokens ++ state.input_stack }
                        putStrLn $ "\n>>> Running input: " ++ expr_str
                        (final_state, _) <- run_machine silent 1 state_to_run
                        putStrLn "\n[Final Output]:"
                        print_state final_state
                        repl env final_state

main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    putStrLn "==============================================================="
    putStrLn "  Six-Stack Five-Mapping Semantic Deduction Engine"
    putStrLn "==============================================================="
    repl [] initial_state