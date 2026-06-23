// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Asset} from "../../src/Asset.sol";
import {RentalEscrow} from "../../src/RentalEscrow.sol";
import {MockStableCoin} from "../../src/MockStableCoin.sol";

contract IntegrationTest is Test{
    Asset public asset;
    RentalEscrow public rental;
    MockStableCoin public mockUsdc;
    address OWNER = makeAddr("owner");
    address RENTER = makeAddr("renter");
    uint256 TOKEN_ID = 1;
    uint256 PRICE = 10 ether;
    uint64 COLLATERAL = 10e6;

    function setUp() public{
         mockUsdc = new MockStableCoin();
         asset = new Asset();
         rental = new RentalEscrow(address(mockUsdc));

         vm.deal(RENTER,100 ether);
         mockUsdc.mint(RENTER, 100e6);

         vm.prank(OWNER);
         asset.mint(OWNER,TOKEN_ID);
         vm.prank(OWNER);
         asset.approve(address(rental),TOKEN_ID);
         vm.prank(OWNER);
         rental.listRental(address(asset),TOKEN_ID,PRICE,COLLATERAL);

         vm.prank(RENTER);
         mockUsdc.approve(address(rental),COLLATERAL);
    }

    function test_IntegrationRentFlow() public{
        vm.prank(RENTER);
        rental.rentNft{value: PRICE}(TOKEN_ID, address(asset));

        assertEq(asset.userOf(TOKEN_ID),RENTER);
        assertEq(mockUsdc.balanceOf(address(rental)),COLLATERAL);
        assertEq(address(OWNER).balance,PRICE);
    }
    function test_IntegrationEndRental() public{
        vm.prank(RENTER);
        rental.rentNft{value: PRICE}(TOKEN_ID, address(asset));

        (address user, bool rentingNFT,uint64 expiry) = rental.userInfo(RENTER);
        vm.warp(expiry + 1);
        vm.prank(RENTER);
        rental.endRental(TOKEN_ID, address(asset));

        assertEq(asset.userOf(TOKEN_ID),address(0));
        assertEq(mockUsdc.balanceOf(RENTER),100e6);
        assertEq(mockUsdc.balanceOf(address(rental)),0);
    }
    function test_IntegrationUSDCTransfers() public{
        uint256 beforeRenter = mockUsdc.balanceOf(RENTER);
        uint256 beforeEscrow = mockUsdc.balanceOf(address(rental));

        vm.prank(RENTER);
        rental.rentNft{value: PRICE}(TOKEN_ID, address(asset));

        assertEq(mockUsdc.balanceOf(RENTER),beforeRenter - COLLATERAL);
        assertEq(mockUsdc.balanceOf(address(rental)),beforeEscrow + COLLATERAL);
    }
   
}