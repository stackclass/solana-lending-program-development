## Implement the Repay Function

In this stage, you'll implement the repay function, allowing users to repay their borrowed tokens and reduce their debt.

## Understanding Repayment

Repayment allows users to:
- Reduce their debt and interest obligations
- Improve their health factor
- Avoid liquidation
- Partially or fully repay loans

## Implementation

Add the context and function:

```rust
#[derive(Accounts)]
pub struct Repay<'info> {
    #[account(mut)] pub signer: Signer<'info>,
    pub mint: InterfaceAccount<'info, Mint>,
    #[account(mut, seeds = [mint.key().as_ref()], bump)] pub bank: Account<'info, Bank>,
    #[account(mut, seeds = [b"treasury", mint.key().as_ref()], bump)] pub bank_token_account: InterfaceAccount<'info, TokenAccount>,
    #[account(mut, seeds = [signer.key().as_ref()], bump)] pub user_account: Account<'info, User>,
    #[account(init_if_needed, payer = signer, associated_token::mint = mint, associated_token::authority = signer)] pub user_token_account: InterfaceAccount<'info, TokenAccount>, 
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

pub fn process_repay(ctx: Context<Repay>, amount: u64) -> Result<()> {
    // Transfer tokens from user to bank
    // Calculate shares to burn
    // Update user and bank state
    // Recalculate health factor
}
```

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| Token transfer | Tokens moved to bank | Validates CPI transfer |
| Share calculation | Correct shares burned | Confirms share accounting |
| Over-repay | Error returned | Verifies debt limits |
