# 🏛️ Decentralized Autonomous Organization (DAO) Architecture

A complete, standard-compliant DAO governance protocol built with Foundry and OpenZeppelin. This repository implements a fully decentralized execution pipeline, complete with voting power checkpointing, proposal state machines, and mandatory timelock delays to ensure robust protocol security.

Built as a proof-of-work portfolio piece for deep EVM security research and smart contract auditing.

## 🧠 System Architecture

This DAO is separated into three highly specialized modules to isolate logic, prevent flash-loan attacks, and secure the protocol's treasury and administrative rights.

### 1. The Governance Token (`GovToken.sol`)
* **Standard:** ERC-20 with `ERC20Votes` extension (EIP-5805).
* **Security Mechanism:** Implements block-by-block checkpointing. Voting power is not derived from current balances, preventing malicious actors from using flash loans to instantly hijack proposals. Users must explicitly `delegate` their tokens to activate their voting weight.

### 2. The Core Engine (`MyGovernor.sol`)
* **Standard:** OpenZeppelin `Governor` (with QuorumFraction and TimelockControl).
* **Role:** The central state machine. It handles the strict lifecycle of a proposal (Pending -> Active -> Succeeded -> Queued -> Executed). It tracks voting delays, voting periods, and dynamically enforces quorum requirements.

### 3. The Ultimate Vault (`Timelock.sol`)
* **Standard:** `TimelockController`.
* **Security Mechanism:** The `Timelock` holds the `DEFAULT_ADMIN_ROLE` and acts as the true `owner` of the target protocol contracts (e.g., the `Box` contract). It prevents the `Governor` from executing proposals immediately, enforcing a mandatory `MIN_DELAY`. This guarantees the community has time to exit the system if a malicious proposal ever manages to pass.

## 🛠️ Prerequisites

* [Foundry](https://getfoundry.sh/) (Forge, Anvil, Cast)

## 📦 Installation

Clone the repository and install the OpenZeppelin dependencies:

```bash
git clone [https://github.com/spider256-pt/foundry-GoverngenceDAO.git](https://github.com/spider256-pt/foundry-GoverngenceDAO.git)
cd foundry-GoverngenceDAO
forge install

🧪 Testing the Governance State Machine
The test suite (test/MyGovernorTest.t.sol) simulates a complete, end-to-end governance lifecycle. It dynamically queries the contract's configuration to accurately manipulate the blockchain's time and block height (vm.warp and vm.roll), ensuring the proposal strictly adheres to the OpenZeppelin state machine transitions.

Run the test suite to watch a proposal successfully update the target Box contract:

forge test --match-contract TestMyGovernor -vvvv


The Simulated Execution Flow:
Propose: The user creates a proposal to change the Box contract's value. State = Pending (0).

Voting Delay: The blockchain is rolled forward. State = Active (1).

Vote: The user casts a vote with their checkpointed weight.

Voting Period: The blockchain is rolled forward to close the polls. State = Succeeded (4).

Queue: The passed proposal is pushed to the Timelock.

Min Delay: The blockchain is rolled forward past the timelock expiration.

Execute: The Timelock officially executes the payload on the Box contract. State = Executed (7).

🛡️ Audit & Security Focus
This implementation strictly adheres to enterprise security standards:

Separation of Concerns: The Governor counts votes, but the Timelock executes them.

Dynamic Time Queries: Avoidance of hardcoded block delays in testing, binding tests strictly to the on-chain configuration as the definitive Source of Truth.

Access Control: Precise management of PROPOSER_ROLE and EXECUTOR_ROLE to ensure only the Governor can queue, and anyone can execute once the timelock expires.

Focused on the elite horizon of Web3 Security, EVM Architecture & Smart Contract Auditing.
