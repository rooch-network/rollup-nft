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
        // reference to metadata
        bytes32 metadataId;
    }

    struct Metadata{
        bytes32 id;
        string name;
        string description;
        string image;
        string animation_url;
        string external_url;
        string background_color;
        string youtube_url;
        string[] attributes_key;
        string[] attributes_value; 
    }

    struct Object{
        bytes data;
        address owner;
    }

    function newMetadata(
        string memory name,
        string memory description,
        string memory image,
        string memory animation_url,
        string memory external_url,
        string memory background_color,
        string memory youtube_url,
        string[] memory attributes_key,
        string[] memory attributes_value
    ) internal pure returns(Metadata memory) {
        bytes32 id = keccak256(abi.encodePacked(name, description, image, animation_url, external_url, background_color, youtube_url, attributes_key, attributes_value));
        return Metadata(id, name, description, image, animation_url, external_url, background_color, youtube_url, attributes_key, attributes_value);
    }

    function newERC721(
        address contractAddress,
        uint256 tokenId,
        bytes32 metadataId
    ) internal pure returns(ERC721 memory) {
        bytes32 id = keccak256(abi.encodePacked(contractAddress, tokenId));
        ERC721 memory data = ERC721(id, contractAddress, tokenId, metadataId);
        return data; 
    }

    function newERC721Object(
        ERC721 memory data,
        address owner
    ) internal pure returns(Object memory) {
        return Object(abi.encode(data), owner); 
    }
}