# Account Space Calculation

This stage teaches you how to calculate and optimize account space for your
lending protocol, ensuring efficient rent costs while storing all necessary data.

## Understanding Account Space

Solana accounts pay rent based on the amount of data they store. Properly
calculating space ensures you don't overpay or run out of room for data.

The account space includes:
- 8-byte discriminator (added by Anchor)
- Field data (based on types)
- Padding for alignment

## Manual Space Calculation

For a simple Bank account:

```rust
#[account]
pub struct Bank {
    pub authority: Pubkey,           // 32 bytes
    pub mint_address: Pubkey,        // 32 bytes
    pub total_deposits: u64,         // 8 bytes
    pub total_borrows: u64,          // 8 bytes
    pub interest_rate: u64,          // 8 bytes
    pub liquidation_threshold: u64,  // 8 bytes
    pub max_ltv: u64,                // 8 bytes
    pub last_updated: i64,           // 8 bytes
    pub bump: u8,                    // 1 byte
}

// Manual calculation: 8 (discriminator) + 32 + 32 + 8*6 + 1 = 149 bytes
// Rounded up to nearest 8: 152 bytes
```

## Using InitSpace

Anchor's `InitSpace` derives calculates the required space automatically:

```rust
#[account]
#[derive(InitSpace)]
pub struct Bank {
    pub authority: Pubkey,           // 32 bytes
    pub mint_address: Pubkey,        // 32 bytes
    pub total_deposits: u64,         // 8 bytes
    pub total_borrows: u64,          // 8 bytes
    pub interest_rate: u64,          // 8 bytes
    pub liquidation_threshold: u64,  // 8 bytes
    pub max_ltv: u64,                // 8 bytes
    pub last_updated: i64,           // 8 bytes
    pub bump: u8,                    // 1 byte + 7 padding
}

// InitSpace calculates: 8 + 32 + 32 + 8*6 + 1 + 7 = 152 bytes
```

## Space for Complex Types

String and Vec types require additional space for length prefixes:

```rust
#[account]
#[derive(InitSpace)]
pub struct Bank {
    pub name: String,                // 4 bytes length + content
    pub total_deposits: u64,         // 8 bytes
}

#[account]
#[derive(InitSpace)]
pub struct User {
    pub positions: Vec<Position>,    // 4 bytes length + each position
    pub owner: Pubkey,               // 32 bytes
}
```

## Practical Space Calculation

When initializing accounts, account for the full space:

```rust
#[derive(Accounts)]
pub struct InitBank<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + Bank::INIT_SPACE,  // 8 bytes discriminator + calculated space
        seeds = [b"bank", mint.key().as_ref()],
        bump,
    )]
    pub bank: Account<'info, Bank>,
}
```

## Optimizing Space

Consider these optimization strategies:

1. **Use u64 instead of String where possible**: 8 bytes vs variable length
2. **Minimize Vec usage**: Each Vec has 4-byte overhead
3. **Pack related data**: Group fields to reduce padding
4. **Store only essential data**: Derive calculations when possible

## Key Takeaways

Account space directly affects rent costs. InitSpace simplifies size calculation.
Complex types (String, Vec) require additional space. Proper space allocation
prevents overflow and minimizes costs. Anchor handles discriminator and padding.
