{-# LANGUAGE OverloadedStrings #-}

module Halley.Ingest (ingestDirectory, loadQueryAnswers) where

import Control.Exception (IOException, try)
import Data.Char (chr, digitToInt, isHexDigit, isSpace)
import Data.List (find, nub)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.ByteString as BS
import qualified Data.Text.Encoding as TE
import Halley.Event
import Halley.Sha256 (sha256Hex)
import Data.Time (UTCTime)
import Data.Time.Clock (getCurrentTime)
import System.FilePath ((</>))
import Text.Parsec (Parsec, between, char, choice, count, eof, getInput, hexDigit, many, many1, noneOf, parse, sepBy, skipMany, space, string)
import qualified Text.Parsec as P

type Row = Map Text Text
type Parser = Parsec Text ()

loadQueryAnswers :: FilePath -> IO (Either Text [QueryAnswer])
loadQueryAnswers path = do
  result <- readUtf8 path
  pure $ case result of
    Left exception -> Left (T.pack (show exception))
    Right (raw, _) -> traverse (parseQueryLine path) [(number, line) | (number, line) <- numbered (T.lines raw), not (T.null (T.strip line))]

parseQueryLine :: FilePath -> (Int, Text) -> Either Text QueryAnswer
parseQueryLine path (lineNumber, raw) = do
  (fields, _) <- either (Left . T.pack . show) Right (parse (jsonObjectWithRaw <* spaces <* eof) (path <> ":" <> show lineNumber) raw)
  let required key = maybe (Left ("Falta el campo requerido " <> key <> " en " <> T.pack path <> ":" <> T.pack (show lineNumber))) Right (Map.lookup key fields)
      listField key = case Map.lookup key fields of
        Nothing -> Left ("Falta el arreglo " <> key <> " en " <> T.pack path <> ":" <> T.pack (show lineNumber))
        Just value | T.null value -> Right []
                   | otherwise -> Right (splitOn '\x1f' value)
  QueryAnswer
    <$> required "query_id"
    <*> required "question"
    <*> required "result"
    <*> required "certainty"
    <*> listField "evidence_ids"
    <*> listField "assumptions"
    <*> listField "limitations"
    <*> required "dataset_version"

data Person = Person
  { personId :: Text
  , personNames :: [Text]
  }

ingestDirectory :: FilePath -> IO [Event]
ingestDirectory directory = do
  reference <- loadPeople (directory </> "personal.csv")
  modules <- loadModules (directory </> "estacion.csv")
  events <- fmap concat (mapM (readSource directory reference modules) sourceFiles)
  ingestedAt <- getCurrentTime
  pure (map (\event -> event {ingestedAtUtc = Just ingestedAt}) (markDuplicates events))
  where
    sourceFiles =
      [ ("tarjetas.csv", CardRead)
      , ("radio.txt", RadioMessage)
      , ("energia.json", EnergyReading)
      , ("presencia.csv", PresenceReading)
      , ("temperatura.csv", TemperatureReading)
      , ("bitacora.txt", LogEntry)
      , ("personal.csv", ReferenceRecord)
      , ("estacion.csv", ReferenceRecord)
      ]

loadModules :: FilePath -> IO (Set Text)
loadModules path = do
  result <- readUtf8 path
  pure $ case result of
    Left _ -> Set.empty
    Right (raw, _) -> case T.lines raw of
      [] -> Set.empty
      header : rows -> case parseCsv header of
        Left _ -> Set.empty
        Right headers -> Set.fromList
          [ moduleId
          | line <- rows
          , Right fields <- [parseCsv line]
          , let values = Map.fromList (zip headers fields)
          , Just moduleId <- [Map.lookup "module_id" values]
          , not (T.null (T.strip moduleId))
          ]

loadPeople :: FilePath -> IO [Person]
loadPeople path = do
  result <- readUtf8 path
  pure $ case result of
    Left _ -> []
    Right (raw, _) -> case T.lines raw of
      [] -> []
      header : rows ->
        let names = either (const []) id (parseCsv header)
         in mapMaybeRow names rows
  where
    mapMaybeRow headers = foldr (\line acc -> maybe acc (: acc) (toPerson headers line)) []
    toPerson headers line = do
      fields <- either (const Nothing) Just (parseCsv line)
      let values = Map.fromList (zip headers fields)
          pid = Map.findWithDefault "" "person_id" values
          name = Map.findWithDefault "" "name" values
          aliases = splitOn '|' (Map.findWithDefault "" "aliases" values)
      if T.null pid then Nothing else Just (Person pid (filter (not . T.null) (name : aliases)))

readSource :: FilePath -> [Person] -> Set Text -> (FilePath, EventType) -> IO [Event]
readSource directory people modules (name, kind) = do
  result <- readUtf8 (directory </> name)
  pure $ case result of
    Left exception -> [missingFileEvent name (T.pack (show exception))]
    Right (raw, hash) -> map (\event -> event {provenanceSha256 = Just hash}) (parseSource people modules name kind raw)

readUtf8 :: FilePath -> IO (Either Text (Text, Text))
readUtf8 path = do
  result <- try (BS.readFile path) :: IO (Either IOException BS.ByteString)
  pure $ case result of
    Left exception -> Left (T.pack (show exception))
    Right bytes -> case TE.decodeUtf8' bytes of
      Left exception -> Left ("UTF-8 inválido: " <> T.pack (show exception))
      Right raw -> Right (T.dropWhile (== '\xfeff') raw, sha256Hex bytes)

missingFileEvent :: FilePath -> Text -> Event
missingFileEvent name message = Event
  { eventId = T.pack name <> "#missing"
  , sourceId = T.pack name
  , sourceRecordId = "file"
  , recordOriginal = ""
  , occurredAtUtc = Nothing
  , timeOriginal = Nothing
  , eventType = UnknownEvent
  , content = Map.empty
  , validationStatus = Invalid
  , diagnostics = [Diagnostic "SOURCE_MISSING" message]
  , provenanceSha256 = Nothing
  , ingestedAtUtc = Nothing
  }

parseSource :: [Person] -> Set Text -> FilePath -> EventType -> Text -> [Event]
parseSource people modules name kind raw
  | name == "energia.json" = case parse jsonArray name raw of
      Left problem -> [parseErrorEvent name raw (T.pack (show problem))]
      Right objects -> zipWith (jsonEvent modules name kind) [1 :: Int ..] objects
  | name == "radio.txt" || name == "bitacora.txt" =
      [pipeEvent people name kind lineNumber line | (lineNumber, line) <- numbered (T.lines raw), not (T.null (T.strip line))]
  | otherwise = csvEvents people modules name kind raw

csvEvents :: [Person] -> Set Text -> FilePath -> EventType -> Text -> [Event]
csvEvents people modules name kind raw = case T.lines raw of
  [] -> [parseErrorEvent name raw "EMPTY_SOURCE"]
  headerLine : rows -> case parseCsv headerLine of
    Left message -> [parseErrorEvent name headerLine ("CSV_HEADER: " <> message)]
    Right headers ->
      [ csvRowEvent people modules name kind headers rowNumber line
      | (rowNumber, line) <- zip [2 :: Int ..] rows
      , not (T.null (T.strip line))
      ]

csvRowEvent :: [Person] -> Set Text -> FilePath -> EventType -> [Text] -> Int -> Text -> Event
csvRowEvent people modules name kind headers rowNumber line = case parseCsv line of
  Left message -> baseEvent name kind rowNumber line Nothing Map.empty Invalid [Diagnostic "CSV_PARSE" message]
  Right values
    | length values /= length headers -> baseEvent name kind rowNumber line Nothing fields Invalid [Diagnostic "CSV_COLUMN_COUNT" "La cantidad de campos no coincide con el encabezado."]
    | otherwise ->
        let timestamp = firstOf ["timestamp_utc", "timestamp", "time"] fields
            instant = timestamp >>= normalizeTimestamp
            timeIssue = case (timestamp, instant) of
              (Nothing, _) -> []
              (Just _, Nothing) -> [Diagnostic "TIME_INVALID_OR_UNZONED" "No se pudo interpretar la hora con zona explícita; se preservó el texto original."]
              _ -> []
            schemaIssue = validateRow kind modules fields
            identityFields = resolveIdentity people fields
            allFields = Map.union identityFields fields
            identityIssues = case Map.lookup "identity_resolution" identityFields of
              Just "ambiguous" -> [Diagnostic "IDENTITY_AMBIGUOUS" "El nombre registrado coincide con más de una identidad de referencia."]
              Just "unresolved" -> [Diagnostic "IDENTITY_UNRESOLVED" "El nombre registrado no coincide con personal.csv; se conserva sin asignar identidad."]
              _ -> []
            problems = timeIssue <> schemaIssue <> identityIssues
            status
              | not (null timeIssue) || not (null schemaIssue) = Invalid
              | not (null identityIssues) = Ambiguous
              | otherwise = Valid
         in baseEvent name kind rowNumber line instant allFields status problems
  where
    fields = Map.fromList (zip headers (either (const []) id (parseCsv line)))

jsonEvent :: Set Text -> FilePath -> EventType -> Int -> (Row, Text) -> Event
jsonEvent modules name kind index (fields, original) =
  let timestamp = Map.lookup "timestamp_utc" fields
      instant = timestamp >>= normalizeTimestamp
      problems = case timestamp of
        Nothing -> [Diagnostic "TIME_MISSING" "El objeto no contiene timestamp_utc."]
        Just _ | instant == Nothing -> [Diagnostic "TIME_INVALID_OR_UNZONED" "Hora JSON no interpretable con zona explícita."]
        _ -> validateRow kind modules fields
      status = if null problems then Valid else Invalid
      event = baseEvent name kind index original instant fields status problems
   in event {sourceRecordId = "record:" <> T.pack (show index)}

pipeEvent :: [Person] -> FilePath -> EventType -> Int -> Text -> Event
pipeEvent people name kind lineNumber line = case map T.strip (splitOn '|' line) of
  timestamp : label : body : _ ->
    let instant = normalizeTimestamp timestamp
        issues = [Diagnostic "TIME_INVALID_OR_UNZONED" "La hora no se pudo normalizar a UTC." | instant == Nothing]
        fields = Map.fromList [("label", label), ("message", body), ("time_original", timestamp)]
     in baseEvent name kind lineNumber line instant (Map.union (resolveIdentity people fields) fields) (if null issues then Valid else Invalid) issues
  _ -> baseEvent name kind lineNumber line Nothing Map.empty Invalid [Diagnostic "PIPE_FIELDS" "Se esperaban al menos tres campos separados por '|'."]

validateRow :: EventType -> Set Text -> Row -> [Diagnostic]
validateRow kind modules fields = requiredIssues <> numericIssues <> moduleIssues
  where
    requiredFields = case kind of
      CardRead -> ["reader_id", "card_id", "person_as_recorded"]
      PresenceReading -> ["module", "count"]
      TemperatureReading -> ["module", "temp_c"]
      EnergyReading -> ["module", "voltage_v"]
      _ -> []
    requiredIssues =
      [ Diagnostic ("FIELD_MISSING_" <> key) ("Falta el campo requerido " <> key <> ".")
      | key <- requiredFields
      , maybe True (T.null . T.strip) (Map.lookup key fields)
      ]
    numericKeys = case kind of
      PresenceReading -> ["count"]
      TemperatureReading -> ["temp_c"]
      EnergyReading -> ["voltage_v"]
      _ -> []
    numericIssues = concatMap numeric numericKeys
    numeric key = case Map.lookup key fields of
      Nothing -> []
      Just value -> case reads (T.unpack value) :: [(Double, String)] of
        [(number, rest)] | null rest && not (isNaN number || isInfinite number) -> []
        _ -> [Diagnostic ("FIELD_NOT_NUMERIC_" <> key) ("El valor de " <> key <> " no es numérico: " <> value)]
    moduleIssues = case Map.lookup "module" fields of
      Just moduleId | not (Set.member moduleId modules) -> [Diagnostic "UNKNOWN_MODULE" ("El módulo " <> moduleId <> " no aparece en estacion.csv.")]
      _ -> []

resolveIdentity :: [Person] -> Row -> Row
resolveIdentity people fields = case firstOf ["person_as_recorded", "person", "name"] fields of
  Nothing -> Map.empty
  Just recorded -> case filter (elem (T.toCaseFold recorded) . map T.toCaseFold . personNames) people of
    [person] -> Map.fromList [("identity_as_recorded", recorded), ("canonical_person_id", personId person)]
    [] -> Map.fromList [("identity_as_recorded", recorded), ("identity_resolution", "unresolved")]
    _ -> Map.fromList [("identity_as_recorded", recorded), ("identity_resolution", "ambiguous")]

baseEvent :: FilePath -> EventType -> Int -> Text -> Maybe UTCTime -> Row -> ValidationStatus -> [Diagnostic] -> Event
baseEvent name kind rowNumber original timestamp fields status issues = Event
  { eventId = T.pack name <> "#" <> T.pack (show rowNumber)
  , sourceId = T.pack name
  , sourceRecordId = "line:" <> T.pack (show rowNumber)
  , recordOriginal = original
  , occurredAtUtc = timestamp
  , timeOriginal = lookupFirst ["timestamp_utc", "timestamp", "time", "time_original"] fields
  , eventType = kind
  , content = fields
  , validationStatus = status
  , diagnostics = issues
  , provenanceSha256 = Nothing
  , ingestedAtUtc = Nothing
  }

parseErrorEvent :: FilePath -> Text -> Text -> Event
parseErrorEvent name raw message = (baseEvent name UnknownEvent 1 raw Nothing Map.empty Invalid [Diagnostic "SOURCE_PARSE" message])

firstOf :: [Text] -> Row -> Maybe Text
firstOf keys fields = find (`Map.member` fields) keys >>= (`Map.lookup` fields)

lookupFirst :: [Text] -> Row -> Maybe Text
lookupFirst = firstOf

markDuplicates :: [Event] -> [Event]
markDuplicates = annotateConflicts . reverse . snd . foldl mark (Map.empty, [])
  where
    mark (seen, accumulated) event =
      let key = (sourceId event, recordOriginal event)
       in case Map.lookup key seen of
            Just firstId ->
              let duplicate = event
                    { validationStatus = if validationStatus event == Valid then DuplicateCandidate else validationStatus event
                    , diagnostics = diagnostics event <> [Diagnostic "DUPLICATE_RECORD" ("Registro idéntico al evento " <> firstId <> "; ambos se conservan.")]
                    }
               in (seen, duplicate : accumulated)
            Nothing -> (Map.insert key (eventId event) seen, event : accumulated)

annotateConflicts :: [Event] -> [Event]
annotateConflicts events = map annotate events
  where
    groups = Map.fromListWith (<>) [(key, [event]) | event <- events, Just key <- [conflictKey event]]
    conflictRecords =
      [ (eventId event, "Mismo sensor y hora que " <> T.intercalate ", " (map eventId peers) <> " con valores distintos.")
      | group <- Map.elems groups
      , length (nub (map recordOriginal group)) > 1
      , event <- group
      , let peers = filter ((/= eventId event) . eventId) group
      , not (null peers)
      ]
    conflicts = Map.fromList conflictRecords
    annotate event = case Map.lookup (eventId event) conflicts of
      Nothing -> event
      Just message -> event
        { validationStatus = if validationStatus event == Valid then Conflicting else validationStatus event
        , diagnostics = diagnostics event <> [Diagnostic "CONFLICTING_SENSOR_READINGS" message]
        }
    conflictKey event = do
      case eventType event of
        PresenceReading -> pure ()
        TemperatureReading -> pure ()
        EnergyReading -> pure ()
        _ -> Nothing
      timestamp <- occurredAtUtc event
      location <- firstOf ["module", "reader_id"] (content event)
      pure (sourceId event, eventType event, timestamp, location)

parseCsv :: Text -> Either Text [Text]
parseCsv line = case parse csvLine "csv" line of
  Left err -> Left (T.pack (show err))
  Right values -> Right values

csvLine :: Parser [Text]
csvLine = P.sepBy csvField (char ',') <* eof

csvField :: Parser Text
csvField = T.pack <$> choice [quotedField, unquotedField]
  where
    quotedField = between (char '"') (char '"') (many quotedChar)
    quotedChar = P.try (string "\"\"") *> pure '"' P.<|> noneOf "\""
    unquotedField = many (noneOf ",\r\n")

jsonArray :: Parser [(Row, Text)]
jsonArray = spaces *> char '[' *> spaces *> jsonObjectWithRaw `sepBy` comma <* spaces <* char ']' <* spaces <* eof
  where comma = P.try (spaces *> char ',' *> spaces)

jsonObjectWithRaw :: Parser (Row, Text)
jsonObjectWithRaw = do
  before <- getInput
  _ <- spaces *> char '{' *> spaces
  pairs <- jsonPair `sepBy` (P.try (spaces *> char ',' *> spaces))
  _ <- spaces *> char '}'
  after <- getInput
  pure (Map.fromList pairs, T.take (T.length before - T.length after) before)

jsonPair :: Parser (Text, Text)
jsonPair = do
  key <- jsonString
  spaces *> char ':' *> spaces
  value <- jsonString P.<|> jsonStringList P.<|> (T.pack <$> many1 (P.satisfy (\c -> c /= ',' && c /= '}' && not (isSpace c))))
  pure (key, value)

jsonStringList :: Parser Text
jsonStringList = T.intercalate "\x1f" <$> between (char '[') (char ']') (jsonString `sepBy` (spaces *> char ',' *> spaces))

jsonString :: Parser Text
jsonString = T.pack <$> between (char '"') (char '"') (many jsonChar)
  where
    jsonChar = noneOf "\"\\" P.<|> (char '\\' *> choice
      [ char '"'
      , char '\\'
      , char '/'
      , char 'b' *> pure '\b'
      , char 'f' *> pure '\f'
      , char 'n' *> pure '\n'
      , char 'r' *> pure '\r'
      , char 't' *> pure '\t'
      , char 'u' *> unicodeChar
      ])
    unicodeChar = do
      first <- readHexCode
      if first >= 0xD800 && first <= 0xDBFF
        then do
          _ <- string "\\u"
          second <- readHexCode
          if second >= 0xDC00 && second <= 0xDFFF
            then pure (chr (0x10000 + ((first - 0xD800) * 0x400) + second - 0xDC00))
            else P.parserFail "Invalid low surrogate in JSON string"
        else if first >= 0xDC00 && first <= 0xDFFF
          then P.parserFail "Unexpected low surrogate in JSON string"
          else pure (chr first)
    readHexCode = do
      digits <- count 4 hexDigit
      let value = foldl (\total digit -> total * 16 + digitToInt digit) 0 digits
      if all isHexDigit digits then pure value else P.parserFail "Invalid Unicode escape in JSON string"

spaces :: Parser ()
spaces = skipMany (space P.<|> char '\n' P.<|> char '\r')

splitOn :: Char -> Text -> [Text]
splitOn delimiter = map T.pack . split . T.unpack
  where
    split [] = [[]]
    split input = case break (== delimiter) input of
      (field, []) -> [field]
      (field, _ : rest) -> field : split rest

numbered :: [a] -> [(Int, a)]
numbered = zip [1 ..]
