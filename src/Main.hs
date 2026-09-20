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
    | TIn String String
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
    | TTrans String String
    | TUpload String
    | TDownload String
    | TPerm [Int]
    deriving (Eq)

data State = State
    { input_stack       :: [Token]
    , var_stack         :: [String]
    , component_stack   :: [Token]
    , quant_stack       :: [String]
    , modifier_stack    :: [Token]
    , relation_stack    :: [Token]
    , clause_stack      :: [String]
    , output_stack      :: [Token]
    , count             :: Int
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
    TSym s -> if s == var then val else TSym s
    TBool b -> TBool b
    TDummy -> TDummy
    TNot t -> TNot (subst_var var val t)
    TOmega s -> if s == var then case val of TSym v -> TOmega v; _ -> TOmega s else TOmega s
    TIn a s ->
        let new_a = if a == var then case val of TSym v -> v; _ -> a else a
            new_s = if s == var then case val of TSym v -> v; _ -> s else s
        in TIn new_a new_s
    TLam v b -> if v == var then TLam v b else TLam v (subst_var var val b)
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
                       , state.var_stack
                       , state.component_stack
                       , state.quant_stack
                       , state.modifier_stack
                       , state.relation_stack
                       , state.clause_stack
                       , state.output_stack
                       ) of

    ( _, _, _, _, _, _, _, TOp "Not" : os_rest ) ->
        Just state
            { component_stack = TBool False : state.component_stack
            , output_stack    = os_rest
            }

    ( _, _, TBool False : cms_rest, _, _, _, _, TOp "Judge" : TSym a : os_rest ) ->
        Just state
            { component_stack = TSym a : TBool False : cms_rest
            , output_stack    = os_rest
            }

    ( _, _, cms, _, _, _, _, TOp "Judge" : TSym a : os_rest ) ->
        Just state
            { component_stack = TSym a : TBool True : cms
            , output_stack    = os_rest
            }

    ( _, _, TBool False : cms_rest, _, _, _, _, TOp "Pop" : os_rest ) ->
        Just state
            { component_stack = cms_rest
            , output_stack    = TBool False : os_rest
            }

    ( _, _, cms, _, _, _, _, TOp "Pop" : os_rest ) ->
        let new_cms = case cms of
                TBool True : rest -> rest
                _                 -> cms
        in Just state
            { component_stack = new_cms
            , output_stack    = TBool True : os_rest
            }

    ( _, a : vrs_rest, _, _, _, _, _, TOp "New" : os_rest ) ->
        Just state
            { var_stack    = vrs_rest
            , output_stack = TSym a : os_rest
            , fmap         = Map.insert a TDummy state.fmap
            }

    ( _, a : vrs_rest, _, _, _, _, _, TOp "Get" : os_rest ) ->
        Just state
            { var_stack    = vrs_rest
            , output_stack = TSym a : TDummy : os_rest
            }

    ( _, _, TSym a : big_a : cms_rest, _, _, _, _, TOp "Use" : os_rest ) ->
        Just state
            { component_stack = cms_rest
            , output_stack    = TSym a : TDummy : big_a : os_rest
            }

    ( _, a : vrs_rest, _, _, _, _, _, TOp "Bubble" : TSym b : os_rest ) ->
        Just state
            { var_stack    = a : b : vrs_rest
            , output_stack = os_rest
            }

    ( _, _, _, _, _, _, _, TOp "Formula" : TSym a : big_a : os_rest ) ->
        Just state
            { output_stack = os_rest
            , fmap         = Map.insert a big_a state.fmap
            }

    ( _, _, _, _, _, _, _, TOp "Insert" : TSym a : big_a : os_rest ) ->
        case Map.lookup a state.fmap of
            Just old_f ->
                Just state
                    { output_stack = os_rest
                    , fmap         = Map.insert a (smart_and old_f big_a) state.fmap
                    }
            Nothing -> Nothing

    ( is_rest, _, _, _, _, _, _, TOp "Apply" : TLam a big_a : big_b : os_rest ) ->
        Just state
            { input_stack  = subst_var a big_b big_a : is_rest
            , output_stack = os_rest
            }

    ( _, _, _, _, _, _, _, TOp "Substitute" : TSym a : big_a : big_b : os_rest ) ->
        Just state
            { output_stack = subst_var a big_b big_a : os_rest
            }

    ( _, _, _, _, _, _, _, TOp "Conjunction" : big_a : big_b : os_rest ) ->
        Just state
            { output_stack = smart_and big_a big_b : os_rest
            }

    ( _, _, _, _, _, _, _, TOp "Negation" : TSym a : big_a : os_rest ) ->
        Just state
            { output_stack = TSym a : TNot big_a : os_rest
            }

    ( _, a : _, _, _, _, _, _, TQuant q : os_rest ) ->
        Just state
            { qmap         = Map.insert a q state.qmap
            , output_stack = os_rest
            }

    ( _, _, _, _, _, _, _, TRelName r_name : TSym a : big_b : c_val : TSym b : big_d : os_rest ) ->
        let is_pos = case c_val of
                TBool True -> True
                TSym "True" -> True
                _ -> False
            rel   = TRel r_name (TSym b) (TSym a)
            e_val = if is_pos then rel else TNot rel
        in Just state
            { output_stack = TSym b : smart_and (smart_and big_b big_d) e_val : os_rest
            }

    ( _, a : vrs_rest, _, _, _, _, _, TConn conn_name : TSym b : big_b : TSym c_sym : big_c : os_rest ) ->
        let res = smart_and (TRel (conn_name ++ "_consequent") (TSym a) (TSym b))
                    (smart_and (TRel (conn_name ++ "_antecedent") (TSym a) (TSym c_sym))
                        (smart_and big_b big_c))
        in Just state
            { var_stack    = vrs_rest
            , output_stack = TSym a : res : os_rest
            }

    ( _, _, TSym a : _, _, _, _, _, TTrans prefix suffix : os_rest ) ->
        case Map.lookup a state.amap of
            Just b -> case Map.lookup b state.smap of
                Just old_s ->
                    let new_s = prefix ++ old_s ++ suffix
                    in Just state
                        { output_stack = os_rest
                        , smap         = Map.insert b new_s state.smap
                        }
                Nothing -> Nothing
            Nothing -> Nothing

    ( _, _, _, _, _, _, _, TOp "Add" : os_rest ) ->
        Just state
            { output_stack = os_rest
            , count        = state.count + 1
            }

    ( _, _, _, _, _, rl_stack, _, TOp "Deter" : os_rest ) ->
        let new_rl    = if state.count == 0 then TOp "Deter" : rl_stack else rl_stack
            new_count = if state.count > 0 then state.count - 1 else 0
        in Just state
            { output_stack   = os_rest
            , relation_stack = new_rl
            , count          = new_count
            }

    ( _, _, _, _, _, rl_stack, _, TOp "Join" : a : os_rest ) ->
        Just state
            { output_stack   = os_rest
            , relation_stack = a : rl_stack
            }

    ( _, _, _, _, _, TOp "Deter" : rls_rest, _, TOp "Absorb" : os_rest ) ->
        Just state
            { output_stack   = os_rest
            , relation_stack = rls_rest
            }

    ( is_rest, _, _, _, _, a : rls_rest, _, TOp "Absorb" : os_rest ) ->
        Just state
            { input_stack    = a : TOp "Absorb" : is_rest
            , output_stack   = os_rest
            , relation_stack = rls_rest
            }

    ( _, _, TSym a : _, _, _, _, _, TUpload b : os_rest ) ->
        Just state
            { emap         = Map.insert b a state.emap
            , output_stack = os_rest
            }

    ( is_rest, _, _, _, _, rl_stack, _, TDownload a : os_rest ) ->
        case Map.lookup a state.emap of
            Just val -> Just state
                { input_stack    = TSym val : TOp "Judge" : TOp "Deter" : is_rest
                , output_stack   = os_rest
                , relation_stack = TList [TOp "Use"] : rl_stack
                }
            Nothing -> Nothing

    ( _, _, _, qns, _, _, _, TPerm idxs : os_rest ) ->
        let n = length idxs
        in if length qns >= n
            then
                let (top_n, rest) = splitAt n qns
                    permuted = map (\i -> top_n !! (i - 1)) (reverse idxs)
                in Just state
                    { quant_stack  = permuted ++ rest
                    , output_stack = os_rest
                    }
            else Nothing

    ( _, _, _, a : b : qns_rest, _, _, _, TOp "Swap" : os_rest ) ->
        Just state
            { quant_stack  = b : a : qns_rest
            , output_stack = os_rest
            }

    ( _, _, _, a : qns_rest, _, _, _, TOp "Go" : os_rest ) ->
        Just state
            { quant_stack  = qns_rest
            , output_stack = TSym a : os_rest
            }

    ( _, _, _, _, _, _, _, TOp "Back" : TSym a : os_rest ) ->
        Just state
            { quant_stack  = a : state.quant_stack
            , output_stack = os_rest
            }

    ( _, _, _, a : qns_rest, _, _, _, TOp "Build" : TSym b : big_a : os_rest ) ->
        case Map.lookup a state.amap of
            Just c -> case Map.lookup c state.smap of
                Just s -> case Map.lookup c state.fmap of
                    Just f ->
                        let q = Map.findWithDefault "Exist" a state.qmap
                        in Just state
                            { quant_stack  = qns_rest
                            , output_stack = TSym b : TBuild q a c s f big_a : os_rest
                            }
                    Nothing -> Nothing
                Nothing -> Nothing
            Nothing -> Nothing

    ( _, _, _, _, _, _, _, TOp "Event" : TSym a : big_a : os_rest ) ->
        Just state
            { output_stack = TSym a : smart_and (TIn a "Ω") big_a : os_rest
            }

    ( is_rest, _, _, "None" : _, _, _, _, TOp "End" : os_rest ) ->
        Just state
            { input_stack  = TOp "Event" : is_rest
            , output_stack = os_rest
            }

    ( is_rest, _, _, a : _, _, _, _, TOp "End" : os_rest )
        | a /= "None" ->
            Just state
                { input_stack  = TOp "Build" : TOp "End" : is_rest
                , output_stack = os_rest
                }

    ( _, _, _, a : qns_rest, _, _, _, TOp "That" : os_rest ) ->
        Just state
            { quant_stack  = qns_rest
            , clause_stack = a : state.clause_stack
            , output_stack = os_rest
            }

    ( is_rest, _, _, _, _, rl_stack, a : cls_rest, TOp "Clause" : TSym b : big_a : os_rest ) ->
        case Map.lookup a state.amap of
            Just c ->
                let omega_b_and_a = smart_and (TIn b "Ω") big_a
                    tokens = [ TSym a
                             , TOp "Judge"
                             , TSym c
                             , omega_b_and_a
                             , TSym a
                             , TOp "Substitute"
                             , TSym c
                             , TOp "Insert"
                             ]
                in Just state
                    { input_stack    = tokens ++ is_rest
                    , quant_stack    = a : state.quant_stack
                    , clause_stack   = cls_rest
                    , relation_stack = TOp "Deter" : TList [TOp "Use"] : rl_stack
                    , output_stack   = os_rest
                    }
            Nothing -> Nothing

    ( is_rest, a : b : vrs_rest, _, _, TOp "Stop" : _, _, _, TSet set_name : os_rest ) ->
        Just state
            { input_stack   = TSym a : TOp "Judge" : is_rest
            , var_stack     = vrs_rest
            , quant_stack   = a : state.quant_stack
            , output_stack  = os_rest
            , amap          = Map.insert a b state.amap
            , smap          = Map.insert b set_name state.smap
            , fmap          = Map.insert b TDummy state.fmap
            }

    ( is_rest, a : b : vrs_rest, _, _, TSym c : big_a : mds_rest, _, _, TSet set_name : os_rest ) ->
        case Map.lookup c state.fmap of
            Just f_c ->
                let applied = eval_app (eval_app (eval_app big_a (TSym b)) (TSym c)) f_c
                    tokens  = [ TSym a
                              , TOp "Judge"
                              , applied
                              , TLam "z" (TList [])
                              , TOp "Apply"
                              , TSym b
                              , TOp "Formula"
                              ]
                in Just state
                    { input_stack    = tokens ++ is_rest
                    , var_stack      = vrs_rest
                    , quant_stack    = a : state.quant_stack
                    , modifier_stack = mds_rest
                    , output_stack   = os_rest
                    , amap           = Map.insert a b state.amap
                    , smap           = Map.insert b set_name state.smap
                    }
            Nothing -> Nothing

    ( _, a : vrs_rest, _, _, TSym b : big_a : TSym c : big_b : mds_rest, _, _, TOp "Combine" : os_rest ) ->
        case Map.lookup c state.fmap of
            Just f_c -> case Map.lookup b state.fmap of
                Just f_b ->
                    let body = TList (reverse
                            [ TConn "And", TOp "Apply", TOp "Apply", TOp "Apply", big_b, TSym "x", TSym c
                            , TOp "Conjunction", f_c, TOp "Substitute", TSym "y", TSym "z", TSym c
                            , TOp "Apply", TOp "Apply", TOp "Apply", big_a, TSym "x", TSym b
                            , TOp "Conjunction", f_b, TOp "Substitute", TSym "y", TSym "z", TSym b
                            ])
                        combined = TLam "x" (TLam "y" (TLam "z" body))
                    in Just state
                        { var_stack      = vrs_rest
                        , modifier_stack = TSym a : combined : mds_rest
                        , output_stack   = os_rest
                        , fmap           = Map.insert a TDummy state.fmap
                        }
                Nothing -> Nothing
            Nothing -> Nothing

    ( _, _, _, _, _, _, _, TOp "Combine" : os_rest ) ->
        Just state
            { output_stack = os_rest
            }

    ( _, a : vrs_rest, _, _, _, _, _, TOp "Empty" : os_rest ) ->
        let empty_lam = TLam "x" (TLam "y" (TLam "z" (TList [TDummy, TSym a])))
        in Just state
            { var_stack      = vrs_rest
            , modifier_stack = TSym a : empty_lam : state.modifier_stack
            , output_stack   = os_rest
            , fmap           = Map.insert a TDummy state.fmap
            }

    ( _, _, _, _, _, _, _, TOp "For" : os_rest ) ->
        Just state
            { modifier_stack = TOp "For" : state.modifier_stack
            , output_stack   = os_rest
            }

    ( _, _, _, _, TOp "For" : mds_rest, _, _, TOp "Cancel" : os_rest ) ->
        Just state
            { modifier_stack = mds_rest
            , output_stack   = os_rest
            }

    ( _, _, _, _, _, _, _, TOp "Merge" : TSym _ : big_a : TSym b_sym : big_b : os_rest ) ->
        case Map.lookup b_sym state.fmap of
            Just f_b -> Just state
                { modifier_stack = TSym b_sym : big_b : state.modifier_stack
                , output_stack   = os_rest
                , fmap           = Map.insert b_sym (smart_and f_b big_a) state.fmap
                }
            Nothing -> Nothing

    ( is_rest, _, _, _, TOp "For" : TSym a : big_a : mds_rest, _, _, TOp "Modify" : TSym b : big_b : os_rest ) ->
        case Map.lookup a state.fmap of
            Just f_a ->
                let applied = eval_app (eval_app (eval_app big_a (TSym b)) (TSym a)) f_a
                in Just state
                    { input_stack    = applied : TOp "Merge" : is_rest
                    , modifier_stack = mds_rest
                    , output_stack   = TSym b : big_b : os_rest
                    }
            Nothing -> Nothing

    ( _, _, _, _, _, _, _, TOp "Modify" : TSym a : big_a : os_rest ) ->
        Just state
            { modifier_stack = TSym a : big_a : state.modifier_stack
            , output_stack   = os_rest
            }

    ( is_rest, _, _, _, TOp "For" : TSym a : big_a : TSym b : big_b : mds_rest, _, _, TOp "Exchange" : os_rest ) ->
        Just state
            { input_stack    = TOp "Modify" : is_rest
            , modifier_stack = TOp "For" : TSym a : big_a : mds_rest
            , output_stack   = TSym b : big_b : os_rest
            }

    ( is_rest, a : vrs_rest, _, _, TOp "Stop" : _, rl_stack, _, TOp "Noun" : TSym b : big_a : os_rest ) ->
        Just state
            { input_stack    = TSym b : TOp "Judge" : is_rest
            , var_stack      = vrs_rest
            , quant_stack    = b : state.quant_stack
            , relation_stack = TOp "Deter" : TList [TOp "Use"] : rl_stack
            , output_stack   = os_rest
            , amap           = Map.insert b a state.amap
            , smap           = Map.insert a "Ω" state.smap
            , fmap           = Map.insert a (subst_var b (TSym a) big_a) state.fmap
            }

    ( is_rest, a : vrs_rest, _, _, TSym b : big_a : mds_rest, rl_stack, _, TOp "Noun" : TSym c : big_b : os_rest ) ->
        case Map.lookup b state.fmap of
            Just f_b ->
                let applied = eval_app (eval_app (eval_app big_a (TSym a)) (TSym b)) f_b
                    tokens  = [ TSym c
                              , TOp "Judge"
                              , applied
                              , TLam "z" (TList [])
                              , TOp "Apply"
                              , TSym a
                              , TOp "Insert"
                              ]
                in Just state
                    { input_stack    = tokens ++ is_rest
                    , var_stack      = vrs_rest
                    , quant_stack    = c : state.quant_stack
                    , modifier_stack = mds_rest
                    , relation_stack = TOp "Deter" : TList [TOp "Use"] : rl_stack
                    , output_stack   = os_rest
                    , amap           = Map.insert c a state.amap
                    , smap           = Map.insert a "Ω" state.smap
                    , fmap           = Map.insert a (subst_var c (TSym a) big_b) state.fmap
                    }
            Nothing -> Nothing

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

