{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Monad (unless)
import qualified Data.ByteString.Char8 as BSC
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (UTCTime)
import Halley.Event
import Halley.Ingest (ingestDirectory, loadQueryAnswers)
import Halley.Sha256 (sha256Hex)
import System.Exit (exitFailure)

main :: IO ()
main = do
  check "SHA-256 known vector" (sha256Hex (BSC.pack "abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
  check "UTC timestamp" (normalizeTimestamp "2042-07-12T03:00:00Z" /= Nothing)
  check "explicit offset" (normalizeTimestamp "2042-07-12T05:00:00+0200" == normalizeTimestamp "2042-07-12T03:00:00Z")
  check "ISO offset with colon" (normalizeTimestamp "2042-07-12T05:00:00+02:00" == normalizeTimestamp "2042-07-12T03:00:00Z")
  check "unzoned timestamp remains unknown" (normalizeTimestamp "2042-07-12T03:00:00" == (Nothing :: Maybe UTCTime))
  events <- ingestDirectory "../../tests/fixtures/member1-demo"
  check "all eight sources load" (length events == 28)
  check "each parsed event has source SHA-256" (all hasHash events)
  let badPresence = findEvent "presencia.csv#3" events
  check "corrupt presence reading is invalid" (maybe False ((== Invalid) . validationStatus) badPresence)
  check "corrupt original is preserved" (maybe False ((== "2042-07-12T03:05:00Z,P3,dos") . recordOriginal) badPresence)
  let lukaRead = findEvent "tarjetas.csv#3" events
  check "alias Luka resolves without replacing recorded name" $
    maybe False (\event -> Map.lookup "canonical_person_id" (content event) == Just "PERS-021" && Map.lookup "person_as_recorded" (content event) == Just "Luka") lukaRead
  check "duplicate is reported without deletion" (maybe False ((== DuplicateCandidate) . validationStatus) (findEvent "tarjetas.csv#6" events))
  check "same-sensor disagreement is marked as conflict" (maybe False ((== Conflicting) . validationStatus) (findEvent "presencia.csv#5" events))
  check "unknown module is diagnosed against station reference" (maybe False (any ((== "UNKNOWN_MODULE") . diagnosticCode) . diagnostics) (findEvent "presencia.csv#6" events))
  check "corrupt card record is preserved and invalid" (maybe False ((== Invalid) . validationStatus) (findEvent "tarjetas.csv#3" events))
  check "CRLF CSV row parses while retaining its original terminator" $ maybe False
    (\event -> validationStatus event == Valid && T.isSuffixOf "\r" (recordOriginal event))
    (findEvent "estacion.csv#4" events)
  let ordered = orderTimeline events
  check "timeline is ordered with dated records first" (allTimesOrdered ordered)
  let answerRecord = QueryAnswer "Q-1" "¿Qué sustenta la presencia en P3?" "Se observó un conteo de dos personas." "supported" ["presencia.csv#2"] ["El sensor registró el conteo correctamente."] ["El sensor no identifica personas."] "demo-v1"
      report = renderReportWithQueries events [answerRecord]
  check "report includes query evidence and limits" ("presencia.csv#2" `T.isInfixOf` report && "El sensor no identifica personas." `T.isInfixOf` report)
  let jsonl = renderJsonl events
  check "JSONL preserves malformed source record" ("\"record_original\":\"2042-07-12T03:05:00Z,P3,dos\"" `T.isInfixOf` jsonl)
  check "JSONL includes ingest time and source location" ("\"ingested_at_utc\":\"" `T.isInfixOf` jsonl && "\"location\":\"line:3\"" `T.isInfixOf` jsonl)
  check "JSON object original is preserved" $
    maybe False (T.isPrefixOf "{" . recordOriginal) (findEvent "energia.json#1" events)
  queryResult <- loadQueryAnswers "../../tests/fixtures/member1-demo/queries.jsonl"
  case queryResult of
    Left _ -> check "demo query response parses" False
    Right queries -> do
      check "demo query response parses" (length queries == 1)
      check "report query links evidence and snapshot" (case queries of
        [query] -> evidenceIds query == ["presencia.csv#2", "presencia.csv#5"] && datasetVersion query == "demo-v1"
        _ -> False)
      check "query JSON Unicode escapes decode" (case queries of
        [query] -> question query == "¿Qué muestran los registros de presencia en P3 a las 02:55 UTC?"
        _ -> False)
      check "loaded query appears in report" ("Q-DEMO-01" `T.isInfixOf` renderReportWithQueries events queries)
  invalidQuery <- loadQueryAnswers "../../tests/fixtures/member1-demo/queries-invalid.jsonl"
  check "incomplete query response is rejected" (case invalidQuery of Left _ -> True; Right _ -> False)
  putStrLn "All member 1 checks passed."

check :: String -> Bool -> IO ()
check label condition = unless condition $ do
  putStrLn ("FAIL: " <> label)
  exitFailure

findEvent :: Text -> [Event] -> Maybe Event
findEvent wanted = foldr (\event rest -> if eventId event == wanted then Just event else rest) Nothing

allTimesOrdered :: [Event] -> Bool
allTimesOrdered events = dates == (quickSort dates)
  where
    dates = [stamp | event <- events, Just stamp <- [occurredAtUtc event]]
    quickSort [] = []
    quickSort (x : xs) = quickSort [a | a <- xs, a < x] <> [x] <> quickSort [a | a <- xs, a >= x]

hasHash :: Event -> Bool
hasHash event = case provenanceSha256 event of
  Just digest -> T.length digest == 64
  Nothing -> False
