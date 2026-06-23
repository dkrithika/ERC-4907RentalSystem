// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import {IERC4907} from "../Interfaces/IERC4907.sol";
contract Asset is ERC721, IERC4907 {
    error CantBeZeroAddress();
    error InvalidExpiry();
    error NotApproved();
    //0x7BDbD638FB04Ca306A7B62f2F99A29a25Db2493f
    
    struct UserInfo{
        address user;
        uint64 expiry;
       
    }
    mapping (uint256 => UserInfo) public _user;
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);
    constructor() ERC721("Asset", "AST"){}
    function mint(address to,uint256 tokenId) public{
        _mint(to,tokenId);
    }
    function setUser(uint256 tokenId, address user, uint64 expires) external override{
     address owner = ownerOf(tokenId);
     if(! _isAuthorized(owner,msg.sender,tokenId)){
        revert NotApproved();
     }
      if(user == address(0) && expires != 0){
        revert InvalidExpiry();
     }
    
     if(user != address(0) && expires <= block.timestamp){
        revert InvalidExpiry();
     }
    
     UserInfo storage info = _user[tokenId];
     info.user = user;
     info.expiry = expires;
    
     emit  UpdateUser(tokenId, user, expires);
     
    }
    function userOf(uint256 tokenId) external view override returns(address){
        if(_user[tokenId].expiry >= block.timestamp){
            return _user[tokenId].user;
        }
        return address(0);
    }
    
    function userExpires(uint256 tokenId) external view override returns(uint256){
        return _user[tokenId].expiry;
    }
     function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return interfaceId == type(IERC4907).interfaceId || super.supportsInterface(interfaceId);
    }
     function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address)
    {
        address from = super._update(to, tokenId, auth);

        if (from != to && _user[tokenId].user != address(0)) {
            delete _user[tokenId];
            emit UpdateUser(tokenId, address(0), 0);
        }

        return from;
    }

}