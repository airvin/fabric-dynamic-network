#!/bin/sh
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This script is used to create a new channel as Org2. 
# It is required that the SampleConsortium2 definition has been added to a 
# orderer channel configuration transaction before it can be run. 
# Therefore, it needs to be run after the add-org-to-consortium.sh script. 

# Point the Fabric configuration path to the new configtx.yaml file
cd org2-artifacts
export FABRIC_CFG_PATH=${PWD}

# Generate channel configuration transaction for channel2
configtxgen -profile Org2Channel -outputCreateChannelTx ../config/channel2.tx -channelID channel2

# Create channel2
echo "Creating the channel 'channel2'"
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer0.org2.example.com peer channel create -o orderer.example.com:7050 -c channel2 -f /etc/hyperledger/configtx/channel2.tx

# Join peer0.org2.example.com to channel2.
echo "Joining peer0.org2 to channel2"
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer0.org2.example.com peer channel join -b channel2.block

# Check that peer0.org2.example.com was able to join channel2
echo "Check that peer0.org2 was able to join channel2"
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer0.org2.example.com peer channel list