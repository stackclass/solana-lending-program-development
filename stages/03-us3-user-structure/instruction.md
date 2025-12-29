With your Bank account structure defined, you now need to create the User account structure to track individual user positions in the lending protocol.

## Understanding User Accounts in Lending Protocols

User accounts track each user's interactions with the lending protocol:
- **Deposits**: How much each user has deposited in each asset
- **Borrows**: How much each user has borrowed from each asset
- **Health Factor**: Whether the user's position is safe or at risk of liquidation
- **Shares**: The user's ownership in the deposit and borrow pools

Each user has one User account that tracks all their positions across different assets.

## Prerequisite Reading

To understand this stage, review:

- **Anchor Account Attributes**: Read the [Account Constraints Documentation](https://www.anchor-lang.com/docs/references/account-constraints) to understand how accounts are defined and managed.
- **Health Factor Calculation**: Learn about health factors in lending protocols in the [Aave Documentation](https://docs.aave.com/risk/liquidity-risk/borrow-health-factor).
- **Multi-Asset Support**: Understand how to track multiple assets in one account in the [Compound Documentation](https://compound.finance/docs/ctokens).
- **Rust Space Calculation**: Learn about `#[derive(InitSpace)]` in the [Anchor Space Calculation Guide](https://www.anchor-lang.com/docs/space).

## Implement the User Account Structure

Add the following structure to your program:

```rust
#[account]
#[derive(InitSpace)]
pub struct User {
    pub owner: Pubkey,
    pub deposited_sol: u64,
    pub deposited_sol_shares: u64,
    pub borrowed_sol: u64,
    pub borrowed_sol_shares: u64,
    pub deposited_usdc: u64,
    pub deposited_usdc_shares: u64,
    pub borrowed_usdc: u64,
    pub borrowed_usdc_shares: u64,
    pub usdc_address: Pubkey,
    pub health_factor: u64,
    pub last_updated: i64,
}
```

## Understanding the Structure

Let's examine each field and its purpose:

### User Identity

- **`owner: Pubkey`**: The user's wallet public key.
  - Uniquely identifies the user
  - Used for PDA derivation and authorization
  - Ensures only the owner can modify their account

### SOL Deposits and Borrows

- **`deposited_sol: u64`**: The actual amount of SOL the user has deposited.
  - Tracks the user's SOL balance in the protocol
  - Used as collateral for borrowing
  - Changes when user deposits or withdraws SOL

- **`deposited_sol_shares: u64`**: The user's share of the SOL deposit pool.
  - Represents ownership in the SOL deposit pool
  - Used to calculate proportional withdrawals
  - Doesn't change with interest (only the underlying value changes)

- **`borrowed_sol: u64`**: The actual amount of SOL the user has borrowed.
  - Tracks the user's SOL debt
  - Used for interest calculations
  - Changes when user borrows or repays SOL

- **`borrowed_sol_shares: u64`**: The user's share of the SOL borrow pool.
  - Represents the user's portion of total SOL borrows
  - Used for calculating interest owed
  - Enables proportional interest distribution

### USDC Deposits and Borrows

- **`deposited_usdc: u64`**: The actual amount of USDC the user has deposited.
  - Tracks the user's USDC balance in the protocol
  - Used as collateral for borrowing
  - Changes when user deposits or withdraws USDC

- **`deposited_usdc_shares: u64`**: The user's share of the USDC deposit pool.
  - Represents ownership in the USDC deposit pool
  - Used to calculate proportional withdrawals
  - Doesn't change with interest

- **`borrowed_usdc: u64`**: The actual amount of USDC the user has borrowed.
  - Tracks the user's USDC debt
  - Used for interest calculations
  - Changes when user borrows or repays USDC

- **`borrowed_usdc_shares: u64`**: The user's share of the USDC borrow pool.
  - Represents the user's portion of total USDC borrows
  - Used for calculating interest owed

### Asset Identification

- **`usdc_address: Pubkey`**: The USDC mint address.
  - Identifies the USDC token
  - Used for token operations and validation
  - Ensures the correct token is used

### Risk Management

- **`health_factor: u64`**: The current health factor of the user's position.
  - Indicates how close the user is to liquidation
  - Health factor > 1: Safe position
  - Health factor < 1: At risk of liquidation
  - Calculated as: Total Collateral / Total Borrowed

### Time Tracking

- **`last_updated: i64`**: Unix timestamp of the last update.
  - Used for calculating interest accrual
  - Enables time-based interest calculations
  - Critical for accurate interest tracking

## Why This Design?

This structure implements several important design principles:

1. **Multi-Asset Tracking**: Tracks positions for both SOL and USDC in one account
2. **Share-Based Accounting**: Uses shares for fair interest distribution
3. **Health Factor Monitoring**: Enables real-time risk assessment
4. **Time-Based Interest**: Timestamp enables accurate interest calculations

## Health Factor Calculation

The health factor is calculated as:

```
Health Factor = (Collateral Value * Liquidation Threshold) / Borrowed Value
```

Where:
- **Collateral Value**: Sum of all deposited assets (converted to a common currency)
- **Borrowed Value**: Sum of all borrowed assets (converted to a common currency)
- **Liquidation Threshold**: The LTV ratio at which liquidation occurs

Example:
- User deposits 1000 USDC (collateral value: 1000 USDC)
- User borrows 500 SOL (borrowed value: 500 SOL)
- SOL price: 1 SOL = 2 USDC (borrowed value: 1000 USDC)
- Liquidation threshold: 80%

```
Health Factor = (1000 * 0.8) / 1000 = 0.8
```

Since health factor < 1, the position is at risk of liquidation.

## Share-Based Accounting Example

Suppose:
- Bank has 1000 SOL total deposits, 100 shares
- User A deposits 100 SOL (10% of total)
- User A receives 10 shares (10% of total shares)

Later, with interest:
- Bank has 1100 SOL total deposits (10% interest)
- User A withdraws: 10/100 * 1100 = 110 SOL
- User A earned 10 SOL interest (10% of their share)

## Multi-Asset Support

This design supports multiple assets (SOL and USDC) in one protocol:
- Users can deposit SOL and borrow USDC
- Users can deposit USDC and borrow SOL
- Cross-collateralization is enabled
- Health factor considers all positions

## Challenge: Scaling to Multiple Assets

**Current Design**: Tracks SOL and USDC separately with dedicated fields.
**Limitation**: Adding more assets requires adding more fields.

**Improved Design**: Use a vector or map to track arbitrary assets:
```rust
pub struct User {
    pub owner: Pubkey,
    pub deposited_assets: Vec<AssetPosition>,
    pub borrowed_assets: Vec<AssetPosition>,
    pub health_factor: u64,
    pub last_updated: i64,
}

pub struct AssetPosition {
    pub mint: Pubkey,
    pub amount: u64,
    pub shares: u64,
}
```

This allows unlimited assets without modifying the User struct.

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| `#[account]` attribute present | Struct is properly annotated | Ensures Anchor recognizes this as an account |
| `#[derive(InitSpace)]` present | Space calculation enabled | Confirms automatic space management |
| All fields present | Correct field types | Validates proper data storage |
| `anchor build` | Compiles successfully | Confirms syntax and structure are correct |
| Space calculation | 8 + 32 + 8*8 + 32 + 8 + 8 = 152 bytes | Verifies correct account size |

## Notes

- The `#[account]` attribute is required for Anchor to properly handle account serialization and deserialization
- `#[derive(InitSpace)]` only works with types that implement the `InitSpace` trait from Anchor
- `Pubkey` is always 32 bytes, `u64` is 8 bytes, and `i64` is 8 bytes
- The discriminator adds 8 bytes to the total account size
- Health factor is typically expressed with 18 decimal places for precision
- Share-based accounting ensures fair interest distribution
- The current design supports two assets (SOL and USDC) but can be extended
- For production protocols, consider using a more scalable design for multi-asset support