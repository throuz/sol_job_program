// import * as anchor from "@coral-xyz/anchor";
// import { Program } from "@coral-xyz/anchor";
// import { SolJobProgram } from "../target/types/sol_job_program";

// describe("sol_job_program", () => {
//   // Configure the client to use the local cluster.
//   const provider = anchor.AnchorProvider.env();
//   anchor.setProvider(provider);

//   const dataAccount = anchor.web3.Keypair.generate();
//   const wallet = provider.wallet;

//   const program = anchor.workspace
//     .SolJobProgram as Program<SolJobProgram>;

//   it("Is initialized!", async () => {
//     // Add your test here.
//     const tx = await program.methods
//       .new()
//       .accounts({ dataAccount: dataAccount.publicKey })
//       .signers([dataAccount])
//       .rpc();
//     console.log("Your transaction signature", tx);

//     const val1 = await program.methods
//       .get()
//       .accounts({ dataAccount: dataAccount.publicKey })
//       .view();

//     console.log("state", val1);

//     await program.methods
//       .flip()
//       .accounts({ dataAccount: dataAccount.publicKey })
//       .rpc();

//     const val2 = await program.methods
//       .get()
//       .accounts({ dataAccount: dataAccount.publicKey })
//       .view();

//     console.log("state", val2);
//   });
// });

import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { SolJobProgram } from "../target/types/sol_job_program";

describe("sol_job_program", () => {
  // Configure the client to use the local cluster.
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const dataAccount = anchor.web3.Keypair.generate();
  const wallet = provider.wallet;

  const program = anchor.workspace.SolJobProgram as Program<SolJobProgram>;

  it("new!", async () => {
    // Add your test here.

    const tx1 = await program.methods
      .new(wallet.publicKey)
      .accounts({ dataAccount: dataAccount.publicKey })
      .signers([dataAccount])
      .rpc();

    console.log("Your new signature", tx1);
  });
  it("initiateContract!", async () => {
    const owerusdtamount = new anchor.BN(2);
    const expirationtime = new anchor.BN(2);

    const tx = await program.methods
      .initiateContract(
        wallet.publicKey,
        "requirement",
        owerusdtamount,
        expirationtime
      )
      .accounts({ dataAccount: wallet.publicKey })
      // .signers([dataAccount])
      .rpc();
    console.log("Your initiateContract work", tx);
  });
});
