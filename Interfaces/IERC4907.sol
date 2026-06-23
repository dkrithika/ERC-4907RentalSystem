

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title ERC-4907 interface
/// @notice ERC-4907 is an extension of ERC-721 that adds a user role with an expiration time.
interface IERC4907 {
    /// @notice Emitted when the user or expires of an NFT is changed
    /// @param tokenId The NFT id
    /// @param user The address of the assigned user
    /// @param expires The Unix timestamp when user access expires
   // event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice Assign a user to an NFT until a given time
    /// @param tokenId The NFT id
    /// @param user The address allowed to use the NFT
    /// @param expires The Unix timestamp when access expires
    function setUser(uint256 tokenId, address user, uint64 expires) external;

    /// @notice Get the active user of an NFT
    /// @param tokenId The NFT id
    /// @return The current user address, or address(0) if none or expired
    function userOf(uint256 tokenId) external view returns (address);

    /// @notice Get the expiration time of the current user assignment
    /// @param tokenId The NFT id
    /// @return The Unix timestamp when the user assignment expires
    function userExpires(uint256 tokenId) external view returns (uint256);
}