strip_quotes :: String -> String
strip_quotes str
    | length str >= 2 && head str == '"' && last str == '"' = init (tail str)
    | otherwise = str

parse_atom :: String -> Token
parse_atom raw_s
    | s == "#"                                    = TDummy
    | s == "True"                                 = TBool True
    | s == "False"                                = TBool False
    | s `elem` [ "Not", "Judge", "Pop", "New", "Get", "Use", "Bubble", "Formula", "Insert"
               , "Apply", "Substitute", "Conjunction", "Negation", "Add", "Deter", "Join"
               , "Absorb", "Swap", "Go", "Back", "Build", "Event", "End", "That", "Clause"
               , "Empty", "For", "Cancel", "Merge", "Modify", "Exchange", "Noun", "Stop"
               , "Combine"
               ]                                  = TOp s
    | s == "Exist"                                = TQuant "Exist"
    | s == "All"                                  = TQuant "All"
    | ":S" `isSuffixOf` s                         = TSet (strip_quotes (take (length s - 2) s))
    | ":R" `isSuffixOf` s                         = TRelName (strip_quotes (take (length s - 2) s))
    | ":Q" `isSuffixOf` s                         =
        let q = strip_quotes (take (length s - 2) s)
        in if q == "All" then TQuant "All" else TQuant "Exist"
    | ":C" `isSuffixOf` s                         = TConn (strip_quotes (take (length s - 2) s))
    | ":F" `isSuffixOf` s                         =
        let base = strip_quotes (take (length s - 2) s)
            (pre, rest) = break (== '$') base
        in TTrans (strip_quotes pre) (strip_quotes (if null rest then "" else drop 1 rest))
    | '$' `elem` s                                =
        let (pre, rest) = break (== '$') s
        in TTrans (strip_quotes pre) (strip_quotes (drop 1 rest))
    | otherwise                                   = TSym s
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

