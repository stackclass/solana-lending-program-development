# Accrued Interest Calculation

This stage teaches you how to calculate and accrue interest over time in
your lending protocol.

## Understanding Accrued Interest

Interest accrues continuously as time passes. When users interact with the
protocol (deposit, withdraw, borrow, repay), we calculate the accrued interest
and update balances.

## Accrued Interest Formula

```
Accrued Interest = Principal × Rate × Time Elapsed
```

In code:

```rust
fn calculate_accrued_interest(
    principal: u64,
    rate: u64,
    last_update: i64,
) -> Result<u64> {
    let current_time = Clock::get()?.unix_timestamp;
    let time_elapsed = current_time - last_update;
    
    // Rate is annual basis points, convert to per-second
    let seconds_per_year = 365.25 * 24 * 60 * 60;
    let rate_per_second = rate as f64 / BASIS_POINTS as f64 / seconds_per_year;
    
    let interest = (principal as f64 * rate_per_second * time_elapsed as f64) as u64;
    
    Ok(interest)
}
```

## Updating Interest on User Interactions

Call interest calculation before any state change:

```rust
pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    // Accrue interest before deposit
    let accrued_interest = calculate_accrued_interest(
        user.borrowed_amount,
        bank.interest_rate,
        user.last_updated,
    )?;
    
    user.borrowed_amount += accrued_interest;
    user.last_updated = Clock::get()?.unix_timestamp;
    
    // ... rest of deposit logic
    Ok(())
}
```

## Per-Block Interest Calculation

For more precise calculations, use slot-based time:

```rust
fn calculate_accrued_interest_slots(
    principal: u64,
    rate: u64,
    last_slot: u64,
) -> Result<u64> {
    let current_slot = Clock::get()?.slot;
    let slots_elapsed = current_slot - last_slot;
    let slots_per_year = 63072000;  // ~2 slots per second
    
    let rate_per_slot = rate as f64 / BASIS_POINTS as f64 / slots_per_year;
    let interest = (principal as f64 * rate_per_slot * slots_elapsed as f64) as u64;
    
    Ok(interest)
}
```

## Key Takeaways

Interest accrues continuously over time. Calculate accrued interest on every
user interaction. Use timestamps or slots for time measurement. Update
last_updated after each calculation. Accrued interest increases debt balances.
