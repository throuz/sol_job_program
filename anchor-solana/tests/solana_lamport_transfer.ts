import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { BN, web3 } from "@coral-xyz/anchor";

describe("anchor-solana", () => {
  // Configure the client to use the local cluster.
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const dataAccount = anchor.web3.Keypair.generate();
  const wallet = provider.wallet;

  const program = anchor.workspace
    .SolJobProgram 

  it("transferLamports", async () => {
    // Add your test here.
    const val = new BN(10000);
    const tx = await program.methods
      .transferLamports(val)
      .accounts({ dataAccount: dataAccount.publicKey })
      .signers([dataAccount])
      .rpc();
  });
});
