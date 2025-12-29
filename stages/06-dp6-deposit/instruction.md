## Implement the Deposit Function

In this stage, you'll implement the deposit function, allowing users to deposit tokens into the lending protocol and earn interest.

## Understanding Deposits

Deposits enable users to:
- Provide liquidity to the protocol
- Earn interest on their deposits
- Use deposits as collateral for borrowing
- Withdraw at any time (subject to available liquidity)

## Share-Based Accounting

When users deposit:
1. Calculate shares: `shares = amount * total_shares / total_deposits`
2. Update user's deposited amount and shares
3. Update bank's total deposits and shares

## Implementation

Add the context and function:

```rust
#[derive(Accounts)]
pub struct Deposit<'info> {
    #[account(mut)]
    pub signer: Signer<'info>,
    pub mint: InterfaceAccount<'info, Mint>,
    #[account(mut, seeds = [mint.key().as_ref()], bump)]  
    pub bank: Account<'info, Bank>,
    #[account(mut, seeds = [b"treasury", mint.key().as_ref()], bump)]  
    pub bank_token_account: InterfaceAccount<'info, TokenAccount>,
    #[account(mut, seeds = [signer.key().as_ref()], bump)]  
    pub user_account: Account<'info, User>,
    #[account(mut, associated_token::mint = mint, associated_token::authority = signer)]  
    pub user_token_account: InterfaceAccount<'info, TokenAccount>, 
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
}

pub fn process_deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
    // Transfer tokens from user to bank
    // Calculate shares
    // Update user and bank state
}
```

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| Token transfer | Tokens moved to bank | Validates CPI transfer |
| Share calculation | Correct shares issued | Confirms share accounting |
| State update | User and bank updated | Verifies state management |
