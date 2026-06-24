// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
//////////REMEMBER TO ADD FEES//////////////

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4907} from "../Interfaces/IERC4907.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract RentalEscrow {
    using SafeERC20 for IERC20;
    IERC20 public stablecoin;

    error NotOwner();
    error Alreadylisted();
    error ContractNotApproved();
    error CannotRentAlreadyRenting();
    error NotListed();
    error IncorrectETHRent();
    error NotRenter();
    error RentalIsntExpiredYet();
    error CannotDelistWhileNotListed();
    error CannotDelistWhileRented();

    event ListedNft(address nftAddress, uint256 tokenId, address owner);
    event RentedAnNft(address nftAddress, uint256 tokenId, address user);
    event RentalEnded(address nftAddress, uint256 tokenId, address owner);
    event DelistedNft(address nftAddress, uint256 tokenId, address owner);

    struct Listings {
        address owner;
        uint256 pricePerDay;
        uint256 collateralAmount;
        uint256 tokenId;
        bool isListed;
        uint64 duration;
    }

    struct UserInfo {
        address user;
        bool isRentingNft;
        uint64 expiry;
    }

    mapping(address => mapping(uint256 => Listings)) public listings;
    mapping(address => UserInfo) public userInfo;

    address public immutable stablecoinAddress;

    // address public nft;
    constructor(address _stablecoinAddress) {
        stablecoinAddress = _stablecoinAddress;
        stablecoin = IERC20(_stablecoinAddress);
    }

    function listRental(address nftAddress, uint256 tokenId, uint256 pricePerDay, uint256 collateralAmount) external {
        // Treat provided contract address as ERC721 to interact with NFT methods
        IERC721 nft = IERC721(nftAddress);
        if (nft.ownerOf(tokenId) != msg.sender) revert NotOwner();
        if (listings[nftAddress][tokenId].isListed) revert Alreadylisted();
        if (nft.getApproved(tokenId) != address(this) && !nft.isApprovedForAll(msg.sender, address(this))) {
            revert ContractNotApproved();
        }

        listings[nftAddress][tokenId] = Listings({
            owner: msg.sender,
            pricePerDay: pricePerDay,
            collateralAmount: collateralAmount,
            tokenId: tokenId,
            isListed: true,
            duration: 7 days
        });
        emit ListedNft(nftAddress, tokenId, msg.sender);
    }

    //Renter deposits collateral + starts rental
    function rentNft(uint256 tokenId, address nftAddress) external payable {
        Listings storage listing = listings[nftAddress][tokenId];
        if (userInfo[msg.sender].isRentingNft) revert CannotRentAlreadyRenting();
        if (!listing.isListed) revert NotListed();
        if (msg.value != listing.pricePerDay) revert IncorrectETHRent();
        // if(IERC4907(nftAddress).setUser(tokenId, msg.sender, expiry)) revert AlreadyRented();
        stablecoin.safeTransferFrom(msg.sender, address(this), listing.collateralAmount);

        (bool success,) = payable(listing.owner).call{value: msg.value}("");
        require(success, "Eth transfer failed!");

        uint64 expiry = uint64(block.timestamp + listing.duration);
        IERC4907(nftAddress).setUser(tokenId, msg.sender, expiry);

        userInfo[msg.sender] = UserInfo({user: msg.sender, isRentingNft: true, expiry: expiry});
        emit RentedAnNft(nftAddress, tokenId, userInfo[msg.sender].user);
    }

    //Renter ends rental: gets collateral
    function endRental(uint256 _tokenId, address nftAddress) external {
        Listings storage listing = listings[nftAddress][_tokenId];
        stablecoin = IERC20(stablecoinAddress);
        if (msg.sender != userInfo[msg.sender].user) revert NotRenter();
        if (userInfo[msg.sender].expiry > uint64(block.timestamp)) revert RentalIsntExpiredYet();
        IERC4907(nftAddress).setUser(_tokenId, address(0), 0);
        stablecoin.safeTransfer(msg.sender, listing.collateralAmount);
        userInfo[msg.sender].user = address(0);
        userInfo[msg.sender].isRentingNft = false;
        userInfo[msg.sender].expiry = 0;
        emit RentalEnded(nftAddress, _tokenId, listing.owner);
    }

    function delist(address nftAddress, uint256 tokenId) public {
        Listings storage listing = listings[nftAddress][tokenId];
        if (msg.sender != listing.owner) revert NotOwner();
        if (!listing.isListed) revert CannotDelistWhileNotListed();
        if (IERC4907(nftAddress).userOf(tokenId) != address(0)) revert CannotDelistWhileRented();
        listing.isListed = false;
        emit DelistedNft(nftAddress, tokenId, listing.owner);
    }
}
