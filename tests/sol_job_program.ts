import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { SolJobProgram } from "../target/types/sol_job_program";

describe("transfer-sol", async () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const wallet = provider.wallet;
  const connection = provider.connection;

  const program = anchor.workspace.SolJobProgram as Program<SolJobProgram>;

  const dataAccount = anchor.web3.Keypair.generate();
  const platformAccount = anchor.web3.Keypair.generate();
  const makerAccount = anchor.web3.Keypair.generate();
  const takerAccount = anchor.web3.Keypair.generate();

  const checkBalances = async () => {
    const getBalance = (publicKey: anchor.web3.PublicKey) => {
      return connection.getBalance(publicKey);
    };
    const dataAccountBalance = await getBalance(dataAccount.publicKey);
    const platformAccountBalance = await getBalance(platformAccount.publicKey);
    const makerAccountBalance = await getBalance(makerAccount.publicKey);
    const takerAccountBalance = await getBalance(takerAccount.publicKey);
    const logBalance = (name: string, balance: number) => {
      console.log(name, balance / anchor.web3.LAMPORTS_PER_SOL);
    };
    logBalance("dataAccountBalance", dataAccountBalance);
    logBalance("platformAccountBalance", platformAccountBalance);
    logBalance("makerAccountBalance", makerAccountBalance);
    logBalance("takerAccountBalance", takerAccountBalance);
  };

  const requestAirdrop = async (
    to: anchor.web3.PublicKey,
    lamports: number
  ) => {
    const airdropSignature = await connection.requestAirdrop(to, lamports);
    const latestBlockHash = await connection.getLatestBlockhash();
    await connection.confirmTransaction({
      blockhash: latestBlockHash.blockhash,
      lastValidBlockHeight: latestBlockHash.lastValidBlockHeight,
      signature: airdropSignature,
    });
  };

  it("Airdrop!", async () => {
    await requestAirdrop(
      platformAccount.publicKey,
      1 * anchor.web3.LAMPORTS_PER_SOL
    );
    await requestAirdrop(
      makerAccount.publicKey,
      1 * anchor.web3.LAMPORTS_PER_SOL
    );
    await requestAirdrop(
      takerAccount.publicKey,
      1 * anchor.web3.LAMPORTS_PER_SOL
    );
    await checkBalances();
  });

  it("initialized!", async () => {
    const budgetLamports = new anchor.BN(0.1 * anchor.web3.LAMPORTS_PER_SOL);
    const securityDepositLamports = new anchor.BN(
      0.03 * anchor.web3.LAMPORTS_PER_SOL
    );
    await program.methods
      .new(platformAccount.publicKey, budgetLamports, securityDepositLamports)
      .accounts({
        payer: makerAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([makerAccount, dataAccount])
      .rpc();
    await checkBalances();
  });

  it("Take case", async () => {
    await program.methods
      .takeCase()
      .accounts({
        signer: takerAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([takerAccount])
      .rpc();
    await checkBalances();
  });

  it("Confirm case complete", async () => {
    await program.methods
      .confirmCaseComplete()
      .accounts({
        signer: makerAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([makerAccount])
      .rpc();
    await checkBalances();
  });

  it("Pay to taker", async () => {
    await program.methods
      .payToTaker()
      .accounts({
        signer: takerAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([takerAccount])
      .rpc();
    await checkBalances();
  });

  it("Close case", async () => {
    await program.methods
      .closeCase()
      .accounts({
        signer: platformAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([platformAccount])
      .rpc();
    await checkBalances();
  });
});
