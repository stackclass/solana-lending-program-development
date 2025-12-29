# PDA Practice

This stage provides practice exercises for implementing PDA-based account
management in your lending protocol. You'll apply concepts from previous
stages to build complete, functional PDA handling.

## Exercise 1: Initialize All Protocol PDAs

Create an instruction that initializes all necessary PDAs for a new lending
market:

```rust
#[derive(Accounts)]
pub struct InitializeMarket<'info> {
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

pub fn initialize_market(ctx: Context<InitializeMarket>) -> Result<()> {
    let bank = &mut ctx.accounts.bank;
    bank.mint_address = ctx.accounts.mint.key();
    bank.authority = ctx.accounts.authority.key();
    bank.total_deposits = 0;
    bank.total_borrows = 0;
    bank.bump = *ctx.bumps.get("bank").unwrap();
    
    Ok(())
}
```

## Exercise 2: PDA-Based Token Transfer

Implement a deposit function that uses PDA signing for the treasury:

```rust
pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
    // Transfer tokens to treasury with PDA signing
    let mint_key = ctx.accounts.mint.key();
    let signer_seeds: &[&[&[u8]]] = &[
        &[
            b"treasury",
            mint_key.as_ref(),
            &[ctx.bumps.bank_token_account],
        ],
    ];
    
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
    
    // Update states...
    Ok(())
}
```

## Exercise 3: Multi-Account PDA Operations

Create a liquidation function that works with multiple PDAs:

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
        seeds = [b"bank", borrowed_mint.key().as_ref()],
        bump,
    )]
    pub borrowed_bank: Account<'info, Bank>,
    
    #[account(
        mut,
        seeds = [liquidatee.key().as_ref()],
        bump,
    )]
    pub user_account: Account<'info, User>,
}
```

## Requirements

1. All accounts must use proper PDA derivation
2. Bumps must be stored in account data
3. All treasury transfers must use PDA signing
4. Error handling for invalid PDAs

## Key Takeaways

PDA initialization requires proper seed design. PDA signing enables program-controlled
treasury operations. Multiple PDAs can be accessed in single instructions. Proper
bump storage enables consistent PDA operations across all protocol functions.
