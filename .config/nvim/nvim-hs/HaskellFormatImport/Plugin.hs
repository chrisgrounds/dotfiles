{-# LANGUAGE OverloadedStrings #-}
module HaskellFormatImport.Plugin (haskellFormatImport) where

import Data.List
import qualified Data.Text as T
import qualified Data.Text.IO as T
import Data.Maybe
import Neovim
import Neovim.API.String
import Basement.IntegralConv (intToInt64)

qualifiedPadLength :: Int
qualifiedPadLength = 9

-- | Invokes the substitute command with given parameters
substitute :: (Int, Int) -> String -> String -> [String] -> Neovim env ()
substitute (start,end) ptn replacement flags = vim_command 
  $  show start
  ++ ","
  ++ show end
  ++ "substitute/"
  ++ ptn ++ "/"
  ++ replacement ++ "/"
  ++ mconcat flags

haskellFormatImport :: CommandArguments -> Neovim env ()
haskellFormatImport (CommandArguments _ range _ _) = do
  let (a, b) = fromMaybe (0,0) range
  buff <- vim_get_current_buffer
  allLines <- nvim_buf_get_lines buff (intToInt64 a) (intToInt64 b) False
  let allImportLines       = filter isImportStatement (zip [1..b] allLines)
      anyImportIsQualified = not . null $ filter isQualified allImportLines
      maxLength            = max $ fmap (\(_,s) -> length s) allImportLines
  -- nvim_buf_set_lines buff 0 0 False allImportLines

  -- nvim_buf_get_lines
  mapM_ (formatImportLine buff anyImportIsQualified maxLength) allImportLines

  -- mapM_ (\line -> substitute (0, 10) line (line ++ "bob") ["g"]) allImportLines
  return ()

formatImportLine buff qualifiedImports longestImport (lineNo, lineContent) = buffer_set_line buff (intToInt64 lineNo) $ padContent lineContent qualifiedImports longestImport

padContent content False longestImport = content ++ (take longestImport $ repeat ' ')

-- haskellFormatImport :: String -> Neovim env [T.Text]
-- haskellFormatImport path = do
--     fileContent <- liftIO $ T.readFile path

--     let splitIntoLInes = T.lines fileContent
--         imports        = filter isImportStatement splitIntoLInes
--         hasQualified   = any isQualified imports
--         paddedImports  = padImports imports hasQualified
--     -- let res = formatImport <$> lines a

--     liftIO $ T.writeFile path $ T.unlines paddedImports

--     return paddedImports

isImportStatement :: (Int, String) -> Bool
isImportStatement (_, s) = isInfixOf "import " s

isQualified :: (Int, String) -> Bool
isQualified (_, s) = isInfixOf "qualified " s

-- padImports :: [T.Text] -> Bool -> [T.Text]
-- padImports i False = i
-- padImports i True  = fmap padQualifiedIfMissing i

-- padQualifiedIfMissing :: T.Text -> T.Text
-- padQualifiedIfMissing s = if isQualified s || alreadyPadded s
--                              then s
--                              else T.replace "import" "import          " s

-- alreadyPadded = T.isInfixOf $ T.replicate qualifiedPadLength " "

-- formatImport :: String -> String
-- formatImport s = 

