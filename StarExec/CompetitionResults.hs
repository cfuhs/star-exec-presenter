-- | semantics specification:
-- In each meta-category, a medal will be awarded to the highest-scoring solver.
-- For every meta-category, we consider the sum of the scores 
-- for each category within that meta-category: 
-- The score of a tool is determined by the number of other tools
-- which could be beaten in that category. 
-- http://www.termination-portal.org/wiki/Termination_Competition_2014#Competition_Categories_and_Awards

module StarExec.CompetitionResults 
  ( getCompetitionResults
  , CompetitionResults(..)
  , MetaCategoryResult(..)
  , CategoryResult(..)
  ) where

import Import

import StarExec.CompetitionResults.Type

import StarExec.Types
import StarExec.JobData
import StarExec.Processing
import StarExec.Statistics
import qualified Data.List as L
import Data.Maybe
import Data.Time.Clock
import qualified Data.IntMap.Strict as IM

import qualified Data.Map as M

sortScore :: (Solver, Score) -> (Solver, Score) -> Ordering
sortScore (_,i1) (_,i2) = compare i1 i2

isYes :: SolverResult -> Bool
isYes (YES _) = True
isYes _       = False

-- | output is decreasing by Score
getScores :: [Solver] -> Scoring -> [JobResultInfo] -> [(Solver,Score)]
getScores solver scoring results =
  reverse $ L.sortBy sortScore scores
  where
    scoreMap =
      case scoring of
        Standard -> calcStandardScores results
        Complexity -> calcComplexityScores results
    scores = flip map solver $ \s@(sId,_) ->
              case IM.lookup sId scoreMap of
                Nothing -> (s,0)
                Just scr -> (s,scr)

--testGetRanking1 = 
--        getRanking [("foo", 30), ("bar", 20), ("what", 20), ("noh", 10)] 
--    ==  [toRank (Just 1,"foo",30), toRank (Just 2,"bar",20), toRank (Nothing,"what",20), toRank (Just 4, "noh", 10)]
--    where
--      toRank (r,slv,scr) = SolverRankEntry r slv scr

-- | input is decreasing by score, output has same order of solvers
getRanking  :: [(Solver, Score)] -> [SolverRankEntry]
getRanking scores =
  let indexedScores = zip [1..] scores 
      equals score (_,(_,scr)) = score == scr
      getRanking' :: (Solver, Score) -> SolverRankEntry
      getRanking' (solver, score) =
          case filter (equals score) indexedScores of
            [] -> SolverRankEntry Nothing solver score
            ((rank,(slv,_)):_) -> SolverRankEntry
              { rank = if solver /= slv then Nothing else Just rank
              , solver = solver
              , score = score
              }
  in map getRanking' scores

--testCalcScores1 = 
--       calcScores [(Just 1,"foo",30),(Just 2,"bar",20),(Nothing,"what",20),(Just 4,"noh",10)]
--    == [("foo",3),("bar",2),("what",2),("noh",0)]

-- | input is decreasing by score (?), as computed by getRanking
-- output is, for each solver, the number of solvers that it could beat.

-- FIXME: as the test case shows, evaluation of x is number of y with score y <= score x
-- (not  "<"  as the spec says)

calcScores :: [SolverRankEntry] -> [(Solver, Int)]
calcScores [entry] = [(solver entry, 0)]
calcScores ranking = calcScores' 1 ranking
  where
    numRankings = length ranking
    calcScores' rnk ((entry):rs) =
      let mRank = rank entry
          slv = solver entry
      in case mRank of
          Nothing -> (slv,numRankings - rnk):calcScores' rnk rs
          Just r -> (slv,numRankings - r):calcScores' r rs
    calcScores' _ [] = []

getMetaScores :: [[SolverRankEntry]] -> [(Solver, Score)]
getMetaScores catScores =
    M.toList $ M.fromListWith (+) $ concat $ map calcScores catScores

getCategoriesResult :: Category -> Handler CategoryResult
getCategoriesResult cat = do
  let catName = getCategoryName cat
      catScoring = getCategoryScoring cat
      catPostProcId = getPostProcId cat
      catJobIds = getJobIds cat
  qResults <- queryManyJobs catJobIds
  qPostProc <- queryPostProc catPostProcId
  let results = concat $ map (snd . queryResult) qResults
      solver = getInfo extractSolver results
      scores = getScores solver catScoring results
      rankedSolver = getRanking scores
      jobInfos = catMaybes $ map (fst . queryResult) qResults
      complete = length jobInfos == length catJobIds && all ((==Complete) . jobInfoStatus) jobInfos
      startTime = if null jobInfos
                    then Nothing
                    else Just $ minimum $ map jobInfoStartDate jobInfos
      endTime = if complete && not (null jobInfos)
                  then maximum $ map jobInfoFinishDate jobInfos
                  else Nothing
      cpuTotal = sum $ map jobResultInfoCpuTime results
      wallTotal = sum $ map jobResultInfoWallclockTime results
      stat = Statistics { complete = complete 
                        , pairs = length results
                        , pairsCompleted = length 
                              $ filter ( ( == JobResultComplete) . jobResultInfoStatus ) results
                        , startTime = startTime, finishTime = endTime 
                        , cpu = cpuTotal, wallclock = wallTotal
                        }

  return $ CategoryResult catName
                          catScoring
                          (queryResult qPostProc)
                          rankedSolver
                          jobInfos
                          complete
                          startTime
                          endTime
                          stat

getMetaResults :: MetaCategory -> Handler MetaCategoryResult
getMetaResults metaCat = do
  let metaName = getMetaCategoryName metaCat
      categories = getCategories metaCat
  catResults <- mapM getCategoriesResult categories
  let scores = getMetaScores $ map categoryRanking catResults
      ranking = getRanking $ reverse $ L.sortBy sortScore scores
      complete = all categoryComplete catResults
      startTime = if null catResults
                    then Nothing
                    else minimum $ map categoryStartTime catResults
      endTime = if complete
                  then maximum $ map categoryFinishTime catResults
                  else Nothing
      stat = mconcat $ map categoryStatistics catResults
      
  return $ MetaCategoryResult metaName
                              catResults
                              ranking
                              complete
                              startTime
                              endTime
                              stat

getCompetitionResults :: Competition -> Handler CompetitionResults
getCompetitionResults comp = do
  let compName = getCompetitionName comp
      metaCats = getMetaCategories comp
  metaResults <- mapM getMetaResults metaCats
  let complete = all metaCategoryComplete metaResults
      startTime = if null metaResults
                    then Nothing
                    else minimum $ map metaCategoryStarTime metaResults
      endTime = if complete
                  then maximum $ map metaCategoryFinishTime metaResults
                  else Nothing
      stat = mconcat $ map metaCategoryStatistics metaResults
  return $ CompetitionResults compName
                              metaResults
                              complete
                              startTime
                              endTime
                              stat
