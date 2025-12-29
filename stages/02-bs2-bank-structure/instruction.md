Now that your development environment is ready, you'll design the core data structure for your lending protocol. In Solana, all data is stored in accounts, so designing an efficient account structure is crucial for building a decentralized lending protocol.

## Understanding Lending Protocols

A lending protocol allows users to:
- **Deposit assets**: Provide liquidity to the protocol and earn interest
- **Borrow assets**: Borrow against deposited collateral
- **Repay loans**: Return borrowed assets plus interest
- **Withdraw deposits**: Remove assets from the protocol

Key concepts in lending protocols:
- **Collateral**: Assets deposited that secure borrowed funds
- **LTV (Loan-to-Value)**: Ratio of borrowed value to collateral value
- **Liquidation**: Forcing repayment when collateral value drops
- **Interest**: Cost of borrowing, earnings for depositors

## Prerequisite Reading

To understand this stage, review these key concepts:

- **Anchor Account Attributes**: Learn how Anchor simplifies account management with the `#[account]` attribute. Read the [Account Constraints Documentation](https://www.anchor-lang.com/docs/references/account-constraints) to understand how accounts are defined and managed.
- **Share-Based Accounting**: Understand how lending protocols use shares to track deposits and borrows. Review the [DeFi Share Accounting Guide](https://docs.aave.com/developers/governance/shares) for the standard approach.
- **LTV and Liquidation**: Learn about loan-to-value ratios and liquidation in the [Aave Documentation](https://docs.aave.com/risk/asset-risk/liquidation-threshold).
- **Rust Space Calculation**: Learn about `#[derive(InitSpace)]` in the [Anchor Space Calculation Guide](https://www.anchor-lang.com/docs/space) to understand automatic account space management.

## Implement the Bank Account Structure

Add the following structure to your program:

```rust
#[account]
#[derive(InitSpace)]
pub struct Bank {
    pub authority: Pubkey,
    pub mint_address: Pubkey,
    pub total_deposits: u64,
    pub total_deposit_shares: u64,
    pub total_borrowed: u64,
    pub total_borrowed_shares: u64,
    pub liquidation_threshold: u64,
    pub liquidation_bonus: u64,
    pub liquidation_close_factor: u64,
    pub max_ltv: u64,
    pub last_updated: i64,
    pub interest_rate: u64,
}
```

## Understanding the Structure

Let's examine each field and why it's necessary:

### Core Identity

- **`authority: Pubkey`**: The admin who can modify bank parameters.
  - Allows protocol governance and parameter adjustments
  - Enables emergency interventions if needed
  - Critical for protocol security and upgrades

- **`mint_address: Pubkey`**: The token mint this bank manages.
  - Identifies which token this bank handles (SOL, USDC, etc.)
  - Enables multi-asset lending protocols
  - Ensures type safety in token operations

### Deposit Tracking (Share-Based Accounting)

- **`total_deposits: u64`**: The actual amount of tokens deposited in the bank.
  - Represents the total token balance held by the bank
  - Changes when users deposit or withdraw
  - Used for calculating interest

- **`total_deposit_shares: u64`**: The total number of deposit shares issued.
  - Represents ownership in the deposit pool
  - Used to calculate each user's share of the pool
  - Enables proportional withdrawals

**Why Share-Based Accounting?**
- When users deposit, they receive shares proportional to their deposit
- Shares don't change with interest (only the underlying value changes)
- When withdrawing, users get `user_shares / total_shares * total_deposits`
- This ensures fair distribution of interest among all depositors

### Borrow Tracking (Share-Based Accounting)

- **`total_borrowed: u64`**: The actual amount of tokens currently borrowed.
  - Represents total outstanding loans
  - Changes when users borrow or repay
  - Used for calculating interest owed

- **`total_borrowed_shares: u64`**: The total number of borrow shares issued.
  - Represents ownership in the borrow pool
  - Used to calculate each user's share of total borrows
  - Enables proportional interest calculations

### Liquidation Parameters

- **`liquidation_threshold: u64`**: The LTV ratio at which loans become liquidatable.
  - Example: 80% means loans become liquidatable when borrowed value is 80% of collateral value
  - Expressed as a percentage (80 = 80%)
  - Protects the protocol from bad debt

- **`liquidation_bonus: u64`**: Bonus percentage of collateral that liquidators receive.
  - Example: 5% means liquidators get 105% of the borrowed value
  - Incentivizes liquidators to act quickly
  - Covers the cost and risk of liquidation

- **`liquidation_close_factor: u64`**: Percentage of collateral that can be liquidated at once.
  - Example: 50% means only half can be liquidated in one transaction
  - Prevents complete liquidation of positions
  - Gives borrowers time to add more collateral

### Borrowing Parameters

- **`max_ltv: u64`**: Maximum LTV ratio allowed for new loans.
  - Example: 75% means users can borrow up to 75% of their collateral value
  - Must be lower than liquidation_threshold (provides safety buffer)
  - Prevents users from immediately becoming liquidatable

### Time and Interest

- **`last_updated: i64`**: Unix timestamp of the last update.
  - Used for calculating interest accrual
  - Enables time-based interest calculations
  - Critical for accurate interest tracking

- **`interest_rate: u64`**: The interest rate for borrowing (expressed as basis points).
  - Example: 500 = 5% annual interest rate
  - Applied to borrowed amounts over time
  - Can be adjusted by the authority

## Why This Design?

This structure follows DeFi lending best practices:

1. **Share-Based Accounting**: Fairly distributes interest and handles deposits/borrows proportionally
2. **Multi-Asset Support**: Each bank manages one asset, enabling multi-asset protocols
3. **Liquidation Safety**: Multiple parameters ensure protocol stability and user protection
4. **Governance**: Authority parameter enables protocol upgrades and parameter adjustments
5. **Time-Based Interest**: Timestamp enables accurate interest calculations

## Share-Based Accounting Example

Suppose:
- Bank has 1000 USDC total deposits, 100 shares
- User A deposits 100 USDC (10% of total)
- User A receives 10 shares (10% of total shares)

Later, with interest:
- Bank has 1100 USDC total deposits (10% interest)
- User A withdraws: 10/100 * 1100 = 110 USDC
- User A earned 10 USDC interest (10% of their share)

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| `#[account]` attribute present | Struct is properly annotated | Ensures Anchor recognizes this as an account |
| `#[derive(InitSpace)]` present | Space calculation enabled | Confirms automatic space management |
| All fields present | Correct field types | Validates proper data storage |
| `anchor build` | Compiles successfully | Confirms syntax and structure are correct |
| Space calculation | 8 + 32 + 32 + 8 + 8 + 8 + 8 + 8 + 8 + 8 + 8 + 8 + 8 = 128 bytes | Verifies correct account size |

## Notes

- The `#[account]` attribute is required for Anchor to properly handle account serialization and deserialization
- `#[derive(InitSpace)]` only works with types that implement the `InitSpace` trait from Anchor
- `Pubkey` is always 32 bytes, `u64` is 8 bytes, and `i64` is 8 bytes
- The discriminator adds 8 bytes to the total account size
- `max_ltv` should always be lower than `liquidation_threshold` to provide a safety buffer
- Interest rates are typically expressed in basis points (1 basis point = 0.01%)
- Share-based accounting is the industry standard for DeFi lending protocols