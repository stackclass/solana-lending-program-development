## Implement the InitBank Context

In this stage, you'll create the context for initializing a new Bank account. The Bank account represents a lending pool for a specific asset (e.g., SOL or USDC).

## Understanding Bank Initialization

The InitBank context creates a new Bank account that:
- Is a PDA derived from the token mint address
- Stores protocol parameters (LTV, liquidation threshold, etc.)
- Tracks total deposits and borrows
- Enables the protocol to manage one asset

## Prerequisite Reading

- **Anchor Account Constraints**: Read the [Account Constraints Documentation](https://www.anchor-lang.com/docs/references/account-constraints)
- **PDA Derivation**: Learn about PDAs in the [Solana PDA Documentation](https://solana.com/docs/core/pda)

## Implementation

Add the context structure to your program:

```rust
#[derive(Accounts)]
pub struct InitBank<'info> {
    #[account(mut)]
    pub signer: Signer<'info>,
    pub mint: InterfaceAccount<'info, Mint>,
    #[account(
        init, 
        space = 8 + Bank::INIT_SPACE, 
        payer = signer,
        seeds = [mint.key().as_ref()],
        bump, 
    )]
    pub bank: Account<'info, Bank>,
    #[account(
        init, 
        payer = signer,
        seeds = [b"treasury", mint.key().as_ref()],
        bump,
    )]
    pub bank_token_account: InterfaceAccount<'info, TokenAccount>,
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}
```

## Key Components

- **`seeds = [mint.key().as_ref()]`**: Derives Bank PDA from mint address
- **`bank_token_account`**: Treasury account holding deposited tokens
- **`seeds = [b"treasury", mint.key().as_ref()]`**: Derives treasury PDA

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| Context compiles | No syntax errors | Ensures proper Rust syntax |
| PDA derivation | Correct seed structure | Validates secure address derivation |
