## Implement the Withdraw Function

In this stage, you'll implement the withdraw function, allowing users to withdraw their deposited tokens from the protocol.

## Understanding Withdrawals

Withdrawals allow users to:
- Remove their deposits from the protocol
- Receive their share of accrued interest
- Must have sufficient deposited shares
- Cannot withdraw more than available liquidity

## Share-Based Withdrawal

When users withdraw:
1. Calculate amount: `amount = shares * total_deposits / total_shares`
2. Transfer tokens from bank to user
3. Update user's deposited amount and shares
4. Update bank's total deposits and shares

## Implementation

Add the context and function:

```rust
#[derive(Accounts)]
pub struct Withdraw<'info> {
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

pub fn process_withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    // Calculate shares to burn
    // Transfer tokens from bank to user
    // Update user and bank state
}
```

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| Share calculation | Correct shares burned | Confirms share accounting |
| Token transfer | Tokens moved to user | Validates CPI transfer |
| Insufficient funds | Error returned | Verifies balance checks |
