# Fitness Tracker Abandonment Timeline

Chronicles the lifecycle from 'closing rings daily' to 'what's my password again?'

## Overview

The Fitness Tracker Abandonment Timeline is a decentralized smart contract system built on the Stacks blockchain using Clarity. This project humorously tracks the inevitable decline of fitness motivation through blockchain-verified metrics, creating an immutable record of our collective journey from enthusiasm to complacency.

## Purpose

This system provides transparent, tamper-proof tracking of fitness goals and gym memberships, allowing users to:

- Set and dynamically adjust step goals based on actual activity patterns
- Monitor gym membership usage and calculate true cost-per-visit metrics
- Maintain honest accountability of fitness commitment (or lack thereof)
- Create verifiable records of fitness journey milestones

## Smart Contracts

### 1. Step Goal Negotiation Engine

**Contract:** `step-goal-negotiation-engine.clar`

This contract manages daily step goals with adaptive algorithms that respond to user behavior patterns. It automatically adjusts targets based on historical performance, making fitness goals more "achievable" over time.

**Key Features:**
- Dynamic step goal adjustment based on completion rates
- Historical tracking of daily achievements
- Reward mechanisms for consistency (or participation)
- Progressive goal reduction for sustained non-achievement

### 2. Gym Membership Ghosting Metrics

**Contract:** `gym-membership-ghosting-metrics.clar`

This contract tracks gym membership utilization and calculates the real cost-per-visit, providing brutally honest metrics about your gym investment ROI.

**Key Features:**
- Membership registration and renewal tracking
- Visit check-in system
- Cost-per-visit calculation
- Abandonment rate tracking
- Monthly utilization statistics

## Technical Stack

- **Blockchain:** Stacks
- **Smart Contract Language:** Clarity
- **Development Framework:** Clarinet
- **Testing:** Vitest

## Project Structure

```
Fitness-Tracker-Abandonment-Timeline/
├── contracts/
│   ├── step-goal-negotiation-engine.clar
│   └── gym-membership-ghosting-metrics.clar
├── tests/
│   ├── step-goal-negotiation-engine.test.ts
│   └── gym-membership-ghosting-metrics.test.ts
├── settings/
│   ├── Devnet.toml
│   ├── Testnet.toml
│   └── Mainnet.toml
├── Clarinet.toml
├── package.json
└── README.md
```

## Getting Started

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) installed
- Node.js and npm
- Stacks wallet for contract interactions

### Installation

1. Clone the repository:
```bash
git clone https://github.com/egisaba29-glitch/Fitness-Tracker-Abandonment-Timeline.git
cd Fitness-Tracker-Abandonment-Timeline
```

2. Install dependencies:
```bash
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## Usage

### Step Goal Negotiation Engine

```clarity
;; Set initial step goal
(contract-call? .step-goal-negotiation-engine set-goal u10000)

;; Record daily steps
(contract-call? .step-goal-negotiation-engine record-steps u8500)

;; Check current goal
(contract-call? .step-goal-negotiation-engine get-current-goal)
```

### Gym Membership Ghosting Metrics

```clarity
;; Register membership
(contract-call? .gym-membership-ghosting-metrics register-membership u100)

;; Check in to gym
(contract-call? .gym-membership-ghosting-metrics check-in)

;; Get cost per visit
(contract-call? .gym-membership-ghosting-metrics get-cost-per-visit)
```

## Testing

Run the test suite with:

```bash
clarinet test
```

Or with npm:

```bash
npm test
```

## Development

### Creating New Contracts

```bash
clarinet contract new <contract-name>
```

### Checking Contract Syntax

```bash
clarinet check
```

### Console Testing

```bash
clarinet console
```

## Deployment

Contracts can be deployed to Devnet, Testnet, or Mainnet using Clarinet's deployment tools. Configuration files for each network are located in the `settings/` directory.

```bash
clarinet deploy --testnet
```

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs, feature requests, or documentation improvements.

## License

MIT License

## Disclaimer

This project is intended for educational and entertainment purposes. While it uses real blockchain technology, the humor-driven use case is meant to make learning Clarity smart contracts more engaging. Always consult with fitness and financial professionals for actual health and investment decisions.

## Contact

- GitHub: [@egisaba29-glitch](https://github.com/egisaba29-glitch)
- Email: egisaba29@gmail.com

---

*Remember: The only bad workout is the one that didn't happen... and that we have permanently recorded on the blockchain.*
