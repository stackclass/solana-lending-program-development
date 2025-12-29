## Implement the Liquidate Function

In this stage, you'll implement the liquidate function, allowing liquidators to repay undercollateralized loans and receive a bonus.

## Understanding Liquidation

Liquidation protects the protocol by:
- Forcing repayment of risky positions
- Providing incentives to liquidators
- Maintaining protocol solvency
- Preventing bad debt accumulation

## Liquidation Mechanics

When a position is liquidated:
1. Liquidator repays a portion of the borrower's debt
2. Liquidator receives collateral plus a bonus
3. Borrower's position is partially or fully closed
4. Health factor improves

## Implementation

Add the context and function:

```rust
#[derive(Accounts)]
pub struct Liquidate<'info> {
    #[account(mut)] pub liquidator: Signer<'info>,
    pub price_update: Account<'info, PriceUpdateV2>,
    pub collateral_mint: InterfaceAccount<'info, Mint>,
    pub borrowed_mint: InterfaceAccount<'info, Mint>,
    #[account(mut, seeds = [collateral_mint.key().as_ref()], bump)] pub collateral_bank: Account<'info, Bank>,
    #[account(mut, seeds = [b"treasury", collateral_mint.key().as_ref()], bump)] pub collateral_bank_token_account: InterfaceAccount<'info, TokenAccount>,
    #[account(mut, seeds = [borrowed_mint.key().as_ref()], bump)] pub borrowed_bank: Account<'info, Bank>,
    #[account(mut, seeds = [b"treasury", borrowed_mint.key().as_ref()], bump)] pub borrowed_bank_token_account: InterfaceAccount<'info, TokenAccount>,
    #[account(mut, seeds = [liquidator.key().as_ref()], bump)] pub user_account: Account<'info, User>,
    #[account(init_if_needed, payer = liquidator, associated_token::mint = collateral_mint, associated_token::authority = liquidator)] pub liquidator_collateral_token_account: InterfaceAccount<'info, TokenAccount>, 
    #[account(init_if_needed, payer = liquidator, associated_token::mint = borrowed_mint, associated_token::authority = liquidator)] pub liquidator_borrowed_token_account: InterfaceAccount<'info, TokenAccount>, 
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

pub fn process_liquidate(ctx: Context<Liquidate>) -> Result<()> {
    // Get prices from Pyth oracle
    // Calculate health factor
    // Check if health factor < 1
    // Calculate liquidation amount
    // Transfer collateral to liquidator
    // Transfer repayment from liquidator
    // Update user and bank state
}
```

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| Health factor check | Only liquidates undercollateralized | Validates liquidation criteria |
| Bonus calculation | Correct bonus applied | Confirms incentive mechanism |
| Token transfers | Both transfers execute | Validates swap functionality |
