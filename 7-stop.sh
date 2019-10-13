#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# Set private key variables to avoid warning messages while bringing down the containers
export CA1_PRIVATE_KEY=""
export CA_PRIVATE_KEY=""

# Stop the docker containers
docker-compose -f docker-compose.yaml stop

# Navigate to the org2 artifacts directory and stop the org2 docker containers
docker-compose -f org2-docker-compose.yaml stop

