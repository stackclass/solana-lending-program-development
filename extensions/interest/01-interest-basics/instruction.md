# Interest Basics

This stage introduces interest concepts that are fundamental to lending
protocol economics.

## What is Lending Interest

Lending protocols earn interest from borrowers and pay interest to depositors.
The interest rate determines:

- **Borrow Rate**: What borrowers pay to use funds
- **Supply Rate**: What depositors earn for supplying funds
- **Protocol Revenue**: Difference between rates

## Interest Rate Components

**Base Rate**: Fixed component ensuring protocol sustainability
**Utilization Rate**: Variable component based on how much is borrowed

```
Utilization = Total Borrows / Total Deposits
```

## Simple Interest Formula

For a simple interest model:

```
Interest = Principal × Rate × Time
```

Example: 1000 SOL at 10% APR for 1 year = 100 SOL interest

## Compound Interest Formula

For compound interest (more realistic):

```
A = P × (1 + r/n)^(n×t)
```

Where:
- A = Final amount
- P = Principal
- r = Annual interest rate
- n = Number of compounding periods per year
- t = Time in years

## Interest in Your Bank

Store interest-related parameters:

```rust
#[account]
#[derive(InitSpace)]
pub struct Bank {
    pub authority: Pubkey,
    pub mint_address: Pubkey,
    pub total_deposits: u64,
    pub total_deposit_shares: u64,
    pub total_borrows: u64,
    pub total_borrow_shares: u64,
    pub interest_rate: u64,      // Annual rate (e.g., 1000 = 10%)
    pub last_updated: i64,
    pub bump: u8,
}

// Interest rate is typically stored as basis points (1/100 of 1%)
pub const BASIS_POINTS: u64 = 10000;
```

## Key Takeaways

Lending protocols earn interest from borrowers and pay depositors. Utilization
rate affects interest rates. Simple interest is easier to calculate. Compound
interest is more realistic. Interest rates are typically stored as basis points.
