This stage guides you through implementing the deposit function, which allows
users to deposit tokens into your lending protocol. This is the first core
operation users will perform in your lending dApp.

## Understanding Deposits

When a user deposits tokens, several things happen:

1. Tokens are transferred from the user's wallet to the protocol
2. The user's deposited balance in the protocol increases
3. The protocol's total deposits increase
4. The user may now use these deposits as collateral for borrowing

## Step 1: Define the Deposit Context

Add the following account structure to handle deposit transactions:

```rust
#[derive(Accounts)]
pub struct Deposit<'info> {
    #[account(mut)]
    pub user: Signer<'info>,
    
    #[account(
        mut,
        seeds = [b"bank", mint.key().as_ref()],
        bump,
    )]
    pub bank: Account<'info, Bank>,
    
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = user,
    )]
    pub user_token_account: InterfaceAccount<'info, TokenAccount>,
    
    #[account(
        seeds = [b"treasury", mint.key().as_ref()],
        bump,
    )]
    pub bank_token_account: InterfaceAccount<'info, TokenAccount>,
    
    pub mint: InterfaceAccount<'info, Mint>,
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}
```

## Step 2: Implement the Deposit Instruction

Add the deposit function to your program:

```rust
pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    // Transfer tokens from user to bank
    let cpi_accounts = TransferChecked {
        from: ctx.accounts.user_token_account.to_account_info(),
        mint: ctx.accounts.mint.to_account_info(),
        to: ctx.accounts.bank_token_account.to_account_info(),
        authority: ctx.accounts.user.to_account_info(),
    };
    
    let cpi_program = ctx.accounts.token_program.to_account_info();
    let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts);
    let decimals = ctx.accounts.mint.decimals;
    
    anchor_spl::token_interface::transfer_checked(cpi_ctx, amount, decimals)?;
    
    // Update user state
    user.deposited_amount += amount;
    
    // Update bank state
    bank.total_deposits += amount;
    
    Ok(())
}
```

## Step 3: Define the User Account Structure

Add the User account to store individual positions:

```rust
#[account]
#[derive(InitSpace)]
pub struct User {
    pub owner: Pubkey,
    pub deposited_amount: u64,
    pub borrowed_amount: u64,
}
```

## Understanding CPI Transfers

Cross-Program Invocation (CPI) allows your program to call the Token Program:

- `TransferChecked`: Verifies the transfer amount against token account balances
- Requires mint decimals for proper amount validation
- The `authority` must sign the transfer

## Security Considerations

- Validate amount > 0
- Ensure user has sufficient token balance before transfer
- Use `transfer_checked` to prevent amount manipulation

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| Valid deposit | Tokens transferred to bank | Validates core functionality |
| Zero amount | Rejected | Prevents spam |
| Insufficient balance | Rejected | Prevents double-spending |

## Key Takeaways

Deposits transfer tokens from user wallets to the protocol treasury. CPI
(transfers require calling the Token Program. Account state must be updated
atomically with token transfers. Always validate amounts and balances.
