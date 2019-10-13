# Dynamic addition of an organization to an existing Hyperledger Fabric network

This repository aims to show how organizations can be added dynamically to existing Hyperledger Fabric networks, including giving the new organization the correct permissions to create a new channel by adding them to a Consortium definition.
It is an extension of the [Build Your First Network (BYFN)](https://hyperledger-fabric.readthedocs.io/en/release-1.4/build_network.html) example in the HLF documentation.

### Prerequisites

The list of prerequisites for running a HLF network can be found in the HLF documentation [here](https://hyperledger-fabric.readthedocs.io/en/release-1.4/prereqs.html) and [here](https://hyperledger-fabric.readthedocs.io/en/release-1.4/install.html). Note that HLF version 1.4 was used in this project.

## The base network

The base network consists of:

- an ordering service with a single node running solo consensus
- a single organization with a single peer
- a certificate authority for managing the crypto material for the organization
- a couchdb container to store the ledger for the organization
- a cli container for accessing the peer node
- a cli container for accessing the orderer node

### Generate the crypto material and create the channel configuration transactions

Before the network can be started, the cryptographic material for the organization needs to be generated.
This is done with the `cryptogen` command, which takes in the configuration file `crypto-config.yaml` and generates the certificates for each of the network components in the `crypto-config` folder.

The channel configuration transactions are created with the `configtxgen` command, which uses the `configtx.yaml` file specified in the `FABRIC_CFG_PATH`.
Configuration transactions are needed for the orderer channel, the channel for the organization, and the registering the anchor peer in the organization channel.
These transactions are stored in the `config` folder.

To generate all of these materials, run the generate script with:

```
./1-generate.sh
```

### Start the network

The containers with the Fabric components are brought up with the `docker-compose` command that uses the `docker-compose.yaml`.

The organization is then able to create the channel with the channel configuration block, and then join the channel using the `peer` command.
This has been automated in the start script:

```
./2-start.sh
```

### Stop the network

The network can be stopped using the stop script (`./7-stop.sh`) and all docker containers and images removed with the teardown script (`./8-teardown.sh`).

## Adding the new organization

The artifacts for creating a new organization, hard-coded as Org2, can be found in the `org2-artifacts` folder.
The script `3-create-new-org.sh` generates all the cryptographic material required for the new organization and starts the following containers for the Fabric components:

- a single peer container for the organization
- a certificate authority container for managing the cryptographic material for the organization
- a couchdb container to store the ledger for the organization
- a cli container for accessing the peer node

### Modify the existing channel1 configuration to allow Org2 to participate

To allow Org2 to join channel 1, the configuration transaction for the channel needs to be updated.
This process has been automated in the script `4-add-org-to-channel.sh`.

### Updating the ordering channel configuration

To update the ordering channel configuration with a new Consortium definition that includes Org2, run the script `5-add-org-to-consortium.sh`.

### Create a new channel as Org2

Now that Org2 is defined in a Consortium that was included in the ordering service channel configuration, it should now be able to create its own new channels.
To verify this is the case, run the script `6-create-new-channel.sh`.
