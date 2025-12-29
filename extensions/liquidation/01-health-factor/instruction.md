# Health Factor Concept

This stage introduces the health factor concept, a critical metric for
determining the safety of lending positions.

## What is Health Factor

The health factor represents the safety of a user's loan position. It is
calculated as the ratio of collateral value to debt value, adjusted by
liquidation parameters.

```
Health Factor = (Collateral Value × Liquidation Threshold) / Debt Value
```

A health factor above 1.0 indicates the position is overcollateralized.
Below 1.0, the position can be liquidated.

## Health Factor Interpretation

| Health Factor | Status | Action |
|---------------|--------|--------|
| > 2.0 | Very Healthy | Position is well collateralized |
| 1.5 - 2.0 | Healthy | Normal operating range |
| 1.0 - 1.5 | At Risk | Approaching liquidation threshold |
| < 1.0 | Liquidatable | Can be liquidated |

## Health Factor in Your Protocol

Store health factor in the user account for quick access:

```rust
#[account]
#[derive(InitSpace)]
pub struct User {
    pub owner: Pubkey,
    pub deposited_amount: u64,
    pub borrowed_amount: u64,
    pub health_factor: u64,
    pub last_updated: i64,
    pub bump: u8,
}
```

## Calculating Health Factor

```rust
fn calculate_health_factor(
    deposited_value: u64,
    borrowed_value: u64,
    liquidation_threshold: u64,
) -> u64 {
    if borrowed_value == 0 {
        return u64::MAX;  // No debt means infinite health
    }
    
    // Health factor scaled by 100 for precision
    ((deposited_value * liquidation_threshold) / borrowed_value)
}
```

## Health Factor Thresholds

Common threshold values:

- **Liquidation Threshold**: Typically 85% (health factor 0.85 = liquidation)
- **Warning Threshold**: Typically 100% (health factor 1.0 = warning)
- **Safe Threshold**: Typically 150%+ (health factor 1.5 = safe)

## Key Takeaways

Health factor indicates loan safety. Formula: (collateral × threshold) / debt.
Health factor > 1.0 means overcollateralized. Health factor < 1.0 triggers liquidation.
Regular health factor updates are essential for protocol safety.
