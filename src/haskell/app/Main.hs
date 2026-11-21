{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import qualified Data.Text.IO as TIO
import Halley.Event (renderJsonl, renderReport)
import Halley.Ingest (ingestDirectory)
import System.Environment (getArgs)
import System.Exit (die)
import System.FilePath ((</>))
import System.IO (IOMode (WriteMode), hSetEncoding, utf8, withFile)

main :: IO ()
main = do
  args <- getArgs
  let (dataDirectory, reportPath, eventsPath) = case args of
        [directory] -> (directory, "report.md", "events.jsonl")
        [directory, report, events] -> (directory, report, events)
        [directory, output] -> (directory, output, "events.jsonl")
        [] -> ("data" </> "demo", "report.md", "events.jsonl")
        _ -> ("", "", "")
  if null dataDirectory
    then die "Uso: halley-member1 [directorio-de-fuentes [archivo-informe.md [eventos.jsonl]]]"
    else do
      events <- ingestDirectory dataDirectory
      withFile reportPath WriteMode $ \handle -> do
        hSetEncoding handle utf8
        TIO.hPutStr handle (renderReport events)
      withFile eventsPath WriteMode $ \handle -> do
        hSetEncoding handle utf8
        TIO.hPutStr handle (renderJsonl events)
      putStrLn ("Informe escrito en " <> reportPath <> " (" <> show (length events) <> " registros).")
      putStrLn ("Eventos normalizados escritos en " <> eventsPath <> ".")
