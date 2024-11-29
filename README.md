# Real Estate Community Token (RECT) Smart Contract

The **Real Estate Community Token (RECT)** is a decentralized smart contract designed for property tokenization and governance. It facilitates secure management of property tokens, voting on proposals, rental income distribution, and community participation with enhanced validation and error handling.

---

## Features

### 1. **Property Tokenization**
- Tokenizes real estate properties into fungible tokens using `real-estate-community-token`.
- Properties are represented by unique IDs, with details such as total value, rental income, management wallet, token supply, and active status.

### 2. **Token Transactions**
- **Purchase Tokens**: Allows users to securely purchase property tokens within the constraints of the available supply.
- **Safe Minting and Transfers**: Ensures secure minting of tokens and transfers using `ft-mint?` and `ft-transfer?`.

### 3. **Voting and Governance**
- **Submit Proposals**: Enables token holders to submit proposals for property management with voting deadlines.
- **Vote on Proposals**: Token holders can cast votes (Yes/No) on active proposals using their voting power (based on token balance).
- **Voting Power Tracking**: Voting power is updated during token transactions.

### 4. **Rental Income Distribution**
- **Distribute Income**: Rental income for a property can be distributed by the management wallet, with validations to ensure secure updates.

### 5. **Block Height Tracking**
- Tracks and updates the current block height to enable time-sensitive voting and governance actions.

### 6. **Enhanced Error Handling**
- A comprehensive set of error codes ensures safe and reliable contract execution. Key error constants include:
  - `err-zero-value` (u106): Value cannot be zero.
  - `err-overflow` (u107): Numeric overflow error.
  - `err-voting-ended` (u108): Voting period has ended.
  - `err-no-voting-power` (u109): Insufficient voting power.
  - `err-invalid-period` (u110): Invalid voting period.
  - `err-property-exists` (u113): Property already exists.
  - `err-property-not-found` (u114): Property not found.

---

## Functions

### **Public Functions**
1. **`create-property-token`**
   - Creates a new property token with specified details.
   - Validates inputs like total value, initial supply, and ensures the property doesn't already exist.

2. **`purchase-tokens`**
   - Allows users to buy property tokens while ensuring proper validation of supply and active status.

3. **`submit-proposal`**
   - Submits a governance proposal for property management, specifying a voting period and description.

4. **`vote-on-proposal`**
   - Enables token holders to vote on proposals using their token balance as voting power.

5. **`distribute-rental-income`**
   - Distributes rental income for a property, managed by the property’s management wallet.

6. **Block Height Management**
   - `increment-block-height`: Simulates block progression.
   - `initialize-block-tracking`: Sets up block tracking for a contract.
   - `update-contract-block-height`: Updates the contract’s block height details.
   - `get-block-height`: Retrieves the current block height.
   - `blocks-passed`: Checks if a specific block count has passed.

### **Read-Only Functions**
- `get-contract-block-height`: Retrieves the tracked block height for the contract.
- `get-block-height`: Retrieves the global block height.
- `blocks-passed`: Verifies if a specific number of blocks have passed since a reference point.

### **Private Functions**
- `check-add`: A helper function to safely add two unsigned integers, preventing overflow errors.

---

## Data Structures

### **Maps**
1. **`properties`**
   - Tracks property details using property IDs.
   - Fields include total value, rental income, management wallet, token supply, and active status.

2. **`block-heights`**
   - Tracks the current and last updated block heights for contracts.

3. **`voting-power`**
   - Tracks the token balance of voters for each property ID.

4. **`property-votes`**
   - Records details of votes on proposals, including yes/no votes, descriptions, and voting deadlines.

### **Data Variables**
- `current-block-height`: Global variable to simulate blockchain height.

---

## Error Codes

| Error Code         | Description                               |
|---------------------|-------------------------------------------|
| `err-zero-value`    | Value cannot be zero.                    |
| `err-overflow`      | Numeric overflow error.                  |
| `err-voting-ended`  | Voting period has ended.                 |
| `err-no-voting-power` | User has no voting power.              |
| `err-invalid-period` | Invalid voting period.                  |
| `err-property-exists` | Property with this ID already exists.  |
| `err-property-not-found` | Property not found.                 |
| `err-unauthorized`  | User is not authorized to perform the action. |

---

## How to Use

### 1. **Deploy the Contract**
- Deploy the RECT contract on the Stacks blockchain.

### 2. **Create a Property Token**
- Use `create-property-token` to tokenize a property by specifying:
  - `property-id`: Unique identifier for the property.
  - `total-value`: Total value of the property in tokens.
  - `initial-supply`: Initial supply of tokens.
  - `management-wallet`: Wallet address for managing property activities.

### 3. **Purchase Tokens**
- Use `purchase-tokens` to buy property tokens, ensuring sufficient supply is available.

### 4. **Submit Proposals**
- Token holders can call `submit-proposal` to propose property management actions, specifying:
  - `property-id`: ID of the property.
  - `description`: Description of the proposal (max 500 characters).
  - `voting-period`: Duration of the voting process.

### 5. **Vote on Proposals**
- Token holders can call `vote-on-proposal` to vote (Yes/No) on active proposals.

### 6. **Distribute Rental Income**
- Property managers can distribute rental income using `distribute-rental-income`.

---

## Security Features
- **Error Handling**: Comprehensive error codes ensure safety during contract execution.
- **Overflow Prevention**: Arithmetic operations are safeguarded against overflow using `check-add`.
- **Access Control**: Ensures only the contract owner or authorized wallets can perform critical actions.

---

## License

This contract is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---
