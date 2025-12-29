# Pyth Network Integration

This stage teaches you how to integrate Pyth Network price feeds into your
lending protocol for real-time asset pricing.

## Adding Pyth Dependency

Add the Pyth SDK to your Cargo.toml:

```toml
[dependencies]
pyth-sdk-solana = "0.10.1"
pyth-solana-receiver-sdk = "0.3.1"
```

## Price Feed IDs

Pyth uses specific feed IDs for each asset. These are hexadecimal strings:

```rust
// SOL/USD price feed on Solana
pub const SOL_USD_FEED_ID: &str = 
    "0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8ed0c6c7bc0f4cfac8c280b56d";

// USDC/USD price feed
pub const USDC_USD_FEED_ID: &str = 
    "0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a";
```

## Importing Pyth Types

```rust
use pyth_solana_receiver_sdk::price_update::{PriceUpdateV2, get_feed_id_from_hex};
```

## Price Update Account

Your instructions need access to a price update account:

```rust
#[derive(Accounts)]
pub struct BorrowWithOracle<'info> {
    #[account(mut)]
    pub user: Signer<'info>,
    
    #[account(
        mut,
        seeds = [b"bank", mint.key().as_ref()],
        bump,
    )]
    pub bank: Account<'info, Bank>,
    
    #[account(
        mut,
        seeds = [b"treasury", mint.key().as_ref()],
        bump,
    )]
    pub bank_token_account: InterfaceAccount<'info, TokenAccount>,
    
    #[account(
        mut,
        seeds = [user.key().as_ref()],
        bump,
    )]
    pub user_account: Account<'info, User>,
    
    // Price update from Pyth
    pub price_update: Account<'info, PriceUpdateV2>,
    
    // ... other accounts
}
```

## Getting Price Data

Fetch the current price from the feed:

```rust
use pyth_solana_receiver_sdk::price_update::{get_feed_id_from_hex, PriceUpdateV2};

fn get_price(
    price_update: &Account<'info, PriceUpdateV2>,
    feed_id_str: &str,
) -> Result<i64> {
    let feed_id = get_feed_id_from_hex(feed_id_str)?;
    let price = price_update.get_price_no_older_than(
        &Clock::get()?,
        MAXIMUM_AGE,  // Max age in seconds
        &feed_id,
    )?;
    Ok(price.price)
}
```

## Practical Exercise

Set up the complete Pyth integration for your lending protocol including
imports, constants, and account definitions.

## Key Takeaways

Pyth SDK provides Solana-specific price feed integration. Feed IDs identify
specific price feeds for each asset. PriceUpdateV2 account holds the price data.
get_price_no_older_than validates price freshness. Integration requires careful
error handling for stale prices.
