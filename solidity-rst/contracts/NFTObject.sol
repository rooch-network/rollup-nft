// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// A object presentation of ERC721 NFT
library NFTObject {

    struct ERC721 {
        //object id
        bytes32 id;
        //contract address
        address contractAddress;
        uint256 tokenId;
    }

    struct ERC721Object{
        ERC721 data;
        address owner;
    }

    function createObject(
        address contractAddress,
        uint256 tokenId,
        address owner
    ) internal pure returns(ERC721Object memory) {
        bytes32 id = keccak256(abi.encodePacked(contractAddress, tokenId));
        ERC721 memory data = ERC721(id, contractAddress, tokenId);
        return ERC721Object(data, owner); 
    }
}