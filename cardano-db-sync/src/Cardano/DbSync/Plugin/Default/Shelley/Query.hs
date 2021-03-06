{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Cardano.DbSync.Plugin.Default.Shelley.Query
  ( queryStakeAddress
  , queryStakePoolKeyHash
  , queryTxInputSum
  ) where


import qualified Cardano.Crypto.Hash as Crypto
import           Cardano.Db
import           Cardano.DbSync.Types
import           Cardano.DbSync.Era.Shelley.Util (unKeyHashBS)

import           Control.Monad.IO.Class (MonadIO)
import           Control.Monad.Trans.Reader (ReaderT)

import           Data.ByteString.Char8 (ByteString)
import           Data.Either (fromRight)
import           Data.Maybe (listToMaybe)
import           Data.Word (Word64)

import           Database.Esqueleto (Value (..),  (^.), (==.), from, select, val, where_)
import           Database.Persist.Sql (SqlBackend)

import qualified Shelley.Spec.Ledger.TxData as Shelley


queryStakeAddress :: MonadIO m => ByteString -> ReaderT SqlBackend m (Either LookupFail StakeAddressId)
queryStakeAddress addr = do
  res <- select . from $ \ saddr -> do
            where_ (saddr ^. StakeAddressHash ==. val addr)
            pure (saddr ^. StakeAddressId)
  pure $ maybeToEither (DbLookupMessage "StakeAddress") unValue (listToMaybe res)

queryStakePoolKeyHash :: MonadIO m => ShelleyStakePoolKeyHash -> ReaderT SqlBackend m (Either LookupFail PoolId)
queryStakePoolKeyHash kh = do
  res <- select . from $ \ pool -> do
            where_ (pool ^. PoolHash ==. val (unKeyHashBS kh))
            pure (pool ^. PoolId)
  pure $ maybeToEither (DbLookupMessage "StakePoolKeyHash") unValue (listToMaybe res)

queryTxInputSum :: MonadIO m => [ShelleyTxIn] -> ReaderT SqlBackend m Word64
queryTxInputSum txins =
    sum <$> mapM queryTxInputValue txins
  where
    queryTxInputValue :: MonadIO m => ShelleyTxIn -> ReaderT SqlBackend m Word64
    queryTxInputValue (Shelley.TxIn (Shelley.TxId hash) index) =
      fromRight 0 <$> queryTxOutValue (Crypto.getHash hash, fromIntegral index)
