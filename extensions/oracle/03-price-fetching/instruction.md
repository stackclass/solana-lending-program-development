# Price Fetching and Usage

This stage teaches you how to fetch and use prices in your lending protocol
instructions for collateral valuation and health factor calculations.

## Setting Up Price Constants

Define price feed IDs as constants:

```rust
use anchor_lang::prelude::*;

pub const SOL_USD_FEED_ID: &str = 
    "0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8ed0c6c7bc0f4cfac8c280b56d";
pub const USDC_USD_FEED_ID: &str = 
    "0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a";
pub const MAXIMUM_AGE: u64 = 100;  // Max 100 seconds old
```

## Fetching Prices in Instructions

```rust
use pyth_solana_receiver_sdk::price_update::{get_feed_id_from_hex, PriceUpdateV2};

pub fn borrow_with_price_check(
    ctx: Context<Borrow>,
    amount: u64
) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    let price_update = &ctx.accounts.price_update;
    
    // Get SOL price
    let sol_feed_id = get_feed_id_from_hex(SOL_USD_FEED_ID)?;
    let sol_price = price_update.get_price_no_older_than(
        &Clock::get()?,
        MAXIMUM_AGE,
        &sol_feed_id,
    )?;
    
    // Get USDC price
    let usdc_feed_id = get_feed_id_from_hex(USDC_USD_FEED_ID)?;
    let usdc_price = price_update.get_price_no_older_than(
        &Clock::get()?,
        MAXIMUM_AGE,
        &usdc_feed_id,
    )?;
    
    // Calculate collateral value in USD
    let sol_value_usd = (user.deposited_amount as i128 * sol_price.price as i128)
        / 10i128.pow((sol_price.exponent.abs() as u32));
    
    // Calculate max borrow in USD
    let max_borrow_usd = sol_value_usd * bank.max_ltv as i128 / 100;
    
    // Check borrow limit
    require!(
        amount <= max_borrow_usd as u64,
        LendingError::BorrowLimitExceeded
    );
    
    Ok(())
}
```

## Handling Price Precision

Prices are scaled integers; handle precision carefully:

```rust
fn get_decimal_price(price: i64, exponent: i32) -> f64 {
    if exponent >= 0 {
        price as f64 * 10f64.powi(exponent)
    } else {
        price as f64 / 10f64.powi(exponent.abs())
    }
}
```

## Stale Price Protection

Always validate price freshness:

```rust
fn validate_price_not_stale(
    price_update: &Account<'info, PriceUpdateV2>,
    max_age: u64
) -> Result<()> {
    let clock = Clock::get()?;
    let staleness = clock.unix_timestamp - price_update.publish_time;
    
    require!(
        staleness <= max_age as i64,
        LendingError::StalePrice
    );
    
    Ok(())
}
```

## Key Takeaways

Prices come from Pyth price update accounts. Handle scaled integer prices carefully.
Validate price freshness to prevent stale data usage. Use prices for collateral
valuation and borrow limits. Error handling for invalid prices is critical.
