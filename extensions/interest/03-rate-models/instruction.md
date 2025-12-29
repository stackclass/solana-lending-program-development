# Interest Rate Models

This stage explores different interest rate models used in lending protocols
to balance supply and demand.

## Why Interest Rate Models Matter

Interest rate models determine how rates change based on utilization. Good
models:

- **Encourage Borrowing**: When liquidity is low, higher rates attract suppliers
- **Encourage Supply**: When rates are high, suppliers are rewarded
- **Maintain Liquidity**: Prevent utilization from reaching 100%

## Model 1: Linear Model

Simple linear relationship between utilization and rate:

```
Rate = Base Rate + (Utilization × Slope)
```

```rust
fn get_borrow_rate_linear(
    total_borrows: u64,
    total_deposits: u64,
    base_rate: u64,
    slope: u64,
) -> u64 {
    if total_deposits == 0 {
        return base_rate;
    }
    
    let utilization = (total_borrows as u128 * BASIS_POINTS as u128) 
        / total_deposits as u128;
    
    base_rate + (utilization as u64 * slope / BASIS_POINTS)
}
```

## Model 2: Kinked Model

More complex model with different slopes above and below a utilization kink:

```
Utilization < Kink: Lower slope
Utilization > Kink: Higher slope
```

```rust
fn get_borrow_rate_kinked(
    total_borrows: u64,
    total_deposits: u64,
    base_rate: u64,
    slope_1: u64,
    slope_2: u64,
    kink_utilization: u64,  // e.g., 80% = 8000
) -> u64 {
    if total_deposits == 0 {
        return base_rate;
    }
    
    let utilization = (total_borrows as u128 * BASIS_POINTS as u128) 
        / total_deposits as u128;
    
    if utilization <= kink_utilization as u128 {
        base_rate + (utilization as u64 * slope_1 / BASIS_POINTS)
    } else {
        let before_kink = base_rate + (kink_utilization as u64 * slope_1 / BASIS_POINTS);
        let excess_utilization = utilization as u64 - kink_utilization;
        before_kink + (excess_utilization * slope_2 / BASIS_POINTS)
    }
}
```

## Model 3: Exponential Model

Rate increases exponentially with utilization:

```
Rate = Base Rate × (Utilization / Optimal)^n
```

## Implementing Rate Updates

Update rates on each interaction:

```rust
pub fn update_interest_rate(
    bank: &mut Account<'info, Bank>,
) -> Result<()> {
    let new_rate = get_borrow_rate_kinked(
        bank.total_borrows,
        bank.total_deposits,
        BASE_RATE,
        SLOPE_1,
        SLOPE_2,
        KINK_UTILIZATION,
    );
    
    bank.interest_rate = new_rate;
    Ok(())
}
```

## Key Takeaways

Interest rate models balance supply and demand. Linear models are simple but
less responsive. Kinked models provide better incentives at different utilization
levels. Exponential models can create strong incentives at high utilization.
Rate updates should happen on user interactions.
