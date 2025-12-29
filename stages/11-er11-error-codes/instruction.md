## Implement Custom Error Codes

In this stage, you'll implement custom error codes for your lending program to provide clear feedback when operations fail.

## Error Types

Define errors for common failure scenarios:
- Over LTV: Borrowing exceeds maximum LTV
- Under collateralized: Position is at risk
- Insufficient funds: Not enough tokens for operation
- Over repay: Repaying more than borrowed
- Over borrowable: Borrowing more than available
- Not undercollateralized: Attempting to liquidate safe position

## Implementation

Add the error enum:

```rust
#[error_code]
pub enum ErrorCode {
    #[msg("Borrowed amount exceeds the maximum LTV.")]
    OverLTV,
    #[msg("Borrowed amount results in an under collateralized loan.")]
    UnderCollateralized,
    #[msg("Insufficient funds to withdraw.")]
    InsufficientFunds,
    #[msg("Attempting to repay more than borrowed.")]
    OverRepay,
    #[msg("Attempting to borrow more than allowed.")]
    OverBorrowableAmount,
    #[msg("User is not undercollateralized.")]
    NotUndercollateralized,
}
```

## Test Cases

| Test | Expected Result | Purpose |
|------|-----------------|---------|
| Error enum compiles | No syntax errors | Ensures proper Rust syntax |
| Error messages | Clear user feedback | Validates descriptive messaging |
