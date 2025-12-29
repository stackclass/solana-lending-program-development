# Bump Seeds and Validation

This stage explains bump seeds, how Anchor automatically handles them, and
how to store and use bump values for PDA signing in your lending protocol.

## What is a Bump Seed

A bump seed is a value from 0-255 that, when combined with other seeds,
produces a PDA address that falls off the Ed25519 curve. Since the derivation
process tries bump values starting from 255 and descending, the "canonical"
bump is typically the highest value that works.

## Anchor's Automatic Bump Handling

Anchor simplifies PDA usage with the `bump` constraint:

```rust
#[account(
    init,
    payer = user,
    space = 1000,
    seeds = [b"bank", mint.key().as_ref()],
    bump  // Anchor finds and stores the bump automatically
)]
pub bank: Account<'info, Bank>,
```

When you use `bump`, Anchor:
1. Calls `find_program_address` to derive the PDA
2. Stores the bump in the account data (8 bytes after discriminator)
3. Makes the bump available via `ctx.bumps.get("bank")`

## Accessing Bumps in Code

You can access stored bumps in your instruction functions:

```rust
pub fn initialize_bank(ctx: Context<InitializeBank>) -> Result<()> {
    let bank = &mut ctx.accounts.bank;
    
    // Access the bump stored by Anchor
    bank.bump = *ctx.bumps.get("bank").unwrap();
    
    Ok(())
}
```

## Using Bumps for PDA Signing

When the treasury needs to sign for token transfers, you use the stored bump:

```rust
let mint_key = ctx.accounts.mint.key();
let bump = ctx.bumps.get("bank_token_account").unwrap();

let signer_seeds: &[&[&[u8]]] = &[
    &[
        b"treasury",
        mint_key.as_ref(),
        &[*bump],
    ],
];

let cpi_ctx = CpiContext::new_with_signer(
    cpi_program,
    cpi_accounts,
    signer_seeds,
);
```

## Why Store the Bump

Storing the bump in your account has several benefits:

1. **Consistency**: The same bump is always used
2. **Efficiency**: No need to recompute the bump
3. **Verification**: Can verify the bump matches derivation

```rust
#[account]
pub struct Bank {
    pub mint_address: Pubkey,
    pub total_deposits: u64,
    pub total_borrows: u64,
    pub bump: u8,  // Store the bump for PDA operations
}
```

## Multiple Bumps in One Instruction

When working with multiple PDAs, you can access each bump:

```rust
#[derive(Accounts)]
pub struct ComplexOperation<'info> {
    #[account(mut, seeds = [b"bank"], bump)]
    pub bank: Account<'info, Bank>,
    
    #[account(mut, seeds = [b"treasury"], bump)]
    pub treasury: Account<'info, TokenAccount>,
    
    #[account(mut, seeds = [user.key().as_ref()], bump)]
    pub user: Account<'info, User>,
}

// In the instruction:
let bank_bump = ctx.bumps.get("bank").unwrap();
let treasury_bump = ctx.bumps.get("treasury").unwrap();
let user_bump = ctx.bumps.get("user").unwrap();
```

## Practical Exercise

Create a lending protocol that uses bump storage for all PDAs. Implement a
function that validates the stored bump matches the derived bump as a security
check.

## Key Takeaways

Bump seeds (0-255) ensure PDAs fall off the Ed25519 curve. Anchor's `bump`
constraint automatically finds and stores the canonical bump. Access bumps via
`ctx.bumps.get("account_name")`. Use stored bumps for consistent PDA signing.
Storing bumps in account data enables verification and efficiency.
