{-# LANGUAGE DuplicateRecordFields #-}
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
import Text.Read (readMaybe)

data Token
    = TNum Int
    | TSym String
    | TBool Bool
    | TDummy
    | TNot Token
    | TAnd Token Token
    | TRel String Token Token
    | TBuild String String String String Token Token
    | TLam String Token
    | TApp Token Token
    | TList [Token]
    | TOp String
    | TSet String
    | TRelName String
    | TQuant String
    | TQQ String
    | TSS String
    | TStackId String
    | TMapId String
    | TPerm [Int]
    deriving (Eq)

data State = State
    { input_stack     :: [Token]
    , num_stack       :: [Int]
    , quant_stack     :: [Int]
    , wait_stack      :: [Token]
    , component_stack :: [Token]
    , perm_stack      :: [Token]
    , output_stack    :: [Token]
    , focus_reg       :: Int
    , imap            :: Map Int Token
    , omap            :: Map Int Token
    , qmap            :: Map Int String
    , smap            :: Map Int String
    , mmap            :: Map Int Bool
    , fmap            :: Map Int Bool
    , emap            :: Map String Int
    , macro_map       :: Map String Token
    }

type MacroEnv = [(String, Token)]

smart_and :: Token -> Token -> Token
smart_and TDummy b = b
smart_and a TDummy = a
smart_and a b      = TAnd a b

subst_var :: String -> Token -> Token -> Token
subst_var var val token = case token of
    TSym s   -> if s == var then val else TSym s
    TNum n   -> TNum n
    TBool b  -> TBool b
    TDummy   -> TDummy
    TNot t   -> TNot (subst_var var val t)
    TLam v b -> if v == var then TLam v b else TLam v (subst_var var val b)
    TApp f x -> TApp (subst_var var val f) (subst_var var val x)
    TAnd a b -> smart_and (subst_var var val a) (subst_var var val b)
    TRel r a b -> TRel r (subst_var var val a) (subst_var var val b)
    TBuild q a b s f d ->
        let new_a = if a == var then token_to_alpha val else a
            new_b = if b == var then token_to_alpha val else b
            new_s = if s == var then token_to_str val else s
            new_f = subst_var var val f
            new_d = subst_var var val d
        in TBuild q new_a new_b new_s new_f new_d
    TList ts -> TList (map (subst_var var val) ts)
    _        -> token

token_to_alpha :: Token -> String
token_to_alpha (TNum n) = "α_" ++ show n
token_to_alpha (TSym s) = s
token_to_alpha t        = show_token t

token_to_str :: Token -> String
token_to_str (TSym s)      = s
token_to_str (TSet s)      = s
token_to_str (TRelName s)  = s
token_to_str (TQuant s)    = s
token_to_str (TQQ s)       = s
token_to_str (TSS s)       = s
token_to_str (TNum n)      = show n
token_to_str t             = show_token t

to_entity_id :: Token -> Maybe Int
to_entity_id (TNum n)              = Just n
to_entity_id (TSym ('α':'_':rest)) = readMaybe rest
to_entity_id (TSym s)              = readMaybe s
to_entity_id _                     = Nothing

to_bool :: Token -> Maybe Bool
to_bool (TBool b)      = Just b
to_bool (TSym "True")  = Just True
to_bool (TSym "False") = Just False
to_bool _              = Nothing

to_map_name :: Token -> Maybe String
to_map_name (TMapId s) = Just s
to_map_name (TSym s)   = Just s
to_map_name _          = Nothing

to_stack_name :: Token -> Maybe String
to_stack_name (TStackId s) = Just s
to_stack_name (TSym s)     = Just s
to_stack_name _            = Nothing

eval_qq :: Token -> String -> String
eval_qq tok old_q = case tok of
    TQQ q       -> q
    TQuant q    -> q
    TSym q      -> q
    TLam v body -> extract_q (subst_var v (TSym old_q) body)
    _           -> old_q
  where
    extract_q (TList ts) = concatMap extract_q (reverse ts)
    extract_q (TSym s)   = s
    extract_q (TQuant s) = s
    extract_q (TQQ s)    = s
    extract_q _          = ""

eval_ss :: Token -> String -> String
eval_ss tok old_s = case tok of
    TSS s       -> s
    TSet s      -> s
    TSym s      -> s
    TLam v body -> extract_s (subst_var v (TSym old_s) body)
    _           -> old_s
  where
    extract_s (TList ts) = concatMap extract_s (reverse ts)
    extract_s (TSym s)   = s
    extract_s (TSet s)   = s
    extract_s (TSS s)    = s
    extract_s _          = ""

permute_qn :: [Int] -> [Int] -> [Int]
permute_qn idxs qns =
    let n = length idxs
    in if length qns >= n
        then
            let (top_n, rest) = splitAt n qns
                permuted = map (\i -> top_n !! (i - 1)) (reverse idxs)
            in permuted ++ rest
        else qns

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
loop_rule state = case (state.output_stack, state.wait_stack, state.num_stack, state.quant_stack, state.component_stack) of

    ( TOp "!" : TSet b : os_rest, _, a : nms_rest, _, _ ) ->
        Just state
            { num_stack       = nms_rest
            , quant_stack     = a : state.quant_stack
            , wait_stack      = TNum a : state.wait_stack
            , output_stack    = os_rest
            , imap            = Map.insert a TDummy state.imap
            , omap            = Map.insert a TDummy state.omap
            , qmap            = Map.insert a "Exist" state.qmap
            , smap            = Map.insert a b state.smap
            , mmap            = Map.insert a True state.mmap
            , fmap            = Map.insert a False state.fmap
            }

    ( TOp "!" : TOp "Combine" : os_rest, TNum a : TLam var body : wts_rest, _, _, _ ) ->
        Just state
            { input_stack  = subst_var var (TNum a) body : state.input_stack
            , wait_stack   = wts_rest
            , output_stack = os_rest
            }

    ( TOp "!" : TOp "Combine" : os_rest, TNum a : wts_rest, _, _, _ ) ->
        Just state
            { component_stack = TNum a : TBool True : state.component_stack
            , wait_stack      = wts_rest
            , output_stack    = os_rest
            }

    ( TOp "!" : TRelName r : b_tok : c_tok : d_tok : e_tok : os_rest, _, _, _, _ )
        | Just c <- to_entity_id c_tok
        , Just b <- to_entity_id b_tok
        , Just d <- to_bool d_tok
        , Just e <- to_bool e_tok ->
            let alpha_c  = TSym ("α_" ++ show c)
                alpha_b  = TSym ("α_" ++ show b)
                rel_atom = TRel r alpha_c alpha_b
                f        = if e then rel_atom else TNot rel_atom
                new_imap = if d then Map.insert c (smart_and (Map.findWithDefault TDummy c state.imap) f) state.imap else state.imap
                new_omap = if not d then Map.insert c (smart_and (Map.findWithDefault TDummy c state.omap) f) state.omap else state.omap
            in Just state
                { output_stack = c_tok : os_rest
                , imap         = new_imap
                , omap         = new_omap
                }

    ( TOp "!" : TOp "Thaw" : a : os_rest, _, _, _, _ ) ->
        Just state
            { input_stack  = a : state.input_stack
            , output_stack = os_rest
            }

    ( TOp "!" : TOp "Apply" : TLam var body : b : os_rest, _, _, _, _ ) ->
        Just state
            { input_stack  = subst_var var b body : state.input_stack
            , output_stack = os_rest
            }

    ( TOp "!" : TOp "Equal" : a : b : os_rest, _, _, _, _ ) ->
        Just state { output_stack = TBool (a == b) : os_rest }

    ( TOp "!" : TOp "Not" : a_tok : os_rest, _, _, _, _ ) ->
        case to_bool a_tok of
            Just b  -> Just state { output_stack = TBool (not b) : os_rest }
            Nothing -> case a_tok of
                TNot x -> Just state { output_stack = x : os_rest }
                _      -> Just state { output_stack = TNot a_tok : os_rest }

    ( TOp "!" : TOp "And" : a_tok : b_tok : os_rest, _, _, _, _ )
        | Just a <- to_bool a_tok, Just b <- to_bool b_tok ->
            Just state { output_stack = TBool (a && b) : os_rest }

    ( TOp "!" : TOp "Or" : a_tok : b_tok : os_rest, _, _, _, _ )
        | Just a <- to_bool a_tok, Just b <- to_bool b_tok ->
            Just state { output_stack = TBool (a || b) : os_rest }

    ( TOp "!" : TOp "If" : a_tok : b_tok : c_tok : os_rest, _, _, _, _ )
        | Just a <- to_bool a_tok ->
            let chosen = if a then b_tok else c_tok
            in Just state
                { input_stack  = chosen : state.input_stack
                , output_stack = os_rest
                }

    ( TOp "!" : TOp "Insert" : m_tok : val : b_tok : os_rest, _, _, _, _ )
        | Just b      <- to_entity_id b_tok
        , Just map_id <- to_map_name m_tok ->
            case map_id of
                "Mmap" | Just bv <- to_bool val -> Just state { output_stack = b_tok : os_rest, mmap = Map.insert b bv state.mmap }
                "Fmap" | Just bv <- to_bool val -> Just state { output_stack = b_tok : os_rest, fmap = Map.insert b bv state.fmap }
                "Imap"                          -> Just state { output_stack = b_tok : os_rest, imap = Map.insert b val state.imap }
                "Omap"                          -> Just state { output_stack = b_tok : os_rest, omap = Map.insert b val state.omap }
                "Qmap"                          -> Just state { output_stack = b_tok : os_rest, qmap = Map.insert b (token_to_str val) state.qmap }
                "Smap"                          -> Just state { output_stack = b_tok : os_rest, smap = Map.insert b (token_to_str val) state.smap }
                _                               -> Nothing

    ( TOp "!" : TOp "Lookup" : m_tok : a_tok : os_rest, _, _, _, _ )
        | Just a      <- to_entity_id a_tok
        , Just map_id <- to_map_name m_tok ->
            let res = case map_id of
                    "Mmap" -> TBool (Map.findWithDefault True a state.mmap)
                    "Fmap" -> TBool (Map.findWithDefault False a state.fmap)
                    "Imap" -> Map.findWithDefault TDummy a state.imap
                    "Omap" -> Map.findWithDefault TDummy a state.omap
                    "Qmap" -> TSym (Map.findWithDefault "Exist" a state.qmap)
                    "Smap" -> TSym (Map.findWithDefault "" a state.smap)
                    _      -> TDummy
            in Just state { output_stack = res : os_rest }

    ( TOp "!" : TOp "Get" : s_tok : os_rest, _, _, _, _ )
        | Just s_id <- to_stack_name s_tok ->
            case s_id of
                "CM" | c : cms_rest <- state.component_stack ->
                    Just state { component_stack = cms_rest, output_stack = c : os_rest }
                "QN" | q : qns_rest <- state.quant_stack ->
                    Just state { quant_stack = qns_rest, output_stack = TNum q : os_rest }
                "WT" | w : wts_rest <- state.wait_stack ->
                    Just state { wait_stack = wts_rest, output_stack = w : os_rest }
                "NM" | n : nms_rest <- state.num_stack ->
                    Just state { num_stack = nms_rest, output_stack = TNum n : os_rest }
                "PR" | p : prs_rest <- state.perm_stack ->
                    Just state { perm_stack = prs_rest, output_stack = p : os_rest }
                _ -> Nothing

    ( TOp "!" : TOp "Back" : s_tok : a_tok : os_rest, _, _, _, _ )
        | Just s_id <- to_stack_name s_tok ->
            case s_id of
                "CM" ->
                    Just state { component_stack = a_tok : state.component_stack, output_stack = os_rest }
                "QN" | Just a <- to_entity_id a_tok ->
                    Just state { quant_stack = a : state.quant_stack, output_stack = os_rest }
                "WT" ->
                    Just state { wait_stack = a_tok : state.wait_stack, output_stack = os_rest }
                "PR" ->
                    Just state { perm_stack = a_tok : state.perm_stack, output_stack = os_rest }
                _ -> Nothing

    ( TOp "!" : TOp "Use" : os_rest, _, _, _, _ ) ->
        Just state { output_stack = TNum state.focus_reg : os_rest }

    ( TOp "!" : TOp "Assign" : a_tok : os_rest, _, _, _, _ )
        | Just a <- to_entity_id a_tok ->
            Just state { focus_reg = a, output_stack = os_rest }

    ( TOp "!" : TOp "Build" : os_rest, _, _, a : b : qns_rest, _ ) ->
        let q_b       = Map.findWithDefault "Exist" b state.qmap
            s_b       = Map.findWithDefault "" b state.smap
            i_b       = Map.findWithDefault TDummy b state.imap
            o_b       = Map.findWithDefault TDummy b state.omap
            alpha_b   = "α_" ++ show b
            is_inner  = Map.findWithDefault True a state.mmap
            target    = if is_inner then Map.findWithDefault TDummy a state.imap else Map.findWithDefault TDummy a state.omap
            scope     = smart_and o_b target
            build_tok = TBuild q_b alpha_b alpha_b s_b i_b scope
            new_imap  = if is_inner then Map.insert a build_tok state.imap else state.imap
            new_omap  = if not is_inner then Map.insert a build_tok state.omap else state.omap
        in Just state
            { quant_stack  = a : qns_rest
            , output_stack = os_rest
            , imap         = Map.delete b new_imap
            , omap         = Map.delete b new_omap
            , qmap         = Map.delete b state.qmap
            , smap         = Map.delete b state.smap
            , mmap         = Map.delete b state.mmap
            , fmap         = Map.delete b state.fmap
            }

    ( TOp "!" : TOp "Mapping" : os_rest, _, _, _, a_tok : _ )
        | Just a <- to_entity_id a_tok ->
            let s_name = Map.findWithDefault "" a state.smap
            in case Map.lookup s_name state.macro_map of
                Just macro_tok ->
                    Just state { input_stack = macro_tok : state.input_stack, output_stack = os_rest }
                Nothing ->
                    Just state { output_stack = os_rest }

    ( TOp "!" : TOp "Quantify" : a_qq : b_tok : os_rest, _, _, _, _ )
        | Just b <- to_entity_id b_tok ->
            let old_q = Map.findWithDefault "Exist" b state.qmap
                new_q = eval_qq a_qq old_q
            in Just state
                { output_stack = b_tok : os_rest
                , qmap         = Map.insert b new_q state.qmap
                }

    ( TOp "!" : TOp "Transform" : a_ss : b_tok : os_rest, _, _, _, _ )
        | Just b <- to_entity_id b_tok ->
            let old_s = Map.findWithDefault "" b state.smap
                new_s = eval_ss a_ss old_s
            in Just state
                { output_stack = b_tok : os_rest
                , smap         = Map.insert b new_s state.smap
                }

    ( TOp "!" : TOp "Traverse" : os_rest, _, _, _, _ )
        | a_tok : prs_rest <- state.perm_stack ->
            Just state
                { perm_stack   = prs_rest
                , input_stack  = a_tok : TOp "Traverse" : TOp "!" : state.input_stack
                , output_stack = os_rest
                }
        | null state.perm_stack ->
            Just state
                { output_stack = os_rest
                }

    ( TOp "!" : TOp "Upload" : a_tok : os_rest, _, _, _, a_cm : _ )
        | Just a <- to_entity_id a_cm ->
            let key = token_to_str a_tok
            in Just state
                { output_stack = os_rest
                , emap         = Map.insert key a state.emap
                }

    ( TOp "!" : TOp "Download" : a_tok : os_rest, _, _, _, _ ) ->
        let key = token_to_str a_tok
        in case Map.lookup key state.emap of
            Just a  -> Just state { component_stack = TNum a : state.component_stack, output_stack = os_rest }
            Nothing -> Nothing

    ( TOp "!" : TOp "Permute" : TPerm idxs : os_rest, _, _, _, _ ) ->
        Just state
            { quant_stack  = permute_qn idxs state.quant_stack
            , output_stack = os_rest
            }

    ( TOp "!" : TOp "Swap" : TPerm idxs : os_rest, _, _, _, _ ) ->
        let swap_ends xs = case xs of
                []       -> []
                [x]      -> [x]
                (y : ys) -> last ys : init ys ++ [y]
        in Just state { output_stack = TPerm (swap_ends idxs) : os_rest }

    ( TOp "!" : TOp "Left" : TPerm idxs : os_rest, _, _, _, _ ) ->
        let new_idxs = case idxs of (x : xs) -> xs ++ [x]; [] -> []
        in Just state { output_stack = TPerm new_idxs : os_rest }

    ( TOp "!" : TOp "Right" : TPerm idxs : os_rest, _, _, _, _ ) ->
        let new_idxs = case idxs of [] -> []; _ -> last idxs : init idxs
        in Just state { output_stack = TPerm new_idxs : os_rest }

    ( TOp "!" : TOp "Top" : TPerm idxs : os_rest, _, _, _, _ ) ->
        Just state { output_stack = TPerm (length idxs + 1 : idxs) : os_rest }

    ( TOp "!" : TOp "Bottom" : TPerm idxs : os_rest, _, _, _, _ ) ->
        Just state { output_stack = TPerm (map (+1) idxs ++ [1]) : os_rest }

    _ -> Nothing

is_var_char :: Char -> Bool
is_var_char c = c `elem` (['a'..'z'] ++ ['A'..'Z'] ++ ['0'..'9'] ++ "_")

token_parser :: MacroEnv -> ReadP Token
token_parser env = skipSpaces *> (perm_p <|> list_p env <|> lambda_p env <|> atom_p env)

perm_p :: ReadP Token
perm_p = do
    _ <- char '('
    skipSpaces
    nums <- sepBy (munch1 isDigit) (skipSpaces *> char ',' <* skipSpaces)
    skipSpaces
    _ <- char ')'
    return (TPerm (map read nums))

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
    body <- token_parser env
    return (TLam v body)

atom_p :: MacroEnv -> ReadP Token
atom_p env = do
    s <- munch1 (\c -> not (isSpace c || c `elem` "[],()"))
    case lookup s env of
        Just tok -> return tok
        Nothing  -> return (parse_atom s)

strip_quotes :: String -> String
strip_quotes str
    | length str >= 2 && head str == '"' && last str == '"' = init (tail str)
    | otherwise = str

parse_atom :: String -> Token
parse_atom raw_s
    | s == "#"       = TDummy
    | s == "True"    = TBool True
    | s == "False"   = TBool False
    | s `elem` [ "!", "Combine", "Thaw", "Apply", "Equal", "Not", "And", "Or", "If"
               , "Insert", "Lookup", "Get", "Back", "Use", "Assign"
               , "Build", "Mapping", "Quantify", "Transform", "Traverse"
               , "Upload", "Download"
               , "Permute", "Swap", "Left", "Right", "Top", "Bottom"
               ]     = TOp s
    | s `elem` [ "NM", "QN", "WT", "CM", "OP", "PR" ]                     = TStackId s
    | s `elem` [ "Imap", "Omap", "Qmap", "Smap", "Mmap", "Fmap", "Emap" ] = TMapId s
    | ":QQ" `isSuffixOf` s = TQQ (strip_quotes (take (length s - 3) s))
    | ":SS" `isSuffixOf` s = TSS (strip_quotes (take (length s - 3) s))
    | ":S"  `isSuffixOf` s = TSet (strip_quotes (take (length s - 2) s))
    | ":R"  `isSuffixOf` s = TRelName (strip_quotes (take (length s - 2) s))
    | ":Q"  `isSuffixOf` s = TQuant (strip_quotes (take (length s - 2) s))
    | s == "Exist"   = TQuant "Exist"
    | s == "Forall"  = TQuant "Forall"
    | all isDigit s  = TNum (read s)
    | otherwise      = TSym s
  where
    s = strip_quotes raw_s

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

parse_map_cmd :: String -> Maybe (String, String)
parse_map_cmd s = case break (=='-') s of
    (s_part, '-':'>':rest) ->
        let s_name = strip_map (trim s_part)
            m_def  = trim rest
        in if not (null s_name) && not (null m_def) then Just (s_name, m_def) else Nothing
    _ -> Nothing
  where
    strip_map str
        | "[map] " `isPrefixOf` str = trim (drop 6 str)
        | "[map]"  `isPrefixOf` str = trim (drop 5 str)
        | "map "   `isPrefixOf` str = trim (drop 4 str)
        | "map"    `isPrefixOf` str = trim (drop 3 str)
        | otherwise                 = str

show_token :: Token -> String
show_token token = case token of
    TNum n             -> show n
    TSym s             -> s
    TBool b            -> show b
    TDummy             -> "#"
    TNot t@(TAnd _ _)  -> "not (" ++ show_token t ++ ")"
    TNot t             -> "not " ++ show_token t
    TRel r x y         -> r ++ "(" ++ show_token x ++ "," ++ show_token y ++ ")"
    TAnd x y           -> show_token x ++ " ∧ " ++ show_token y
    TBuild q a b s f d ->
        let set_str = case f of
                TDummy -> s
                _      -> "{" ++ b ++ "∈" ++ s ++ " | " ++ show_token f ++ "}"
            quant_str = q ++ " " ++ a ++ "∈" ++ set_str
        in case d of
            TDummy -> "(" ++ quant_str ++ ")"
            _      -> "(" ++ quant_str ++ " " ++ show_token d ++ ")"
    TLam v b           -> "λ" ++ v ++ "." ++ show_token b
    TApp f x           -> "(" ++ show_token f ++ " " ++ show_token x ++ ")"
    TList ts           -> "[" ++ intercalate ", " (map show_token (reverse ts)) ++ "]"
    TOp s              -> s
    TSet s             -> s ++ ":S"
    TRelName s         -> s ++ ":R"
    TQuant s           -> s ++ ":Q"
    TQQ s              -> s ++ ":QQ"
    TSS s              -> s ++ ":SS"
    TStackId s         -> s
    TMapId s           -> s
    TPerm idxs         -> "(" ++ intercalate "," (map show idxs) ++ ")"

show_stack :: [Token] -> String
show_stack ts = unwords (map show_token (reverse ts))

show_int_stack :: [Int] -> String
show_int_stack is = unwords (map show (reverse is))

show_vus :: [Int] -> String
show_vus vs = "... " ++ unwords (map show (reverse (take 6 vs)))

show_map_v :: (a -> String) -> Map Int a -> String
show_map_v f m = "[" ++ intercalate ", " [show k ++ " -> " ++ f v | (k, v) <- Map.toList m] ++ "]"

show_map_str_int :: Map String Int -> String
show_map_str_int m = "[" ++ intercalate ", " [k ++ " -> " ++ show v | (k, v) <- Map.toList m] ++ "]"

print_state :: State -> IO ()
print_state s = do
    putStrLn "==================== Machine State ===================="
    putStrLn $ "Input Stack (IP):       " ++ show_stack s.input_stack
    putStrLn $ "Num Stack (NM):         " ++ show_vus s.num_stack
    putStrLn $ "Quant Stack (QN):       " ++ show_int_stack s.quant_stack
    putStrLn $ "Wait Stack (WT):        " ++ show_stack s.wait_stack
    putStrLn $ "Component Stack (CM):   " ++ show_stack s.component_stack
    putStrLn $ "Perm Stack (PR):        " ++ show_stack s.perm_stack
    putStrLn $ "Output Stack (OP):      " ++ show_stack s.output_stack
    putStrLn $ "Focus Register (<F>):   " ++ show s.focus_reg
    putStrLn "------------------------- Maps -------------------------"
    putStrLn $ "Imap (Restrictors):     " ++ show_map_v show_token s.imap
    putStrLn $ "Omap (Nuclear Scopes):  " ++ show_map_v show_token s.omap
    putStrLn $ "Qmap (Quantifiers):     " ++ show_map_v id s.qmap
    putStrLn $ "Smap (Sets):            " ++ show_map_v id s.smap
    putStrLn $ "Mmap (Modes):           " ++ show_map_v show s.mmap
    putStrLn $ "Fmap (Focus Flags):     " ++ show_map_v show s.fmap
    putStrLn $ "Emap (Environment):     " ++ show_map_str_int s.emap
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
    { input_stack     = []
    , num_stack       = [1..]
    , quant_stack     = []
    , wait_stack      = []
    , component_stack = []
    , perm_stack      = []
    , output_stack    = []
    , focus_reg       = 0
    , imap            = Map.empty
    , omap            = Map.empty
    , qmap            = Map.empty
    , smap            = Map.empty
    , mmap            = Map.empty
    , fmap            = Map.empty
    , emap            = Map.empty
    , macro_map       = Map.empty
    }

repl :: MacroEnv -> State -> IO ()
repl env state = do
    putStrLn "\nReady (:q to quit, :r to reset, // for trace, define <name>:=<expr>, map <S>-><Macro>):"
    input_str <- getLine
    let trimmed = trim input_str
    case trimmed of
        ":q" -> putStrLn "Exiting SML Deduction Engine."
        ":r" -> do
            putStrLn "System reset: Stacks and instance maps cleared (macros & mappings preserved)."
            repl env initial_state { macro_map = state.macro_map }
        ""   -> repl env state
        _    -> case parse_define_cmd trimmed of
            Just (name, def_str) -> case parse_input env def_str of
                Just [tok] -> do
                    putStrLn $ "Macro defined: " ++ name ++ " := " ++ show_token tok
                    repl ((name, tok) : env) state
                _ -> do
                    putStrLn "Error: Failed to parse macro definition."
                    repl env state
            Nothing -> case parse_map_cmd trimmed of
                Just (s_name, macro_name) -> case parse_input env macro_name of
                    Just [tok] -> do
                        putStrLn $ "Mapping registered: " ++ s_name ++ " -> " ++ show_token tok
                        let new_macro_map = Map.insert s_name tok state.macro_map
                        repl env state { macro_map = new_macro_map }
                    _ -> do
                        putStrLn "Error: Failed to parse mapping target."
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
                            putStrLn $ "\n>>> Running: " ++ expr_str
                            (final_state, _) <- run_machine silent 1 state_to_run
                            putStrLn "\n[Final Output]:"
                            print_state final_state
                            repl env final_state

main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    putStrLn "==============================================================="
    putStrLn " SML (Refactored v1.0) Concatenative Semantic Deduction Engine"
    putStrLn "==============================================================="
    repl [] initial_state