import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { Solva } from "../target/types/solva";

describe("transfer-sol", async () => {
  const SOL = anchor.web3.LAMPORTS_PER_SOL;

  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const wallet = provider.wallet;
  const connection = provider.connection;

  const program = anchor.workspace.Solva as Program<Solva>;

  const dataAccount = anchor.web3.Keypair.generate();
  const platformAccount = anchor.web3.Keypair.generate();
  const expertAccount = anchor.web3.Keypair.generate();
  const clientAccount = anchor.web3.Keypair.generate();

  const checkBalances = async () => {
    const getBalance = (publicKey: anchor.web3.PublicKey) => {
      return connection.getBalance(publicKey);
    };
    const dataAccountBalance = await getBalance(dataAccount.publicKey);
    const platformAccountBalance = await getBalance(platformAccount.publicKey);
    const expertAccountBalance = await getBalance(expertAccount.publicKey);
    const clientAccountBalance = await getBalance(clientAccount.publicKey);
    const logBalance = (name: string, balance: number) => {
      console.log(name, balance / SOL);
    };
    logBalance("dataAccountBalance", dataAccountBalance);
    logBalance("platformAccountBalance", platformAccountBalance);
    logBalance("expertAccountBalance", expertAccountBalance);
    logBalance("clientAccountBalance", clientAccountBalance);
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

  const caseAmountLamports = new anchor.BN(1 * SOL);
  const expertDepositLamports = new anchor.BN(0.3 * SOL);
  const clientDepositLamports = new anchor.BN(0.2 * SOL);

  it("This test is for normal process, case amount: 1 SOL, expert deposit: 0.3 SOL, client deposit: 0.2 SOL", async () => {
    await requestAirdrop(platformAccount.publicKey, 10 * SOL);
    await requestAirdrop(expertAccount.publicKey, 10 * SOL);
    await requestAirdrop(clientAccount.publicKey, 10 * SOL);
    await checkBalances();
  });

  it("Expert create case", async () => {
    await program.methods
      .new(platformAccount.publicKey, caseAmountLamports, expertDepositLamports)
      .accounts({
        payer: expertAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([expertAccount, dataAccount])
      .rpc();
    await checkBalances();
  });

  it("Client take case", async () => {
    await program.methods
      .clientTakeCase(clientDepositLamports)
      .accounts({
        signer: clientAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([clientAccount])
      .rpc();
    await checkBalances();
  });

  it("Expert confirm case complete", async () => {
    await program.methods
      .expertConfirmCaseComplete()
      .accounts({
        signer: expertAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([expertAccount])
      .rpc();
    await checkBalances();
  });

  it("Client get income", async () => {
    await program.methods
      .clientGetIncome()
      .accounts({
        signer: clientAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([clientAccount])
      .rpc();
    await checkBalances();
  });

  it("Expert redemption deposit", async () => {
    await program.methods
      .expertRedemptionDeposit()
      .accounts({
        signer: expertAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([expertAccount])
      .rpc();
    await checkBalances();
  });

  it("Client redemption deposit", async () => {
    await program.methods
      .clientRedemptionDeposit()
      .accounts({
        signer: clientAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([clientAccount])
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
