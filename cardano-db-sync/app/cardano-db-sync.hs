{-# LANGUAGE NoImplicitPrelude #-}

import           Cardano.Prelude

import           Cardano.Db (MigrationDir (..))
import           Cardano.DbSync (ConfigFile (..), DbSyncNodeParams (..), GenesisFile (..),
                    SocketPath (..), defDbSyncNodePlugin, runDbSyncNode)

import           Cardano.Slotting.Slot (SlotNo (..))

import           Options.Applicative (Parser, ParserInfo)
import qualified Options.Applicative as Opt


main :: IO ()
main = do
  runDbSyncNode defDbSyncNodePlugin =<< Opt.execParser opts

-- -------------------------------------------------------------------------------------------------

opts :: ParserInfo DbSyncNodeParams
opts =
  Opt.info (pCommandLine <**> Opt.helper)
    ( Opt.fullDesc
    <> Opt.progDesc "Cardano PostgreSQL sync node."
    )

pCommandLine :: Parser DbSyncNodeParams
pCommandLine =
  DbSyncNodeParams
    <$> pConfigFile
    <*> pGenesisFile
    <*> pSocketPath
    <*> pMigrationDir
    <*> optional pSlotNo

pConfigFile :: Parser ConfigFile
pConfigFile =
  ConfigFile <$> Opt.strOption
    ( Opt.long "config"
    <> Opt.help "Path to the db-sync node config file"
    <> Opt.completer (Opt.bashCompleter "file")
    <> Opt.metavar "FILEPATH"
    )

pGenesisFile :: Parser GenesisFile
pGenesisFile =
  GenesisFile <$> Opt.strOption
    ( Opt.long "genesis-file"
    <> Opt.help "Path to the genesis JSON file"
    <> Opt.completer (Opt.bashCompleter "file")
    <> Opt.metavar "FILEPATH"
    )

pMigrationDir :: Parser MigrationDir
pMigrationDir =
  MigrationDir <$> Opt.strOption
    (  Opt.long "schema-dir"
    <> Opt.help "The directory containing the migrations."
    <> Opt.completer (Opt.bashCompleter "directory")
    <> Opt.metavar "FILEPATH"
    )

pSocketPath :: Parser SocketPath
pSocketPath =
  SocketPath <$> Opt.strOption
    ( Opt.long "socket-path"
    <> Opt.help "Path to a cardano-node socket"
    <> Opt.completer (Opt.bashCompleter "file")
    <> Opt.metavar "FILEPATH"
    )

pSlotNo :: Parser SlotNo
pSlotNo =
  SlotNo <$> Opt.option Opt.auto
    (  Opt.long "rollback-to-slot"
    <> Opt.help "Force a rollback to the specified slot (mainly for testing and debugging)."
    <> Opt.metavar "WORD"
    )
