# Repay Basics

This stage teaches you how to implement the repay instruction that allows
users to repay borrowed tokens to the lending protocol.

## Understanding Repayment

When a user repays tokens:

1. The protocol validates the user has a borrow position
2. Tokens are transferred from user to treasury
3. The user's borrowed balance decreases
4. The protocol's total borrows decreases

## Step 1: Define the Repay Context

```rust
#[derive(Accounts)]
pub struct Repay<'info> {
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
    
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = user,
    )]
    pub user_token_account: InterfaceAccount<'info, TokenAccount>,
    
    pub mint: InterfaceAccount<'info, Mint>,
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}
```

## Step 2: Implement the Repay Instruction

```rust
pub fn repay(ctx: Context<Repay>, amount: u64) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    // Validate user has a borrow position
    require!(
        user.borrowed_amount > 0,
        LendingError::NoBorrowPosition
    );
    
    // Cap repayment at borrowed amount (no overpayment)
    let repay_amount = amount.min(user.borrowed_amount);
    
    // Transfer tokens from user to treasury
    let cpi_accounts = TransferChecked {
        from: ctx.accounts.user_token_account.to_account_info(),
        mint: ctx.accounts.mint.to_account_info(),
        to: ctx.accounts.bank_token_account.to_account_info(),
        authority: ctx.accounts.user.to_account_info(),
    };
    
    let cpi_ctx = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts,
    );
    
    anchor_spl::token_interface::transfer_checked(
        cpi_ctx,
        repay_amount,
        ctx.accounts.mint.decimals,
    )?;
    
    // Update user state
    user.borrowed_amount -= repay_amount;
    
    // Update bank state
    bank.total_borrows -= repay_amount;
    
    Ok(())
}
```

## Full Repayment Pattern

Users should be able to repay their full balance:

```rust
pub fn repay_full(ctx: Context<Repay>) -> Result<()> {
    let amount = ctx.accounts.user_account.borrowed_amount;
    repay(ctx, amount)
}
```

## Key Takeaways

Repayment reduces user's debt. Amount should be capped at borrowed balance.
User signs for transfer to treasury. State updates happen atomically.
Full repayment can be handled as a special case.
