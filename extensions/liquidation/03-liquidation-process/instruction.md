# Liquidation Process

This stage teaches you how to implement the actual liquidation execution
that seizes collateral from undercollateralized positions.

## What is Liquidation

Liquidation is the process where a liquidator (third party) repays part of
the user's debt in exchange for receiving the user's collateral at a
discount. This protects the protocol from bad debt.

## Liquidation Steps

1. Liquidator identifies undercollateralized position
2. Liquidator repays a portion of the debt
3. Liquidator receives collateral worth more than repaid (discount)
4. User's debt and collateral are reduced proportionally
5. Protocol remains solvent

## Liquidation Context

```rust
#[derive(Accounts)]
pub struct Liquidate<'info> {
    #[account(mut)]
    pub liquidator: Signer<'info>,
    
    #[account(
        mut,
        seeds = [b"bank", collateral_mint.key().as_ref()],
        bump,
    )]
    pub collateral_bank: Account<'info, Bank>,
    
    #[account(
        mut,
        seeds = [b"bank", debt_mint.key().as_ref()],
        bump,
    )]
    pub debt_bank: Account<'info, Bank>,
    
    #[account(
        mut,
        seeds = [liquidatee.key().as_ref()],
        bump,
    )]
    pub user_account: Account<'info, User>,
    
    #[account(mut)]
    pub collateral_treasury: InterfaceAccount<'info, TokenAccount>,
    
    #[account(mut)]
    pub debt_treasury: InterfaceAccount<'info, TokenAccount>,
    
    #[account(
        init_if_needed,
        payer = liquidator,
        associated_token::mint = collateral_mint,
        associated_token::authority = liquidator,
    )]
    pub liquidator_collateral_token: InterfaceAccount<'info, TokenAccount>,
    
    pub price_update: Account<'info, PriceUpdateV2>,
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}
```

## Liquidation Implementation

```rust
pub fn liquidate(
    ctx: Context<Liquidate>,
    repay_amount: u64
) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    let collateral_bank = &mut ctx.accounts.collateral_bank;
    
    // Calculate liquidation amount (close factor)
    let close_factor = 50;  // Can liquidate up to 50% of debt
    let max_liquidatable = (user.borrowed_amount * close_factor) / 100;
    let actual_repay = repay_amount.min(max_liquidatable);
    
    // Liquidator repays debt
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
    
    // Calculate collateral to receive (with bonus)
    let bonus = 10;  // 10% bonus for liquidator
    let collateral_value = (actual_repay * (100 + bonus)) / 100;
    let collateral_amount = collateral_value;  // Simplified
    
    // Transfer collateral to liquidator
    let signer_seeds: &[&[&[u8]]] = &[
        &[
            b"treasury",
            ctx.accounts.collateral_mint.key().as_ref(),
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
        collateral_amount,
        ctx.accounts.collateral_mint.decimals,
    )?;
    
    // Update user state
    user.borrowed_amount -= actual_repay;
    user.deposited_amount -= collateral_amount;
    
    Ok(())
}
```

## Key Takeaways

Liquidation requires detecting undercollateralized positions. Liquidators
repay debt and receive collateral at a discount. Close factor limits
liquidation per transaction. PDA signing is needed for collateral transfer.
User state must be updated atomically.
