# Bank Account Structure

This stage teaches you how to design and implement the Bank account structure
that stores the core lending protocol state for each token market.

## What the Bank Account Stores

The Bank account represents a lending market for a specific token. It stores
global state including:

- Total deposits and borrows
- Interest rate configuration
- Risk parameters (LTV, liquidation threshold)
- Mint address for the supported token
- Administrative authority

## Basic Bank Structure

```rust
#[account]
#[derive(InitSpace)]
pub struct Bank {
    pub authority: Pubkey,
    pub mint_address: Pubkey,
    pub total_deposits: u64,
    pub total_borrows: u64,
    pub borrow_shares: u64,
    pub deposit_shares: u64,
    pub interest_rate: u64,
    pub liquidation_threshold: u64,
    pub max_ltv: u64,
    pub last_updated: i64,
    pub bump: u8,
}
```

## Field Explanations

- **authority**: Admin address that can update protocol parameters
- **mint_address**: The token this bank accepts
- **total_deposits**: Total tokens deposited (accounting for interest)
- **total_borrows**: Total tokens borrowed (accounting for interest)
- **deposit_shares**: Represents user shares of deposits (for accounting)
- **borrow_shares**: Represents user shares of borrows (for accounting)
- **interest_rate**: Annual interest rate (scaled)
- **liquidation_threshold**: Health factor threshold for liquidation
- **max_ltv**: Maximum loan-to-value ratio for borrowing
- **last_updated**: Timestamp for interest calculation
- **bump**: PDA bump seed for treasury signing

## Why Share-Based Accounting

Using shares instead of direct amounts provides several benefits:

1. **Interest Distribution**: When interest accrues, shares remain constant
   while amounts increase
2. **Efficiency**: Users can calculate their share of protocol earnings
3. **Precision**: Shares maintain precision even with fractional amounts

```rust
// Calculate user's deposit amount from shares
let user_amount = (user.deposit_shares * bank.total_deposits) 
    / bank.deposit_shares;

// Calculate shares to mint for a new deposit
let new_shares = (amount * bank.deposit_shares) / bank.total_deposits;
```

## Initialization with InitSpace

The `#[derive(InitSpace)]` attribute calculates the required account space:

```rust
#[account]
#[derive(InitSpace)]
pub struct Bank {
    #[anchor(skip)]
    pub discriminator: [u8; 8],
    pub authority: Pubkey,           // 32 bytes
    pub mint_address: Pubkey,        // 32 bytes
    pub total_deposits: u64,         // 8 bytes
    pub total_borrows: u64,          // 8 bytes
    pub borrow_shares: u64,          // 8 bytes
    pub deposit_shares: u64,         // 8 bytes
    pub interest_rate: u64,          // 8 bytes
    pub liquidation_threshold: u64,  // 8 bytes
    pub max_ltv: u64,                // 8 bytes
    pub last_updated: i64,           // 8 bytes
    pub bump: u8,                    // 1 byte
}
```

## Practical Exercise

Design a Bank structure for a multi-asset lending protocol. Consider how
different risk parameters might apply to different assets.

## Key Takeaways

Bank accounts store global protocol state for each token market. Share-based
accounting enables precise interest distribution. Risk parameters control
borrowing limits. InitSpace simplifies account size calculation.
