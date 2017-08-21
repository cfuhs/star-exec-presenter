module Handler.CompetitionWithConfig where

import Import
import Presenter.STM
import Presenter.Utils.WidgetMetaRefresh
import Presenter.Prelude
import Data.Time.Clock

import Yesod.Auth
import Data.Maybe

import Control.Monad.Logger
import qualified Data.Text as T

minute :: Seconds
minute = 60

hour :: Seconds
hour = 60 * minute

getDuration :: Maybe UTCTime -> Maybe UTCTime -> String
getDuration mStart mEnd =
  case diffTime <$> mEnd <*> mStart of
    Nothing -> "unkown time"
    Just d  -> renderTime d
  where
    renderTime d =
      if d >= hour
        then let hours = floor $ d / hour
             in (show hours) ++ "h " ++ renderTime ( d - (fromIntegral hours) * hour )
        else if d > minute
          then let minutes = floor $ d / minute
               in (show minutes) ++ "m " ++ renderTime ( d - (fromIntegral minutes) * minute )
          else (show $ floor d) ++ "s"

getCompletionClass :: Bool -> Text
getCompletionClass True = "completed"
getCompletionClass False = "running"

getCompetitionWithConfigR :: Competition -> Handler Html
getCompetitionWithConfigR comp = do

  logWarnN $ T.pack $ "getCompetitionWithConfigR" <> show comp
  
  mCompResults <- lookupCache comp

  let need_refresh = case mCompResults of
          Nothing -> True
          Just cr -> not $ competitionComplete cr
  maid <- maybeAuthId
  let authorized = isJust maid

  
  let jobcontrol js = do
        [whamlet|
        $if authorized
              <a href=@{PauseR $ JobIds js}>Pa
            |
              <a href=@{ResumeR $ JobIds js}>Re
            |
              <a href=@{ProblemsR False $ JobIds js}>Ch
        |]
  
  defaultLayout $ do
    if need_refresh
      then insertWidgetMetaRefresh
      else return ()
    case mCompResults of
        Nothing -> [whamlet|competition currently not in results cache|]
        Just compResults -> $(widgetFile "competition_slim2")
