## Implement the Borrow Function

In this stage, you'll implement the borrow function, allowing users to borrow tokens against their deposited collateral.

## Understanding Borrowing

Borrowing enables users to:
- Access liquidity without selling collateral
- Maintain exposure to collateral assets
- Pay interest on borrowed amounts
- Must maintain sufficient collateral (LTV < max_ltv)

## Health Factor and LTV

- **LTV (Loan-to-Value)**: Ratio of borrowed value to collateral value
- **Health Factor**: (Collateral Value * Liquidation Threshold) / Borrowed Value
- **Max LTV**: Maximum LTV allowed for new loans
- **Liquidation Threshold**: LTV at which loans become liquidatable

## Prerequisite Reading

- **Pyth Oracle**: Read the [Pyth Documentation](https://docs.pyth.network/price-feeds)
- **Health Factor**: Learn about health factors in the [Aave Documentation](https://docs.aave.com/risk/liquidity-risk/borrow-health-factor)

## Implementation

Add the context and function:

```rust
#[derive(Accounts)]
pub struct Borrow<'info> {
    #[account(mut)] pub signer: Signer<'info>,
    pub mint: InterfaceAccount<'info, Mint>,
    #[account(mut, seeds = [mint.key().as_ref()], bump)] pub bank: Account<'info, Bank>,
    #[account(mut, seeds = [b"treasury", mint.key().as_ref()], bump)] pub bank_token_account: InterfaceAccount<'info, TokenAccount>,
    #[account(mut, seeds = [signer.key().as_ref()], bump)] pub user_account: Account<'info, User>,
    #[account(init_if_needed, payer = signer, associated_token::mint = mint, associated_token::authority = signer)] pub user_token_account: InterfaceAccount<'info, TokenAccount>, 
    pub price_update: Account<'info, PriceUpdateV2>,
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

pub fn process_borrow(ctx: Context<Borrow>, amount: u64) -> Result<()> {
    // Get prices from Pyth oracle
    // Calculate health factor
    // Check if health factor > 1
    // Calculate shares
    // Transfer tokens from bank to user
    // Update user and bank state
}
```

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| Health factor check | Rejects over-collateralized loans | Validates LTV limits |
| Price oracle | Correct price data | Confirms Pyth integration |
| Token transfer | Tokens moved to user | Validates CPI transfer |
