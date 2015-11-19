module ConceptAnalysis.DotGraph where

import Import

import Control.Monad (guard)
import Data.List (elemIndex)
import Data.Maybe (fromJust)
import qualified Data.Text.Lazy as TL
import           Data.Graph.Inductive (mkGraph, Gr, LNode, LEdge)
import Data.GraphViz (graphToDot, GraphvizParams, nonClusteredParams)
import Data.GraphViz.Algorithms (transitiveReduction)
import Data.GraphViz.Printing (renderDot, toDot)
-- import Presenter.PersistHelper
-- import Presenter.Model.Entities()
import ConceptAnalysis.FCA
import ConceptAnalysis.FCAPreparation
import Data.Set (fromList, showTree, isProperSubsetOf)
-- import Handler.Concepts
-- import Yesod
-- import Control.Monad (liftM)

-- global_graph_attributes ::
-- global_graph_attributes = 


-- getConcepts :: JobID -> [Concept ob at]
-- getConcepts jid = do
--   jobResults <- getPersistJobResults jid
--   let contextData = collectData $ getStarExecResults jobResults
--   let context = contextFromList contextData
--   concepts context


dotted_graph :: String
-- hard coded examples
concept_lattice :: [Concept JobPairId Attribute]
concept_lattice = [Concept (fromList [91845333,91845334,91845335,91845336,91845337,91845338,91845339,91845340,91845341,91845342,91845343,91845344,91845345,91845346,91845347,91845348,91845349,91845350,91845351,91845352,91845353,91845354,91845355,91845356,91845357,91845358]) (fromList [AJobResultInfoSolver "matchbox2015-2015-04-27",ASlowCpuTime True]),Concept (fromList [91845333,91845335,91845337,91845339,91845341,91845343,91845345,91845347,91845349,91845351,91845353,91845355,91845357]) (fromList [AJobResultInfoSolver "matchbox2015-2015-04-27",AJobResultInfoConfiguration "dp_satchmo.sh",ASlowCpuTime True]),Concept (fromList [91845334,91845336,91845338,91845340,91845342,91845344,91845346,91845348,91845350,91845352,91845354,91845356,91845358]) (fromList [AJobResultInfoSolver "matchbox2015-2015-04-27",AJobResultInfoConfiguration "dp_ur_satchmo.sh",ASlowCpuTime True]),Concept (fromList [91845333,91845334,91845335,91845336,91845343,91845344,91845345,91845346,91845347,91845348,91845349,91845350,91845351,91845352,91845354,91845355,91845356]) (fromList [AJobResultInfoSolver "matchbox2015-2015-04-27",ASlowCpuTime True,ASolverResult YES]),Concept (fromList [91845333,91845335,91845343,91845345,91845347,91845349,91845351,91845355]) (fromList [AJobResultInfoSolver "matchbox2015-2015-04-27",AJobResultInfoConfiguration "dp_satchmo.sh",ASlowCpuTime True,ASolverResult YES]),Concept (fromList [91845334,91845336,91845344,91845346,91845348,91845350,91845352,91845354,91845356]) (fromList [AJobResultInfoSolver "matchbox2015-2015-04-27",AJobResultInfoConfiguration "dp_ur_satchmo.sh",ASlowCpuTime True,ASolverResult YES]),Concept (fromList [91845337,91845338,91845339,91845340,91845341,91845342,91845353,91845357,91845358]) (fromList [AJobResultInfoSolver "matchbox2015-2015-04-27",ASlowCpuTime True,ASolverResult MAYBE]),Concept (fromList [91845337,91845339,91845341,91845353,91845357]) (fromList [AJobResultInfoSolver "matchbox2015-2015-04-27",AJobResultInfoConfiguration "dp_satchmo.sh",ASlowCpuTime True,ASolverResult MAYBE]),Concept (fromList [91845338,91845340,91845342,91845358]) (fromList [AJobResultInfoSolver "matchbox2015-2015-04-27",AJobResultInfoConfiguration "dp_ur_satchmo.sh",ASlowCpuTime True,ASolverResult MAYBE]),Concept (fromList []) (fromList [AJobResultInfoSolver "matchbox2015-2015-04-27",AJobResultInfoConfiguration "dp_satchmo.sh",AJobResultInfoConfiguration "dp_ur_satchmo.sh",ASlowCpuTime True,ASolverResult YES,ASolverResult MAYBE])]
-- concept_lattice = [Concept (fromList [91845333]) (fromList [AJobResultInfoSolver "matchbox2015-2015-04-27",ASlowCpuTime True])]
-- concept_lattice = [Concept (fromList [121518471,121518472,121518473,121518474,121518475,121518476,121518477,121518478,121518479,121518480,121518481,121518482,121518483,121518484,121518485,121518486,121518487,121518488,121518489,121518490,121518491,121518492,121518493,121518494,121518495,121518496,121518497,121518498,121518499,121518500,121518501,121518502,121518503,121518504,121518505,121518506,121518507,121518508,121518509,121518510,121518511,121518512,121518513,121518514,121518515,121518516,121518517,121518518,121518519,121518520,121518521,121518522,121518523,121518524,121518525,121518526,121518527,121518528,121518529,121518530,121518531,121518532,121518533,121518534,121518535,121518536,121518537,121518538,121518539,121518540,121518541,121518542,121518543,121518544,121518545,121518546,121518547,121518548,121518549,121518550,121518551,121518552,121518553,121518554,121518555,121518556,121518557,121518558,121518559,121518560,121518561,121518562,121518563,121518564,121518565,121518566,121518567,121518568,121518569,121518570,121518571,121518572,121518573,121518574,121518575,121518576,121518577,121518578,121518579,121518580,121518581,121518582,121518583,121518584,121518585,121518586,121518587,121518588,121518589,121518590,121518591,121518592,121518593,121518594,121518595,121518596,121518597,121518598,121518599,121518600,121518601,121518602,121518603,121518604,121518605,121518606,121518607,121518608,121518609,121518610,121518611,121518612,121518613,121518614,121518615,121518616,121518617,121518618,121518619,121518620,121518621,121518622,121518623,121518624,121518625,121518626,121518627,121518628,121518629,121518630,121518631,121518632,121518633,121518634,121518635,121518636,121518637,121518638,121518639,121518640,121518641,121518642,121518643,121518644,121518645,121518646,121518647,121518648,121518649,121518650,121518651,121518652,121518653,121518654,121518655,121518656,121518657,121518658,121518659,121518660,121518661,121518662,121518663,121518664,121518665,121518666,121518667,121518668,121518669,121518670,121518671,121518672,121518673,121518674,121518675,121518676,121518677,121518678,121518679,121518680,121518681,121518682,121518683,121518684,121518685,121518686,121518687,121518688,121518689,121518690,121518691,121518692,121518693,121518694,121518695,121518696,121518697,121518698,121518699,121518700,121518701,121518702,121518703,121518704]) (fromList []),Concept (fromList [121518472,121518474,121518476,121518478,121518480,121518482,121518484,121518486,121518488,121518490,121518492,121518494,121518496,121518498,121518500,121518502,121518504,121518506,121518508,121518510,121518512,121518514,121518516,121518518,121518520,121518522,121518524,121518526,121518528,121518530,121518532,121518534,121518536,121518538,121518540,121518542,121518544,121518546,121518548,121518550,121518552,121518554,121518556,121518558,121518560,121518562,121518564,121518566,121518568,121518570,121518572,121518574,121518576,121518578,121518580,121518582,121518584,121518586,121518588,121518590,121518592,121518594,121518596,121518598,121518600,121518602,121518604,121518606,121518608,121518610,121518612,121518614,121518616,121518618,121518620,121518622,121518624,121518626,121518628,121518630,121518632,121518634,121518636,121518638,121518640,121518642,121518644,121518646,121518648,121518650,121518652,121518654,121518656,121518658,121518660,121518662,121518664,121518666,121518668,121518670,121518672,121518674,121518676,121518678,121518680,121518682,121518684,121518686,121518688,121518690,121518692,121518694,121518696,121518698,121518700,121518702,121518704]) (fromList [AJobResultInfoSolver "Ctrl",AJobResultInfoConfiguration "Itrs"]),Concept (fromList [121518471,121518473,121518475,121518477,121518479,121518481,121518483,121518485,121518487,121518489,121518491,121518493,121518495,121518497,121518499,121518501,121518503,121518505,121518507,121518509,121518511,121518513,121518515,121518517,121518519,121518521,121518523,121518525,121518527,121518529,121518531,121518533,121518535,121518537,121518539,121518541,121518543,121518545,121518547,121518549,121518551,121518553,121518555,121518557,121518559,121518561,121518563,121518565,121518567,121518569,121518571,121518573,121518575,121518577,121518579,121518581,121518583,121518585,121518587,121518589,121518591,121518593,121518595,121518597,121518599,121518601,121518603,121518605,121518607,121518609,121518611,121518613,121518615,121518617,121518619,121518621,121518623,121518625,121518627,121518629,121518631,121518633,121518635,121518637,121518639,121518641,121518643,121518645,121518647,121518649,121518651,121518653,121518655,121518657,121518659,121518661,121518663,121518665,121518667,121518669,121518671,121518673,121518675,121518677,121518679,121518681,121518683,121518685,121518687,121518689,121518691,121518693,121518695,121518697,121518699,121518701,121518703]) (fromList [AJobResultInfoSolver "AProVE 2015",AJobResultInfoConfiguration "itrs"]),Concept (fromList [121518471,121518472,121518473,121518474,121518476,121518477,121518478,121518479,121518480,121518481,121518482,121518483,121518484,121518486,121518487,121518488,121518490,121518491,121518492,121518494,121518495,121518496,121518497,121518498,121518499,121518500,121518501,121518502,121518503,121518504,121518505,121518506,121518507,121518508,121518509,121518510,121518511,121518512,121518513,121518514,121518515,121518516,121518517,121518518,121518519,121518520,121518521,121518522,121518523,121518524,121518526,121518527,121518528,121518529,121518530,121518532,121518533,121518536,121518537,121518538,121518540,121518541,121518542,121518543,121518544,121518546,121518547,121518548,121518550,121518551,121518552,121518553,121518554,121518555,121518556,121518557,121518558,121518559,121518560,121518562,121518564,121518565,121518566,121518567,121518568,121518569,121518570,121518571,121518572,121518573,121518574,121518576,121518577,121518578,121518579,121518580,121518582,121518584,121518585,121518586,121518587,121518588,121518589,121518590,121518592,121518594,121518598,121518600,121518601,121518602,121518603,121518604,121518606,121518608,121518609,121518610,121518611,121518612,121518613,121518614,121518615,121518616,121518618,121518621,121518622,121518623,121518624,121518626,121518628,121518631,121518632,121518633,121518634,121518635,121518636,121518637,121518638,121518639,121518640,121518641,121518642,121518643,121518644,121518645,121518646,121518647,121518648,121518649,121518650,121518651,121518652,121518653,121518654,121518655,121518656,121518657,121518658,121518659,121518660,121518661,121518662,121518664,121518665,121518666,121518668,121518669,121518670,121518671,121518672,121518673,121518674,121518675,121518676,121518677,121518678,121518680,121518681,121518682,121518684,121518685,121518686,121518687,121518688,121518689,121518690,121518691,121518692,121518694,121518695,121518696,121518697,121518698,121518699,121518700,121518701,121518702,121518704]) (fromList [ASlowCpuTime False]),Concept (fromList [121518472,121518474,121518476,121518478,121518480,121518482,121518484,121518486,121518488,121518490,121518492,121518494,121518496,121518498,121518500,121518502,121518504,121518506,121518508,121518510,121518512,121518514,121518516,121518518,121518520,121518522,121518524,121518526,121518528,121518530,121518532,121518536,121518538,121518540,121518542,121518544,121518546,121518548,121518550,121518552,121518554,121518556,121518558,121518560,121518562,121518564,121518566,121518568,121518570,121518572,121518574,121518576,121518578,121518580,121518582,121518584,121518586,121518588,121518590,121518592,121518594,121518598,121518600,121518602,121518604,121518606,121518608,121518610,121518612,121518614,121518616,121518618,121518622,121518624,121518626,121518628,121518632,121518634,121518636,121518638,121518640,121518642,121518644,121518646,121518648,121518650,121518652,121518654,121518656,121518658,121518660,121518662,121518664,121518666,121518668,121518670,121518672,121518674,121518676,121518678,121518680,121518682,121518684,121518686,121518688,121518690,121518692,121518694,121518696,121518698,121518700,121518702,121518704]) (fromList [AJobResultInfoSolver "Ctrl",AJobResultInfoConfiguration "Itrs",ASlowCpuTime False]),Concept (fromList [121518475,121518485,121518489,121518493,121518525,121518531,121518534,121518535,121518539,121518545,121518549,121518561,121518563,121518575,121518581,121518583,121518591,121518593,121518595,121518596,121518597,121518599,121518605,121518607,121518617,121518619,121518620,121518625,121518627,121518629,121518630,121518663,121518667,121518679,121518683,121518693,121518703]) (fromList [ASlowCpuTime True]),Concept (fromList [121518534,121518596,121518620,121518630]) (fromList [AJobResultInfoSolver "Ctrl",AJobResultInfoConfiguration "Itrs",ASlowCpuTime True]),Concept (fromList [121518475,121518485,121518489,121518493,121518525,121518531,121518535,121518539,121518545,121518549,121518561,121518563,121518575,121518581,121518583,121518591,121518593,121518595,121518597,121518599,121518605,121518607,121518617,121518619,121518625,121518627,121518629,121518663,121518667,121518679,121518683,121518693,121518703]) (fromList [AJobResultInfoSolver "AProVE 2015",AJobResultInfoConfiguration "itrs",ASlowCpuTime True]),Concept (fromList [121518471,121518472,121518473,121518474,121518475,121518476,121518477,121518478,121518479,121518480,121518481,121518482,121518483,121518484,121518485,121518486,121518487,121518488,121518489,121518491,121518492,121518493,121518495,121518496,121518497,121518498,121518499,121518500,121518501,121518502,121518503,121518504,121518505,121518506,121518507,121518508,121518509,121518510,121518511,121518512,121518513,121518514,121518515,121518517,121518518,121518519,121518520,121518521,121518522,121518523,121518524,121518525,121518526,121518527,121518528,121518529,121518530,121518533,121518535,121518536,121518537,121518539,121518541,121518542,121518543,121518544,121518547,121518548,121518549,121518551,121518553,121518554,121518555,121518556,121518557,121518558,121518559,121518560,121518564,121518565,121518566,121518567,121518568,121518569,121518570,121518571,121518572,121518573,121518574,121518577,121518578,121518579,121518580,121518581,121518582,121518583,121518585,121518586,121518587,121518588,121518589,121518590,121518591,121518592,121518595,121518596,121518599,121518600,121518601,121518602,121518603,121518604,121518609,121518610,121518611,121518612,121518613,121518615,121518616,121518621,121518622,121518623,121518624,121518625,121518626,121518631,121518632,121518633,121518635,121518636,121518637,121518638,121518639,121518640,121518641,121518642,121518643,121518644,121518645,121518646,121518647,121518649,121518651,121518652,121518653,121518654,121518655,121518656,121518657,121518658,121518659,121518661,121518662,121518665,121518667,121518669,121518670,121518671,121518672,121518673,121518674,121518675,121518676,121518677,121518678,121518679,121518680,121518681,121518682,121518683,121518685,121518686,121518687,121518688,121518689,121518691,121518692,121518693,121518694,121518695,121518696,121518697,121518698,121518699,121518700,121518701,121518702]) (fromList [ASolverResult YES]),Concept (fromList [121518472,121518474,121518476,121518478,121518480,121518482,121518484,121518486,121518488,121518492,121518496,121518498,121518500,121518502,121518504,121518506,121518508,121518510,121518512,121518514,121518518,121518520,121518522,121518524,121518526,121518528,121518530,121518536,121518542,121518544,121518548,121518554,121518556,121518558,121518560,121518564,121518566,121518568,121518570,121518572,121518574,121518578,121518580,121518582,121518586,121518588,121518590,121518592,121518596,121518600,121518602,121518604,121518610,121518612,121518616,121518622,121518624,121518626,121518632,121518636,121518638,121518640,121518642,121518644,121518646,121518652,121518654,121518656,121518658,121518662,121518670,121518672,121518674,121518676,121518678,121518680,121518682,121518686,121518688,121518692,121518694,121518696,121518698,121518700,121518702]) (fromList [AJobResultInfoSolver "Ctrl",AJobResultInfoConfiguration "Itrs",ASolverResult YES]),Concept (fromList [121518471,121518473,121518475,121518477,121518479,121518481,121518483,121518485,121518487,121518489,121518491,121518493,121518495,121518497,121518499,121518501,121518503,121518505,121518507,121518509,121518511,121518513,121518515,121518517,121518519,121518521,121518523,121518525,121518527,121518529,121518533,121518535,121518537,121518539,121518541,121518543,121518547,121518549,121518551,121518553,121518555,121518557,121518559,121518565,121518567,121518569,121518571,121518573,121518577,121518579,121518581,121518583,121518585,121518587,121518589,121518591,121518595,121518599,121518601,121518603,121518609,121518611,121518613,121518615,121518621,121518623,121518625,121518631,121518633,121518635,121518637,121518639,121518641,121518643,121518645,121518647,121518649,121518651,121518653,121518655,121518657,121518659,121518661,121518665,121518667,121518669,121518671,121518673,121518675,121518677,121518679,121518681,121518683,121518685,121518687,121518689,121518691,121518693,121518695,121518697,121518699,121518701]) (fromList [AJobResultInfoSolver "AProVE 2015",AJobResultInfoConfiguration "itrs",ASolverResult YES]),Concept (fromList [121518471,121518472,121518473,121518474,121518476,121518477,121518478,121518479,121518480,121518481,121518482,121518483,121518484,121518486,121518487,121518488,121518491,121518492,121518495,121518496,121518497,121518498,121518499,121518500,121518501,121518502,121518503,121518504,121518505,121518506,121518507,121518508,121518509,121518510,121518511,121518512,121518513,121518514,121518515,121518517,121518518,121518519,121518520,121518521,121518522,121518523,121518524,121518526,121518527,121518528,121518529,121518530,121518533,121518536,121518537,121518541,121518542,121518543,121518544,121518547,121518548,121518551,121518553,121518554,121518555,121518556,121518557,121518558,121518559,121518560,121518564,121518565,121518566,121518567,121518568,121518569,121518570,121518571,121518572,121518573,121518574,121518577,121518578,121518579,121518580,121518582,121518585,121518586,121518587,121518588,121518589,121518590,121518592,121518600,121518601,121518602,121518603,121518604,121518609,121518610,121518611,121518612,121518613,121518615,121518616,121518621,121518622,121518623,121518624,121518626,121518631,121518632,121518633,121518635,121518636,121518637,121518638,121518639,121518640,121518641,121518642,121518643,121518644,121518645,121518646,121518647,121518649,121518651,121518652,121518653,121518654,121518655,121518656,121518657,121518658,121518659,121518661,121518662,121518665,121518669,121518670,121518671,121518672,121518673,121518674,121518675,121518676,121518677,121518678,121518680,121518681,121518682,121518685,121518686,121518687,121518688,121518689,121518691,121518692,121518694,121518695,121518696,121518697,121518698,121518699,121518700,121518701,121518702]) (fromList [ASlowCpuTime False,ASolverResult YES]),Concept (fromList [121518472,121518474,121518476,121518478,121518480,121518482,121518484,121518486,121518488,121518492,121518496,121518498,121518500,121518502,121518504,121518506,121518508,121518510,121518512,121518514,121518518,121518520,121518522,121518524,121518526,121518528,121518530,121518536,121518542,121518544,121518548,121518554,121518556,121518558,121518560,121518564,121518566,121518568,121518570,121518572,121518574,121518578,121518580,121518582,121518586,121518588,121518590,121518592,121518600,121518602,121518604,121518610,121518612,121518616,121518622,121518624,121518626,121518632,121518636,121518638,121518640,121518642,121518644,121518646,121518652,121518654,121518656,121518658,121518662,121518670,121518672,121518674,121518676,121518678,121518680,121518682,121518686,121518688,121518692,121518694,121518696,121518698,121518700,121518702]) (fromList [AJobResultInfoSolver "Ctrl",AJobResultInfoConfiguration "Itrs",ASlowCpuTime False,ASolverResult YES]),Concept (fromList [121518471,121518473,121518477,121518479,121518481,121518483,121518487,121518491,121518495,121518497,121518499,121518501,121518503,121518505,121518507,121518509,121518511,121518513,121518515,121518517,121518519,121518521,121518523,121518527,121518529,121518533,121518537,121518541,121518543,121518547,121518551,121518553,121518555,121518557,121518559,121518565,121518567,121518569,121518571,121518573,121518577,121518579,121518585,121518587,121518589,121518601,121518603,121518609,121518611,121518613,121518615,121518621,121518623,121518631,121518633,121518635,121518637,121518639,121518641,121518643,121518645,121518647,121518649,121518651,121518653,121518655,121518657,121518659,121518661,121518665,121518669,121518671,121518673,121518675,121518677,121518681,121518685,121518687,121518689,121518691,121518695,121518697,121518699,121518701]) (fromList [AJobResultInfoSolver "AProVE 2015",AJobResultInfoConfiguration "itrs",ASlowCpuTime False,ASolverResult YES]),Concept (fromList [121518475,121518485,121518489,121518493,121518525,121518535,121518539,121518549,121518581,121518583,121518591,121518595,121518596,121518599,121518625,121518667,121518679,121518683,121518693]) (fromList [ASlowCpuTime True,ASolverResult YES]),Concept (fromList [121518596]) (fromList [AJobResultInfoSolver "Ctrl",AJobResultInfoConfiguration "Itrs",ASlowCpuTime True,ASolverResult YES]),Concept (fromList [121518475,121518485,121518489,121518493,121518525,121518535,121518539,121518549,121518581,121518583,121518591,121518595,121518599,121518625,121518667,121518679,121518683,121518693]) (fromList [AJobResultInfoSolver "AProVE 2015",AJobResultInfoConfiguration "itrs",ASlowCpuTime True,ASolverResult YES]),Concept (fromList [121518490,121518494,121518516,121518531,121518532,121518534,121518538,121518540,121518545,121518546,121518550,121518552,121518561,121518562,121518563,121518575,121518576,121518584,121518593,121518594,121518597,121518598,121518605,121518606,121518607,121518608,121518614,121518617,121518618,121518619,121518620,121518627,121518628,121518629,121518630,121518634,121518648,121518650,121518660,121518663,121518664,121518666,121518668,121518684,121518690,121518703,121518704]) (fromList [ASolverResult MAYBE]),Concept (fromList [121518490,121518494,121518516,121518532,121518534,121518538,121518540,121518546,121518550,121518552,121518562,121518576,121518584,121518594,121518598,121518606,121518608,121518614,121518618,121518620,121518628,121518630,121518634,121518648,121518650,121518660,121518664,121518666,121518668,121518684,121518690,121518704]) (fromList [AJobResultInfoSolver "Ctrl",AJobResultInfoConfiguration "Itrs",ASolverResult MAYBE]),Concept (fromList [121518490,121518494,121518516,121518532,121518538,121518540,121518546,121518550,121518552,121518562,121518576,121518584,121518594,121518598,121518606,121518608,121518614,121518618,121518628,121518634,121518648,121518650,121518660,121518664,121518666,121518668,121518684,121518690,121518704]) (fromList [AJobResultInfoSolver "Ctrl",AJobResultInfoConfiguration "Itrs",ASlowCpuTime False,ASolverResult MAYBE]),Concept (fromList [121518531,121518534,121518545,121518561,121518563,121518575,121518593,121518597,121518605,121518607,121518617,121518619,121518620,121518627,121518629,121518630,121518663,121518703]) (fromList [ASlowCpuTime True,ASolverResult MAYBE]),Concept (fromList [121518534,121518620,121518630]) (fromList [AJobResultInfoSolver "Ctrl",AJobResultInfoConfiguration "Itrs",ASlowCpuTime True,ASolverResult MAYBE]),Concept (fromList [121518531,121518545,121518561,121518563,121518575,121518593,121518597,121518605,121518607,121518617,121518619,121518627,121518629,121518663,121518703]) (fromList [AJobResultInfoSolver "AProVE 2015",AJobResultInfoConfiguration "itrs",ASlowCpuTime True,ASolverResult MAYBE]),Concept (fromList []) (fromList [AJobResultInfoSolver "AProVE 2015",AJobResultInfoSolver "Ctrl",AJobResultInfoConfiguration "Itrs",AJobResultInfoConfiguration "itrs",ASlowCpuTime False,ASlowCpuTime True,ASolverResult YES,ASolverResult MAYBE])]

