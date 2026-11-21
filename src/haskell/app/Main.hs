{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import qualified Data.Text.IO as TIO
import qualified Data.Text as T
import Halley.Event (renderJsonl, renderReportWithQueries)
import Halley.Ingest (ingestDirectory, loadQueryAnswers)
import System.Environment (getArgs)
import System.Exit (die)
import System.FilePath ((</>))
import System.IO (IOMode (WriteMode), hSetEncoding, utf8, withFile)

main :: IO ()
main = do
  args <- getArgs
  let (dataDirectory, reportPath, eventsPath, queryPath) = case args of
        [directory] -> (directory, "report.md", "events.jsonl", Nothing)
        [directory, report, events] -> (directory, report, events, Nothing)
        [directory, report, events, queries] -> (directory, report, events, Just queries)
        [directory, output] -> (directory, output, "events.jsonl", Nothing)
        [] -> ("data" </> "demo", "report.md", "events.jsonl", Nothing)
        _ -> ("", "", "", Nothing)
  if null dataDirectory
    then die "Uso: halley-member1 [directorio-de-fuentes [archivo-informe.md [eventos.jsonl [consultas.jsonl]]]]"
    else do
      events <- ingestDirectory dataDirectory
      queries <- case queryPath of
        Nothing -> pure []
        Just path -> loadQueryAnswers path >>= either (die . T.unpack) pure
      withFile reportPath WriteMode $ \handle -> do
        hSetEncoding handle utf8
        TIO.hPutStr handle (renderReportWithQueries events queries)
      withFile eventsPath WriteMode $ \handle -> do
        hSetEncoding handle utf8
        TIO.hPutStr handle (renderJsonl events)
      putStrLn ("Informe escrito en " <> reportPath <> " (" <> show (length events) <> " registros).")
      putStrLn ("Eventos normalizados escritos en " <> eventsPath <> ".")
      putStrLn ("Respuestas incorporadas al informe: " <> show (length queries) <> ".")
