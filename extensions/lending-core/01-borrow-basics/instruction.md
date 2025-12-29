# Borrow Basics

This stage teaches you how to implement the basic borrow instruction that
allows users to borrow tokens from the lending protocol against their collateral.

## Understanding Borrowing

When a user borrows tokens from the protocol:

1. The protocol validates the user has sufficient collateral
2. Tokens are transferred from the treasury to the user
3. The user's borrowed balance increases
4. The protocol's total borrows increases

## Step 1: Define the Borrow Context

```rust
#[derive(Accounts)]
pub struct Borrow<'info> {
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
        init_if_needed,
        payer = user,
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

## Step 2: Implement the Borrow Instruction

```rust
pub fn borrow(ctx: Context<Borrow>, amount: u64) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    // Calculate max borrowable amount based on collateral
    let max_borrow = user.deposited_amount * bank.max_ltv / 100;
    let current_borrow = user.borrowed_amount;
    
    require!(
        current_borrow + amount <= max_borrow,
        LendingError::BorrowLimitExceeded
    );
    
    // Transfer tokens from treasury to user
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
    
    // Update user state
    user.borrowed_amount += amount;
    
    // Update bank state
    bank.total_borrows += amount;
    
    Ok(())
}
```

## Understanding Borrow Limits

The borrow limit is determined by the maximum loan-to-value (LTV) ratio:

```rust
// max_ltv = 80 means user can borrow up to 80% of their deposit
let max_borrowable = user.deposited_amount * bank.max_ltv / 100;
let available_to_borrow = max_borrowable - user.borrowed_amount;
```

## Key Takeaways

Borrowing requires collateral-based validation. LTV determines maximum borrow.
Treasury must have sufficient liquidity. PDA signing authorizes treasury transfers.
User and bank state must be updated atomically.
