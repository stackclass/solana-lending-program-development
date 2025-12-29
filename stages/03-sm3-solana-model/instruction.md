This stage explores Solana's account model, which is fundamentally different
from other blockchain platforms. Understanding accounts is crucial for building
lending protocols that manage user funds securely.

## What is a Solana Account

A Solana account is a record stored on the blockchain that holds data and
lamports (Solana's native token). Every account has several important properties:

- **Address**: A 32-byte public key identifying the account
- **Lamports**: The amount of SOL held by the account (pays for rent and value)
- **Data**: Arbitrary byte array storing program-specific information
- **Owner**: The program that can modify the account's data
- **Executable**: Boolean indicating if the account is a program

```rust
pub struct Account {
    pub lamports: u64,
    pub data: Vec<u8>,
    pub owner: Pubkey,
    pub executable: bool,
    pub rent_epoch: u64,
}
```

## Program Accounts vs Data Accounts

Solana distinguishes between programs and data accounts.

**Program Accounts** are executable accounts that contain compiled bytecode.
When you deploy your lending program, you're creating a program account. Only
the BPF loader can execute programs, and programs can only modify accounts they
own.

**Data Accounts** store state. In a lending protocol, you'll have:
- Bank accounts: Store global protocol state (total deposits, borrows, rates)
- User accounts: Store individual user positions (deposited amount, borrowed amount)

```rust
// This account stores lending protocol state
#[account]
pub struct Bank {
    pub mint_address: Pubkey,
    pub total_deposits: u64,
    pub total_borrows: u64,
    pub interest_rate: u64,
}
```

## Lamports and Rent

Accounts must maintain a minimum lamport balance to remain on-chain, calculated
based on the data size. This is called rent. If an account's balance falls
below the minimum, the account will be deactivated.

```rust
// Calculate minimum rent for an account
let rent = Rent::get()?;
let minimum_balance = rent.minimum_balance(Bank::INIT_SPACE);
```

When you create an account, you must allocate enough lamports to cover rent.
Anchor's `#[account(init)]` handles this automatically with the `payer`
constraint specifying who funds the account.

## Account Ownership

Every account has an owner program. Only the owner can modify the account's
data. This is a crucial security feature—if an account is owned by your lending
program, no other program can manipulate it.

```rust
// During initialization, we specify the program as owner
#[account(
    init,
    payer = user,
    space = 1000,
    seeds = [b"bank", mint.key().as_ref()],
    bump
)]
pub bank: Account<'info, Bank>,
```

## Practical Exercise

Review the Account struct in the template. Think about what data your lending
protocol needs to store. Consider the different types of accounts you'll need
and what information each should contain.

## Key Takeaways

Solana accounts store both data and lamports. Programs are executable accounts
that own data accounts. Account ownership provides security—only the owner can
modify data. Rent ensures accounts maintain minimum balances. Understanding
this model is foundational for building lending protocols.
