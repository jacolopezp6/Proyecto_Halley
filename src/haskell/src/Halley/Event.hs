{-# LANGUAGE OverloadedStrings #-}

module Halley.Event
  ( Event (..)
  , QueryAnswer (..)
  , EventType (..)
  , ValidationStatus (..)
  , Diagnostic (..)
  , normalizeTimestamp
  , orderTimeline
  , renderReport
  , renderReportWithQueries
  , renderJsonl
  ) where

import Data.List (sortOn)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Char (ord)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (UTCTime, defaultTimeLocale, formatTime, parseTimeM)
import Numeric (showHex)

data EventType
  = CardRead
  | PresenceReading
  | TemperatureReading
  | RadioMessage
  | EnergyReading
  | LogEntry
  | ReferenceRecord
  | UnknownEvent
  deriving (Eq, Ord, Show)

data ValidationStatus
  = Valid
  | Invalid
  | Ambiguous
  | DuplicateCandidate
  | Conflicting
  | Unparsed
  deriving (Eq, Ord, Show)

data Diagnostic = Diagnostic
  { diagnosticCode :: Text
  , diagnosticMessage :: Text
  }
  deriving (Eq, Show)

data Event = Event
  { eventId :: Text
  , sourceId :: Text
  , sourceRecordId :: Text
  , recordOriginal :: Text
  , occurredAtUtc :: Maybe UTCTime
  , timeOriginal :: Maybe Text
  , eventType :: EventType
  , content :: Map Text Text
  , validationStatus :: ValidationStatus
  , diagnostics :: [Diagnostic]
  , provenanceSha256 :: Maybe Text
  , ingestedAtUtc :: Maybe UTCTime
  }
  deriving (Eq, Show)

data QueryAnswer = QueryAnswer
  { queryId :: Text
  , question :: Text
  , answer :: Text
  , certainty :: Text
  , evidenceIds :: [Text]
  , assumptions :: [Text]
  , limitations :: [Text]
  , datasetVersion :: Text
  }
  deriving (Eq, Show)

-- Only timestamps with an explicit UTC marker or numeric offset are accepted.
-- A local-looking time is not silently assigned a timezone.
normalizeTimestamp :: Text -> Maybe UTCTime
normalizeTimestamp raw = firstJust (map parseFormat formats)
  where
    value = T.unpack (T.strip raw)
    formats =
      [ "%Y-%m-%dT%H:%M:%S%QZ"
      , "%Y-%m-%dT%H:%M:%S%Q%z"
      , "%Y-%m-%dT%H:%M:%S%Q%Ez"
      , "%Y-%m-%d %H:%M:%S%QZ"
      , "%Y-%m-%d %H:%M:%S%Q%z"
      , "%Y-%m-%d %H:%M:%S%Q%Ez"
      ]
    parseFormat fmt = parseTimeM True defaultTimeLocale fmt value
    firstJust [] = Nothing
    firstJust (Nothing : xs) = firstJust xs
    firstJust (x : _) = x

-- Dated events are ordered first by UTC time, then by stable event ID.
-- Undated records follow in source/record order so they remain visible.
orderTimeline :: [Event] -> [Event]
orderTimeline = sortOn key
  where
    key event =
      ( maybe (1 :: Int) (const 0) (occurredAtUtc event)
      , occurredAtUtc event
      , sourceId event
      , sourceRecordId event
      , eventId event
      )

renderReport :: [Event] -> Text
renderReport events = renderReportWithQueries events []

renderReportWithQueries :: [Event] -> [QueryAnswer] -> Text
renderReportWithQueries events queries = T.unlines (header <> summary <> timeline <> anomalySection <> querySection)
  where
    ordered = orderTimeline events
    invalidEvents = filter ((/= Valid) . validationStatus) ordered
    header = ["# Halley-7 — informe de ingesta", "", "> Conjunto de demostración: verificar contra las fuentes originales antes de extraer conclusiones del caso.", ""]
    summary =
      [ "## Resumen"
      , ""
      , "- Registros procesados: " <> tshow (length events)
      , "- Registros válidos: " <> tshow (length (filter ((== Valid) . validationStatus) events))
      , "- Registros con anomalías: " <> tshow (length invalidEvents)
      , "- Eventos sin hora UTC interpretable: " <> tshow (length (filter (maybe True (const False) . occurredAtUtc) events))
      , ""
      , "## Línea de tiempo (UTC)"
      , ""
      , "| UTC | Fuente | Registro | Tipo | Estado | Contenido |"
      , "|---|---|---|---|---|---|"
      ]
    timeline = map renderEvent ordered
    anomalySection =
      [ ""
      , "## Diagnósticos"
      , ""
      ] <> if null invalidEvents then ["No se detectaron anomalías en los registros procesados."] else concatMap renderDiagnostics invalidEvents
    querySection =
      [ ""
      , "## Consultas y respuestas"
      , ""
      ] <> if null queries then ["No se recibieron respuestas de consultas para esta ejecución."] else concatMap renderQuery queries
    renderQuery query =
      [ "### " <> queryId query <> " — " <> question query
      , ""
      , "- Respuesta: " <> answer query
      , "- Nivel: " <> certainty query
      , "- Versión de datos: " <> datasetVersion query
      , "- Evidencia: " <> listOrNone (evidenceIds query)
      , "- Supuestos: " <> listOrNone (assumptions query)
      , "- Límites: " <> listOrNone (limitations query)
      ]
    renderEvent event =
      "| " <> maybe "sin hora" formatUtc (occurredAtUtc event)
        <> " | " <> sourceId event
        <> " | " <> sourceRecordId event
        <> " | " <> tshow (eventType event)
        <> " | " <> tshow (validationStatus event)
        <> " | " <> escapeCell (T.intercalate "; " [k <> "=" <> v | (k, v) <- Map.toAscList (content event)])
        <> " |"
    renderDiagnostics event =
      ("- **" <> eventId event <> "** (" <> sourceId event <> ":" <> sourceRecordId event <> "):")
        : map (\d -> "  - " <> diagnosticCode d <> ": " <> diagnosticMessage d) (diagnostics event)
    escapeCell = T.replace "|" "\\|" . T.replace "\n" " "
    listOrNone [] = "ninguno declarado"
    listOrNone xs = T.intercalate ", " xs
    formatUtc = T.pack . formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%SZ"
    tshow :: Show a => a -> Text
    tshow = T.pack . show

renderJsonl :: [Event] -> Text
renderJsonl = T.unlines . map encodeEvent . orderTimeline
  where
    encodeEvent event =
      "{"
        <> field "event_id" (jsonString (eventId event)) <> ","
        <> "\"occurred_at_utc\":" <> maybe "null" (jsonString . formatUtc) (occurredAtUtc event) <> ","
        <> "\"time_original\":" <> maybe "null" jsonString (timeOriginal event) <> ","
        <> field "source_id" (jsonString (sourceId event)) <> ","
        <> field "source_record_id" (jsonString (sourceRecordId event)) <> ","
        <> field "record_original" (jsonString (recordOriginal event)) <> ","
        <> field "event_type" (jsonString (eventTypeName (eventType event))) <> ","
        <> field "content" (jsonObject (content event)) <> ","
        <> field "validation_status" (jsonString (statusName (validationStatus event))) <> ","
        <> field "diagnostics" (jsonArray (map encodeDiagnostic (diagnostics event))) <> ","
        <> field "provenance" ("{\"file\":" <> jsonString (sourceId event) <> ",\"sha256\":" <> maybe "null" jsonString (provenanceSha256 event) <> ",\"parser_version\":\"0.1.0\",\"location\":" <> jsonString (sourceRecordId event) <> "}") <> ","
        <> field "ingested_at_utc" (maybe "null" (jsonString . formatUtc) (ingestedAtUtc event)) <> ","
        <> field "schema_version" (jsonString "1") <> ","
        <> field "correction_of" "null"
        <> "}"
    encodeDiagnostic item = jsonObject (Map.fromList [("code", diagnosticCode item), ("message", diagnosticMessage item)])
    field name value = jsonString name <> ":" <> value
    jsonObject fields = "{" <> T.intercalate "," [jsonString key <> ":" <> jsonString value | (key, value) <- Map.toAscList fields] <> "}"
    jsonArray values = "[" <> T.intercalate "," values <> "]"
    jsonString value = "\"" <> T.concatMap escape value <> "\""
    escape '"' = "\\\""
    escape '\\' = "\\\\"
    escape '\n' = "\\n"
    escape '\r' = "\\r"
    escape '\t' = "\\t"
    escape c
      | ord c < 32 = "\\u00" <> T.pack (padHex (showHex (ord c) ""))
      | otherwise = T.singleton c
    padHex [digit] = ['0', digit]
    padHex digits = digits
    formatUtc = T.pack . formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%SZ"
    eventTypeName CardRead = "card_read"
    eventTypeName PresenceReading = "presence_reading"
    eventTypeName TemperatureReading = "temperature_reading"
    eventTypeName RadioMessage = "radio_message"
    eventTypeName EnergyReading = "energy_reading"
    eventTypeName LogEntry = "log_entry"
    eventTypeName ReferenceRecord = "reference_record"
    eventTypeName UnknownEvent = "unknown"
    statusName Valid = "valid"
    statusName Invalid = "invalid"
    statusName Ambiguous = "ambiguous"
    statusName DuplicateCandidate = "duplicate_candidate"
    statusName Conflicting = "conflicting"
    statusName Unparsed = "unparsed"
