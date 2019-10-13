#!/bin/sh

# This script generates all the required artifacts for the base network. 
# It uses the cryptogen tool to create the x509 certificates for all of the
# network components specified in the crypto-config.yaml file.
# It then uses the configtxgen tool to create the configuration transactions
# that are used to bootstrap the orderer channel and the Org1 channel, with the 
# configuration defined in the configtx.yaml file.

export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}

# Create the config folder
mkdir config

# Remove previous crypto material and configuration transactions if there are any.
rm -fr config/*
rm -fr crypto-config/*

# Generate the x509 certificates for network components.
cryptogen generate --config=./crypto-config.yaml
if [ "$?" -ne 0 ]; then
  echo "Failed to generate crypto material..."
  exit 1
fi

# Generate the genesis block for the ordering service channel.
configtxgen -profile OneOrgOrdererGenesis -channelID ordererchannel -outputBlock ./config/genesis.block
if [ "$?" -ne 0 ]; then
  echo "Failed to generate orderer genesis block..."
  exit 1
fi

# Generate the channel configuration transaction for channel1.
configtxgen -profile Org1Channel -outputCreateChannelTx ./config/channel1.tx -channelID channel1

# Generate anchor peer transaction for Org1 in channel1.
configtxgen -profile Org1Channel -outputAnchorPeersUpdate ./config/Org1MSPanchorsChannel1.tx -channelID channel1 -asOrg Org1MSP
