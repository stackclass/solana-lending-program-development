# Oracle Concept

This stage introduces oracle concepts and explains why price feeds are
essential for lending protocols to determine collateral value.

## What is an Oracle

An oracle is a service that provides external data to smart contracts. For
lending protocols, oracles provide real-time prices of assets, enabling
accurate collateral valuation and borrowing limits.

Without oracles, smart contracts cannot access off-chain data like asset prices.
Oracles bridge this gap by feeding external data to on-chain programs.

## Why Lending Protocols Need Oracles

Lending protocols require accurate asset prices for several purposes:

**Collateral Valuation**: Determine the value of deposited assets in a common
denominator (e.g., USD) to calculate borrowing limits.

**Health Factor Calculation**: Monitor the ratio of collateral value to debt
value to detect undercollateralized positions.

**Liquidation Triggers**: When collateral value drops relative to debt, trigger
liquidation to protect the protocol.

**Cross-Asset Borrowing**: Allow users to borrow one asset using another as
collateral, requiring price conversion.

## Types of Oracles

**Pyth Network**: Aggregates price data from hundreds of sources (exchanges,
market makers) and provides low-latency, high-quality price feeds.

**Switchboard**: General-purpose oracle that can be configured for custom
data feeds and aggregation strategies.

**Chainlink (on Solana)**: Provides verified price feeds with built-in
aggregation and fallback mechanisms.

## Price Feed Structure

Oracles provide price data in a standardized format:

```rust
pub struct Price {
    pub price: i64,          // Price as scaled integer
    pub exponent: i32,       // Scale factor (e.g., -8 means divide by 100M)
    pub conf: u64,           // Confidence interval
    pub publish_time: i64,   // Last update timestamp
}
```

## Understanding Price Scaling

Prices are stored as scaled integers to maintain precision:

```rust
// If price is 100.50 USD and exponent is -8
let actual_price = price.price as f64 * 10f64.powi(price.exponent);
// 100.50 = 10050000000 * 10^-8
```

## Key Takeaways

Oracles provide external data (prices) to smart contracts. Lending protocols
need prices for collateral valuation and risk management. Different oracle
providers offer varying features and reliability. Price feeds use scaled
integers for precision. Oracle integration is critical for protocol safety.
