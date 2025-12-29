# Account Structure Practice

This stage provides practice exercises for implementing complete account
structures for your lending protocol.

## Exercise 1: Complete Bank Account Implementation

Define a complete Bank account with all necessary fields:

```rust
#[account]
#[derive(InitSpace)]
pub struct Bank {
    pub authority: Pubkey,
    pub mint_address: Pubkey,
    pub total_deposits: u64,
    pub total_deposit_shares: u64,
    pub total_borrows: u64,
    pub total_borrow_shares: u64,
    pub interest_rate: u64,
    pub liquidation_threshold: u64,
    pub max_ltv: u64,
    pub liquidation_bonus: u64,
    pub last_updated: i64,
    pub bump: u8,
}
```

## Exercise 2: Complete User Account Implementation

Define a complete User account for a single-asset protocol:

```rust
#[account]
#[derive(InitSpace)]
pub struct User {
    pub owner: Pubkey,
    pub deposited_amount: u64,
    pub deposited_shares: u64,
    pub borrowed_amount: u64,
    pub borrowed_shares: u64,
    pub last_updated: i64,
    pub bump: u8,
}
```

## Exercise 3: Initialize User Account

Create the initialization instruction for user accounts:

```rust
#[derive(Accounts)]
pub struct InitUser<'info> {
    #[account(mut)]
    pub user: Signer<'info>,
    
    #[account(
        init,
        payer = user,
        space = 8 + User::INIT_SPACE,
        seeds = [user.key().as_ref()],
        bump,
    )]
    pub user_account: Account<'info, User>,
    
    pub system_program: Program<'info, System>,
}

pub fn init_user(ctx: Context<InitUser>) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    user.owner = ctx.accounts.user.key();
    user.deposited_amount = 0;
    user.deposited_shares = 0;
    user.borrowed_amount = 0;
    user.borrowed_shares = 0;
    user.last_updated = Clock::get()?.unix_timestamp;
    user.bump = *ctx.bumps.get("user_account").unwrap();
    Ok(())
}
```

## Exercise 4: Multi-Asset User Account

Extend the user account for multiple assets:

```rust
#[account]
#[derive(InitSpace)]
pub struct User {
    pub owner: Pubkey,
    
    // SOL position
    pub sol_deposited_amount: u64,
    pub sol_deposited_shares: u64,
    pub sol_borrowed_amount: u64,
    pub sol_borrowed_shares: u64,
    
    // USDC position
    pub usdc_deposited_amount: u64,
    pub usdc_deposited_shares: u64,
    pub usdc_borrowed_amount: u64,
    pub usdc_borrowed_shares: u64,
    
    pub last_updated: i64,
    pub bump: u8,
}
```

## Requirements

1. All accounts must use `#[derive(InitSpace)]`
2. Initialize all fields to sensible defaults
3. Store bump seeds for PDA operations
4. Initialize last_updated timestamp
5. Support multiple asset types where applicable

## Key Takeaways

Complete account structures include all necessary fields. InitSpace calculates
proper account size. User initialization creates individual positions. Multi-asset
support requires extended structures. Proper initialization ensures protocol
correctness.
