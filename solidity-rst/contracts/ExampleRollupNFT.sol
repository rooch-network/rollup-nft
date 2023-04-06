// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import "./IRollupNFT.sol";
import "./RollupNFT.sol";

contract ExampleRollupNFT is RollupNFT {
    
    constructor() RollupNFT("ExampleRollupNFT", "ExampleRollupNFT", false) {}

}