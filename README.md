# ERC4907 Rental System

A decentralized NFT rental application built with Solidity, Foundry, and a minimal ethers.js frontend. The project uses ERC-4907-style user assignments and an escrow-based rental flow that lets owners list NFTs, renters lock collateral, and temporary usage rights be assigned on-chain.
## Features


- 🏠 **List NFTs** - Owners can list their NFTs with daily rent price and collateral
- 🔑 **Rent NFTs** - Users can rent NFTs by paying ETH and depositing USDC collateral
- ⏰ **Time-Controlled Access** - Automatic expiry after rental period (7 days)
- 💰 **Collateral System** - USDC collateral protects lenders against misuse
- 🔄 **End Rental** - Renters get collateral back after expiry
- 🗑️ **Delist** - Owners can remove listings at any time (unless actively rented)
- 📡 **Events** - Complete event emission for frontend tracking
## Tech Stack

- Solidity
- Foundry
- Ethers.js  / HTML-CSS-JS
- Sepolia testnet
- OpenZeppelin

## Architecture

┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ Owner       │────▶│ Asset │────▶│ Rental │
│ (Lender)    │ │ (ERC-4907) │   │ Escrow │
└─────────────┘ └─────────────┘ └─────────────┘
│ │
▼ ▼
┌─────────────┐ ┌─────────────┐
│ User │          │ USDC │
│ (Renter) │      │ (Collateral)│
└─────────────┘ └─────────────┘

## Project Structure

```bash
.
├── Frontend/
├── Interface/
├── lib/
├── script/
├── src/
├── test/
├── foundry.toml
└── README.md
```

## Getting Started

### Prerequisites



- Foundry installed
- Node.js and npm installed
- MetaMask browser wallet
- Sepolia ETH for test transactions
- Environment variables set in `.env`

### Installation


```bash
git clone <your-repo-url>
cd <your-project-folder>
forge install
forge build
```

## Compile and Test

```bash
forge build
forge test -vv
```



```bash
forge coverage
```

## Deployment

Add the exact deployment commands you used. Example:

```bash
forge script script/Asset.s.sol:AssetScript 
  --rpc-url $SEPOLIA_RPC_URL 
  --broadcast

forge script script/RentalEscrow.s.sol:RentalEscrowScript 
  --rpc-url $SEPOLIA_RPC_URL 
  --broadcast
```

## Usage Flow

1. Deploy the NFT contract.
2. Deploy the escrow contract.
3. Mint an NFT (The Nft minted here will be test NFT,If you want to use your own NFT make sure it follows ERC4907 guidlines).
4. List the NFT for rent.
5. Approve stablecoin collateral from the renter wallet.
6. Rent the NFT through the frontend.
7. End the rental
8. Delist the NFT if you want.

## Smart Contract Notes

- Why you chose ERC-4907.
- How rental permissions are assigned and revoked.
- How collateral is handled.
- Known constraints, such as whether one renter can have only one active rental at a time.
- Important validation or security checks.

## Frontend

Describe what the frontend can do:

- Connect wallet
- Set contract address
- Approve token spending
- List NFT
- Rent NFT
- End rental
- Read listing data


## Example Demo

You can add:

- A screenshot of the UI
- Sepolia contract addresses
- A short demo GIF
- Sample transaction hashes

Visuals and examples are often recommended because they make the README easier to understand quickly.[3][2]

## Security Considerations

- NFT must be ERC4907 compatible
- Ownership checks before listing
- Approval checks before transfer
- Rental status checks before delisting
- Input validation for token IDs, price, or collateral
- This isnt supportive of cross-chain interaction,only sepolia

## Future Improvements

- Improve frontend UX
- Add more test coverage for edge cases
- Add protocol fees
- Support multiple concurrent rentals per renter if contract design changes


## License

MIT License

## Contact

Add your details:

- Name: Krithika Damshala
- GitHub: <your-link>

***


# NFT Rental dApp


```

