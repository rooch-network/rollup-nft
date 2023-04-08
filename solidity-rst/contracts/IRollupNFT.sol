// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IRollupNFT is IERC721 {

    /// Mint NFT from Offchain
    function mintWithProof(bytes calldata objectBytes, bytes calldata inclusionProof) external;

    /// Move Onchain NFT to Offchain
    function moveToOffchain(uint256 tokenId, bytes calldata noInclusionProof) external;

    function ownerOfWithProof(bytes calldata objectBytes, bytes calldata inclusionProof) external view returns (address) ;
}