dotted_graph = do
  let graph_with_trans_edges = graphToDot graph_params $ graph concept_lattice
  TL.unpack $ renderDot $ toDot $ transitiveReduction graph_with_trans_edges
-- renderDot :: DotCode -> Text
-- graphToDot :: (Ord cl, Graph gr) => GraphvizParams Node nl el cl l -> gr nl el -> DotGraph Node

graph :: (Eq ob, Eq at, Show at, Ord at) => [Concept ob at] -> Gr TL.Text TL.Text
graph concept_lattice = do
  mkGraph (get_nodes concept_lattice) $ get_edges concept_lattice

get_nodes :: (Eq ob, Eq at, Show at) => [Concept ob at] -> [LNode TL.Text]
get_nodes concept_lattice = map
 (\c -> (fromJust $ elemIndex c concept_lattice, TL.pack $ showTree $ ats c))
 concept_lattice

get_edges :: (Eq ob, Eq at, Ord at) => [Concept ob at] -> [LEdge TL.Text]
get_edges concept_lattice = do
  concept <- concept_lattice
  concept2 <- concept_lattice
  guard (isProperSubsetOf (ats concept) (ats concept2))
  -- math: ats concept < ats concept2 -> (ats concept) -> (ats concept2)
  return (fromJust $ elemIndex concept concept_lattice, fromJust $ elemIndex concept2 concept_lattice, "")

graph_params :: GraphvizParams n TL.Text TL.Text () TL.Text
graph_params = nonClusteredParams