show_token :: Token -> String
show_token token = case token of
    TSym s             -> s
    TBool b            -> show b
    TDummy             -> "#"
    TNot t@(TAnd _ _)  -> "Not(" ++ show_token t ++ ")"
    TNot t             -> "Not " ++ show_token_nested t
    TOmega a           -> "Ω(" ++ a ++ ")"
    TIn a s            -> a ++ "∈" ++ s
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
    TTrans pre post    -> pre ++ "$" ++ post
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
    putStrLn $ "Var Stack (VR):         " ++ show_vus s.var_stack
    putStrLn $ "Component Stack (CM):   " ++ show_stack s.component_stack
    putStrLn $ "Quant Stack (QN):       " ++ show_var_stack s.quant_stack
    putStrLn $ "Modifier Stack (MD):    " ++ show_stack s.modifier_stack
    putStrLn $ "Relation Stack (RL):    " ++ show_stack s.relation_stack
    putStrLn $ "Clause Stack (CL):      " ++ show_var_stack s.clause_stack
    putStrLn $ "Output Stack (OP):      " ++ show_stack s.output_stack
    putStrLn $ "Counter (Count):        " ++ show s.count
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
    , var_stack         = ["v" ++ show i | i <- [(1 :: Int)..]]
    , component_stack   = []
    , quant_stack       = ["None"]
    , modifier_stack    = [TOp "Stop"]
    , relation_stack    = [TOp "Deter"]
    , clause_stack      = []
    , output_stack      = []
    , count             = 0
    , emap              = Map.empty
    , qmap              = Map.empty
    , smap              = Map.empty
    , fmap              = Map.empty
    , amap              = Map.empty
    }

