# !/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This script is used to add the new organization, Org2, to a new consortium definition.
# Consortia are defined in the ordering service channel configuration transactions, 
# so this process requires that the orderer creates and submits a new 
# channel configuration transaction that includes Org2 in a Consortium. 
# This script should be run after the base network and Org2 have been started, 
# using the start.sh and create-new-org.sh scripts, respectively. 

cd org2-artifacts/

# Remove all the old artifacts for any previous org addition
rm ../crypto-config/*.json ../crypto-config/*.pb

# FABRIC_CFG_PATH is used by configtxgen to let the tool know where to find the configtx.yaml file it needs.
export FABRIC_CFG_PATH=$PWD 

# Create a json file that contains the policy definitions for org2 as well as the admin user certificate, CA root certificate and a TLS root certificate.
configtxgen -printOrg Org2MSP > ../crypto-config/org2.json

# Copy the orderer org's MSP material into the crypto-config directory for the new org.
cp -r ../crypto-config/ordererOrganizations ./crypto-config/

# Fetch the latest channel configuration block from the channel as the orderer
docker exec cliOrderer peer channel fetch config sys_config_block.pb -o orderer.example.com:7050 -c ordererchannel

# Convert the configuration transaction in the block to json and trim it down.
docker exec cliOrderer configtxlator proto_decode --input sys_config_block.pb --type common.Block | jq .data.data[0].payload.data.config > ../crypto-config/sys_config.json

# Create a modified version of the config transaction with the new org material added
docker exec cliOrderer jq -s '.[0] * {"channel_group":{"groups":{"Consortiums":{"groups": {"SampleConsortium'2'": {"groups": {"'Org2'MSP":.[1]}, "mod_policy": "/Channel/Orderer/Admins", "policies": {}, "values": {"ChannelCreationPolicy": {"mod_policy": "/Channel/Orderer/Admins","value": {"type": 3,"value": {"rule": "ANY","sub_policy": "Admins"}},"version": "0"}},"version": "0"}}}}}}' ./crypto/sys_config.json ./crypto/org2.json > ../crypto-config/modified_config.json

# Convert the original config sys_json into protobuf
docker exec cliOrderer configtxlator proto_encode --input ./crypto/sys_config.json --type common.Config --output ./crypto/sys_config.pb

# Convert the modified config json into protobuf
docker exec cliOrderer configtxlator proto_encode --input ./crypto/modified_config.json --type common.Config --output ./crypto/modified_config.pb

# Create a protobuf with the difference between the two configs
docker exec cliOrderer configtxlator compute_update --channel_id ordererchannel --original ./crypto/sys_config.pb --updated ./crypto/modified_config.pb --output ./crypto/org2_update.pb

# Convert the update protobuf into json
docker exec cliOrderer configtxlator proto_decode --input ./crypto/org2_update.pb --type common.ConfigUpdate | jq . > ../crypto-config/org2_update.json

# Add the header field to the update config json
docker exec cliOrderer echo '{"payload":{"header":{"channel_header":{"channel_id":"ordererchannel", "type":2}},"data":{"config_update":'$(cat ../crypto-config/org2_update.json)'}}}' | jq . > ../crypto-config/org2_update_in_envelope.json

# Convert the config with header attached back to protobuf
docker exec cliOrderer configtxlator proto_encode --input ./crypto/org2_update_in_envelope.json --type common.Envelope --output ./crypto/org2_update_in_envelope.pb

docker exec cliOrderer peer channel update -f ./crypto/org2_update_in_envelope.pb -c ordererchannel -o orderer.example.com:7050

