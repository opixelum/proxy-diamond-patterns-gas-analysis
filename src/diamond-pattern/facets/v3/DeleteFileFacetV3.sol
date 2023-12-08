// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {LibNotarizationDiamondV3} from "../../libraries/LibNotarizationDiamondV3.sol";

/// @title DeleteFileFacetV3
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract allows users to delete a notarized file
/// @dev This contract uses the diamond pattern
contract DeleteFileFacetV3 {
    /// @notice Emitted when a notarized file is deleted.
    /// @param filename Name of the deleted file.
    /// @param hash Hash of the deleted file.
    event FileDeleted(string indexed filename, bytes32 indexed hash);

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

    /// @notice Deletes a notarized file.
    /// @param filename Name of the file to be deleted.
    function deleteFile(
        string memory filename
    ) external fileExists(filename) onlyOwner(filename) {
        LibNotarizationDiamondV3.Storage storage s = LibNotarizationDiamondV3
            ._storage();
        bytes32 oldHash = s.files[filename].hash;
        delete s.hashToFileName[oldHash];
        delete s.files[filename];

        emit FileDeleted(filename, oldHash);
    }
}
