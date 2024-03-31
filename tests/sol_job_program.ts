import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { SolJobProgram } from "../target/types/sol_job_program";
import {
  SystemProgram,
  Transaction,
  sendAndConfirmTransaction,
} from "@solana/web3.js";

describe("transfer-sol", async () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const wallet = provider.wallet;
  const connection = provider.connection;

  const dataAccount = anchor.web3.Keypair.generate();
  const platformAccount = anchor.web3.Keypair.generate();
  const makerAccount = anchor.web3.Keypair.generate();
  const takerAccount = anchor.web3.Keypair.generate();

  const program = anchor.workspace.SolJobProgram as Program<SolJobProgram>;

  const budgetLamports = new anchor.BN(0.1 * anchor.web3.LAMPORTS_PER_SOL);
  const securityDepositLamports = new anchor.BN(
    0.03 * anchor.web3.LAMPORTS_PER_SOL
  );

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
  });

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

  it("Check balances", checkBalances);

  it("initialized!", async () => {
    await program.methods
      .new(budgetLamports, securityDepositLamports)
      .accounts({
        payer: makerAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([dataAccount])
      .rpc();
  });

  it("Check balances", checkBalances);

  it("Take case", async () => {
    await program.methods
      .takeCase()
      .accounts({
        dataAccount: dataAccount.publicKey,
        takerAccount: takerAccount.publicKey,
      })
      .signers([takerAccount])
      .rpc();
  });

  it("Check balances", checkBalances);

  it("Close case", async () => {
    await program.methods
      .closeCase()
      .accounts({
        dataAccount: dataAccount.publicKey,
        platformAccount: platformAccount.publicKey,
        makerAccount: makerAccount.publicKey,
        takerAccount: takerAccount.publicKey,
      })
      .rpc();
  });

  it("Check balances", checkBalances);

  // it("Close case by platform & maker win", async () => {
  //   await program.methods
  //     .closeCaseByPlatform()
  //     .accounts({
  //       platformAccount: platformAccount.publicKey,
  //       winnerAccount: makerAccount.publicKey,
  //     })
  //     .rpc();
  // });

  // it("Check balances", checkBalances);
});
