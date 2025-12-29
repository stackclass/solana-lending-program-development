# Treasury Account Creation

This stage teaches you how to create treasury accounts for your lending
protocol, including the specific Anchor constraints needed for proper setup.

## Creating a Treasury with Associated Token

The treasury is an Associated Token Account (ATA) owned by the bank PDA:

```rust
#[derive(Accounts)]
pub struct InitBank<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub mint: InterfaceAccount<'info, Mint>,
    
    #[account(
        init,
        payer = authority,
        space = 8 + Bank::INIT_SPACE,
        seeds = [b"bank", mint.key().as_ref()],
        bump,
    )]
    pub bank: Account<'info, Bank>,
    
    #[account(
        init,
        payer = authority,
        associated_token::mint = mint,
        associated_token::authority = bank,
        seeds = [b"treasury", mint.key().as_ref()],
        bump,
    )]
    pub bank_token_account: InterfaceAccount<'info, TokenAccount>,
    
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}
```

## Understanding Each Constraint

The treasury initialization uses several important constraints:

```rust
#[account(
    init,                                    // Create new account
    payer = authority,                       // Authority pays for creation
    associated_token::mint = mint,           // This is a token account for this mint
    associated_token::authority = bank,      // Bank PDA is the token authority
    seeds = [b"treasury", mint.key().as_ref()],  // PDA derivation seeds
    bump,                                    // Store bump for later signing
)]
pub bank_token_account: InterfaceAccount<'info, TokenAccount>,
```

The `associated_token::authority = bank` constraint is crucial—it sets the
bank PDA as the token account's authority, meaning only the bank can sign
for transfers from this account.

## Initialization Logic

After account creation, initialize the bank state:

```rust
pub fn init_bank(ctx: Context<InitBank>) -> Result<()> {
    let bank = &mut ctx.accounts.bank;
    
    bank.mint_address = ctx.accounts.mint.key();
    bank.authority = ctx.accounts.authority.key();
    bank.total_deposits = 0;
    bank.total_borrows = 0;
    bank.interest_rate = 0;
    bank.bump = *ctx.bumps.get("bank").unwrap();
    
    Ok(())
}
```

## Finding the Treasury in Client Code

Clients need to derive the treasury address:

```typescript
const [treasury] = await PublicKey.findProgramAddress(
    [Buffer.from("treasury"), mint.toBuffer()],
    programId
);
```

## Verifying Treasury Creation

After initialization, you can verify the treasury exists:

```typescript
const treasuryInfo = await connection.getAccountInfo(treasury);
if (treasuryInfo) {
    const tokenAccount = await getTokenAccount(connection, treasury);
    console.log("Treasury balance:", tokenAccount.amount);
}
```

## Multiple Token Support

For a multi-asset protocol, create treasuries for each supported token:

```rust
#[derive(Accounts)]
pub struct AddTokenToBank<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub new_mint: InterfaceAccount<'info, Mint>,
    
    #[account(mut)]
    pub bank: Account<'info, Bank>,
    
    #[account(
        init,
        payer = authority,
        associated_token::mint = new_mint,
        associated_token::authority = bank,
        seeds = [b"treasury", new_mint.key().as_ref()],
        bump,
    )]
    pub new_treasury: InterfaceAccount<'info, TokenAccount>,
    
    // ... programs
}
```

## Key Takeaways

Treasury creation requires `associated_token::authority = bank` to set PDA control.
The PDA must sign all treasury transfers using `with_signer`. Multiple treasuries
can exist for different token types. Client code can derive treasury addresses
deterministically. Proper treasury creation is foundational for protocol security.
