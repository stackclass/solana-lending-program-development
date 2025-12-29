This stage guides you through implementing the withdraw function, which allows
users to retrieve their deposited tokens from the lending protocol. This is a
core operation that enables users to exit the protocol.

## Understanding Withdrawals

When a user withdraws tokens:

1. The protocol validates the user has sufficient deposited balance
2. Tokens are transferred from the treasury to the user's wallet
3. The user's deposited balance decreases
4. The protocol's total deposits decrease

## Step 1: Define the Withdraw Context

Add the following account structure for withdrawals:

```rust
#[derive(Accounts)]
pub struct Withdraw<'info> {
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
        seeds = [b"treasury", mint.key().as_ref()],
        bump,
    )]
    pub bank_token_account: InterfaceAccount<'info, TokenAccount>,
    
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = user,
    )]
    pub user_token_account: InterfaceAccount<'info, TokenAccount>,
    
    #[account(
        mut,
        seeds = [user.key().as_ref()],
        bump,
    )]
    pub user_account: Account<'info, User>,
    
    pub mint: InterfaceAccount<'info, Mint>,
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}
```

## Step 2: Implement the Withdraw Instruction

Add the withdraw function to your program:

```rust
pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    // Validate sufficient balance
    require!(
        user.deposited_amount >= amount,
        LendingError::InsufficientFunds
    );
    
    // Transfer tokens from bank to user
    let mint_key = ctx.accounts.mint.key();
    let signer_seeds: &[&[&[u8]]] = &[
        &[
            b"treasury",
            mint_key.as_ref(),
            &[ctx.bumps.bank_token_account],
        ],
    ];
    
    let cpi_accounts = TransferChecked {
        from: ctx.accounts.bank_token_account.to_account_info(),
        mint: ctx.accounts.mint.to_account_info(),
        to: ctx.accounts.user_token_account.to_account_info(),
        authority: ctx.accounts.bank_token_account.to_account_info(),
    };
    
    let cpi_program = ctx.accounts.token_program.to_account_info();
    let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts)
        .with_signer(signer_seeds);
    let decimals = ctx.accounts.mint.decimals;
    
    anchor_spl::token_interface::transfer_checked(cpi_ctx, amount, decimals)?;
    
    // Update user state
    user.deposited_amount -= amount;
    
    // Update bank state
    bank.total_deposits -= amount;
    
    Ok(())
}
```

## Step 3: Add Error Codes

Define the error enum for withdrawal validation:

```rust
#[error_code]
pub enum LendingError {
    #[msg("Insufficient funds for withdrawal")]
    InsufficientFunds,
}
```

## Understanding PDA Signing for Withdrawals

Unlike deposits where the user signs, withdrawals require the treasury PDA
to authorize the transfer. This is done through CPI with signer seeds:

```rust
let signer_seeds: &[&[&[u8]]] = &[
    &[
        b"treasury",
        mint_key.as_ref(),
        &[ctx.bumps.bank_token_account],
    ],
];
```

The `with_signer` method provides these seeds to the runtime, proving the
program controls the treasury account.

## Security Considerations

- Always validate withdrawal amount against deposited balance
- Ensure the treasury has sufficient liquidity
- Use PDA signing for treasury authority
- Check for arithmetic underflow (handled by require!)

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| Valid withdrawal | Tokens transferred to user | Validates core functionality |
| Zero amount | Rejected | Prevents spam |
| Excessive amount | Rejected | Prevents over-withdrawal |
| Insufficient liquidity | Rejected | Ensures treasury has funds |

## Key Takeaways

Withdrawals transfer tokens from protocol treasury to user wallets. PDA
signing is required for treasury-authorized transfers. Balance validation
prevents users from withdrawing more than deposited. State updates must
happen atomically with token transfers.
