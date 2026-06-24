# ERC4907 NFTRental System

A decentralized NFT rental application built with Solidity, Foundry, and a minimal ethers.js frontend. The system allows NFT owners to list ERC-4907-compatible assets for rent, while renters pay ETH for access and lock USDC as collateral. Temporary user rights are assigned on-chain and expire automatically after the rental period.

## Features
- List NFTs with a daily rental price and collateral requirement.
- Rent NFTs by paying ETH and depositing USDC collateral.
- Assign temporary usage rights through ERC-4907-compatible user access.
- Expire rental access automatically after the rental period.
- Return collateral to renters after a completed rental.
- Delist NFTs when they are not actively rented.
- Emit events for frontend tracking and transaction updates.

## Tech Stack

- Solidity
- Foundry
- Ethers.js
- HTML, CSS, JavaScript
- OpenZeppelin
- Sepolia testnet

## Architecture

```text
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ Owner        │─────▶│ Asset        │─────▶│ Rental       │
│ (Lender)     │      │ (ERC-4907)   │      │ Escrow       │
└──────────────┘      └──────────────┘      └──────────────┘
        │                                           │
        │                                           │
        ▼                                           ▼
┌──────────────┐                           ┌──────────────┐
│ User         │                           │ USDC         │
│ (Renter)     │                           │ (Collateral) │
└──────────────┘                           └──────────────┘
```

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
git clone https://github.com/dkrithika/ERC-4907RentalSystem
cd ERC-4907RentalSystem
forge install
forge build
```

## Compile and Test

```bash
forge build
forge test -vv
forge coverage
```


## Deployment

Deploy the NFT contract and escrow contract using Foundry scripts:

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
2. Deploy the rental escrow contract.
3. Mint an NFT. The NFT minted here will be a test NFT. If you want to use your own NFT, make sure it follows ERC-4907 guidelines.
4. List the NFT for rent.
5. Approve stablecoin collateral from the renter wallet.
6. Rent the NFT through the frontend.
7. End the rental.
8. Delist the NFT if you want.

## Design Notes

- ERC-4907 was chosen because it separates ownership from temporary usage rights.
- Rental permissions are assigned by setting a temporary user with an expiry time.
- Access is revoked automatically once the rental period ends.
- USDC collateral is locked in escrow during the rental period and returned after completion.
- The current contract design may limit one renter to one active rental record at a time, depending on how renter state is stored.

## Frontend

- MetaMask wallet connection
- NFT listing with rent and collateral values
- USDC approval for collateral transfers
- NFT rental flow
- Rental ending after expiry
- NFT delisting
- Real-time transaction status updates



## Security Considerations

- NFT must be ERC4907 compatible
- Ownership checks before listing
- Approval checks before transfer
- Rental status checks before delisting
- Input validation for token IDs, price, or collateral
- SafeERC20 for token transfers
- Custom errors for gas efficiency
- Access control (only owner can list/delist)
- Rental period enforcement (cannot end early)
- 94%+ test coverage
- The project is currently deployed only on Sepolia and does not support cross-chain interaction.

## 🏆 Achievements

- ERC-4907 compliant
- 24 unit & integration tests
- 94% branch coverage
- Deployed to Sepolia testnet
- Verified on Etherscan


## Live Demo on Etherscan

[View contract on Etherscan](https://sepolia.etherscan.io/address/0x135ee939aF16Ce33036A965f7Ea65954A75801fb)

## Future Improvements

- Improve frontend UX
- Add more test coverage for edge cases
- Add protocol fees
- Support multiple concurrent rentals per renter if contract design changes
- Add richer listing discovery in the frontend

## License

MIT License

## Contact


- Name: Krithika Damshala
- GitHub: https://github.com/dkrithika


