// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {LibNotarizationDiamondV3} from "../../libraries/LibNotarizationDiamondV3.sol";

/// @title UpdateFileFacetV3
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract allows users to update the hash of an existing file
/// @dev This contract uses the diamond pattern
contract UpdateFileFacetV3 {
    /// @notice Emitted when a notarized file is updated.
    /// @param filename Name of the updated file.
    /// @param oldHash Original hash of the file before update.
    /// @param newHash New hash of the file after update.
    event FileUpdated(
        string indexed filename,
        bytes32 indexed oldHash,
        bytes32 indexed newHash
    );

    /// @dev Modifier to check if a file with the given name exists.
    /// @param filename Name of the file to check.
    modifier fileExists(string memory filename) {
        LibNotarizationDiamondV3.Storage storage s = LibNotarizationDiamondV3
            ._storage();
        require(s.files[filename].createdAt != 0, "File not found");
        _;
    }

    /// @dev Modifier to ensure only the owner of a file can perform certain operations.
    /// @param filename Name of the file to check.
    modifier onlyOwner(string memory filename) {
        LibNotarizationDiamondV3.Storage storage s = LibNotarizationDiamondV3
            ._storage();
        require(s.files[filename].owner == msg.sender, "Not the file owner");
        _;
    }

    /// @notice Updates the hash of an existing notarized file.
    /// @param filename Name of the file.
    /// @param newHash New hash for the file.
    function updateFile(
        string memory filename,
        bytes32 newHash
    ) external fileExists(filename) onlyOwner(filename) {
        LibNotarizationDiamondV3.Storage storage s = LibNotarizationDiamondV3
            ._storage();
        bytes32 oldHash = s.files[filename].hash;
        delete s.hashToFileName[oldHash]; // Remove the old hash mapping
        s.hashToFileName[newHash] = filename; // Add the new hash mapping

        s.files[filename].hash = newHash;

        emit FileUpdated(filename, oldHash, newHash);
    }
}
