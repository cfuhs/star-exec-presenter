module Handler.Control where

import Import

import Yesod.Auth

import qualified Presenter.Registration as R
import Presenter.Control.Job
import Presenter.STM

import qualified Data.Text as T
import qualified Data.Map.Strict as M
import Data.Time.Clock
import Control.Monad ( guard, forM )
import Control.Monad.Fail

inputForm = renderTable $ JobControl
        <$> areq checkBoxField "is public" (Just False)
        <*> areq (radioFieldList
                  [("pushJobXML - sllooowwww" :: T.Text , PushJobXML)
                  ,("createJob (on ALL benchmarks - ignores parameters a,b,c" , CreateJob)
                  ]) "job creation method" (Just CreateJob)
        <*> areq checkBoxField "start paused" (Just False)
        <*> areq (radioFieldList
                  [("Competition (at least 2 participants)"::T.Text,SelectionCompetition)
                  ,("Demonstration (exactly 1 participant)",SelectionDemonstration)
                  ,("Everything (>= 1 participant)",SelectionAll)
                  ]) "categories" (Just SelectionCompetition)
        <*> areq (radioFieldList
                  [ ("termcomp.q", 61056 )
                  , ("all.q"::T.Text,1)
                  ]) "queue" (Just 54723)
        <*> areq (radioFieldList
                  [("tc2018/test2",325861),("tc2018/run":: T.Text, 326386)])
                 "space" (Just 274864)
        <*> areq (radioFieldList [("10",10),("30",30),("60"::T.Text, 60),("300", 300), ("900", 900)])
                 "wallclock_timeout (for rewriting)" (Just 300)
        <*> areq (radioFieldList [("10",10),("30",30),("60"::T.Text, 60),("300", 300), ("900", 900)])
                 "wallclock_timeout (for programs)" (Just 300)
        <*> areq (radioFieldList [("1", 1), ("10"::T.Text,10), ("25", 25), ("100", 100)])
                 "family_lower_bound (selection parameter a)" (Just 1)
        <*> areq (radioFieldList [("1", 1), ("10"::T.Text,10), ("25", 25), ("100", 100),("250",250),("1000",1000)])
                 "family_upper_bound (selection parameter b)" (Just 1)
        <*> areq (radioFieldList [("0.01", 0.01), ("0.03", 0.03), ("0.1", 0.1), ("0.3"::T.Text,0.3), ("1.0", 1.0)])
                 "family_factor (selection parameter c)" (Just 0.01)
        <*> formToAForm ( do
            e <- askParams
            return ( FormSuccess $ maybe M.empty id e, [] ) )

benches :: Monad m => m R.Benchmark_Source -> m Int
benches bs = do R.Bench b <- bs ; return b

alls :: Monad m => m R.Benchmark_Source -> m Int
alls bs = do R.All b <- bs ; return b

hierarchies :: MonadFail m => m R.Benchmark_Source -> m Int
hierarchies bs = do R.Hierarchy b <- bs ; return b

getControlR :: Year -> Handler Html
getControlR year = do
  maid <- maybeAuthId
  (widget, enctype) <- generateFormPost inputForm
  let comp = R.the_competition year
  defaultLayout $(widgetFile "control")

postControlR :: Year -> Handler Html
postControlR year = do
  maid <- maybeAuthId
  ((result, widget), enctype) <- runFormPost inputForm

  let comp = R.the_competition year
      public = case result of
                  FormSuccess input-> isPublic input
                  _ -> False
  mc <- case result of
          FormSuccess input -> do
            Just [con] <- return $ M.lookup "control" $ env input
            startjobs year input con
          _ -> return Nothing
  mKey <- case mc of
            Nothing -> return Nothing
            Just c -> do
              now <- liftIO getCurrentTime
              let competition = ( timed now c )
              key <- runDB $ insert $ CompetitionInfo competition now public
              startWorker competition
              return $ Just key
  defaultLayout $ do
    [whamlet|
      <h2>Result of previous command
      $maybe key <- mKey
        jobs started, <a href=@{CompetitionR $ CRefId key}>output</a>
      $nothing
        could not start jobs
    |]
    $(widgetFile "control")

