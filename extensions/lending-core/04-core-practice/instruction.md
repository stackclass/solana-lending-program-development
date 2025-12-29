# Lending Core Practice

This stage provides comprehensive practice exercises for implementing all
core lending operations in your protocol.

## Exercise 1: Complete Deposit Instruction

Implement a deposit instruction with proper state updates:

```rust
#[derive(Accounts)]
pub struct Deposit<'info> {
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

pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
    require!(amount > 0, LendingError::ZeroAmount);
    
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    // Transfer tokens
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
        amount,
        ctx.accounts.mint.decimals,
    )?;
    
    // Update state
    user.deposited_amount += amount;
    bank.total_deposits += amount;
    
    Ok(())
}
```

## Exercise 2: Complete Withdraw Instruction

Implement a withdraw instruction with proper validation:

```rust
pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    require!(amount > 0, LendingError::ZeroAmount);
    require!(
        ctx.accounts.user_account.deposited_amount >= amount,
        LendingError::InsufficientFunds
    );
    
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    // Check LTV after withdrawal
    let new_deposit = user.deposited_amount - amount;
    let max_borrow = (new_deposit * bank.max_ltv) / 100;
    
    require!(
        user.borrowed_amount <= max_borrow,
        LendingError::WouldExceedLTV
    );
    
    // Transfer from treasury with PDA signing
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
    
    // Update state
    user.deposited_amount -= amount;
    bank.total_deposits -= amount;
    
    Ok(())
}
```

## Exercise 3: Complete Borrow Instruction

Implement borrow with LTV enforcement:

```rust
pub fn borrow(ctx: Context<Borrow>, amount: u64) -> Result<()> {
    require!(amount > 0, LendingError::ZeroAmount);
    
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    // Check LTV
    let max_borrow = (user.deposited_amount * bank.max_ltv) / 100;
    require!(
        user.borrowed_amount + amount <= max_borrow,
        LendingError::BorrowLimitExceeded
    );
    
    // Transfer from treasury
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
    
    // Update state
    user.borrowed_amount += amount;
    bank.total_borrows += amount;
    
    Ok(())
}
```

## Requirements

1. All amounts must be validated (> 0)
2. Withdraw must check post-withdrawal LTV
3. Borrow must check LTV limit
4. All treasury transfers use PDA signing
5. State updates are atomic

## Key Takeaways

Core operations include deposit, withdraw, borrow, and repay. LTV validation
is critical for withdraw and borrow. PDA signing is required for treasury
transfers. State updates must be atomic and consistent.
