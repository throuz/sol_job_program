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

  const caseAmountLamports = new anchor.BN(1 * anchor.web3.LAMPORTS_PER_SOL);
  const makerDepositLamports = new anchor.BN(
    0.3 * anchor.web3.LAMPORTS_PER_SOL
  );
  const takerDepositLamports = new anchor.BN(
    0.2 * anchor.web3.LAMPORTS_PER_SOL
  );

  it("This test is for indemnitee maker, case amount: 1 SOL, maker deposit: 0.3 SOL, taker deposit: 0.2 SOL", async () => {
    await requestAirdrop(
      platformAccount.publicKey,
      10 * anchor.web3.LAMPORTS_PER_SOL
    );
    await requestAirdrop(
      makerAccount.publicKey,
      10 * anchor.web3.LAMPORTS_PER_SOL
    );
    await requestAirdrop(
      takerAccount.publicKey,
      10 * anchor.web3.LAMPORTS_PER_SOL
    );
    await checkBalances();
  });

  it("Maker create case", async () => {
    await program.methods
      .new(platformAccount.publicKey, caseAmountLamports, makerDepositLamports)
      .accounts({
        payer: makerAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([makerAccount, dataAccount])
      .rpc();
    await checkBalances();
  });

  it("Taker take case", async () => {
    await program.methods
      .takerTakeCase(takerDepositLamports)
      .accounts({
        signer: takerAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([takerAccount])
      .rpc();
    await checkBalances();
  });

  it("Platform forced case complete", async () => {
    await program.methods
      .platformForcedCaseComplete({ maker: {} })
      .accounts({
        signer: platformAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([platformAccount])
      .rpc();
    await checkBalances();
  });

  it("Maker redemption deposit", async () => {
    await program.methods
      .makerRedemptionDeposit()
      .accounts({
        signer: makerAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([makerAccount])
      .rpc();
    await checkBalances();
  });

  it("Maker receive compensation", async () => {
    await program.methods
      .indemniteeReceiveCompensation()
      .accounts({
        signer: makerAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([makerAccount])
      .rpc();
    await checkBalances();
  });

  it("Platform close case", async () => {
    await program.methods
      .platformCloseCase()
      .accounts({
        signer: platformAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([platformAccount])
      .rpc();
    await checkBalances();
  });
});
