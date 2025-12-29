This stage covers SPL (Solana Program Library) tokens, which are the standard
for creating and managing tokens on Solana. Understanding tokens is essential
for building lending protocols that handle deposits and borrows of various
assets.

## What are SPL Tokens

SPL tokens are fungible tokens on Solana, similar to ERC-20 on Ethereum. They
follow a standardized interface and are managed by the Token Program. SPL
tokens can represent anything: stablecoins (USDC, USDT), governance tokens,
or any digital asset.

Key components of SPL tokens:

- **Mint Account**: Defines the token (supply, decimals, metadata)
- **Token Accounts**: Hold token balances for users
- **Token Program**: Manages token operations (transfer, mint, burn)

## Token Mints

A mint account represents a unique token type. It stores:

```rust
pub struct Mint {
    pub supply: u64,           // Total supply of tokens
    pub decimals: u8,          // Decimal places (usually 9 for Solana)
    pub mint_authority: Pubkey, // Who can mint new tokens
    pub freeze_authority: Pubkey, // Who can freeze accounts
}
```

## Token Accounts

Token accounts hold token balances. Each token account is associated with a
specific mint and owner.

```rust
pub struct TokenAccount {
    pub mint: Pubkey,          // Which token this account holds
    pub owner: Pubkey,         // Who controls this account
    pub amount: u64,           // Balance of tokens
    pub delegate: Pubkey,      // Optional delegate
    pub state: AccountState,   // Account state (initialized/frozen)
}
```

## Associated Token Accounts (ATA)

Associated Token Accounts are standardized token accounts derived from a
user's wallet address and a mint. They're the recommended way to store user
tokens.

```typescript
// Finding an ATA address
const ata = await getAssociatedTokenAddress(
    mintAddress,
    userPublicKey
);
```

## Basic Token Operations

The Token Program supports several operations:

**Transfer**: Move tokens from one account to another

**Mint**: Create new tokens (only mint authority can do this)

**Burn**: Destroy tokens (reduces supply)

**Approve/Delegate**: Allow another account to transfer up to a certain amount

## Token Program in Anchor

Anchor provides the `anchor_spl` crate for token operations:

```rust
use anchor_spl::token::{Token, TokenAccount, Transfer};

#[derive(Accounts)]
pub struct Deposit<'info> {
    pub user_token_account: Account<'info, TokenAccount>,
    pub bank_token_account: Account<'info, TokenAccount>,
    pub user: Signer<'info>,
    pub token_program: Program<'info, Token>,
}
```

## Practical Exercise

Review the template's program. Identify the mint account, token accounts, and
how tokens are transferred. Consider how your lending protocol will handle
different token types.

## Key Takeaways

SPL tokens are Solana's standard for fungible tokens. Token accounts store
balances and are associated with specific mints. Associated Token Accounts
(ATAs) provide standardized user token storage. The Token Program handles
all token operations. Understanding tokens is crucial for building lending
protocols that handle deposits and borrows.
