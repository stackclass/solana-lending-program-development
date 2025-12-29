## Implement the InitUser Context

In this stage, you'll create the context for initializing a new User account. The User account tracks an individual's positions in the lending protocol.

## Understanding User Initialization

The InitUser context creates a new User account that:
- Is a PDA derived from the user's public key
- Tracks the user's deposits and borrows
- Calculates the user's health factor
- Enables the user to interact with the protocol

## Prerequisite Reading

- **Anchor Account Constraints**: Read the [Account Constraints Documentation](https://www.anchor-lang.com/docs/references/account-constraints)
- **PDA Derivation**: Learn about PDAs in the [Solana PDA Documentation](https://solana.com/docs/core/pda)

## Implementation

Add the context structure to your program:

```rust
#[derive(Accounts)]
pub struct InitUser<'info> {
    #[account(mut)]
    pub signer: Signer<'info>,
    #[account(
        init,
        payer = signer, 
        space = 8 + User::INIT_SPACE,
        seeds = [signer.key().as_ref()],
        bump,
    )]
    pub user_account: Account<'info, User>,
    pub system_program: Program <'info, System>,
}
```

## Key Components

- **`seeds = [signer.key().as_ref()]`**: Derives User PDA from user's public key
- **`space = 8 + User::INIT_SPACE`**: Allocates space for User struct
- **One User per wallet**: Each user has exactly one User account

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| Context compiles | No syntax errors | Ensures proper Rust syntax |
| PDA derivation | Correct seed structure | Validates secure address derivation |
