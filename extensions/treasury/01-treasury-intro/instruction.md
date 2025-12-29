# Treasury Introduction

This stage introduces the treasury vault concept for token custody in lending
protocols. Treasuries enable secure escrow where deposited tokens are held
safely until users withdraw or the protocol processes borrows.

## What is a Treasury Vault

A treasury vault is a token account whose authority is a Program Derived
Address rather than a user keypair. When a user deposits tokens into the
treasury, the tokens remain there until the user withdraws or borrows against
them. The protocol acts as an impartial custodian that releases funds only
according to programmed rules.

In a traditional lending platform, the platform holds user funds in its own
wallets. Users must trust the platform to maintain custody and return funds
upon withdrawal. In a decentralized lending protocol, treasuries eliminate
this trust requirement. No single party controls the treasury—only the program
logic can move tokens, and that logic is public and auditable.

For our lending protocol, each token type has an associated treasury holding
the tokens deposited by all users. When users withdraw, tokens move from the
treasury to their wallets. When users borrow, tokens move from the treasury
to their wallets.

## Why Treasuries are Essential

Treasuries provide several critical guarantees for decentralized lending.

**Trustless Custody**: Tokens in a treasury can only be moved according to
program rules. Neither depositors nor borrowers can unilaterally access
funds—the program enforces all conditions.

**Conditional Release**: Tokens are released only when specific conditions
are met. The treasury does not release tokens based on trust but on verifiable
on-chain conditions (sufficient balance, health factor, etc.).

**Auditability**: Anyone can inspect the treasury's balance and the program's
logic. Users can verify that the program will release tokens only under
expected conditions.

**Non-custodial**: The lending program never takes ownership of user tokens.
Tokens move directly between user wallets and the treasury.

## Treasury Architecture

The treasury architecture involves several components.

**Bank Account**: Stores global protocol state including total deposits,
borrows, and interest rates. The bank PDA controls the treasury.

**Treasury Token Account**: Holds actual deposited tokens. The bank PDA is
set as the authority, allowing the program to sign for transfers.

**User Accounts**: Store individual user positions including deposited
amounts and borrowed amounts.

## How Programs Control Treasuries

A treasury is a token account with the bank PDA as its authority:

```rust
#[account(
    init,
    payer = authority,
    associated_token::mint = mint,
    associated_token::authority = bank,  // Bank PDA controls the treasury
    seeds = [b"treasury", mint.key().as_ref()],
    bump,
)]
pub bank_token_account: InterfaceAccount<'info, TokenAccount>,
```

Since the bank is a PDA with no private key, only the program can authorize
transfers from the treasury. The program proves ownership by providing the
PDA's signing seeds during CPI.

## Treasury Lifecycle

A treasury goes through a predictable lifecycle.

**Creation** occurs during bank initialization when the authority sets up
a new lending market. The program creates a token account owned by the bank PDA.

**Depositing** happens when users deposit tokens. The program transfers tokens
from user wallets into the treasury and updates user account balances.

**Withdrawal** occurs when users request their deposited tokens. The program
transfers tokens from the treasury to user wallets.

**Borrowing** releases tokens to borrowers. The treasury decreases while
user debt increases.

**Closing** concludes the treasury when the lending market is deprecated.
All remaining tokens are distributed according to protocol rules.

## Key Takeaways

Treasuries are PDA-controlled token accounts enabling trustless custody. The
bank PDA serves as treasury authority, allowing only program-controlled
transfers. Treasuries hold deposited tokens until program logic authorizes
release. The treasury lifecycle spans creation, depositing, withdrawal,
borrowing, and closing.
