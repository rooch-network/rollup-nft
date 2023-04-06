// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {SMT} from './SMT.sol';
import {NFTObject} from './NFTObject.sol';
import {IRollupNFT} from './IRollupNFT.sol';
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RollupNFT is ERC721, IRollupNFT  {
    //Offchain State Tree Root
    SMT.OPRU public stateRoot;
    //Is allow update the State Tree offchain
    bool public offchainUpdateable;
    uint256 latestTokenId;
    constructor(string memory name_, string memory symbol_, bool offchainUpdateable_)  ERC721(name_, symbol_) {
        offchainUpdateable = offchainUpdateable_;
        stateRoot = SMT.newOPRU(SMT.PLACE_HOLDER);
        console.log("Deploying a RollupNFT contract");
    }

    function initRoot(bytes32 root, uint256 latestTokenId_) public {
        require(stateRoot.next == SMT.PLACE_HOLDER, "already initialized");
        stateRoot.next = root;
        latestTokenId = latestTokenId_;
        console.log("initRoot, root %s, latestTokenId %s", Strings.toHexString(uint256(root)), latestTokenId_);
    }

    function updateRoot(bytes32 root, uint256 latestTokenId_) public {
        require(offchainUpdateable, "offchain update is not allowed");
        stateRoot.prev = stateRoot.next;
        stateRoot.next = root;
        latestTokenId = latestTokenId_;
    }

    function mint(address) public pure returns (uint256) {
        revert("directly mint is not allowed");
    }

    function mintWithProof(bytes calldata nftObject, bytes calldata inclusionProof) public {
        SMT.Proof memory proof = abi.decode(inclusionProof, (SMT.Proof));
        NFTObject.ERC721Object memory object = abi.decode(nftObject, (NFTObject.ERC721Object));
        require(object.data.contractAddress == address(this), "invalid contract address");
        bytes32 value = keccak256(nftObject);
        require(SMT.inclusionProof(stateRoot.next, object.data.id, value, proof.siblings), "invalid proof");    
        _mint(object.owner, object.data.tokenId);
    }

    function moveToOffchain(uint256 tokenId, bytes calldata noInclusionProof) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
        SMT.Proof memory proof = abi.decode(noInclusionProof, (SMT.Proof));
        NFTObject.ERC721Object memory object = NFTObject.createObject(address(this), tokenId, ownerOf(tokenId));
        require(SMT.nonInclusionProof(stateRoot.next, object.data.id, proof.siblings), "invalid proof");
        _burn(tokenId);
        bytes32 value = keccak256(abi.encode(object));
        SMT.update(stateRoot, object.data.id, value, proof.siblings);
    }

    function ownerOfWithProof(bytes calldata nftObject, bytes calldata inclusionProof) public view returns (address) {
        SMT.Proof memory proof = abi.decode(inclusionProof, (SMT.Proof));
        NFTObject.ERC721Object memory object = abi.decode(nftObject, (NFTObject.ERC721Object));
        bytes32 value = keccak256(nftObject);
        require(SMT.inclusionProof(stateRoot.next, object.data.id, value, proof.siblings), "invalid proof");
        return object.owner;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return tokenId <= latestTokenId;
    }
}