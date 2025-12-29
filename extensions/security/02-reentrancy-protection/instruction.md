# Reentrancy Protection

This stage teaches techniques to prevent reentrancy attacks in your lending
protocol.

## Understanding Reentrancy

Reentrancy allows an attacker to repeatedly call back into your contract
before the original function completes, potentially draining funds.

In Solana, reentrancy is less common than in Ethereum due to the runtime's
parallel execution model, but it can still occur through CPI calls.

## Protection Technique 1: Checks-Effects-Interactions

The standard pattern is to perform all checks, make all state changes, then
make external calls:

```rust
pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    // CHECKS
    require!(amount > 0, LendingError::ZeroAmount);
    require!(
        ctx.accounts.user_account.deposited_amount >= amount,
        LendingError::InsufficientFunds
    );
    
    // EFFECTS
    let user = &mut ctx.accounts.user_account;
    user.deposited_amount -= amount;
    
    let bank = &mut ctx.accounts.bank;
    bank.total_deposits -= amount;
    
    // INTERACTIONS
    let signer_seeds: &[&[&[u8]]] = &[
        &[
            b"treasury",
            ctx.accounts.mint.key().as_ref(),
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

## Protection Technique 2: State Locking

Use a lock flag to prevent reentrancy:

```rust
#[account]
pub struct Bank {
    pub authority: Pubkey,
    pub total_deposits: u64,
    pub total_borrows: u64,
    pub is_locked: bool,  // Reentrancy guard
    pub bump: u8,
}

pub fn complex_operation(ctx: Context<ComplexOp>, amount: u64) -> Result<()> {
    let bank = &mut ctx.accounts.bank;
    
    // Check and set lock
    require!(!bank.is_locked, LendingError::ReentrancyDetected);
    bank.is_locked = true;
    
    // Perform operations...
    
    // Unlock when done
    bank.is_locked = false;
    
    Ok(())
}
```

## Protection Technique 3: Limit External Calls

Minimize external calls and use the most restrictive program possible:

```rust
// Use Token-2022 or Token Interface for better security
pub token_program: Interface<'info, TokenInterface>,

// Avoid arbitrary program calls
```

## Key Takeaways

Reentrancy allows repeated function calls before completion. Always use
checks-effects-interactions pattern. Consider state locking for complex
operations. Minimize external calls. State updates must complete before
external calls.
