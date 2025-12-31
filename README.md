# Solana Lending Program Development

Build a decentralized lending protocol on the Solana blockchain using the Anchor framework.

## Overview

This challenge guides you through creating a secure lending smart contract that enables users to:
- Deposit collateral
- Borrow assets
- Repay loans
- Face liquidation when undercollateralized

## What You'll Learn

- **Solana's Account Model**: Understanding how accounts store state and data
- **Program-Derived Addresses (PDAs)**: Deriving deterministic addresses for program accounts
- **Cross-Program Invocations (CPI)**: Interacting with SPL Token programs
- **Oracle Integration**: Fetching real-time price feeds for asset valuation
- **Interest Rate Models**: Calculating and applying interest on loans
- **Health Factors**: Monitoring collateralization ratios
- **Liquidation Protocols**: Handling undercollateralized positions

## Challenge Structure

### Stages
1. **Environment Setup** - Configure your development environment
2. **Rust Basics** - Essential Rust programming concepts
3. **Solana Model** - Understanding Solana's architecture
4. **Anchor Framework** - Getting started with Anchor
5. **SPL Token Basics** - Working with tokens on Solana
6. **Basic Deposit** - Implementing deposit functionality
7. **Basic Withdraw** - Implementing withdrawal functionality

### Extensions
- **Account Structure** - Bank, user accounts, and account space management
- **Interest** - Interest calculation, accrual, and rate models
- **Lending Core** - Borrow, repay, and LTV calculations
- **Liquidation** - Health factors, triggers, and liquidation process
- **Oracle** - Price feed integration and fetching
- **PDA** - PDA concepts, derivation, and bump seeds
- **Security** - Vulnerabilities, reentrancy protection, and validation
- **Treasury** - Treasury creation and security

## Setup

This challenge is developed using the StackClass Course SDK. Refer to the StackClass documentation for information on:
- Contributing language support
- Submitting solutions

## Requirements

- Rust 1.87+
- Cargo 1.87+
- Anchor framework
- Solana CLI

## Getting Started

The main source file you'll be working with is:
```
programs/lending-program/src/lib.rs
```

## License

See LICENSE file for details.