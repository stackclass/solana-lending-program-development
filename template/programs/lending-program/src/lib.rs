use anchor_lang::prelude::*;

declare_id!("3CtFsp1pYwxuS7hyoNt5iynXtykC5QCozjMiJBya1JEN");

#[program]
pub mod lending_program {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        msg!("Greetings from: {:?}", ctx.program_id);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize {}
