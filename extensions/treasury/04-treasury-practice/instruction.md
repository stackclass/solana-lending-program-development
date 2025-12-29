# Treasury Practice

This stage provides comprehensive practice exercises for implementing treasury
management in your lending protocol.

## Exercise 1: Complete Bank Initialization

Create a complete bank initialization instruction with treasury creation:

```rust
#[derive(Accounts)]
pub struct InitBank<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub mint: InterfaceAccount<'info, Mint>,
    
    #[account(
        init,
        payer = authority,
        space = 8 + Bank::INIT_SPACE,
        seeds = [b"bank", mint.key().as_ref()],
        bump,
    )]
    pub bank: Account<'info, Bank>,
    
    #[account(
        init,
        payer = authority,
        associated_token::mint = mint,
        associated_token::authority = bank,
        seeds = [b"treasury", mint.key().as_ref()],
        bump,
    )]
    pub bank_token_account: InterfaceAccount<'info, TokenAccount>,
    
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

pub fn init_bank(ctx: Context<InitBank>) -> Result<()> {
    let bank = &mut ctx.accounts.bank;
    
    bank.mint_address = ctx.accounts.mint.key();
    bank.authority = ctx.accounts.authority.key();
    bank.total_deposits = 0;
    bank.total_borrows = 0;
    bank.interest_rate = 0;
    bank.liquidation_threshold = 0;
    bank.max_ltv = 0;
    bank.bump = *ctx.bumps.get("bank").unwrap();
    
    Ok(())
}
```

## Exercise 2: Secure Deposit Function

Implement a deposit function with proper treasury handling:

```rust
pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
    require!(amount > 0, LendingError::ZeroAmount);
    
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    // Transfer tokens to treasury
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

## Exercise 3: Secure Withdraw Function

Implement a withdraw function with proper treasury validation:

```rust
pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    require!(amount > 0, LendingError::ZeroAmount);
    require!(
        ctx.accounts.user_account.deposited_amount >= amount,
        LendingError::InsufficientFunds
    );
    require!(
        ctx.accounts.bank_token_account.amount >= amount,
        LendingError::InsufficientLiquidity
    );
    
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    // PDA signing for treasury transfer
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

## Requirements

1. All treasury transfers must use PDA signing
2. Validate amounts are greater than zero
3. Validate user has sufficient balance for withdrawals
4. Validate treasury has sufficient liquidity
5. Update all relevant state variables atomically

## Key Takeaways

Complete bank initialization includes both bank account and treasury creation.
Deposits transfer tokens from user to treasury without PDA signing.
Withdrawals require PDA signing to authorize treasury transfers.
Always validate amounts and balances before operations. State updates must
be atomic with token transfers.
