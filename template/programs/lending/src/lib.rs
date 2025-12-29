use anchor_lang::prelude::*;
use instructions::*;

mod state;
mod instructions;
mod error;
mod constants;

declare_id!("CdZeD33fXsAHfZYS8jdxg4qHgXYJwBQ1Bv6GJyETtLST");

#[program]
pub mod lending_protocol {

    use super::*;

    pub fn init_bank(ctx: Context<InitBank>, liquidation_threshold: u64, max_ltv: u64) -> Result<()> {
        // Students will implement this function
        Ok(())
    }

    pub fn init_user(ctx: Context<InitUser>, usdc_address: Pubkey) -> Result<()> {
        // Students will implement this function
        Ok(())
    }

    pub fn deposit (ctx: Context<Deposit>, amount: u64) -> Result<()> {
        // Students will implement this function
        Ok(())
    }

    pub fn withdraw (ctx: Context<Withdraw>, amount: u64) -> Result<()> {
        // Students will implement this function
        Ok(())
    }

    pub fn borrow(ctx: Context<Borrow>, amount: u64) -> Result<()> {
        // Students will implement this function
        Ok(())
    }

    pub fn repay(ctx: Context<Repay>, amount: u64) -> Result<()> {
        // Students will implement this function
        Ok(())
    }

    pub fn liquidate(ctx: Context<Liquidate>) -> Result<()> {
        // Students will implement this function
        Ok(())
    }
}