# Nexsar - Smart Contract

## Turks

> The **Turks** smart contract is designed to facilitate a voting system for `distributors`, `workers`, and options related to various posts. **Distributors create posts**, **workers vote on options within those posts**, and rewards are distributed accordingly. The contract handles the management of distributors, posts, options, and workers, ensuring a transparent, decentralized voting mechanism and fair distribution of rewards.<br>
> The `Posts` are generated via `DALLE` model present in **`Galadriel`** ecosystem.

## DalleNft

> **DalleNft** is a Solidity-based smart contract that integrates with the **teeML** oracle to generate and mint NFTs based on user-provided text prompts. The contract works in conjunction with an external oracle, which processes the input text to generate images and returns the corresponding metadata (token URI) for minting the NFT.
> The contract uses **OpenZeppelin's ERC721** standards, including **ERC721URIStorage** and **ERC721Enumerable**, to handle the storage of NFTs and their metadata.

## Features (Turks)

- **Distributor Management**: Initialize and manage distributors with posts and associated options.
- **Post Management**: Distributors can create posts, each containing multiple voting options. (Post will be generated via `DALLE` model)
- **Worker Management**: Workers can be registered and rewarded for participation in voting processes.
- **Voting System**: Workers vote on options within posts, and votes are tallied.
- **Reward Distribution**: Distributors can allocate rewards, and workers can withdraw their accumulated earnings.

## Features (Dalle)
- **NFT Minting**: Users can submit text prompts that are passed to an oracle. The oracle returns the generated image's metadata (token URI), which is used to mint the NFT.
- **Oracle Integration**: The contract communicates with an oracle (e.g., teeML) to handle the actual image generation from text prompts.
- **Customizable Prompts**: The owner of the contract can update the base prompt that is used in conjunction with the user's text input to generate the images.
- **Token Metadata Storage**: The contract stores the metadata of the generated NFTs, such as the token URI, which contains information about the image.
- **Event Logging**: Events are emitted for important actions like creating mint inputs, updating the oracle address, and modifying prompts.

---

## Deployed Contracts

