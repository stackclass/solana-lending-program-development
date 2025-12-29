## Pyth Price Oracle Integration

In this stage, you'll integrate the Pyth price oracle to get real-time asset prices for collateral valuation and health factor calculation.

## Understanding Pyth Oracle

Pyth provides:
- Real-time price feeds for crypto assets
- On-chain price updates
- High-frequency price data
- Confidence intervals for price accuracy

## Prerequisite Reading

- **Pyth Documentation**: Read the [Pyth Price Feeds Guide](https://docs.pyth.network/price-feeds)
- **Pyth Anchor SDK**: Review the [Pyth Anchor SDK](https://github.com/pyth-network/pyth-client)

## Implementation

### Add Constants

```rust
#[constant]
pub const SOL_USD_FEED_ID: &str = "0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8ed0c6c7bc0f4cfac8c280b56d";
pub const USDC_USD_FEED_ID: &str = "0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a";
pub const MAXIMUM_AGE: u64 = 100;
```

### Add Dependencies

Update `Cargo.toml`:

```toml
[dependencies]
pyth-sdk = "0.10.0"
```

### Price Update Account

Add `price_update: Account<'info, PriceUpdateV2>` to Borrow and Liquidate contexts.

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| Price feed | Valid price data | Confirms Pyth integration |
| Price staleness | Rejects old prices | Validates freshness checks |
