# Interest Rate Practice

This stage provides practice exercises for implementing complete interest
mechanics in your lending protocol.

## Exercise 1: Interest Accrual on User Operations

Implement interest accrual before each operation:

```rust
pub fn accrue_interest(
    user: &mut Account<'info, User>,
    bank: &Account<'info, Bank>,
) -> Result<()> {
    let current_time = Clock::get()?.unix_timestamp;
    let time_elapsed = current_time - user.last_updated;
    
    if time_elapsed == 0 {
        return Ok(());
    }
    
    let seconds_per_year = 365.25 * 24 * 60 * 60;
    let rate_per_second = bank.interest_rate as f64 
        / BASIS_POINTS as f64 
        / seconds_per_year;
    
    // Accrue borrow interest
    let borrow_interest = (user.borrowed_amount as f64 
        * rate_per_second 
        * time_elapsed as f64) as u64;
    
    user.borrowed_amount += borrow_interest;
    user.last_updated = current_time;
    
    Ok(())
}
```

## Exercise 2: Interest Rate Model Implementation

Implement a kinked interest rate model:

```rust
pub const BASE_RATE: u64 = 500;       // 5%
pub const SLOPE_1: u64 = 1000;        // 10%
pub const SLOPE_2: u64 = 3000;        // 30%
pub const KINK_UTILIZATION: u64 = 8000; // 80%

fn get_borrow_rate(
    total_borrows: u64,
    total_deposits: u64,
) -> u64 {
    if total_deposits == 0 {
        return BASE_RATE;
    }
    
    let utilization = (total_borrows as u128 * BASIS_POINTS as u128) 
        / total_deposits as u128;
    
    if utilization <= KINK_UTILIZATION as u128 {
        BASE_RATE + (utilization as u64 * SLOPE_1 / BASIS_POINTS)
    } else {
        let before_kink = BASE_RATE + (KINK_UTILIZATION * SLOPE_1 / BASIS_POINTS);
        let excess = utilization as u64 - KINK_UTILIZATION;
        before_kink + (excess * SLOPE_2 / BASIS_POINTS)
    }
}
```

## Exercise 3: Complete Borrow with Interest

Implement borrow with interest accrual:

```rust
pub fn borrow(ctx: Context<Borrow>, amount: u64) -> Result<()> {
    let user = &mut ctx.accounts.user_account;
    let bank = &mut ctx.accounts.bank;
    
    // Accrue interest first
    accrue_interest(user, bank)?;
    
    // Check LTV
    let max_borrow = (user.deposited_amount * bank.max_ltv) / 100;
    require!(
        user.borrowed_amount + amount <= max_borrow,
        LendingError::BorrowLimitExceeded
    );
    
    // Transfer tokens
    let signer_seeds: &[&[&[u8]]] = &[
        &[
            b"treasury",
            ctx.accounts.mint.key().as_ref(),
            &[ctx.bumps.bank_token_account],
        ],
    ];
    
    let cpi_accounts = TransferChecked {
        from: ctx.accounts.bank_token_account.to_account_info(),
        mint: ctx.accounts.mint.to_account_info(),
        to: ctx.accounts.user_token_account.to_account_info(),
        authority: ctx.accounts.bank_token_account.to_account_info(),
    };
    
    let cpi_ctx = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts,
    ).with_signer(signer_seeds);
    
    anchor_spl::token_interface::transfer_checked(
        cpi_ctx,
        amount,
        ctx.accounts.mint.decimals,
    )?;
    
    // Update state
    user.borrowed_amount += amount;
    bank.total_borrows += amount;
    
    // Update interest rate based on new utilization
    bank.interest_rate = get_borrow_rate(bank.total_borrows, bank.total_deposits);
    
    Ok(())
}
```

## Requirements

1. Accrue interest on every state-changing operation
2. Update last_updated timestamp
3. Calculate rates based on utilization
4. Use kinked or linear model
5. Update bank interest rate dynamically

## Key Takeaways

Interest must be accrued before state changes. Time elapsed determines accrued
interest. Interest rate models balance supply and demand. Dynamic rates respond
to utilization changes. Proper interest handling is essential for protocol economics.
