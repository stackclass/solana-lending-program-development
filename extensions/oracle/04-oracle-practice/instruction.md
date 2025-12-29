# Oracle Integration Practice

This stage provides practice exercises for implementing oracle-based lending
operations in your protocol.

## Exercise 1: Health Factor Calculation with Oracle

Implement a health factor calculation using oracle prices:

```rust
pub fn calculate_health_factor(
    user: &User,
    banks: &[(&Bank, &PriceUpdateV2)],
) -> Result<u64> {
    let mut total_collateral_usd: u128 = 0;
    let mut total_debt_usd: u128 = 0;
    
    // Calculate SOL collateral value
    let sol_feed_id = get_feed_id_from_hex(SOL_USD_FEED_ID)?;
    let sol_price = banks[0].1.get_price_no_older_than(
        &Clock::get()?,
        MAXIMUM_AGE,
        &sol_feed_id,
    )?;
    
    let sol_value = (user.sol_deposited_amount as u128 
        * sol_price.price as u128)
        / 10u128.pow((sol_price.exponent.abs() as u32));
    
    total_collateral_usd += sol_value;
    
    // Calculate debt value
    let debt_value = (user.sol_borrowed_amount as u128
        * sol_price.price as u128)
        / 10u128.pow((sol_price.exponent.abs() as u32));
    
    total_debt_usd += debt_value;
    
    // Health factor = (collateral * threshold) / debt
    if total_debt_usd == 0 {
        return Ok(u64::MAX);
    }
    
    let health_factor = (total_collateral_usd * banks[0].0.liquidation_threshold as u128
        / total_debt_usd) as u64;
    
    Ok(health_factor)
}
```

## Exercise 2: Oracle-Based Borrow Validation

Implement borrow validation with oracle prices:

```rust
pub fn borrow(ctx: Context<Borrow>, amount: u64) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    let price_update = &ctx.accounts.price_update;
    
    // Get price
    let feed_id = get_feed_id_from_hex(SOL_USD_FEED_ID)?;
    let price = price_update.get_price_no_older_than(
        &Clock::get()?,
        MAXIMUM_AGE,
        &feed_id,
    )?;
    
    // Calculate current collateral value in USD
    let collateral_value = (user.deposited_amount as u128
        * price.price as u128)
        / 10u128.pow((price.exponent.abs() as u32));
    
    // Calculate max borrow in USD
    let max_borrow = collateral_value * bank.max_ltv as u128 / 100;
    let current_borrow_value = (user.borrowed_amount as u128
        * price.price as u128)
        / 10u128.pow((price.exponent.abs() as u32));
    
    // Check limit
    require!(
        current_borrow_value + amount as u128 <= max_borrow,
        LendingError::BorrowLimitExceeded
    );
    
    // ... rest of borrow logic
    Ok(())
}
```

## Exercise 3: Oracle-Based Liquidate Check

Implement liquidation check using oracle prices:

```rust
pub fn liquidate(ctx: Context<Liquidate>) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    let bank = &ctx.accounts.bank;
    let price_update = &ctx.accounts.price_update;
    
    // Calculate health factor
    let health_factor = calculate_health_factor(user, &[(bank, price_update)])?;
    
    require!(
        health_factor < bank.liquidation_threshold,
        LendingError::HealthyPosition
    );
    
    // ... liquidation logic
    Ok(())
}
```

## Requirements

1. Use Pyth price feeds for all valuations
2. Handle price precision correctly
3. Validate price freshness
4. Calculate health factor for liquidation
5. Enforce LTV with oracle prices

## Key Takeaways

Oracle integration enables real-time collateral valuation. Health factor
calculation requires multiple price feeds. Borrow limits use oracle prices.
Liquidation triggers depend on accurate pricing. Precision handling is critical.
