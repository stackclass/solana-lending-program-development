# Liquidation Trigger

This stage teaches you how to detect when lending positions become
liquidatable and should be liquidated.

## When Does Liquidation Occur

A position becomes liquidatable when its health factor drops below the
liquidation threshold. This typically happens when:

1. **Collateral Value Decreases**: The asset used as collateral drops in price
2. **Debt Increases**: Interest accrues on borrowed tokens
3. **User Does Not Repay**: Position deteriorates over time

## Checking Liquidation Conditions

```rust
#[derive(Accounts)]
pub struct CheckLiquidation<'info> {
    pub user_account: Account<'info, User>,
    pub bank: Account<'info, Bank>,
    pub price_update: Account<'info, PriceUpdateV2>,
}

pub fn check_liquidation_needed(ctx: Context<CheckLiquidation>) -> Result<bool> {
    let user = &ctx.accounts.user_account;
    let bank = &ctx.accounts.bank;
    let price_update = &ctx.accounts.price_update;
    
    // Get current price
    let feed_id = get_feed_id_from_hex(SOL_USD_FEED_ID)?;
    let price = price_update.get_price_no_older_than(
        &Clock::get()?,
        MAXIMUM_AGE,
        &feed_id,
    )?;
    
    // Calculate collateral and debt values
    let collateral_value = (user.deposited_amount as u128
        * price.price as u128)
        / 10u128.pow((price.exponent.abs() as u32));
    
    let debt_value = (user.borrowed_amount as u128
        * price.price as u128)
        / 10u128.pow((price.exponent.abs() as u32));
    
    // Calculate health factor
    let health_factor = if debt_value == 0 {
        u64::MAX
    } else {
        ((collateral_value * bank.liquidation_threshold as u128
            / debt_value) / 100) as u64
    };
    
    // Check if liquidation is needed
    let is_liquidatable = health_factor < LIQUIDATION_THRESHOLD;
    
    Ok(is_liquidatable)
}
```

## Liquidation Threshold

The liquidation threshold is stored in the bank:

```rust
#[account]
#[derive(InitSpace)]
pub struct Bank {
    pub authority: Pubkey,
    pub mint_address: Pubkey,
    pub total_deposits: u64,
    pub total_borrows: u64,
    pub interest_rate: u64,
    pub max_ltv: u64,               // e.g., 80 for 80%
    pub liquidation_threshold: u64,  // e.g., 85 for 85%
    pub last_updated: i64,
    pub bump: u8,
}

// Common threshold: 85%
pub const LIQUIDATION_THRESHOLD: u64 = 85;
```

## Continuous Monitoring

Positions should be checked regularly:

1. **At Borrow/Repay**: Check health after any state-changing operation
2. **On Price Update**: Monitor price changes that could trigger liquidation
3. **On Interest Accrual**: Check if accumulated interest triggers liquidation

## Key Takeaways

Liquidation triggers when health factor < liquidation threshold. Collateral
debt value changes can trigger liquidation. Regular health checks are essential.
Price oracles enable real-time liquidation detection. Proactive monitoring
protects protocol solvency.
