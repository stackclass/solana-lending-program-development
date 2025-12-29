# PDA Derivation for Lending

This stage teaches you how to design and implement PDA derivation schemes for
your lending protocol's various accounts. Proper seed design ensures security
and enables deterministic account addresses.

## Designing PDA Seeds

The seeds used to derive PDAs should be:

- **Unique**: Different accounts should use different seed prefixes
- **Stable**: Seeds should not change over time
- **Minimal**: Use the minimum information needed

For a lending protocol, consider these accounts:

## Bank Account PDA

The bank account represents a lending market for a specific token type.

```rust
#[account(
    init,
    payer = authority,
    space = 8 + Bank::INIT_SPACE,
    seeds = [b"bank", mint.key().as_ref()],
    bump,
)]
pub bank: Account<'info, Bank>,
```

Seeds breakdown:
- `b"bank"`: Static prefix distinguishing bank accounts
- `mint.key().as_ref()`: The token mint, ensuring different banks for different tokens

## User Account PDA

Each user has a position account tracking their deposits and borrows.

```rust
#[account(
    init,
    payer = user,
    space = 8 + User::INIT_SPACE,
    seeds = [user.key().as_ref()],
    bump,
)]
pub user_account: Account<'info, User>,
```

Seeds breakdown:
- `user.key().as_ref()`: The user's wallet address, ensuring one account per user

## Treasury Account PDA

The treasury holds deposited tokens and requires PDA signing authority.

```rust
#[account(
    init,
    payer = authority,
    associated_token::mint = mint,
    associated_token::authority = bank,
    seeds = [b"treasury", mint.key().as_ref()],
    bump,
)]
pub bank_token_account: InterfaceAccount<'info, TokenAccount>,
```

Seeds breakdown:
- `b"treasury"`: Static prefix for treasury accounts
- `mint.key().as_ref()`: The token mint, matching the bank

## Finding PDAs in Client Code

When interacting with your program, clients need to find PDA addresses:

```typescript
const [bankPDA] = await PublicKey.findProgramAddress(
    [Buffer.from("bank"), mint.toBuffer()],
    programId
);

const [userPDA] = await PublicKey.findProgramAddress(
    [userPublicKey.toBuffer()],
    programId
);
```

## Deriving Multiple Accounts in One Instruction

Some instructions need to work with multiple derived accounts:

```rust
#[derive(Accounts)]
pub struct Liquidate<'info> {
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
        seeds = [liquidator.key().as_ref()],
        bump,
    )]
    pub user_account: Account<'info, User>,
}
```

## Practical Exercise

Design a PDA scheme for a multi-asset lending protocol. Consider how you would
handle:
- Multiple collateral types
- User positions across different markets
- Protocol-wide settings accounts

## Key Takeaways

PDA seeds should be unique, stable, and minimal. Bank accounts use mint as seed.
User accounts use wallet address as seed. Treasury accounts use mint for
differentiation. Client code must derive the same PDAs to interact with accounts.
