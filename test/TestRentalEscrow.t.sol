// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {RentalEscrow} from "../src/RentalEscrow.sol";
import {MockStableCoin} from "../src/MockStableCoin.sol";
import {DeployRentalEscrow} from "../script/RentalEscrow.s.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4907} from "../Interfaces/IERC4907.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Asset} from "../src/Asset.sol";

contract TestRentalEscrow is Test {
    RentalEscrow public rental;
    DeployRentalEscrow public deployRental;
    MockStableCoin public mockUSDC;
    address public OWNER = makeAddr("owner");
    address public USER = makeAddr("user");
    Asset public asset;

    function setUp() public {
        mockUSDC = new MockStableCoin();
        //console.log("Mock deployed at:",address(mockUSDC));
        // 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
        rental = new RentalEscrow(address(mockUSDC));
        //console.log("RentalEscrow deployed at:",address(rental));
        //0x2e234DAe75C793f67A35089C9d99245E1C58470b
        mockUSDC.transfer(USER, 1000 * 10 ** 6);
        asset = new Asset();
    }

    function testRevertNotOwner() public {
        uint256 tokenId = 1;
        uint256 storedPrice = 10 ether;
        uint64 storedCollateralAmount = 10e6;

        vm.startPrank(OWNER);
        asset.mint(address(this), tokenId);
        vm.stopPrank();

        vm.startPrank(USER);
        vm.expectRevert(RentalEscrow.NotOwner.selector);
        rental.listRental(address(asset), tokenId, storedPrice, storedCollateralAmount);
        vm.stopPrank();
    }

    function testRentalListings() public {
        uint256 tokenId = 1;
        uint256 pricePerDay = 10 ether;
        uint256 collateralAmount = 10e6;
        uint64 expectedDuration = 7 days;
        asset.mint(OWNER, tokenId);
        vm.startPrank(OWNER);
        asset.approve(address(rental), tokenId);
        rental.listRental(address(asset), tokenId, pricePerDay, collateralAmount);
        vm.stopPrank();
        (
            address owner,
            uint256 storedRentFee,
            uint256 storedCollateralAmount,
            uint256 storedTokenId,
            bool isListed,
            uint64 storedDuration
        ) = rental.listings(address(asset), tokenId);

        assertEq(owner, OWNER);
        assertEq(storedRentFee, pricePerDay);
        assertEq(storedCollateralAmount, collateralAmount);
        assertEq(storedTokenId, tokenId);
        assertTrue(isListed);
        assertEq(storedDuration, expectedDuration);
    }

    function testRevertAlreadyListed() public {
        uint256 tokenId = 1;
        uint256 storedPrice = 10 ether;
        uint64 storedCollateralAmount = 10e6;
        asset.mint(OWNER, tokenId);

        vm.startPrank(OWNER);
        asset.approve(address(rental), tokenId);

        rental.listRental(address(asset), tokenId, storedPrice, storedCollateralAmount);
        vm.expectRevert(RentalEscrow.Alreadylisted.selector);
        rental.listRental(address(asset), tokenId, storedPrice, storedCollateralAmount);
        vm.stopPrank();
    }

    function testRevertNotApproved() public {
        uint256 tokenId = 1;
        uint256 storedPrice = 10 ether;
        uint64 storedCollateralAmount = 10e6;

        asset.mint(OWNER, tokenId);
        vm.startPrank(OWNER);

        vm.expectRevert(RentalEscrow.ContractNotApproved.selector);
        rental.listRental(address(asset), tokenId, storedPrice, storedCollateralAmount);
        vm.stopPrank();
    }

    function testSuccessApproval() public {
        uint256 tokenId = 1;
        uint256 storedPrice = 10 ether;
        uint64 storedCollateralAmount = 10e6;

        asset.mint(OWNER, tokenId);
        vm.startPrank(OWNER);
        asset.approve(address(rental), tokenId);

        rental.listRental(address(asset), tokenId, storedPrice, storedCollateralAmount);
        vm.stopPrank();
    }

    function testRent() public {
        uint256 tokenId = 1;
        uint256 pricePerDay = 10 ether;
        uint256 collateralAmount = 10e6;

        vm.deal(USER, 20 ether);

        asset.mint(OWNER, tokenId);

        vm.startPrank(OWNER);
        asset.approve(address(rental), tokenId);
        rental.listRental(address(asset), tokenId, pricePerDay, collateralAmount);
        vm.stopPrank();

        uint256 ownerEthBefore = OWNER.balance;
        uint256 contractUsdcBefore = mockUSDC.balanceOf(address(rental));
        uint256 userUsdcBefore = mockUSDC.balanceOf(USER);
        uint256 expectedExpiry = block.timestamp + 7 days;

        vm.startPrank(USER);
        mockUSDC.approve(address(rental), collateralAmount);
        rental.rentNft{value: pricePerDay}(tokenId, address(asset));
        vm.stopPrank();

        {
            (
                address owner,
                uint256 storedRentFee,
                uint256 storedCollateralAmount,
                uint256 storedTokenId,
                bool isListed,
                uint64 storedDuration
            ) = rental.listings(address(asset), tokenId);

            assertEq(owner, OWNER);
            assertEq(storedRentFee, pricePerDay);
            assertEq(storedCollateralAmount, collateralAmount);
            assertEq(storedTokenId, tokenId);
            assertTrue(isListed);
            assertEq(storedDuration, 7 days);
        }

        assertEq(OWNER.balance, ownerEthBefore + pricePerDay);
        assertEq(mockUSDC.balanceOf(address(rental)), contractUsdcBefore + collateralAmount);
        assertEq(mockUSDC.balanceOf(USER), userUsdcBefore - collateralAmount);

        {
            (address storedUser, bool isRentingNft, uint64 storedExpiry) = rental.userInfo(USER);
            assertEq(storedUser, USER);
            assertTrue(isRentingNft);
            assertEq(storedExpiry, expectedExpiry);
        }

        {
            address currentUser = IERC4907(address(asset)).userOf(tokenId);
            uint256 currentExpiry = IERC4907(address(asset)).userExpires(tokenId);
            assertEq(currentUser, USER);
            assertEq(currentExpiry, expectedExpiry);
        }
    }

    function testRevertCannotRentAlreadyRenting() public {
        uint256 tokenId = 1;
        uint256 storedPrice = 10 ether;
        uint64 storedCollateralAmount = 10e6;

        asset.mint(OWNER, tokenId);
        vm.startPrank(OWNER);
        asset.approve(address(rental), tokenId);

        rental.listRental(address(asset), tokenId, storedPrice, storedCollateralAmount);
        vm.stopPrank();

        vm.deal(USER, 50 ether);
        mockUSDC.mint(USER, storedCollateralAmount * 2);
        vm.startPrank(USER);
        mockUSDC.approve(address(rental), storedCollateralAmount);
        vm.stopPrank();

        vm.prank(USER);
        rental.rentNft{value: 10 ether}(tokenId, address(asset));

        vm.prank(USER);
        vm.expectRevert(RentalEscrow.CannotRentAlreadyRenting.selector);
        rental.rentNft{value: 10 ether}(tokenId, address(asset));
    }

    function testRevertNotListed() public {
        uint256 tokenId = 1;
        uint256 storedPrice = 10 ether;
        uint64 storedCollateralAmount = 10e6;

        vm.deal(USER, 50 ether);
        mockUSDC.mint(USER, storedCollateralAmount * 2);
        vm.startPrank(USER);
        mockUSDC.approve(address(rental), storedCollateralAmount);
        vm.stopPrank();

        asset.mint(OWNER, tokenId);
        vm.startPrank(OWNER);
        asset.approve(address(rental), tokenId);
        vm.stopPrank();
        vm.prank(USER);
        vm.expectRevert(RentalEscrow.NotListed.selector);
        rental.rentNft(tokenId, address(asset));
    }

    function testRevertInncorrectEthRent() public {
        uint256 tokenId = 1;
        uint256 storedPrice = 10 ether;
        uint64 storedCollateralAmount = 10e6;

        asset.mint(OWNER, tokenId);
        vm.startPrank(OWNER);
        asset.approve(address(rental), tokenId);

        rental.listRental(address(asset), tokenId, storedPrice, storedCollateralAmount);
        vm.stopPrank();

        vm.deal(USER, 50 ether);
        mockUSDC.mint(USER, storedCollateralAmount * 2);
        vm.startPrank(USER);
        mockUSDC.approve(address(rental), storedCollateralAmount);
        vm.stopPrank();

        vm.expectRevert(RentalEscrow.IncorrectETHRent.selector);
        rental.rentNft(tokenId, address(asset));
    }

    function testEndRental() public {
        uint256 tokenId = 1;
        uint256 pricePerDay = 10 ether;
        uint256 collateralAmount = 10e6;

        vm.deal(USER, 20 ether);

        asset.mint(OWNER, tokenId);

        vm.startPrank(OWNER);
        asset.approve(address(rental), tokenId);
        rental.listRental(address(asset), tokenId, pricePerDay, collateralAmount);
        vm.stopPrank();

        uint256 expectedExpiry = block.timestamp + 7 days;
        vm.startPrank(USER);
        mockUSDC.approve(address(rental), collateralAmount);
        rental.rentNft{value: pricePerDay}(tokenId, address(asset));
        vm.stopPrank();

        uint256 renterUsdcBeforeEnd = mockUSDC.balanceOf(USER);
        uint256 contractUsdcBeforeEnd = mockUSDC.balanceOf(address(rental));

        vm.warp(expectedExpiry + 1);
        vm.prank(USER);
        rental.endRental(tokenId, address(asset));

        assertEq(mockUSDC.balanceOf(USER), renterUsdcBeforeEnd + collateralAmount);
        assertEq(mockUSDC.balanceOf(address(rental)), contractUsdcBeforeEnd - collateralAmount);
        {
            (address storedUser, bool isRentingNft, uint64 storedExpiry) = rental.userInfo(USER);
            assertEq(storedUser, address(0));
            assertFalse(isRentingNft);
            assertEq(storedExpiry, 0);
        }
        {
            address currentUser = IERC4907(address(asset)).userOf(tokenId);
            uint256 currentExpiry = IERC4907(address(asset)).userExpires(tokenId);
            assertEq(currentExpiry, 0);
            assertEq(currentUser, address(0));
        }
    }

    function testRevertNotRenter() public {
        uint256 tokenId = 1;
        uint256 storedPrice = 10 ether;
        uint64 storedCollateralAmount = 10e6;

        asset.mint(OWNER, tokenId);
        vm.startPrank(OWNER);
        asset.approve(address(rental), tokenId);

        rental.listRental(address(asset), tokenId, storedPrice, storedCollateralAmount);
        vm.stopPrank();

        vm.deal(USER, 50 ether);
        mockUSDC.mint(USER, storedCollateralAmount * 2);
        vm.startPrank(USER);
        mockUSDC.approve(address(rental), storedCollateralAmount);
        vm.stopPrank();

        vm.prank(OWNER);
        vm.expectRevert(RentalEscrow.NotRenter.selector);
        rental.endRental(tokenId, address(asset));
    }

    function testRevertRentalIsntExpiredYet() public {
        uint256 tokenId = 1;
        uint256 storedPrice = 10 ether;
        uint64 storedCollateralAmount = 10e6;

        asset.mint(OWNER, tokenId);
        vm.startPrank(OWNER);
        asset.approve(address(rental), tokenId);

        rental.listRental(address(asset), tokenId, storedPrice, storedCollateralAmount);
        vm.stopPrank();

        vm.deal(USER, 50 ether);
        mockUSDC.mint(USER, storedCollateralAmount * 2);
        vm.startPrank(USER);
        mockUSDC.approve(address(rental), storedCollateralAmount);
        rental.rentNft{value: storedPrice}(tokenId, address(asset));
        vm.stopPrank();
        vm.prank(USER);
        vm.expectRevert(RentalEscrow.RentalIsntExpiredYet.selector);
        rental.endRental(tokenId, address(asset));
    }

    function testDelistingNft() public {
        uint256 tokenId = 1;
        uint256 storedPrice = 10 ether;
        uint64 storedCollateralAmount = 10e6;

        asset.mint(OWNER, tokenId);
        vm.startPrank(OWNER);
        asset.approve(address(rental), tokenId);

        rental.listRental(address(asset), tokenId, storedPrice, storedCollateralAmount);
        vm.stopPrank();
        vm.prank(OWNER);
        rental.delist(address(asset), tokenId);
        (,,,, bool isListed, uint64 storedDuration) = rental.listings(address(asset), tokenId);
        assertFalse(isListed);
    }

    function testDelistNft_RevertIfNotListed() public {
        uint256 tokenId = 1;
        uint256 storedPrice = 10 ether;
        uint64 storedCollateralAmount = 10e6;

        asset.mint(OWNER, tokenId);
        vm.startPrank(OWNER);
        asset.approve(address(rental), tokenId);
        rental.listRental(address(asset), tokenId, storedPrice, storedCollateralAmount);
        rental.delist(address(asset), tokenId);
        vm.stopPrank();

        vm.prank(OWNER);
        vm.expectRevert(RentalEscrow.CannotDelistWhileNotListed.selector);
        rental.delist(address(asset), tokenId);
    }

    function testDelistNft_RevertIfNotOwner() public {
        uint256 tokenId = 1;
        uint256 storedPrice = 10 ether;
        uint64 storedCollateralAmount = 10e6;

        vm.startPrank(OWNER);
        asset.mint(address(this), tokenId);
        vm.stopPrank();

        vm.startPrank(USER);
        vm.expectRevert(RentalEscrow.NotOwner.selector);
        rental.delist(address(asset), tokenId);
        vm.stopPrank();
    }

    function testDelistNft_RevertIfRenting() public {
        uint256 tokenId = 1;
        uint256 storedPrice = 10 ether;
        uint64 storedCollateralAmount = 10e6;

        asset.mint(OWNER, tokenId);
        vm.startPrank(OWNER);
        asset.approve(address(rental), tokenId);

        rental.listRental(address(asset), tokenId, storedPrice, storedCollateralAmount);
        vm.stopPrank();

        vm.deal(USER, 50 ether);
        mockUSDC.mint(USER, storedCollateralAmount * 2);
        vm.startPrank(USER);
        mockUSDC.approve(address(rental), storedCollateralAmount);
        rental.rentNft{value: storedPrice}(tokenId, address(asset));
        vm.stopPrank();

        vm.prank(OWNER);
        vm.expectRevert(RentalEscrow.CannotDelistWhileRented.selector);
        rental.delist(address(asset), tokenId);
    }
}
