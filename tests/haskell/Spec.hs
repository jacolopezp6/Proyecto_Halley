{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Monad (unless)
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (UTCTime)
import Halley.Event
import Halley.Ingest (ingestDirectory)
import System.Exit (exitFailure)

main :: IO ()
main = do
  check "UTC timestamp" (normalizeTimestamp "2042-07-12T03:00:00Z" /= Nothing)
  check "explicit offset" (normalizeTimestamp "2042-07-12T05:00:00+0200" == normalizeTimestamp "2042-07-12T03:00:00Z")
  check "ISO offset with colon" (normalizeTimestamp "2042-07-12T05:00:00+02:00" == normalizeTimestamp "2042-07-12T03:00:00Z")
  check "unzoned timestamp remains unknown" (normalizeTimestamp "2042-07-12T03:00:00" == (Nothing :: Maybe UTCTime))
  events <- ingestDirectory "../../tests/fixtures/member1-demo"
  check "all eight sources load" (length events == 28)
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
