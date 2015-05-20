{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import Control.Applicative
import Control.Monad
import Data.ByteString as BS
import Data.List as L
import Data.Time.Clock
import Data.Time.Calendar
import Data.Yaml
import Control.Concurrent
import System.Environment
import System.IO
import System.Process
import Data.HashMap.Lazy as HM

data Task = Task
  { taskName :: String
  , taskCmd  :: String
  , taskInterval :: NominalDiffTime
  }
  deriving (Eq, Ord, Show)

newtype Tasks = Tasks { getTasks :: [Task] }
  deriving (Eq, Ord, Show)

data YamlTask = YamlTask String NominalDiffTime

instance FromJSON YamlTask where
  parseJSON (Object v) = YamlTask <$> v .: "command"
                                  <*> (fromInteger <$> v .: "interval")
  parseJSON _ = mzero

instance FromJSON Tasks where
  parseJSON (Object v) = f <$> v .: "tasks"
    where f = Tasks . fmap g . HM.toList
          g (name, YamlTask cmd interval) = Task name cmd interval
  parseJSON _ = mzero

data Job = Job { jobLastTime :: UTCTime, jobTask :: Task }
  deriving (Eq, Ord, Show)

distantPast :: UTCTime
distantPast = UTCTime (ModifiedJulianDay 0) (secondsToDiffTime 0)

timeTillJob :: UTCTime -> Job -> NominalDiffTime
timeTillJob now job =
  let nextRunTime = addUTCTime (taskInterval (jobTask job)) (jobLastTime job)
  in nextRunTime `diffUTCTime` now

work :: [Job] -> IO a
work jobs = do
  now <- getCurrentTime
  -- split jobs into which need to be run, and the rest
  let (as, bs) = L.partition ((< 0) . timeTillJob now) jobs
  if L.null as
     then do let interval = L.minimum . L.map (timeTillJob now) $ jobs
             Prelude.putStrLn $ "====> Next task in " ++ show interval
             hFlush stdout
             threadDelay $ (min 60 . (1+) . round $ interval) * 1000000
             work jobs
     else do forM_ as $ \(Job _ task) -> do
               Prelude.putStrLn $ "====> Running task " ++ taskName task
               hFlush stdout
               callCommand $ taskCmd task
             -- Fetch new now, so we don't starvate
             now' <- getCurrentTime
             let as' = L.map (Job now' . jobTask) as
             work $ as' ++ bs

main :: IO ()
main = do
  [configFileName] <- getArgs
  example <- BS.readFile configFileName
  let Right tasks = getTasks <$> decodeEither example
  let jobs = Job distantPast <$> tasks
  work jobs

