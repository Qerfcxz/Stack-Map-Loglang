{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Main where

import Control.Applicative ((<|>))
import Control.Monad (unless)
import Data.Char (isSpace)
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
    , readP_to_S
    , sepBy
    , skipSpaces
    , string
    )

data Token
    = TSym String
    | TDummy
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
    deriving (Eq)

data State = State
    { input_stack       :: [Token]
    , var_upper_stack   :: [String]
    , var_middle_stack  :: [String]
    , var_lower_stack   :: [String]
    , output_stack      :: [Token]
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

simplify_set_expr :: String -> String
simplify_set_expr "" = ""
simplify_set_expr ('{' : rest) =
    case extract_balanced 0 "" rest of
        Just (inner, after) ->
            case break (== '|') inner of
                (left, "|#") ->
                    case break (== '∈') left of
                        (_, '∈' : set_name) -> set_name ++ simplify_set_expr after
                        _                   -> '{' : simplify_set_expr rest
                _ -> '{' : simplify_set_expr rest
        Nothing -> '{' : simplify_set_expr rest
simplify_set_expr (c : cs) = c : simplify_set_expr cs

extract_balanced :: Int -> String -> String -> Maybe (String, String)
extract_balanced _ _ [] = Nothing
extract_balanced depth acc ('{' : cs) = extract_balanced (depth + 1) (acc ++ "{") cs
extract_balanced 0 acc ('}' : cs)     = Just (acc, cs)
extract_balanced depth acc ('}' : cs) = extract_balanced (depth - 1) (acc ++ "}") cs
extract_balanced depth acc (c : cs)   = extract_balanced depth (acc ++ [c]) cs

replace_var :: String -> String -> String -> String
replace_var _ _ "" = ""
replace_var var val s =
    let (w, rest) = span is_var_char s
    in if null w
        then head s : replace_var var val (tail s)
        else if w == var
            then val ++ replace_var var val rest
            else w ++ replace_var var val rest

subst_var :: String -> Token -> Token -> Token
subst_var var val token = case token of
    TSym s ->
        if s == var
            then val
            else TSym (simplify_set_expr (replace_var var (show_token val) s))
    TDummy -> TDummy
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
                       ) of

    ( _, a : vus_rest, _, _, TOp "Get" : os_rest ) ->
        Just state
            { var_upper_stack = vus_rest
            , output_stack    = TDummy : TSym a : os_rest
            }

    ( _, _, a : vms_rest, _, TOp "Use" : os_rest ) ->
        Just state
            { var_middle_stack = vms_rest
            , output_stack     = TDummy : TSym a : os_rest
            }

    ( _, a : _, _, _, TQuant q : os_rest ) ->
        Just state
            { qmap         = Map.insert a q state.qmap
            , output_stack = os_rest
            }

    ( _, a : b : vus_rest, _, _, TSet set_name : os_rest ) ->
        Just state
            { var_upper_stack  = vus_rest
            , var_middle_stack = a : state.var_middle_stack
            , var_lower_stack  = a : state.var_lower_stack
            , smap             = Map.insert b set_name state.smap
            , fmap             = Map.insert b TDummy state.fmap
            , amap             = Map.insert a b state.amap
            , output_stack     = os_rest
            }

    ( _, _, _, _, TRelName r_name : b_val : TSym a : c_val : TSym b : os_rest ) ->
        let new_val = smart_and (smart_and b_val c_val) (TRel r_name (TSym b) (TSym a))
        in Just state
            { output_stack = new_val : TSym b : os_rest
            }

    ( _, _, _, a : vls_rest, TOp "Apply" : a_body : os_rest ) ->
        case Map.lookup a state.amap of
            Just b ->
                let q = Map.findWithDefault "Exist" a state.qmap
                    s = Map.findWithDefault "全集" b state.smap
                    f = Map.findWithDefault TDummy b state.fmap
                    built = TBuild q a b s f a_body
                in Just state
                    { var_lower_stack = vls_rest
                    , output_stack    = built : os_rest
                    }
            Nothing -> Nothing

    ( is_rest, _, _, _ : _, TOp "End" : a_val : os_rest ) ->
        Just state
            { input_stack  = TOp "End" : is_rest
            , output_stack = TOp "Apply" : a_val : os_rest
            }

    ( _, _, _, [], TOp "End" : a_val : os_rest ) ->
        Just state
            { output_stack = a_val : os_rest
            }

    ( _, a : vus_rest, _, _, TConn conn_name : b_val : TSym b : c_val : TSym c : os_rest ) ->
        let res = smart_and
                    (smart_and b_val c_val)
                    (smart_and
                        (TRel (conn_name ++ "_antecedent") (TSym a) (TSym c))
                        (TRel (conn_name ++ "_consequent") (TSym a) (TSym b)))
        in Just state
            { var_upper_stack = vus_rest
            , output_stack    = res : TSym a : os_rest
            }

    ( _, _, _, _, TOp "Modify" : a_mod : TSym a : b_val : TSym b : c_val : os_rest ) ->
        let new_b = smart_and b_val (subst_var b (TSym a) c_val)
        in Just state
            { output_stack = TOp "Modify" : a_mod : TSym a : new_b : os_rest
            }

    ( _, _, a : _, _, TOp "Modify" : a_mod : TSym b : b_val : os_rest ) ->
        case Map.lookup a state.amap of
            Just c ->
                let old_c   = Map.findWithDefault TDummy c state.fmap
                    applied = eval_app (eval_app (eval_app a_mod (TSym c)) (TSym b)) b_val
                    new_c   = smart_and old_c applied
                in Just state
                    { fmap         = Map.insert c new_c state.fmap
                    , output_stack = os_rest
                    }
            Nothing -> Nothing

    ( _, a : vus_rest, b : _, _, TOp "Modify" : a_mod : os_rest ) ->
        case Map.lookup b state.amap of
            Just c ->
                let old_b   = Map.findWithDefault TDummy c state.fmap
                    applied = eval_app (eval_app (eval_app a_mod (TSym c)) (TSym a)) TDummy
                    new_b   = smart_and old_b applied
                in Just state
                    { var_upper_stack = vus_rest
                    , fmap            = Map.insert c new_b state.fmap
                    , output_stack    = os_rest
                    }
            Nothing -> Nothing

    ( _, a : vus_rest, _, _, TOp "Polish" : a_mod : TSym b : b_val : os_rest ) ->
        let res = eval_app (eval_app (eval_app a_mod (TSym a)) (TSym b)) b_val
        in Just state
            { var_upper_stack = vus_rest
            , output_stack    = TSym a : res : os_rest
            }

    ( _, a : b : vus_rest, _, _, TOp "Polish" : a_mod : os_rest ) ->
        let res = eval_app (eval_app (eval_app a_mod (TSym a)) (TSym b)) TDummy
        in Just state
            { var_upper_stack = vus_rest
            , output_stack    = TSym a : res : os_rest
            }

    ( _, _, a : _, _, TUpload b : os_rest ) ->
        Just state
            { emap         = Map.insert b a state.emap
            , output_stack = os_rest
            }

    ( _, _, _, _, TDownload a : os_rest ) ->
        case Map.lookup a state.emap of
            Just val -> Just state
                { var_middle_stack = val : state.var_middle_stack
                , output_stack     = os_rest
                }
            Nothing -> Nothing

    ( _, _, _, _, TOp "And" : TSym a : a_val : TSym b : b_val : os_rest ) ->
        let new_b = subst_var b (TSym a) b_val
            res   = smart_and a_val new_b
        in Just state
            { output_stack = TSym a : res : os_rest
            }

    _ -> Nothing

