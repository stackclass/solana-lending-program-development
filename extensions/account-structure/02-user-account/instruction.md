# User Account Structure

This stage teaches you how to design and implement the User account structure
that tracks individual user positions in your lending protocol.

## What the User Account Stores

The User account represents an individual user's position in the lending
protocol. For a simple single-asset protocol, it stores:

- User's deposited amount and shares
- User's borrowed amount and shares
- Timestamps for interest calculation
- Reference to supported tokens

## Basic User Structure

```rust
#[account]
#[derive(InitSpace)]
pub struct User {
    pub owner: Pubkey,
    pub deposited_amount: u64,
    pub deposited_shares: u64,
    pub borrowed_amount: u64,
    pub borrowed_shares: u64,
    pub last_updated: i64,
    pub bump: u8,
}
```

## Field Explanations

- **owner**: The user's wallet address
- **deposited_amount**: Current deposited tokens (with interest)
- **deposited_shares**: User's ownership of bank deposits
- **borrowed_amount**: Current borrowed tokens (with interest)
- **borrowed_shares**: User's share of bank borrows
- **last_updated**: Timestamp for interest calculation
- **bump**: PDA bump seed for account derivation

## Multi-Asset User Structure

For a protocol supporting multiple assets, extend the user account:

```rust
#[account]
#[derive(InitSpace)]
pub struct User {
    pub owner: Pubkey,
    
    // SOL position
    pub sol_deposited_amount: u64,
    pub sol_deposited_shares: u64,
    pub sol_borrowed_amount: u64,
    pub sol_borrowed_shares: u64,
    
    // USDC position
    pub usdc_deposited_amount: u64,
    pub usdc_deposited_shares: u64,
    pub usdc_borrowed_amount: u64,
    pub usdc_borrowed_shares: u64,
    
    // Cross-asset health tracking
    pub health_factor: u64,
    
    pub last_updated: i64,
    pub bump: u8,
}
```

## Converting Between Amounts and Shares

When users interact with the protocol, we convert between amounts and shares:

```rust
// Depositing: amount -> shares
fn get_deposit_shares(amount: u64, bank: &Bank) -> u64 {
    if bank.total_deposits == 0 {
        amount
    } else {
        (amount as u128 * bank.deposit_shares as u128 
            / bank.total_deposits as u128) as u64
    }
}

// Withdrawing: shares -> amount
fn get_deposit_amount(shares: u64, bank: &Bank) -> u64 {
    if bank.deposit_shares == 0 {
        shares
    } else {
        (shares as u128 * bank.total_deposits as u128 
            / bank.deposit_shares as u128) as u64
    }
}
```

## Health Factor Tracking

For liquidation, users need to track their health factor:

```rust
impl User {
    pub fn calculate_health_factor(&self, banks: &[(Bank, Price)]) -> u64 {
        let collateral_value = 
            self.sol_deposited_amount * banks[0].price +
            self.usdc_deposited_amount * banks[1].price;
        
        let borrowed_value = 
            self.sol_borrowed_amount * banks[0].price +
            self.usdc_borrowed_amount * banks[1].price;
        
        if borrowed_value == 0 {
            return u64::MAX;
        }
        
        (collateral_value * LIQUIDATION_THRESHOLD) / borrowed_value
    }
}
```

## Key Takeaways

User accounts track individual positions across deposits and borrows. Share-based
accounting enables precise interest calculation per user. Multi-asset support
requires extending the user structure. Health factor calculation enables
liquidation triggers.
