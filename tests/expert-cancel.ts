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
    const logBalance = (name: string, balance: number) => {
      console.log(name, balance / SOL);
    };
    const dataAccountBalance = await getBalance(dataAccount.publicKey);
    const platformAccountBalance = await getBalance(platformAccount.publicKey);
    const expertAccountBalance = await getBalance(expertAccount.publicKey);
    const clientAccountBalance = await getBalance(clientAccount.publicKey);
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

  const caseAmount = 1;
  const expertDeposit = 0.3;
  const clientDeposit = 0.2;
  const caseAmountLamports = new anchor.BN(caseAmount * SOL);
  const expertDepositLamports = new anchor.BN(expertDeposit * SOL);
  const clientDepositLamports = new anchor.BN(clientDeposit * SOL);

  it(`This test is for expert cancel process\n      case amount: ${caseAmount} SOL\n      expert deposit: ${expertDeposit} SOL\n      client deposit: ${clientDeposit} SOL`, async () => {
    await requestAirdrop(platformAccount.publicKey, 10 * SOL);
    await requestAirdrop(expertAccount.publicKey, 10 * SOL);
    await requestAirdrop(clientAccount.publicKey, 10 * SOL);
    await checkBalances();
    console.log("Status: Nothing");
  });

  it("Expert create case", async () => {
    await program.methods
      .new(
        platformAccount.publicKey,
        caseAmountLamports,
        expertDepositLamports,
        clientDepositLamports
      )
      .accounts({
        payer: expertAccount.publicKey,
        dataAccount: dataAccount.publicKey,
      })
      .signers([expertAccount, dataAccount])
      .rpc();
    await checkBalances();
    console.log("Status: Created");
  });

  it("Expert cancel case", async () => {
    await program.methods
      .expertCancelCase()
      .accounts({
        signer: expertAccount.publicKey,
        dataAccount: dataAccount.publicKey,
        DA: dataAccount.publicKey,
      })
      .signers([expertAccount])
      .rpc();
    await checkBalances();
    console.log("Status: Canceled");
  });
});
