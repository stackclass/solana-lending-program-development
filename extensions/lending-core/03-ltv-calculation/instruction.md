# LTV Calculation

This stage teaches you how to calculate and enforce Loan-to-Value (LTV)
ratios, which are fundamental risk parameters in lending protocols.

## What is LTV

Loan-to-Value (LTV) ratio represents the percentage of collateral value that
can be borrowed. For example, an LTV of 80% means a user can borrow up to 80%
of their deposited collateral's value.

LTV is a critical risk parameter that determines:
- Maximum borrow capacity
- Liquidation threshold
- Protocol solvency

## LTV in Your Bank Account

```rust
#[account]
#[derive(InitSpace)]
pub struct Bank {
    pub authority: Pubkey,
    pub mint_address: Pubkey,
    pub total_deposits: u64,
    pub total_borrows: u64,
    pub interest_rate: u64,
    pub max_ltv: u64,              // e.g., 80 for 80%
    pub liquidation_threshold: u64, // e.g., 85 for 85%
    pub last_updated: i64,
    pub bump: u8,
}
```

## Calculating Maximum Borrow

```rust
fn calculate_max_borrow(user: &User, bank: &Bank) -> u64 {
    // User can borrow up to max_ltv % of their deposit
    (user.deposited_amount * bank.max_ltv) / 100
}

fn calculate_available_to_borrow(user: &User, bank: &Bank) -> u64 {
    let max_borrow = calculate_max_borrow(user, bank);
    if user.borrowed_amount >= max_borrow {
        0
    } else {
        max_borrow - user.borrowed_amount
    }
}
```

## Enforcing LTV on Borrow

```rust
pub fn borrow(ctx: Context<Borrow>, amount: u64) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    let max_borrow = (user.deposited_amount * bank.max_ltv) / 100;
    let new_total_borrow = user.borrowed_amount + amount;
    
    require!(
        new_total_borrow <= max_borrow,
        LendingError::BorrowLimitExceeded
    );
    
    // ... rest of borrow logic
    Ok(())
}
```

## LTV vs Liquidation Threshold

While LTV determines borrowing limits, the liquidation threshold determines
when a position becomes liquidatable:

```rust
// LTV: 80% - max borrow limit
// Liquidation threshold: 85% - liquidation trigger
```

A position might be healthy (below LTV) but approaching liquidation (above
liquidation threshold in terms of health factor).

## Key Takeaways

LTV determines maximum borrow capacity. LTV is stored as a percentage in the
bank. Calculate available borrow as (deposit * max_ltv) - current_borrow.
LTV and liquidation threshold work together for risk management.
