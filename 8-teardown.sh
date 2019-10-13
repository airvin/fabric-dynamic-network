#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# Set private key variables to avoid warning messages while bringing down the containers
export CA1_PRIVATE_KEY=""
export CA_PRIVATE_KEY=""

# Shut down the docker containers
docker-compose -f docker-compose.yaml -f org2-docker-compose.yaml kill && docker-compose -f docker-compose.yaml -f org2-docker-compose.yaml down

# Remove the local state
rm -f ~/.hfc-key-store/*

# Remove the crypto material and config transactions
rm -rf crypto-config config
rm -rf org2-artifacts/crypto-config org2-artifacts/config

# Remove docker images
docker rm $(docker ps -aq)
docker rmi $(docker images dev-* -q)