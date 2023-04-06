// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// A solidity Sparse Merkle Tree implementation
/// TODO optimize the SMT according to Rust version SMT(https://github.com/rooch-network/smt)
library SMT {
    // in Solidity: SMT.create_literal_hash("SPARSE_MERKLE_PLACEHOLDER_HASH")
    bytes32 constant public PLACE_HOLDER = 0x5350415253455f4d45524b4c455f504c414345484f4c4445525f484153480000;
    

    struct RollUp {
        bytes32 root;
        bytes32[] keys;
        bytes32[] values;
        bytes32[256][] siblings;
    }

    struct OPRU {
        bytes32 prev;
        bytes32 next;
        bytes32 mergedLeaves;
    }

    struct Proof{
        bytes32[256] siblings;
    }

    function inclusionProof(
        bytes32 root,
        bytes32 key,
        bytes32 value,
        bytes32[256] memory siblings
    ) internal pure returns(bool) {
        return merkleProof(root, key, value, siblings);
    }

    function nonInclusionProof(
        bytes32 root,
        bytes32 key,
        bytes32[256] memory siblings
    ) internal pure returns(bool) {
        //TODO check the proof is valid
        return true;
        //return merkleProof(root, key, PLACE_HOLDER, siblings);
    }

    function merkleProof(
        bytes32 root,
        bytes32 key,
        bytes32 value,
        bytes32[256] memory siblings
    ) internal pure returns(bool) {
        require(calculateRoot(key, value, siblings) == root, "Invalid merkle proof");
        return true;
    }

    function calculateRoot(
        bytes32 key,
        bytes32 value,
        bytes32[256] memory siblings
    ) internal pure returns (bytes32) {
        bytes32 cursor = value;
        uint path = uint(key);
        //TODO optimize this, compact the internal node
        for (uint16 i = 0; i < siblings.length; i++) {
            if (path % 2 == 0) {
                // Right sibling
                cursor = keccak256(abi.encodePacked(cursor, siblings[i]));
            } else {
                // Left sibling
                cursor = keccak256(abi.encodePacked(siblings[i], cursor));
            }
            path = path >> 1;
        }
        return cursor;
    }

    function append(
        bytes32 root,
        bytes32 key,
        bytes32 value,
        bytes32[256] memory siblings
    ) internal pure returns (bytes32 nextRoot) {
        // Prove that the array of sibling is valid and also the key does not exist in the tree
        require(nonInclusionProof(root, key, siblings), "Failed to build the previous root using jthe leaf and its sibling");
        // Calculate the new root when the leaf exists using its proven siblings
        nextRoot = calculateRoot(key, value, siblings);
        // Make sure it has been updated
        require(root != nextRoot, "Already exisiting leaf");
    }

    function rollUp(RollUp memory proof) internal pure returns (bytes32) {
        // Inspect the RollUp structure
        require(proof.keys.length == proof.siblings.length, "Both array should have same length");
        // Start from the root
        bytes32 root = proof.root;
        // Update the root using append function
        for (uint i = 0; i < proof.keys.length; i ++) {
            root = append(root, proof.keys[i], proof.values[i], proof.siblings[i]);
        }
        return root;
    }

    function rollUp(
        bytes32 root,
        bytes32[] memory keys,
        bytes32[] memory values,
        bytes32[256][] memory siblings
    ) internal pure returns (bytes32 nextRoot) {
        nextRoot = rollUp(RollUp(root, keys, values, siblings));
    }

    function rollUpProof(
        bytes32 root,
        bytes32 nextRoot,
        bytes32[] memory keys,
        bytes32[] memory values,
        bytes32[256][] memory siblings
    ) internal pure returns (bool) {
        require(nextRoot == rollUp(RollUp(root, keys, values, siblings)), "Failed to drive the next root from the proof");
    }

    function newOPRU(bytes32 startingRoot) internal pure returns (OPRU memory opru) {
        opru.prev = startingRoot;
        opru.next = startingRoot;
        opru.mergedLeaves = bytes32(0);
    }
    
    function update(
        OPRU storage opru,
        bytes32 key,
        bytes32 value,
        bytes32[256] memory siblings) internal {
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = key;
        bytes32[] memory values = new bytes32[](1);
        values[0] = value;
        bytes32[256][] memory siblingsArray = new bytes32[256][](1);
        siblingsArray[0] = siblings;
        update_batch(opru, keys, values, siblingsArray);
    }

    function update_batch(
        OPRU storage opru,
        bytes32[] memory keys,
        bytes32[] memory values,
        bytes32[256][] memory siblings
    ) internal {
        opru.next = rollUp(opru.next, keys, values, siblings);
        opru.mergedLeaves = merge(opru.mergedLeaves, keys);
    }

    function verify(
        OPRU memory opru,
        bytes32 prev,
        bytes32 next,
        bytes32 mergedLeaves
    ) internal pure returns (bool) {
        require(opru.prev == prev, "Started with different root");
        require(opru.mergedLeaves == mergedLeaves, "Appended different leaves");
        return opru.next == next;
    }

    function merge(
        bytes32 base,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 mergedLeaves) {
        mergedLeaves = base;
        for(uint i = 0; i < leaves.length; i++) {
            mergedLeaves = keccak256(abi.encodePacked(mergedLeaves, leaves[i]));
        }
    }

    function create_literal_hash(
        string memory literal
    ) internal pure returns (bytes32) {
        bytes memory value = bytes(literal);
        bytes32 hash_result = bytes32(abi.encodePacked(value));
        return hash_result;
    }
    
}