startjobs :: Year -> JobControl -> Text -> Handler (Maybe Competition)
startjobs year input con =
      checkPrefix "hier:" con (startHier year input)
    $ checkPrefix "cat:"  con (startCat year input)
    $ checkPrefix "mc:" con (startMC year input)
    $ checkPrefix "comp:" con (startComp year input)
    $ return Nothing

checkPrefix :: T.Text -> T.Text -> ( T.Text -> a ) -> a ->  a
checkPrefix s con action next =
    let (pre, post) = T.splitAt (T.length s) con
    in  if pre == s then action post else next

select :: JobControl -> R.Competition R.Catinfo -> R.Competition R.Catinfo
select input comp = case selection input of
    SelectionAll ->
        comp { R.metacategories = map ( \ mc -> mc { R.categories = R.all_categories mc } )
                              $ R.metacategories comp }
    SelectionCompetition ->
        comp { R.metacategories = map ( \ mc -> mc { R.categories = R.full_categories mc } )
                              $ R.metacategories comp }
    SelectionDemonstration ->
        comp { R.metacategories = map ( \ mc -> mc { R.categories = R.demonstration_categories mc } )
                              $ R.metacategories comp }

startHier :: Year -> JobControl -> Name -> Handler (Maybe Competition)
startHier year input t = do
    let cats = do
            mc <- R.metacategories $ select input $ R.the_competition year
            c <- R.categories mc
            let cc = R.contents c
            let bms = filter ( \ bm -> case bm of
                                 R.Hierarchy h -> show h == T.unpack t
                                 _ -> False
                             ) $ R.benchmarks cc
            guard $ not $ null bms
            return $ c { R.contents = cc { R.benchmarks = bms } }
    case cats of
        [] -> return Nothing
        _ -> do
            cats_with_jobs <- forM cats $ pushcat input
            let m = params input t
                c = Competition m [ MetaCategory (metaToName m) $ map convertC cats_with_jobs ]
            return $ Just c
        _ -> return Nothing

startCat :: Year -> JobControl -> Name -> Handler (Maybe Competition)
startCat year input t = do
    let cats = do
            mc <- R.metacategories $ select input $ R.the_competition year
            c <- R.categories mc
            guard $ R.categoryName c == t
            return c
    case cats of
        [ cat ] -> do
            cat_with_jobs <- pushcat input cat
            let m = params input t
                c = Competition m [ MetaCategory (metaToName m) [ convertC cat_with_jobs]]
            return $ Just c
        _ -> return Nothing

startMC :: Year -> JobControl -> Name -> Handler (Maybe Competition)
startMC year input t = do
    let mcs = do
            mc <- R.metacategories $ select input $ R.the_competition year
            guard $ R.metaCategoryName mc == t
            return mc
    case mcs of
        [ mc ] -> do
            mc_with_jobs <- pushmetacat input mc
            let m = params input t
                c = Competition m [ convertMC mc_with_jobs]
            return $ Just c
        _ -> return Nothing

startComp :: Year -> JobControl -> Text -> Handler (Maybe Competition)
startComp year input t = do
    comp_with_jobs <- pushcomp input $ select input $ R.the_competition year
    let Competition name mcs = convertComp comp_with_jobs
        m = params input t
        c = Competition m mcs
    return $ Just c

params :: JobControl -> Text -> CompetitionMeta
params conf t = CompetitionMeta
  { getMetaName = T.append t $ case selection conf of
        SelectionCompetition -> T.empty
        SelectionDemonstration -> " (Demonstration)"
        SelectionAll -> " (Competition + Demonstration)"
  , getMetaDescription =
      T.unwords [ "wc_r", "=", T.pack $ show $ wallclock_for_rewriting conf
                , "wc_p", "=", T.pack $ show $ wallclock_for_programs conf
                , "a", "=", T.pack $ show $ family_lower_bound conf
                , "b", "=", T.pack $ show $ family_upper_bound conf
                , "c", "=", T.pack $ show $ family_factor conf
                ]
  }

metaToName :: CompetitionMeta -> Name
metaToName meta = getMetaName meta
