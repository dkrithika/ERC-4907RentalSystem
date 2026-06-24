// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4907} from "../Interfaces/IERC4907.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Asset} from "../src/Asset.sol";
import {DeployRentalEscrow} from "../script/RentalEscrow.s.sol";

contract TestAsset is Test {
    Asset public asset;
    DeployRentalEscrow public deployAsset;
    address USER = makeAddr("user");
    address OWNER = makeAddr("owner");
    uint256 TOKEN_ID = 1;

    function setUp() public {
        asset = new Asset();
    }

    function testSetUser() public {
        vm.prank(OWNER);
        asset.mint(OWNER, TOKEN_ID);

        uint64 expires = uint64(block.timestamp + 7 days);
        vm.prank(OWNER);
        asset.setUser(TOKEN_ID, USER, expires);

        emit Asset.UpdateUser(TOKEN_ID, USER, expires);

        assertEq(asset.userOf(TOKEN_ID), USER);
        assertEq(asset.userExpires(TOKEN_ID), expires);
    }

    function testRevertNotApproved() public {
        vm.prank(OWNER);
        asset.mint(OWNER, TOKEN_ID);

        uint64 expires = uint64(block.timestamp + 7 days);
        vm.prank(USER);
        vm.expectRevert(Asset.NotApproved.selector);
        asset.setUser(TOKEN_ID, USER, expires);
    }

    function testRevertInvalidExpiry() public {
        vm.prank(OWNER);
        asset.mint(OWNER, TOKEN_ID);

        uint64 expires = uint64(block.timestamp + 7 days);
        vm.warp(expires + 1);
        vm.prank(OWNER);
        vm.expectRevert(Asset.InvalidExpiry.selector);
        asset.setUser(TOKEN_ID, USER, expires);
    }

    function testZeroAddressWithExpiry() public {
        testSetUser();
        uint64 expires = uint64(block.timestamp + 7 days);
        vm.prank(OWNER);
        vm.expectRevert(Asset.InvalidExpiry.selector);
        asset.setUser(TOKEN_ID, address(0), expires);
    }

    function testUserOf() public {
        vm.prank(OWNER);
        asset.mint(OWNER, TOKEN_ID);

        uint64 expires = uint64(block.timestamp + 7 days);
        vm.prank(OWNER);
        asset.setUser(TOKEN_ID, USER, expires);

        emit Asset.UpdateUser(TOKEN_ID, USER, expires);

        assertEq(asset.userOf(TOKEN_ID), USER);
        assertEq(asset.userExpires(TOKEN_ID), expires);

        asset.userOf(TOKEN_ID);
        assertEq(asset.userOf(TOKEN_ID), USER);
    }

    function testUserOf_returnsZeroAfterExpiry() public {
        testSetUser();
        uint64 expires = uint64(block.timestamp + 7 days);
        vm.warp(expires + 1);
        assertEq(asset.userOf(TOKEN_ID), address(0));
    }

    function testUserExpires() public {
        testSetUser();
        uint64 expires = uint64(block.timestamp + 7 days);
        uint256 returnExpiry = asset.userExpires(TOKEN_ID);

        assertEq(returnExpiry, expires);
    }

    function test_SupportsInterface_ERC4907() public {
        bool supportsERC4907 = asset.supportsInterface(type(IERC4907).interfaceId);
        assertTrue(supportsERC4907);

        bool supportsERC721 = asset.supportsInterface(type(IERC721).interfaceId);
        assertTrue(supportsERC721);
    }

    function testUpdate() public {
        testSetUser();
        address newOwner = makeAddr("newOwner");
        vm.prank(OWNER);
        asset.transferFrom(OWNER, newOwner, TOKEN_ID);
        assertEq(asset.userOf(TOKEN_ID), address(0));
        assertEq(asset.userExpires(TOKEN_ID), 0);
    }
}
