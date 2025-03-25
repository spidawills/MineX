# MineX: Blockchain Mining Rewards System

## Overview
MineX is a blockchain-based mining rewards system designed to incentivize miners through progressive challenges and structured rewards. The platform leverages smart contracts to ensure transparency, security, and fairness in mining competition.

## Features
- **Mining Challenges**: Miners solve progressively difficult challenges for rewards.
- **Secure Rewards System**: Uses SHA256 hashes to verify solutions and allocate rewards.
- **Progress Tracking**: Miners' progress is recorded to track achievements and top performers.
- **Staking Mechanism**: Requires an entry stake to prevent spam and ensure fair participation.
- **Leaderboard**: Maintains a list of top miners for each challenge.
- **Transparent Smart Contract**: Fully decentralized and automated reward distribution.

## Smart Contract Details

### Constants
- **Error Codes**: Defined error messages for validation.
- **Admin Control**: Only the platform administrator can initialize and manage challenges.
- **Platform Activation**: Mining only works when the platform is active.
- **Max Reward Limits**: Ensures fair distribution of mining incentives.

### Data Variables
- **Platform State**: Stores admin details, activity status, and reward pool.
- **Mining Challenges**: Defines difficulty clues, hash targets, unlock conditions, and rewards.
- **Miner Progress**: Tracks miners' challenges and rewards.
- **Challenge Solutions**: Maintains mining attempts and solved challenges.
- **Leaderboard**: Keeps a list of top miners per challenge.

## Functions

### Platform Management
- `initialize-mining-platform`: Activates the mining platform.
- `add-mining-challenge`: Adds a new mining challenge with a difficulty clue and a target hash.

### Miner Operations
- `register-miner`: Registers a miner by requiring an entry stake.
- `submit-mining-solution`: Allows miners to submit their solutions for verification.

### Read-Only Functions
- `get-current-mining-difficulty`: Returns the mining challenge difficulty clue.
- `get-miner-status`: Retrieves the progress of a miner.
- `get-challenge-top-miners`: Returns the leaderboard for a specific challenge.
- `get-platform-stats`: Provides key metrics about the platform.

## How It Works
1. **Platform Setup**: Admin initializes the platform and adds challenges.
2. **Miner Registration**: Miners register by staking a predefined amount.
3. **Mining Challenges**: Miners solve cryptographic puzzles and submit solutions.
4. **Verification**: The smart contract verifies solutions against pre-defined hash targets.
5. **Reward Distribution**: Successful miners receive rewards, and top miners are recorded.
6. **Progress Tracking**: Miners can track their status and compete for leaderboard positions.

## Requirements
- **Blockchain**: The contract is designed for Clarity-based blockchains (e.g., Stacks).
- **STX Tokens**: Used for staking and reward distribution.
- **SHA256 Hashing**: Utilized for solution validation.

## Installation & Deployment
1. Deploy the contract using Clarity tools.
2. Fund the contract with STX for reward distribution.
3. Register miners and initiate mining challenges.

## Future Enhancements
- Dynamic difficulty adjustment based on mining participation.
- Integration with external data sources for challenge verification.
- Enhanced leaderboard system with ranking incentives.
- Support for multi-token mining rewards.
