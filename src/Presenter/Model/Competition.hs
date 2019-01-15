module Presenter.Model.Competition where

import Yesod
import Presenter.Model.Types
import Presenter.Model.RouteTypes
import Presenter.Output
import Prelude (Show, Read, Eq, Ord, Enum, Bounded
               , ($), (.), show, reads, return, Maybe (..))
import qualified Data.Text as T
import Control.Monad ((>=>))

data Scoring =
  Standard
  | Complexity
  deriving (Show, Read, Eq)

instance Output Scoring where output = text . show

-- | this is for managing registrations (which are in the source) FIXME
data Year = Y2014 | Y2015 | Y2016 | Y2017 | Y2018 | E
  deriving (Show, Eq, Ord, Read, Enum, Bounded)

instance PathPiece Year where
  toPathPiece year = T.pack $ show year
  fromPathPiece t = case reads (T.unpack t) of
    [(y, "")] -> return y
    _ -> Nothing


-- | solver sorted by YES/CERTIFIED/NO, maybe with scoring -> SolverResult
data Category = Category
  { getCategoryName :: Name
  , getCategoryScoring :: Scoring
  , getPostProcId :: PostProcId
  , getJobIds :: [JobID]
  } deriving (Show, Read, Eq)

instance Output Category where
    output c = "Category" <#> dutch_record
             [ "getCategoryName" <+> equals <#> output (getCategoryName c)
             , "getCategoryScoring" <+> equals <#> output (getCategoryScoring c)
             , "getPostProcId" <+> equals <#> output (getPostProcId c)
             , "getJobIds" <+> equals <#> output (getJobIds c)
             ]

-- |  solver by rank in the categories
data MetaCategory = MetaCategory
  { getMetaCategoryName :: Name
  , getCategories :: [Category]
  } deriving (Show, Read, Eq)
derivePersistField "MetaCategory"

instance Output MetaCategory where
    output c = "MetaCategory" <#> dutch_record
             [ "getMetaCategoryName" <+> equals <#> output (getMetaCategoryName c)
             , "getCategories" <+> equals <#> output (getCategories c)
             ]

data CompetitionMeta = CompetitionMeta
  { getMetaName :: Name
  , getMetaDescription :: Description
  } deriving (Eq, Ord, Read, Show)

instance Output CompetitionMeta where
    output c = "CompetitionMeta" <#> dutch_record
             [ "getMetaName" <+> equals <#> output (getMetaName c)
             , "getMetaDescription" <+> equals <#> output (getMetaDescription c)
             ]

data Competition = Competition
  { getMetaData :: CompetitionMeta
  , getMetaCategories :: [MetaCategory]
  } deriving (Show, Read, Eq)
derivePersistField "Competition"


getCompetitionName :: Competition -> Name
getCompetitionName = getMetaName . getMetaData

getCompetitionDescription :: Competition -> Description
getCompetitionDescription = getMetaDescription . getMetaData

instance Output Competition where
    output c = "Competition" <#> dutch_record
             [ "getMetaData" <+> equals <#> output (getMetaData c)
             , "getMetaCategories" <+> equals <#> output (getMetaCategories c)
             ]

instance PathPiece Competition where
  toPathPiece comp = T.pack $ show comp
  fromPathPiece t = case reads (T.unpack t) of
    [(c, "")] -> return c
    _ -> Nothing

instance PathPiece Scoring where
  fromPathPiece "standard" = return Standard
  fromPathPiece "complexity" = return Complexity
  fromPathPiece _ = Nothing
  toPathPiece s = T.toLower $ T.pack $ show s

class AllJobIDs c where allJobIDs :: c -> [JobID]

instance AllJobIDs Category where allJobIDs = getJobIds
instance AllJobIDs MetaCategory where allJobIDs = getCategories >=> allJobIDs
instance AllJobIDs Competition where allJobIDs = getMetaCategories >=> allJobIDs
