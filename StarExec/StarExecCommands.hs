{-# LANGUAGE TupleSections, OverloadedStrings #-}

module StarExec.StarExecCommands
  ( login
  , logout
  , checkLogin
  ) where

import Import
import Prelude (head)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import Network.HTTP.Conduit
-- import Control.Monad.IO.Class
import qualified Data.ByteString as BS

-- Static-Paths

starExecUrl :: String
starExecUrl = "https://www.starexec.org/"

indexPath :: BS.ByteString
indexPath = "starexec/secure/index.jsp"

loginPath :: BS.ByteString
loginPath = "starexec/secure/j_security_check"

logoutPath :: BS.ByteString
logoutPath = "starexec/services/session/logout"

-- Methods

parseCookies sCookies = read (T.unpack sCookies) :: [Cookie]

sendRequest secFunc = do
  sec <- parseUrl "https://www.starexec.org/"
  withManager $ secFunc sec

getLocation resp = 
    let locs = filter (\(n,_) -> n == "Location" ) (responseHeaders resp)
    in
      if null locs then Nothing else Just $ snd $ head locs

-- checkLogin :: MonadIO m => Maybe Text -> m Bool
checkLogin Nothing = return False
checkLogin (Just sCookies) = do
  let cookies = parseCookies sCookies
  loggedIn <- sendRequest $ \sec man -> do
    cookies <- index sec man $ createCookieJar cookies
    let req = sec { method = "HEAD"
                  , path = "starexec/secure/index.jsp"
                  , cookieJar = Just cookies
                  , redirectCount = 0
                  , checkStatus = (\_ _ _ -> Nothing)
                  }
    resp <- httpLbs req man
    let loc = getLocation resp
    let loggedIn = case loc of
                        Just location -> if location == "https://www.starexec.org/starexec/secure/explore/spaces.jsp"
                                                then True
                                                else False
                        Nothing            -> False
    return loggedIn
  return loggedIn

-- index :: MonadIO m => Request -> Manager -> CookieJar -> m CookieJar
index sec man cookies = do
  let req = sec { method = "GET"
                , path = indexPath
                , cookieJar = Just cookies
                }
  resp <- httpLbs req man
  let respCookies = responseCookieJar resp
  return respCookies

-- login :: MonadIO m => BS.ByteString -> BS.ByteString -> m CookieJar
login user pass sCookies = do
  let cookies = case sCookies of
                     Nothing -> []
                     Just sc -> parseCookies sc
  sendRequest $ \sec man -> do
    cookies <- index sec man $ createCookieJar cookies
    let req = urlEncodedBody [ ("j_username", TE.encodeUtf8 user)
                             , ("j_password", TE.encodeUtf8 pass) 
                             , ("cookieexists", "false")
                             ] 
                $ sec { method = "POST"
                      , path = loginPath
                      , cookieJar = Just cookies
                      }
    resp <- httpLbs req man
    let respCookies = responseCookieJar resp
    return $ T.pack $ show $ destroyCookieJar respCookies

-- logout :: MonadIO m => Request -> Manager -> CookieJar -> m CookieJar
logout sCookies = do
  let cookies = case sCookies of
                     Nothing -> []
                     Just sc -> parseCookies sc
  sendRequest $ \sec man -> do
    cookies <- index sec man $ createCookieJar cookies
    let req = sec { method = "POST"
                  , path = logoutPath
                  , cookieJar = Just cookies
                  }
    resp <- httpLbs req man
    let respCookies = responseCookieJar resp
    return $ T.pack $ show $ destroyCookieJar respCookies
