use anchor_lang::prelude::*;
use anchor_spl::token::{self, Token, TokenAccount, Transfer as SplTransfer};
use mpl_token_metadata::types::DataV2;
use solana_program::system_instruction;
declare_id!("6nouU53m9Q6AuKSV5zYwP9aTwPq2xN6Bt9tSvv8yBY2F");

#[derive(Accounts)]
pub struct TransferLamports<'info> {
    #[account(mut)]
    pub from: Signer<'info>,
    #[account(mut)]
    /// CHECK: Requires careful handling to prevent unintended behavior.
    pub to: AccountInfo<'info>,
    pub system_program: Program<'info, System>,
}

#[program]
pub mod sol_job_program {
    use super::*;
    pub fn transfer_lamports(ctx: Context<TransferLamports>, amount: u64) -> Result<()> {
        let from_account = &ctx.accounts.from;
        let to_account = &ctx.accounts.to;
        // Create the transfer instruction
        let transfer_instruction =
            system_instruction::transfer(from_account.key, to_account.key, amount);
        // Invoke the transfer instruction
        msg!(
            "Transferring {} lamports from {} to {}",
            amount,
            from_account.key,
            to_account.key
        );
        anchor_lang::solana_program::program::invoke_signed(
            &transfer_instruction,
            &[
                from_account.to_account_info(),
                to_account.clone(),
                ctx.accounts.system_program.to_account_info(),
            ],
            &[],
        )?;
        Ok(())
    }
}

// #[derive(Accounts)]
// pub struct TransferLamportsSigned<'info> {
//     #[account(mut, signer)]
//     ///CHECK:
//     pub from: AccountInfo<'info>,
//     #[account(mut)]
//     ///CHECK:
//     pub to: AccountInfo<'info>,
//     ///CHECK:
//     pub authority: AccountInfo<'info>,
//     ///CHECK:
//     pub system_program: AccountInfo<'info>,
// }
// pub mod solana_lamport_transfer {
//     use super::*;

//     pub fn transfer_lamports_signed(
//         ctx: Context<TransferLamportsSigned>,
//         amount: u64,
//     ) -> Result<()> {
//         let from_account = &ctx.accounts.from;
//         let to_account = &ctx.accounts.to;
//         let authority_account = &ctx.accounts.authority;

//         // Create the transfer instruction
//         let transfer_instruction =
//             system_instruction::transfer(from_account.key, to_account.key, amount);

//         // Invoke the transfer instruction signed by the authority
//         anchor_lang::solana_program::program::invoke_signed(
//             &transfer_instruction,
//             &[
//                 from_account.clone(),
//                 to_account.clone(),
//                 authority_account.clone(),
//                 ctx.accounts.system_program.clone(),
//             ],
//             &[&[authority_account.key().as_ref()]],
//         )?;

//         Ok(())
//     }
// }
