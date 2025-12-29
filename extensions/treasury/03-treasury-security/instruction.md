# Treasury Security Patterns

This stage covers essential security patterns for treasury account management
in your lending protocol. Proper treasury security is critical since these
accounts hold user funds.

## Treasury Access Control

Only specific program instructions should be able to transfer tokens from
the treasury. This is enforced through PDA signing:

```rust
// WRONG: User can withdraw directly from treasury
let cpi_accounts = TransferChecked {
    from: ctx.accounts.bank_token_account.to_account_info(),
    mint: ctx.accounts.mint.to_account_info(),
    to: ctx.accounts.user_token_account.to_account_info(),
    authority: ctx.accounts.user.to_account_info(),  // User signs - BAD!
};

// CORRECT: Program signs via PDA
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

let cpi_ctx = CpiContext::new_with_signer(
    ctx.accounts.token_program.to_account_info(),
    cpi_accounts,
    signer_seeds,
);
```

## Balance Validation

Always validate that the treasury has sufficient balance before transfers:

```rust
fn validate_liquidity(ctx: &Context<Withdraw>, amount: u64) -> Result<()> {
    let treasury_balance = ctx.accounts.bank_token_account.amount;
    require!(
        treasury_balance >= amount,
        LendingError::InsufficientLiquidity
    );
    Ok(())
}
```

## Reentrancy Protection

Prevent reentrancy attacks that could drain the treasury:

```rust
#[account]
pub struct Bank {
    pub mint_address: Pubkey,
    pub total_deposits: u64,
    pub total_borrows: u64,
    pub is_locked: bool,  // Lock during operations
    pub bump: u8,
}

pub fn complex_operation(ctx: Context<ComplexOp>, amount: u64) -> Result<()> {
    let bank = &mut ctx.accounts.bank;
    
    // Lock the bank
    bank.is_locked = true;
    
    // Perform operations...
    
    // Unlock when done
    bank.is_locked = false;
    
    Ok(())
}
```

## Access Control Lists (ACL)

Implement ACLs for administrative treasury functions:

```rust
#[derive(Accounts)]
pub struct EmergencyWithdraw<'info> {
    #[account(
        seeds = [b"bank", mint.key().as_ref()],
        bump,
    )]
    pub bank: Account<'info, Bank>,
    
    #[account(
        mut,
        seeds = [b"treasury", mint.key().as_ref()],
        bump,
    )]
    pub treasury: InterfaceAccount<'info, TokenAccount>,
    
    // Only admin can call this
    #[account(
        constraint = admin.key() == bank.authority
    )]
    pub admin: Signer<'info>,
}
```

## Audit Trail

Track all treasury movements for auditing:

```rust
#[account]
pub struct TreasuryEvent {
    pub from_treasury: bool,
    pub amount: u64,
    pub user: Pubkey,
    pub timestamp: i64,
    pub event_type: u8,
}
```

## Key Takeaways

PDA signing is mandatory for treasury transfers. Always validate treasury
balance before transfers. Use locking mechanisms to prevent reentrancy.
Implement ACLs for administrative functions. Maintain audit trails for all
treasury movements. Treasury security is paramount for user fund protection.
