module Handler.Registered where

import Import hiding (competitionName, metaCategoryName, categoryName)
import Presenter.Registration
--import Text.Lucius (luciusFile)
--import Text.Hamlet (hamletFile)

getRegisteredR :: Year -> Handler Html
getRegisteredR year = do
    let comp = Presenter.Registration.the_competition year
        -- configs build in 2014 have low numbers
        oldconfig c = c < 10000
        partclass :: (Int,Int) -> Text
        partclass (s,c) = if oldconfig c then "oldconf" else "conf"
    defaultLayout $ do
        $(widgetFile "registered")
