# Security Practice

This stage provides comprehensive practice exercises for implementing
security best practices in your lending protocol.

## Exercise 1: Secure Withdraw Function

Implement a withdraw function with comprehensive security measures:

```rust
pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    // CHECKS
    require!(amount > 0, LendingError::ZeroAmount);
    
    let user = &ctx.accounts.user_account;
    let bank = &ctx.accounts.bank;
    
    require!(
        user.deposited_amount >= amount,
        LendingError::InsufficientFunds
    );
    
    require!(
        bank.total_deposits >= amount,
        LendingError::InsufficientLiquidity
    );
    
    // Check post-withdraw LTV
    let new_deposit = user.deposited_amount - amount;
    let max_borrow = (new_deposit * bank.max_ltv) / 100;
    require!(
        user.borrowed_amount <= max_borrow,
        LendingError::WouldExceedLTV
    );
    
    // EFFECTS - Update state BEFORE external call
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    user.deposited_amount = user.deposited_amount.checked_sub(amount)
        .ok_or(LendingError::Underflow)?;
    bank.total_deposits = bank.total_deposits.checked_sub(amount)
        .ok_or(LendingError::Underflow)?;
    
    // INTERACTIONS - External call AFTER state update
    let mint_key = ctx.accounts.mint.key();
    let signer_seeds: &[&[&[u8]]] = &[
        &[
            b"treasury",
            mint_key.as_ref(),
            &[ctx.bumps.bank_token_account],
        ],
    ];
    
    let cpi_accounts = TransferChecked {
        from: ctx.accounts.bank_token_account.to_account_info(),
        mint: ctx.accounts.mint.to_account_info(),
        to: ctx.accounts.user_token_account.to_account_info(),
        authority: ctx.accounts.bank_token_account.to_account_info(),
    };
    
    let cpi_ctx = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts,
    ).with_signer(signer_seeds);
    
    anchor_spl::token_interface::transfer_checked(
        cpi_ctx,
        amount,
        ctx.accounts.mint.decimals,
    )?;
    
    Ok(())
}
```

## Exercise 2: Secure Borrow Function

Implement borrow with comprehensive validation:

```rust
pub fn borrow(ctx: Context<Borrow>, amount: u64) -> Result<()> {
    // CHECKS
    require!(amount > 0, LendingError::ZeroAmount);
    
    let user = &ctx.accounts.user_account;
    let bank = &ctx.accounts.bank;
    
    require!(
        bank.total_deposits >= amount,
        LendingError::InsufficientLiquidity
    );
    
    // Validate LTV
    let max_borrow = (user.deposited_amount * bank.max_ltv) / 100;
    require!(
        user.borrowed_amount.checked_add(amount).ok_or(LendingError::Overflow)?
            <= max_borrow,
        LendingError::BorrowLimitExceeded
    );
    
    // EFFECTS - Update state BEFORE external call
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    user.borrowed_amount = user.borrowed_amount.checked_add(amount)
        .ok_or(LendingError::Overflow)?;
    bank.total_borrows = bank.total_borrows.checked_add(amount)
        .ok_or(LendingError::Overflow)?;
    
    // INTERACTIONS - External call AFTER state update
    let mint_key = ctx.accounts.mint.key();
    let signer_seeds: &[&[&[u8]]] = &[
        &[
            b"treasury",
            mint_key.as_ref(),
            &[ctx.bumps.bank_token_account],
        ],
    ];
    
    let cpi_accounts = TransferChecked {
        from: ctx.accounts.bank_token_account.to_account_info(),
        mint: ctx.accounts.mint.to_account_info(),
        to: ctx.accounts.user_token_account.to_account_info(),
        authority: ctx.accounts.bank_token_account.to_account_info(),
    };
    
    let cpi_ctx = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts,
    ).with_signer(signer_seeds);
    
    anchor_spl::token_interface::transfer_checked(
        cpi_ctx,
        amount,
        ctx.accounts.mint.decimals,
    )?;
    
    Ok(())
}
```

## Exercise 3: Secure Liquidate Function

Implement liquidation with comprehensive validation:

```rust
pub fn liquidate(ctx: Context<Liquidate>, repay_amount: u64) -> Result<()> {
    // CHECKS
    require!(repay_amount > 0, LendingError::ZeroAmount);
    
    let user = &ctx.accounts.user_account;
    let bank = &ctx.accounts.bank;
    
    // Validate user has borrow position
    require!(user.borrowed_amount > 0, LendingError::NoBorrowPosition);
    
    // Validate health factor
    let health_factor = calculate_health_factor(user, bank)?;
    require!(
        health_factor < bank.liquidation_threshold,
        LendingError::HealthyPosition
    );
    
    // Validate close factor
    let max_liquidatable = (user.borrowed_amount * CLOSE_FACTOR) / 100;
    let actual_repay = repay_amount.min(max_liquidatable);
    
    // EFFECTS
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    user.borrowed_amount = user.borrowed_amount.checked_sub(actual_repay)
        .ok_or(LendingError::Underflow)?;
    
    // ... more effects
    
    // INTERACTIONS
    // ... CPI calls
    
    Ok(())
}
```

## Requirements

1. All amounts validated (> 0)
2. State updates before external calls
3. Checked arithmetic for all math operations
4. Post-operation LTV validation for withdraw
5. Health factor validation for liquidation
6. Close factor limits for liquidation

## Key Takeaways

Secure functions require comprehensive validation. Checks-effects-interactions
pattern prevents reentrancy. Checked arithmetic prevents overflow/underflow.
LTV validation protects against undercollateralization. Health factor checks
enable proper liquidation. Close factor limits prevent griefing.
