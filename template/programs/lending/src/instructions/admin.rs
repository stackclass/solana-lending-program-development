use anchor_lang::prelude::*;
use anchor_spl::token_interface::{ Mint, TokenAccount, TokenInterface };
use crate::state::*;

#[derive(Accounts)]
pub struct InitBank<'info> {
    // Students will complete this struct
}

#[derive(Accounts)]
pub struct InitUser<'info> {
    // Students will complete this struct
}

pub fn process_init_bank(ctx: Context<InitBank>, liquidation_threshold: u64, max_ltv: u64) -> Result<()> {
    // Students will implement this function
    Ok(())
}

pub fn process_init_user(ctx: Context<InitUser>, usdc_address: Pubkey) -> Result<()> {
    // Students will implement this function
    Ok(())
}
