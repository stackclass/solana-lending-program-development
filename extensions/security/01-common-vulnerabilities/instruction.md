# Common Vulnerabilities

This stage covers common security vulnerabilities in lending protocols and
how to avoid them.

## 1. Reentrancy Attacks

Reentrancy occurs when an external call allows the attacker to re-enter the
original function before it completes, potentially draining funds.

**Vulnerable Pattern:**
```rust
pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    
    // External call BEFORE state update
    let cpi_ctx = CpiContext::new(...);
    token_interface::transfer(cpi_ctx, amount)?;  // External call!
    
    // State update happens AFTER external call
    user.deposited_amount -= amount;  // Can be reentered!
    
    Ok(())
}
```

**Secure Pattern:**
```rust
pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    
    // State update BEFORE external call
    user.deposited_amount -= amount;
    
    // External call happens AFTER state update
    let cpi_ctx = CpiContext::new(...);
    token_interface::transfer(cpi_ctx, amount)?;
    
    Ok(())
}
```

## 2. Integer Overflow/Underflow

Rust prevents overflow by default in debug mode but panics in release. Use
checked arithmetic:

**Vulnerable:**
```rust
user.borrowed_amount += amount;  // Could overflow
bank.total_deposits -= amount;   // Could underflow
```

**Secure:**
```rust
user.borrowed_amount = user.borrowed_amount.checked_add(amount)
    .ok_or(LendingError::Overflow)?;
bank.total_deposits = bank.total_deposits.checked_sub(amount)
    .ok_or(LendingError::Underflow)?;
```

## 3. Insufficient Validation

Always validate all inputs and state:

```rust
require!(amount > 0, LendingError::ZeroAmount);
require!(user.deposited_amount >= amount, LendingError::InsufficientFunds);
require!(bank.total_deposits >= amount, LendingError::InsufficientLiquidity);
```

## 4. Oracle Manipulation

Oracles can be manipulated if not properly validated:

**Secure Pattern:**
```rust
// Validate price is not too old
let staleness = Clock::get()?.unix_timestamp - price_update.publish_time;
require!(staleness <= MAX_PRICE_AGE, LendingError::StalePrice);

// Use multiple price feeds when possible
```

## 5. Flash Loan Attacks

Flash loans enable large-scale manipulation:

**Protection:**
- Use time-weighted average prices (TWAP)
- Implement sanity checks on large movements
- Use delayed liquidations

## Key Takeaways

Reentrancy is prevented by updating state before external calls. Use checked
arithmetic to prevent overflow/underflow. Validate all inputs and state. Oracle
prices must be validated for freshness and manipulation. Flash loan protection
requires additional safeguards.
