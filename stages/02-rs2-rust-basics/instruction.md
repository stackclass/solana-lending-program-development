This stage covers the Rust programming language fundamentals that you need
for Solana smart contract development. While Rust is a complex language, we'll
focus on the concepts most relevant to writing secure and efficient on-chain
programs.

## Understanding Rust Ownership

Rust's ownership system is its most distinctive feature and is crucial for
writing safe smart contracts. Every value in Rust has a variable that is called
its owner. When the owner goes out of scope, the value is automatically dropped.

```rust
fn main() {
    let s1 = String::from("hello");  // s1 becomes the owner
    let s2 = s1;                      // Ownership moves to s2
    
    // println!("{}", s1);  // This would cause a compile error!
    println!("{}", s2);  // This works fine
}
```

For smart contracts, this means you need to be careful about how you pass
accounts and data between functions. When you pass a value to a function, you
either move it (transferring ownership) or borrow it (creating a reference).

## Borrowing and References

Instead of taking ownership, you can create references to values. This is called
borrowing. References are immutable by default.

```rust
fn calculate_length(s: &String) -> usize {
    s.len()
}  // s goes out of scope but nothing happens to the String
```

For mutable data, you need mutable references:

```rust
fn modify_string(s: &mut String) {
    s.push_str(", world!");
}
```

In Anchor, you see this pattern frequently with account references:

```rust
pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
    let user = &mut ctx.accounts.user_account;  // Mutable borrow
    user.deposited_amount += amount;
    Ok(())
}
```

## Structs and Methods

Structs allow you to group related data. In lending protocols, you'll define
structs for your account states.

```rust
pub struct Bank {
    pub total_deposits: u64,
    pub total_borrows: u64,
    pub collateral_ratio: u64,
}
```

Methods are functions associated with structs:

```rust
impl Bank {
    pub fn total_assets(&self) -> u64 {
        self.total_deposits + self.total_borrows
    }
}
```

## Enums and Pattern Matching

Enums are perfect for representing different states or error conditions in
your lending protocol.

```rust
pub enum PositionStatus {
    Healthy,
    AtRisk,
    Liquidatable,
}

pub fn check_status(health_factor: u64) -> PositionStatus {
    if health_factor >= 150 {
        PositionStatus::Healthy
    } else if health_factor >= 100 {
        PositionStatus::AtRisk
    } else {
        PositionStatus::Liquidatable
    }
}
```

## Result and Option Types

Rust uses `Result<T, E>` for operations that can fail and `Option<T>` for values
that might be absent. Anchor uses these extensively.

```rust
pub fn get_borrow_amount(user: &User) -> Result<u64> {
    let amount = user.borrowed_amount.ok_or(ErrorCode::NoBorrowPosition)?;
    Ok(amount)
}
```

The `?` operator propagates errors: if the result is an error, return it
immediately; if it's Ok, unwrap the value.

## Practical Exercise

Examine the template's lib.rs file. Identify the struct definitions and
understand what data each field represents. Practice tracing how ownership
moves when accounts are passed to instruction functions.

## Key Takeaways

Rust ownership prevents memory errors at compile time. Understanding ownership
and borrowing is essential for working with Anchor accounts. Result and Option
types provide safe error handling patterns. Structs and enums help organize
your lending protocol's state and logic.
