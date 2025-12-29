# Account Validation

This stage teaches comprehensive account validation techniques to ensure
your lending protocol only processes legitimate transactions.

## Basic Account Types

Anchor provides several account types for validation:

```rust
#[account(mut)]      // Account can be modified
pub user: Signer<'info>,        // Transaction signer

#[account]
pub user_account: Account<'info, User>,  // Deserialized account data

#[account]
pub token_account: InterfaceAccount<'info, TokenAccount>,  // Token account
```

## Validation Constraints

Anchor constraints provide built-in validation:

```rust
#[derive(Accounts)]
pub struct ComplexOperation<'info> {
    #[account(mut)]
    pub user: Signer<'info>,
    
    #[account(
        mut,
        seeds = [user.key().as_ref()],
        bump,
    )]
    pub user_account: Account<'info, User>,
    
    #[account(
        constraint = user_account.owner == user.key()
    )]
    pub user_account_check: Account<'info, User>,
    
    #[account(
        mut,
        seeds = [b"bank", mint.key().as_ref()],
        bump,
    )]
    pub bank: Account<'info, Bank>,
    
    #[account(
        constraint = bank.mint_address == mint.key()
    )]
    pub mint_check: Account<'info, Mint>,
}
```

## Cross-Account Validation

Validate relationships between accounts:

```rust
#[derive(Accounts)]
pub struct Liquidate<'info> {
    #[account(mut)]
    pub liquidator: Signer<'info>,
    
    #[account(
        mut,
        seeds = [liquidatee.key().as_ref()],
        bump,
    )]
    pub user_account: Account<'info, User>,
    
    #[account(
        mut,
        seeds = [b"bank", user_account.mint_address.as_ref()],
        bump,
    )]
    pub bank: Account<'info, Bank>,
}
```

## Owner Validation

Always validate that accounts have the expected owner:

```rust
// Token accounts must be owned by the Token Program
#[account(
    associated_token::mint = mint,
    associated_token::authority = user,
)]
pub user_token_account: InterfaceAccount<'info, TokenAccount>,

// System accounts must be owned by System Program
pub system_program: Program<'info, System>,
```

## Custom Validation

Implement custom validation in instruction functions:

```rust
pub fn validate_liquidation(
    user: &User,
    bank: &Bank,
    liquidator: &Pubkey,
) -> Result<()> {
    // Validate user has borrow position
    require!(user.borrowed_amount > 0, LendingError::NoBorrowPosition);
    
    // Validate health factor
    let health_factor = calculate_health_factor(user, bank);
    require!(
        health_factor < bank.liquidation_threshold,
        LendingError::HealthyPosition
    );
    
    // Validate liquidator is not the user
    require!(
        liquidator != &user.owner,
        LendingError::SelfLiquidation
    );
    
    Ok(())
}
```

## Key Takeaways

Anchor constraints provide built-in validation. Cross-account validation
ensures consistency. Owner validation prevents fake accounts. Custom validation
handles complex business logic. Always validate before state changes.