is_var_char :: Char -> Bool
is_var_char c = c `elem` (['a'..'z'] ++ ['A'..'Z'] ++ ['0'..'9'] ++ "_")

token_parser :: MacroEnv -> ReadP Token
token_parser env = skipSpaces *> (upload_p <|> download_p <|> list_p env <|> lambda_p env <|> atom_p env)

upload_p :: ReadP Token
upload_p = string "Upload" *> skipSpaces *> (TUpload <$> munch1 is_var_char)

download_p :: ReadP Token
download_p = string "Download" *> skipSpaces *> (TDownload <$> munch1 is_var_char)

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
    | s `elem` ["Get","Use","Apply","End"
               ,"Modify","Polish","And"]          = TOp s
    | s `elem` ["Exist","All","∃","∀"]            = TQuant s
    | ":S" `isSuffixOf` s                         = TSet (take (length s - 2) s)
    | ":R" `isSuffixOf` s                         = TRelName (take (length s - 2) s)
    | ":Q" `isSuffixOf` s                         = TQuant (take (length s - 2) s)
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
    TDummy             -> "#"
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
    putStrLn $ "Input Stack (IS):       " ++ show_stack s.input_stack
    putStrLn $ "Var Upper Stack (VUS):  " ++ show_vus s.var_upper_stack
    putStrLn $ "Var Middle Stack (VMS): " ++ show_var_stack s.var_middle_stack
    putStrLn $ "Var Lower Stack (VLS):  " ++ show_var_stack s.var_lower_stack
    putStrLn $ "Output Stack (OS):      " ++ show_stack s.output_stack
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
    putStrLn "  Five-Stack Five-Mapping Semantic Deduction Engine"
    putStrLn "==============================================================="
    repl [] initial_state