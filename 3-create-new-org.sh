#!/bin/bash

# This script brings up the network components for the new organization, Org2. 
# It uses the cryptogen tool to create the x509 certificates for the
# Org2 components specified in the org2-artifacts/crypto-config.yaml file.
# It then starts all the containers required for the organization. 
# This script should be run after the base network has been started using
# the start.sh script.

# Navigate to the directory with the required artifacts for org2
cd org2-artifacts/

# Generate the crypto material for org2
cryptogen generate --config=./crypto-config.yaml
if [ "$?" -ne 0 ]; then
  echo "Failed to generate crypto material..."
  exit 1
fi

# Copy the org2 crypto material into the main crypto-config folder.
cp -r ./crypto-config/peerOrganizations/org2.example.com ../crypto-config/peerOrganizations

# Export the private key of the certificate authority for the new org.
export CA_PRIVATE_KEY=$(cd crypto-config/peerOrganizations/org2.example.com/ca && ls *_sk)

cd ..
# Bring up the containers
docker-compose -f org2-docker-compose.yaml up -d

echo "Sleep for 10s to allow fabric components to start"
sleep 10

docker ps -a