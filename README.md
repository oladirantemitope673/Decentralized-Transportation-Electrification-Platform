# Decentralized Transportation Electrification Platform

A comprehensive blockchain-based platform for managing electric vehicle infrastructure, battery lifecycle, fleet transitions, and grid optimization.

## Overview

This platform consists of five interconnected smart contracts that work together to create a decentralized ecosystem for transportation electrification:

### Core Contracts

1. **EV Charging Network Contract** (`ev-charging-network.clar`)
    - Coordinates charging station placement and deployment
    - Manages load balancing across charging infrastructure
    - Tracks station utilization and performance metrics

2. **Battery Recycling Coordination Contract** (`battery-recycling.clar`)
    - Manages end-of-life battery processing workflows
    - Coordinates material recovery and recycling incentives
    - Tracks battery lifecycle from deployment to recycling

3. **Fleet Electrification Planning Contract** (`fleet-electrification.clar`)
    - Assists organizations in transitioning vehicle fleets to electric
    - Provides planning tools and milestone tracking
    - Manages fleet electrification incentives and compliance

4. **Grid Impact Management Contract** (`grid-impact-management.clar`)
    - Balances EV charging demand with electrical grid capacity
    - Implements smart charging schedules and load distribution
    - Monitors grid stability and charging coordination

5. **Charging Cost Optimization Contract** (`charging-cost-optimization.clar`)
    - Provides dynamic pricing for EV charging based on real-time demand
    - Implements time-of-use pricing and demand response programs
    - Optimizes charging costs for both operators and consumers

## Key Features

- **Decentralized Infrastructure Management**: No single point of failure
- **Dynamic Pricing**: Real-time cost optimization based on supply and demand
- **Grid Integration**: Smart charging that considers grid capacity and stability
- **Lifecycle Management**: Complete battery tracking from deployment to recycling
- **Fleet Transition Support**: Tools and incentives for organizational electrification
- **Load Balancing**: Intelligent distribution of charging demand across infrastructure

## Data Structures

### Charging Station
- Station ID, location coordinates, capacity
- Current load, availability status
- Operator information and pricing

### Battery Record
- Battery ID, type, capacity, manufacturing date
- Current status, location, health metrics
- Recycling status and material recovery data

### Fleet Profile
- Organization ID, fleet size, vehicle types
- Electrification progress, milestones
- Incentive eligibility and compliance status

### Grid Node
- Node ID, capacity, current load
- Connected charging stations
- Load balancing parameters

### Pricing Model
- Base rates, demand multipliers
- Time-of-use schedules
- Dynamic adjustment parameters

## Installation

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Run `npm test` to execute the test suite

## Testing

The platform includes comprehensive tests using Vitest:

\`\`\`bash
npm install
npm test
\`\`\`

## Deployment

Deploy contracts using Clarinet:

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Register a Charging Station
\`\`\`clarity
(contract-call? .ev-charging-network register-station
u1 u100 u50 "Station Alpha" tx-sender)
\`\`\`

### Submit Battery for Recycling
\`\`\`clarity
(contract-call? .battery-recycling submit-battery-for-recycling
u1 u85 "Tesla Model S")
\`\`\`

### Create Fleet Electrification Plan
\`\`\`clarity
(contract-call? .fleet-electrification create-fleet-plan
u50 u10 "Corporate Fleet A")
\`\`\`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details
