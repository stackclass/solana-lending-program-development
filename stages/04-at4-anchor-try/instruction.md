This stage introduces the Anchor framework, which makes Solana smart contract
development significantly easier and more secure. Anchor provides abstractions
that handle common patterns and reduce the risk of security vulnerabilities.

## What is Anchor

Anchor is a framework for Solana smart contracts that provides:

- **Code Generation**: Automatically handles account serialization/deserialization
- **Account Validation**: Derives and validates accounts through constraints
- **Error Handling**: Simplifies custom error definition
- **IDL Generation**: Creates interface definitions for client interactions

## Program Structure

An Anchor program has several key components:

```rust
use anchor_lang::prelude::*;

declare_id!("YourProgramIdHere1111111111111111111111111");

#[program]
pub mod lending_program {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        // Instruction logic here
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    // Account definitions with constraints
}
```

The `#[program]` module contains your instruction functions. Each function
takes a `Context` and returns a `Result<()>`.

## Account Definitions with #[derive(Accounts)]

The `#[derive(Accounts)]` macro tells Anchor how to validate and deserialize
accounts for an instruction. Each field represents an account, and attributes
specify constraints:

```rust
#[derive(Accounts)]
pub struct InitializeBank<'info> {
    #[account(init, payer = user, space = 1000)]
    pub bank: Account<'info, Bank>,
    
    #[account(mut)]
    pub user: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}
```

Key constraints include:
- `init`: Creates a new account
- `payer`: Specifies who pays for account creation
- `mut`: Marks account as mutable
- `seeds`/`bump`: For PDA derivation

## Account Types

Anchor provides different account wrapper types:

```rust
pub struct Context<'info, T> {
    pub accounts: T,
    pub remaining_accounts: Vec<AccountInfo<'info>>,
    pub program_id: Pubkey,
}

// Common account wrappers:
- Account<'info, T>: Deserializes and validates account data
- AccountInfo: Raw account information
- Signer<'info>: Validates the account signed the transaction
- Program<'info, T>: Validates a program account
```

## Custom Errors

Define custom errors for your lending protocol:

```rust
#[error_code]
pub enum LendingError {
    #[msg("Insufficient collateral for borrowing")]
    InsufficientCollateral,
    
    #[msg("Position is healthy, cannot liquidate")]
    HealthyPosition,
}
```

## Practical Exercise

Review the template's lib.rs file. Identify the program module, instruction
functions, and account structures. Try to understand how each account is
validated and what data it stores.

## Key Takeaways

Anchor simplifies Solana development with powerful abstractions. The `#[program]`
module contains instruction logic. `#[derive(Accounts)]` validates and
deserializes accounts. Constraints like `init`, `mut`, and `seeds` control
account behavior. Custom errors improve debugging and user experience.
