## Implement Dynamic Interest Rate Model

In this advanced stage, you'll implement a dynamic interest rate model that adjusts borrowing rates based on utilization, similar to Aave and Compound.

## Understanding Interest Rate Models

Dynamic interest rates provide:
- **Market Efficiency**: Rates adjust based on supply and demand
- **Protocol Stability**: Prevents liquidity crises during high demand
- **Incentive Alignment**: Encourages deposits during high utilization
- **Risk Management**: Prices risk appropriately

## Prerequisite Reading

- **Interest Rate Models**: Study Aave's [Interest Rate Strategy](https://docs.aave.com/rates/interest-rate-strategy)
- **Utilization Rate**: Understand how utilization affects rates
- **Mathematical Models**: Learn about piecewise linear functions

## Interest Rate Model

```
Utilization = Total Borrowed / Total Deposited

If Utilization < Kink:
    Base Rate + (Slope1 * Utilization)
Else:
    Base Rate + (Slope1 * Kink) + (Slope2 * (Utilization - Kink))
```

Where:
- **Base Rate**: Minimum interest rate (e.g., 0%)
- **Kink**: Utilization threshold (e.g., 80%)
- **Slope1**: Rate increase before kink (e.g., 4%)
- **Slope2**: Rate increase after kink (e.g., 75%)

## Implementation

### 1. Update Bank Structure

Add interest rate parameters:

```rust
#[account]
#[derive(InitSpace)]
pub struct Bank {
    // ... existing fields
    pub base_rate: u64,      // Base interest rate (basis points)
    pub kink: u64,           // Utilization threshold (basis points)
    pub slope1: u64,         // Rate slope before kink (basis points)
    pub slope2: u64,         // Rate slope after kink (basis points)
    pub current_rate: u64,   // Current interest rate (basis points)
}
```

### 2. Calculate Utilization

```rust
fn calculate_utilization(total_deposits: u64, total_borrowed: u64) -> u64 {
    if total_deposits == 0 {
        return 0;
    }
    (total_borrowed * 10_000) / total_deposits  // Return in basis points
}
```

### 3. Calculate Interest Rate

```rust
fn calculate_interest_rate(
    utilization: u64,
    base_rate: u64,
    kink: u64,
    slope1: u64,
    slope2: u64,
) -> u64 {
    if utilization < kink {
        base_rate + (slope1 * utilization / 10_000)
    } else {
        base_rate + (slope1 * kink / 10_000) + 
        (slope2 * (utilization - kink) / 10_000)
    }
}
```

### 4. Update Bank Rate

In deposit/borrow functions:

```rust
pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
    let bank = &mut ctx.accounts.bank;
    
    // Calculate utilization and update rate
    let utilization = calculate_utilization(bank.total_deposits, bank.total_borrowed);
    bank.current_rate = calculate_interest_rate(
        utilization,
        bank.base_rate,
        bank.kink,
        bank.slope1,
        bank.slope2,
    );
    
    // ... rest of deposit logic
}
```

### 5. Accrue Interest

```rust
fn accrue_interest(bank: &mut Bank, user: &mut User, clock: &Clock) -> Result<()> {
    let time_elapsed = clock.unix_timestamp - bank.last_updated;
    let interest_amount = (bank.total_borrowed * bank.current_rate as u64 * time_elapsed as u64) 
        / (10_000 * 365 * 24 * 60 * 60);
    
    bank.total_borrowed += interest_amount;
    user.borrowed_sol += interest_amount;
    
    bank.last_updated = clock.unix_timestamp;
    user.last_updated = clock.unix_timestamp;
    
    Ok(())
}
```

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| Low utilization | Base rate applied | Validates rate calculation |
| High utilization | Higher rate applied | Confirms kink logic |
| Rate updates | Rate changes with utilization | Verifies dynamic adjustment |
| Interest accrual | Correct interest calculated | Confirms time-based accrual |

## Notes

- Use basis points (1/100 of 1%) for precision
- Update rates before each deposit/borrow
- Accrue interest based on time elapsed
- Consider adding rate smoothing to prevent volatility
- Document rate parameters for transparency