| Contract     | Contract Address                           | Explorer Link                                                                                           |
| ------------ | ------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| Turks.sol    | 0x9800E70e6531c5ABFaa6df5f8F5152a18998C701 | [Sepolia Etherscan](https://sepolia.etherscan.io/address/0x9800E70e6531c5ABFaa6df5f8F5152a18998C701)    |
| DalleNft.sol | 0x5a76D8a2BAD252fe57fb5281029a46C65d96aF52 | [Galadriel Explorer](https://explorer.galadriel.com/address/0x5a76D8a2BAD252fe57fb5281029a46C65d96aF52) |

---

## Code Coverage

```
Test Summary:

╭------------+--------+--------+---------╮
| Test Suite | Passed | Failed | Skipped |
+========================================+
| TurksTest  |   41   |    0   |    0    |
╰------------+--------+--------+---------╯

| File          | % Lines          | % Statements     | % Branches     | % Funcs         |
| ------------- | ---------------- | ---------------- | -------------- | --------------- |
| src/Turks.sol | 79.65% (137/172) | 84.21% (160/190) | 24.39% (10/41) | 100.00% (25/25) |
| Total         | 79.65% (137/172) | 84.21% (160/190) | 24.39% (10/41) | 100.00% (25/25) |
```

## Table of Contents

- [Nexsar - Smart Contract](#nexsar---smart-contract)
  - [Turks](#turks)
  - [DalleNft](#dallenft)
  - [Features (Turks)](#features-turks)
  - [Features (Dalle)](#features-dalle)
  - [Deployed Contracts](#deployed-contracts)
  - [Code Coverage](#code-coverage)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
    - [Use Cases](#use-cases)
  - [Smart Contract Flow](#smart-contract-flow)
  - [Core Functionalities](#core-functionalities)
    - [Distributor Functions](#distributor-functions)
    - [Post and Option Functions](#post-and-option-functions)
    - [Worker Functions](#worker-functions)
    - [Voting Functions](#voting-functions)
  - [Getters](#getters)
  - [Setup and Deployment](#setup-and-deployment)
    - [Prerequisites](#prerequisites)
    - [Deploying the Contract](#deploying-the-contract)
  - [Usage](#usage)
    - [Build](#build)
    - [Test](#test)
    - [Gas Snapshots](#gas-snapshots)
    - [Help](#help)

---

## Overview

The **Turks** contract is built on Solidity `0.8.20` and provides decentralized functionality for managing posts, options, and voting within a secure, efficient, and transparent framework.

### Use Cases

- **Distributors**: Manage their posts and options. Each post contains multiple voting options, and distributors provide a budget for rewarding workers.
- **Workers**: Register themselves to participate in voting and can withdraw earned rewards from the contract.
- **Voting**: Workers vote on various options tied to a specific post.

---

## Smart Contract Flow

1. **Distributor Initialization**: Distributors can initialize themselves, creating their first post and options with a budget for worker rewards.
2. **Post and Option Management**: Distributors can add posts and associated voting options.
3. **Worker Registration**: Workers register themselves and can then participate in voting for different options within a post.
4. **Voting**: Workers cast votes on options, and votes are recorded in the contract.
5. **Reward Distribution**: Distributors can allocate rewards to workers, who can then withdraw their rewards.

---

## Core Functionalities

### Distributor Functions

- `initDistributor(bool listed, uint256 initialBudget, ...)`: Initializes a distributor with a post and options.
- `depositETH()`: Allows distributors to deposit additional funds to their account.
- `withdrawETH(uint256 amount)`: Allows distributors to withdraw ETH from their account.

### Post and Option Functions

- `AddPost(...)`: Distributors can add new posts with associated options.
- `updateDescription(string memory desc, string memory postId)`: Updates the description of a post.
- `updateVotes(uint64[] memory votes, string[] memory optionIds, ...)`: Updates the vote counts for options in a post.

### Worker Functions

- `initWorker()`: Registers a worker in the system.
- `withdrawRewards()`: Allows workers to withdraw their accumulated rewards.

### Voting Functions

- `updateVotingMapping(address[] memory workers, string[] memory postIds, ...)`: Updates voting mappings for workers and posts.
  
---

## Getters

The contract provides several getter functions to retrieve contract data:

- `getBudget(address distributor)`: Returns the current budget of a distributor.
- `getAllPosts(address distributorId)`: Returns all posts created by a distributor.
- `getAllOptions(string memory postId)`: Returns all options associated with a post.
- `getTotalVotesOnPost(string memory postId)`: Returns the total votes for a specific post.

---

## Setup and Deployment

### Prerequisites

- Solidity ^0.8.20
- A working knowledge of Ethereum-based smart contracts
- Ethereum wallet (e.g., MetaMask) for testing

### Deploying the Contract

1. **Install Dependencies**: Set up your development environment with Hardhat, Truffle, or Remix.
2. **Compile the Contract**: Ensure the contract compiles without errors.
3. **Deploy the Contract**: Use a suitable network (e.g., Ethereum, Polygon) for deployment.

---

This README outlines the Turks smart contract's functionalities, providing a guide for developers to interact with the contract efficiently and securely.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Gas Snapshots

```shell
$ forge snapshot
```

<details>
<summary>
Gas Snapshot
</summary>

| methods                                                     | Gas            |
| ----------------------------------------------------------- | -------------- |
| TurksTest:testAddPost()                                     | (gas: 1963194) |
| TurksTest:testComplexVotingScenario()                       | (gas: 1286375) |
| TurksTest:testDepositETH()                                  | (gas: 1050608) |
| TurksTest:testFailGetAllOptionsNonExistentPost()            | (gas: 370488)  |
| TurksTest:testFailGetAllPostsNonExistentDistributor()       | (gas: 370555)  |
| TurksTest:testFailGetFrequencyNonExistentDistributor()      | (gas: 370512)  |
| TurksTest:testFailGetFrequencyUnauthorized()                | (gas: 370511)  |
| TurksTest:testFailGetParticularPostNonExistent()            | (gas: 370532)  |
| TurksTest:testFailGetTotalVotesOnPostNonExistent()          | (gas: 370490)  |
| TurksTest:testFailInitDistributorAlreadyExists()            | (gas: 370510)  |
| TurksTest:testFailInitDistributorInsufficientBalance()      | (gas: 30706)   |
| TurksTest:testFailInitDistributorNotListed()                | (gas: 370554)  |
| TurksTest:testFailInitWorkerTwice()                         | (gas: 370489)  |
| TurksTest:testFailUpdateDescriptionNonExistentPost()        | (gas: 370534)  |
| TurksTest:testFailUpdateRewardsNonExistentWorker()          | (gas: 15549)   |
| TurksTest:testFailUpdateVotesNonExistentOption()            | (gas: 370532)  |
| TurksTest:testFailUpdateVotingMappingMismatchedArrays()     | (gas: 19735)   |
| TurksTest:testFailWithdrawETHInsufficientBalance()          | (gas: 1041798) |
| TurksTest:testFailWithdrawETHUnauthorized()                 | (gas: 1045796) |
| TurksTest:testFailWithdrawRewardsNoRewards()                | (gas: 38328)   |
| TurksTest:testGetAllOptions()                               | (gas: 1078301) |
| TurksTest:testGetAllPosts()                                 | (gas: 2003008) |
| TurksTest:testGetFrequency()                                | (gas: 1042531) |
| TurksTest:testGetParticularPost()                           | (gas: 1058826) |
| TurksTest:testGetTotalVotesOnPost()                         | (gas: 1175239) |
| TurksTest:testInitDistributor()                             | (gas: 1039034) |
| TurksTest:testInitWorker()                                  | (gas: 39011)   |
| TurksTest:testMultipleDistributors()                        | (gas: 2109411) |
| TurksTest:testMultipleDistributorsCannotHaveSameOptionIds() | (gas: 1285853) |
| TurksTest:testMultipleDistributorsCannotHaveSamePostId()    | (gas: 1061297) |
| TurksTest:testNonDistributorCannotCreatePost()              | (gas: 26240)   |
| TurksTest:testPostLifecycle()                               | (gas: 2085373) |
| TurksTest:testRewardDistributionAndWithdrawal()             | (gas: 1143791) |
| TurksTest:testUnauthorizedAccess()                          | (gas: 2146021) |
| TurksTest:testUpdateBudget()                                | (gas: 1052596) |
| TurksTest:testUpdateDescription()                           | (gas: 1063929) |
| TurksTest:testUpdateRewards()                               | (gas: 119123)  |
| TurksTest:testUpdateVotes()                                 | (gas: 1155551) |
| TurksTest:testUpdateVotingMapping()                         | (gas: 77028)   |
| TurksTest:testWithdrawETH()                                 | (gas: 1056867) |
| TurksTest:testWithdrawRewards()                             | (gas: 58978)   |

</details>

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
