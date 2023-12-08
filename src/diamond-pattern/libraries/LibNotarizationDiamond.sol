// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

/// @title LibNotarizationDiamond
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This library contains the storage for the NotarizationDiamond
/// contract
/// @dev This contract uses the diamond pattern
library LibNotarizationDiamond {
    bytes32 internal constant STORAGE_POSITION = keccak256("diamond.storage");

    struct Storage {
        mapping(string => bytes32) nameToHash;
        mapping(bytes32 => string) hashToName;
    }

    function _storage() internal pure returns (Storage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
