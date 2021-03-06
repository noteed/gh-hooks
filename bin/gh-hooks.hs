{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Main (main) where

import Control.Lens (makeLenses)
import Control.Monad.Trans (liftIO)
import Data.Aeson (decode, Value)
import qualified Data.ByteString.Lazy.Char8 as L
import qualified Data.ByteString.Char8 as B
import Data.Digest.Pure.SHA (hmacSha1, showDigest)
import qualified Database.PostgreSQL.Queue as Q
import Database.PostgreSQL.Simple (connectPostgreSQL, execute_, close)
import Snap.Core
  ( getHeader, getsRequest, ifTop, method, modifyResponse
  , readRequestBody, setContentType, setResponseStatus
  , writeText, Method(POST))
import Snap.Http.Server (defaultConfig)
import Snap.Snaplet
import System.IO (hFlush, stdout)

data App = App

makeLenses ''App

main :: IO ()
main = serveSnaplet defaultConfig appInit

appInit :: SnapletInit App App
appInit =
  makeSnaplet "gh-hooks" description Nothing $ do
    content <- liftIO $ readFile "/github-shared-secret.txt"
    dbUrl <- liftIO $ B.readFile "/database-url.txt"
    addRoutes $
      [ ("", ifTop index)
      , ("/payload", ifTop $ method POST
          (payload dbUrl $ L.pack (head (words content)))) -- TODO May explode.
      ]
    return App

  where description = "GitHub Webhooks Receiver"

index :: Handler App App ()
index = do
  modifyResponse $ setContentType "text/plain"
  writeText "GitHub Webhooks Receiver.\n"

payload :: B.ByteString -> L.ByteString -> Handler App App ()
payload dbUrl secret = do
  signature <- getsRequest $ getHeader "X-Hub-Signature"
  body <- readRequestBody 16384 -- TODO correct size.
  liftIO $ do
    putStrLn "Got some payload."
    print body
    hFlush stdout
  modifyResponse $ setContentType "text/plain"
  if signature == Just (B.pack ("sha1=" ++ showDigest (hmacSha1 secret body)))
    then case decode body of
      Just (body' :: Value) -> do
        event <- getsRequest $ getHeader "X-GitHub-Event"
        if event == Just "push"
          then do
            liftIO $ do
              con <- connectPostgreSQL dbUrl
              _ <- execute_ con "SET application_name='gh-hooks'"
              let q = Q.Queue "ghhooks"
              Q.enqueue con q "push" body'
              close con
            writeText "Payload accepted.\n"
          else do
            modifyResponse $ setResponseStatus 400 "Event is not a push."
            writeText "Event is not a push.\n"
      Nothing -> do
        modifyResponse $ setResponseStatus 400 "Error decoding JSON payload."
        writeText "Error decoding JSON payload.\n"
    else do
      modifyResponse $ setResponseStatus 401 "Signature mismatch."
      writeText "Signature mismatch.\n"