repl :: MacroEnv -> State -> IO ()
repl env state = do
    putStrLn "\nReady for input (:q to quit, :r to reset, // for trace mode, define <name> := <expr>, suffix * to auto-reset):"
    input_str <- getLine
    let trimmed = trim input_str
    case trimmed of
        ":q" -> putStrLn "Exiting Deduction Engine."
        ":r" -> do
            putStrLn "System reset. Stacks, maps, and counter cleared (macros preserved)."
            repl env initial_state
        "" -> repl env state
        _ ->
            let (auto_reset, no_star) =
                    if not (null trimmed) && last trimmed == '*'
                        then (True, trim (init trimmed))
                        else (False, trimmed)
            in case parse_define_cmd no_star of
                Just (name, def_str) -> case parse_input env def_str of
                    Just [tok] -> do
                        putStrLn $ "Macro defined: " ++ name ++ " := " ++ show_token tok
                        if auto_reset
                            then do
                                putStrLn "System reset (:r auto-executed, macros preserved)."
                                repl ((name, tok) : env) initial_state
                            else repl ((name, tok) : env) state
                    _ -> do
                        putStrLn "Error: Failed to parse macro definition."
                        repl env state
                Nothing -> do
                    let (silent, expr_str) =
                            if "//" `isPrefixOf` no_star
                                then (False, trim (drop 2 no_star))
                                else (True, no_star)
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
                            if auto_reset
                                then do
                                    putStrLn "\n[Auto Reset]: Stacks and maps cleared (:r auto-executed, macros preserved)."
                                    repl env initial_state
                                else repl env final_state

main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    putStrLn "==============================================================="
    putStrLn " Eight-Stack Five-Mapping One-Counter Semantic Deduction Engine"
    putStrLn "==============================================================="
    repl [] initial_state