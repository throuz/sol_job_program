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

  it("initiateContract!", async () => {
    // Add your test here.

    const newAuthority = new anchor.web3.PublicKey(anchor.web3.Keypair.generate());
    const tx1 = await program.methods
      .new(newAuthority)
      .accounts({ dataAccount: dataAccount.publicKey })
      .signers([dataAccount])
      .rpc();

    console.log("Your transaction signature", tx1);

    const owerusdtamount = new anchor.BN(10000);
    const expirationtime = new anchor.BN(10000);

    const tx = await program.methods
      .initiateContract(
        newAuthority,
        "requirement",
        owerusdtamount,
        expirationtime
      )
      .accounts({ dataAccount: dataAccount.publicKey })
      .signers([dataAccount])
      .rpc();
    console.log("Your transaction signature", tx);
  });
});
