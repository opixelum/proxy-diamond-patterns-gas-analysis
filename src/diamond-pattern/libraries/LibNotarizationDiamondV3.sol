// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

/// @title LibNotarizationDiamondV3
/// @author Anto Benedetti (anto.benedetti)
/// @notice This library contains the storage for the V3 of NotarizationDiamond
/// contract
/// @dev This contract uses the diamond pattern
library LibNotarizationDiamondV3 {
    bytes32 internal constant STORAGE_POSITION = keccak256("diamond.storage");

    struct File {
        bytes32 hash;
        address owner;
        uint256 createdAt;
        uint256 lastModifiedAt;
    }

    struct Storage {
        mapping(string => bytes32) nameToHash;
        mapping(bytes32 => string) hashToName;

        // New storage variables
        mapping(string => File) files;
        mapping(bytes32 => string) hashToFileName;
    }

    function _storage() internal pure returns (Storage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
