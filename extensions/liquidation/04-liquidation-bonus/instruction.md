# Liquidation Bonus

This stage explains the liquidation bonus (also called liquidation incentive)
that motivates liquidators to participate in the liquidation process.

## Why Liquidators Need Incentives

Liquidators perform important work for the protocol:

1. **Risk Taking**: Liquidators must have capital to repay debt
2. **Monitoring**: Liquidators must watch for liquidatable positions
3. **Gas Costs**: Liquidators pay transaction fees

Without adequate incentives, no one would liquidate positions, putting the
protocol at risk of bad debt.

## How Liquidation Bonus Works

The liquidation bonus is a percentage added to the collateral value received
by liquidators:

```
Bonus = 10% (typical)
Liquidator receives: Collateral worth (Repaid Debt × (1 + Bonus))
```

For example, if a liquidator repays 100 USDC worth of debt:
- Receives 110 USDC worth of collateral (10% bonus)
- Protocol covers the difference

## Bonus Configuration

Store the bonus percentage in the bank:

```rust
#[account]
#[derive(InitSpace)]
pub struct Bank {
    pub authority: Pubkey,
    pub mint_address: Pubkey,
    pub total_deposits: u64,
    pub total_borrows: u64,
    pub interest_rate: u64,
    pub max_ltv: u64,
    pub liquidation_threshold: u64,
    pub liquidation_bonus: u8,  // e.g., 10 for 10%
    pub last_updated: i64,
    pub bump: u8,
}
```

## Calculating Bonus Amount

```rust
fn calculate_liquidation_bonus(
    repaid_amount: u64,
    bonus_percent: u64,
) -> u64 {
    (repaid_amount * (100 + bonus_percent)) / 100
}

fn calculate_bonus_amount(
    repaid_amount: u64,
    bonus_percent: u64,
) -> u64 {
    (repaid_amount * bonus_percent) / 100
}
```

## Balancing Bonus Parameters

The bonus must be calibrated carefully:

- **Too Low**: No liquidators will participate, risking bad debt
- **Too High**: Users lose too much collateral, discouraging participation

Typical values:
- **Bonus**: 5-15%
- **Close Factor**: 25-50%

## Key Takeaways

Liquidation bonuses incentivize liquidators to maintain protocol health.
Bonus is added to collateral value received by liquidators. Typical bonus
is 5-15%. Proper calibration encourages liquidation while protecting users.
Without adequate incentives, protocols risk bad debt.
