#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This script is used to add the new organization, Org2, to the existing channel1.
# As Org2 was not included in the original consortium definition for the channel,
# this process requires that Org1, the sole channel administrator, creates and 
# submits a new channel configuration transaction that includes Org2 as an admin.
# This script should be run after the base network and Org2 have been started, 
# using the start.sh and create-new-org.sh scripts, respectively. 

# Navigate to the directory with the new org artifacts
cd org2-artifacts

# FABRIC_CFG_PATH is used by configtxgen to let the tool know where to find the configtx.yaml file it needs.
export FABRIC_CFG_PATH=$PWD 

# Create a json file that contains the policy definitions for $ORG_NAME as well as the admin user certificate, CA root certificate and a TLS root certificate.
configtxgen -printOrg Org2MSP > ../crypto-config/org2.json

# Copy the orderer org's MSP material into the crypto-config directory for the new org.
cp -r ../crypto-config/ordererOrganizations ./crypto-config/

# Fetch the latest channel configuration block from the channel
docker exec cli1 peer channel fetch config config_block.pb -o orderer.example.com:7050 -c channel1

# Convert the configuration transaction in the block to json and trim it down.
docker exec cli1 configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > ../crypto-config/config.json

# Create a modified version of the config transaction with the new org material added
docker exec cli1 jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org2MSP":.[1]}}}}}' ./crypto/config.json ./crypto/org2.json > ../crypto-config/modified_config.json

# Convert the original config json into protobuf
docker exec cli1 configtxlator proto_encode --input ./crypto/config.json --type common.Config --output ./crypto/config.pb

# Convert the modified config json into protobuf
docker exec cli1 configtxlator proto_encode --input ./crypto/modified_config.json --type common.Config --output ./crypto/modified_config.pb

# Create a protobuf with the difference between the two configs
docker exec cli1 configtxlator compute_update --channel_id channel1 --original ./crypto/config.pb --updated ./crypto/modified_config.pb --output ./crypto/org2_update.pb

# Convert the update protobuf into json
docker exec cli1 configtxlator proto_decode --input ./crypto/org2_update.pb --type common.ConfigUpdate | jq . > ../crypto-config/org2_update.json

# Add the header field to the update config json
docker exec cli1 echo '{"payload":{"header":{"channel_header":{"channel_id":"channel1", "type":2}},"data":{"config_update":'$(cat ../crypto-config/org2_update.json)'}}}' | jq . > ../crypto-config/org2_update_in_envelope.json

# Convert the config with header attached back to protobuf
docker exec cli1 configtxlator proto_encode --input ./crypto/org2_update_in_envelope.json --type common.Envelope --output ./crypto/org2_update_in_envelope.pb

# Submit the new channel configuration transaction
# Note that if there was more than one administrator of the channel, this transaction may need to be signed by the
# other channel administrators before submitting the update. 
docker exec cli1 peer channel update -f ./crypto/org2_update_in_envelope.pb -c channel1 -o orderer.example.com:7050

# Remove all the artifacts for org addition
rm ../crypto-config/*.json ../crypto-config/*.pb

# Fetch the genesis block to start syncing the new org peer's ledger
docker exec cli2 peer channel fetch 0 channel1.block -o orderer.example.com:7050 -c channel1

# Join peer to channel
docker exec cli2 peer channel join -b channel1.block