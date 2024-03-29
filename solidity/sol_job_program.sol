import "../libraries/system_instruction.sol";

@program_id("D5Y1bmRzxQK8RSTGbxMBHkfa2DEmxZU2qcoiEX1PABeJ")
contract sol_job_program {
    @payer(payer) // payer to create new data account
    constructor() {
        // No data is stored in the account in this example
    }

    // Transfer SOL from one account to another using CPI (Cross Program Invocation) to the System program
    @mutableSigner(sender)
    @mutableAccount(recipient)
    function transferSolWithCpi(uint64 lamports) external {
        // CPI to transfer SOL using "system_instruction" library
        SystemInstruction.transfer(
            tx.accounts.sender.key, tx.accounts.recipient.key, lamports
        );
    }

    // Transfer SOL from program owned account to another address by directly modifying the account data lamports
    // This approach only works for accounts owned by the program itself (ex. the dataAccount created in the constructor)
    @mutableAccount(sender)
    @mutableAccount(recipient)
    function transferSolWithProgram(uint64 lamports) external view {
        AccountInfo from = tx.accounts.sender; // first account must be an account owned by the program
        AccountInfo to = tx.accounts.recipient; // second account must be the intended recipient

        print("From: {:}".format(from.key));
        print("To: {:}".format(to.key));

        from.lamports -= lamports;
        to.lamports += lamports;
    }
}
