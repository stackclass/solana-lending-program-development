# Liquidation Practice

This stage provides comprehensive practice exercises for implementing complete
liquidation functionality in your lending protocol.

## Exercise 1: Health Factor Calculation

Implement health factor calculation with oracle prices:

```rust
pub fn calculate_health_factor(
    user: &User,
    bank: &Bank,
    price_update: &Account<'info, PriceUpdateV2>,
) -> Result<u64> {
    let feed_id = get_feed_id_from_hex(SOL_USD_FEED_ID)?;
    let price = price_update.get_price_no_older_than(
        &Clock::get()?,
        MAXIMUM_AGE,
        &feed_id,
    )?;
    
    let deposited_value = (user.deposited_amount as u128
        * price.price as u128)
        / 10u128.pow((price.exponent.abs() as u32));
    
    let borrowed_value = (user.borrowed_amount as u128
        * price.price as u128)
        / 10u128.pow((price.exponent.abs() as u32));
    
    if borrowed_value == 0 {
        return Ok(u64::MAX);
    }
    
    let health_factor = ((deposited_value * bank.liquidation_threshold as u128
        / borrowed_value) / 100) as u64;
    
    Ok(health_factor)
}
```

## Exercise 2: Complete Liquidation Instruction

Implement a complete liquidation function:

```rust
pub fn liquidate(
    ctx: Context<Liquidate>,
    repay_amount: u64
) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    let collateral_bank = &ctx.accounts.collateral_bank;
    let debt_bank = &ctx.accounts.debt_bank;
    let price_update = &ctx.accounts.price_update;
    
    // Check if liquidation is needed
    let health_factor = calculate_health_factor(user, collateral_bank, price_update)?;
    require!(
        health_factor < LIQUIDATION_THRESHOLD,
        LendingError::HealthyPosition
    );
    
    // Calculate liquidation amount
    let max_liquidatable = (user.borrowed_amount * CLOSE_FACTOR) / 100;
    let actual_repay = repay_amount.min(max_liquidatable);
    
    // Calculate collateral to receive (with bonus)
    let bonus_amount = (actual_repay * collateral_bank.liquidation_bonus as u64) / 100;
    let total_collateral = actual_repay + bonus_amount;
    
    // Validate user has enough collateral
    require!(
        user.deposited_amount >= total_collateral,
        LendingError::InsufficientCollateral
    );
    
    // Transfer debt repayment from liquidator to treasury
    let cpi_accounts = TransferChecked {
        from: ctx.accounts.liquidator_token_account.to_account_info(),
        mint: ctx.accounts.debt_mint.to_account_info(),
        to: ctx.accounts.debt_treasury.to_account_info(),
        authority: ctx.accounts.liquidator.to_account_info(),
    };
    
    let cpi_ctx = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts,
    );
    
    anchor_spl::token_interface::transfer_checked(
        cpi_ctx,
        actual_repay,
        ctx.accounts.debt_mint.decimals,
    )?;
    
    // Transfer collateral to liquidator with PDA signing
    let mint_key = ctx.accounts.collateral_mint.key();
    let signer_seeds: &[&[&[u8]]] = &[
        &[
            b"treasury",
            mint_key.as_ref(),
            &[ctx.bumps.collateral_treasury],
        ],
    ];
    
    let cpi_accounts = TransferChecked {
        from: ctx.accounts.collateral_treasury.to_account_info(),
        mint: ctx.accounts.collateral_mint.to_account_info(),
        to: ctx.accounts.liquidator_collateral_token.to_account_info(),
        authority: ctx.accounts.collateral_treasury.to_account_info(),
    };
    
    let cpi_ctx = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts,
    ).with_signer(signer_seeds);
    
    anchor_spl::token_interface::transfer_checked(
        cpi_ctx,
        total_collateral,
        ctx.accounts.collateral_mint.decimals,
    )?;
    
    // Update user state
    user.borrowed_amount -= actual_repay;
    user.deposited_amount -= total_collateral;
    
    Ok(())
}
```

## Requirements

1. Calculate health factor using oracle prices
2. Validate liquidation conditions before execution
3. Enforce close factor limits
4. Calculate bonus correctly
5. Use PDA signing for collateral transfers
6. Update user state atomically

## Key Takeaways

Complete liquidation requires health factor calculation. Close factor limits
liquidation per transaction. Bonus motivates liquidators. PDA signing is
required for collateral transfers. State updates must be atomic.
