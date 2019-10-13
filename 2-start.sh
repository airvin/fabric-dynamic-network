#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This script starts the base Fabric network. 
# It first brings up the containers for the ordering service and organization 1,
# then creates channel1 and joins the peer for organization 1 to the channel. 
# This script should only be run after the crypto material and channel transactions 
# have has been generated in the generate.sh script.

export CA1_PRIVATE_KEY=$(cd crypto-config/peerOrganizations/org1.example.com/ca && ls *_sk)

docker-compose -f docker-compose.yaml down

docker-compose -f docker-compose.yaml up -d ca.org1.example.com orderer.example.com peer0.org1.example.com couchdb1 cliOrderer cli1

docker ps -a

echo "Sleep for 10s to allow Fabric network to start"
sleep 10

# Create channel1
echo "Creating the channel 'channel1'"
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c channel1 -f /etc/hyperledger/configtx/channel1.tx

# Join peer0.org1.example.com to channel1.
echo "Joining peer0.org1 to channel1"
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b channel1.block

# Check that peer0.org1.example.com was able to join channel1
echo "Check that peer0.org1 was able to join channel1"
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel list