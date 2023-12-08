// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {LibNotarizationDiamondV3} from "../../libraries/LibNotarizationDiamondV3.sol";

/// @title GettersFacetV3
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract allows users to retrieve information about notarized
/// files
/// @dev This contract uses the diamond pattern
contract GettersFacetV3 {
    /// @notice Retrieves the name of a file based on its hash.
    /// @param hash Hash of the file.
    /// @return Name of the specified file.
    function getFilename(bytes32 hash) external view returns (string memory) {
        LibNotarizationDiamondV3.Storage storage s =LibNotarizationDiamondV3
            ._storage();
        return s.hashToFileName[hash];
    }

    /// @notice Retrieves detailed information about a notarized file.
    /// @param filename Name of the file.
    /// @return fileDetails File struct containing the hash, owner, and timestamps of notarization.
    function getFileDetails(
        string memory filename
    )
    external
    view
    returns (LibNotarizationDiamondV3.File memory)
    {
        LibNotarizationDiamondV3.Storage storage s =LibNotarizationDiamondV3
            ._storage();
        return s.files[filename];
    }

    /// @notice Retrieves the hash of a notarized file.
    /// @param filename Name of the file.
    /// @return Hash of the specified file.
    function getFileHash(
        string memory filename
    ) external view returns (bytes32) {
        LibNotarizationDiamondV3.Storage storage s =LibNotarizationDiamondV3
            ._storage();
        return s.files[filename].hash;
    }

    /// @notice Retrieves the owner of a notarized file.
    /// @param filename Name of the file.
    /// @return Address of the owner who notarized the file.
    function getFileOwner(
        string memory filename
    ) external view returns (address) {
        LibNotarizationDiamondV3.Storage storage s =LibNotarizationDiamondV3
            ._storage();
        return s.files[filename].owner;
    }

    /// @notice Retrieves the timestamp when a notarized file was notarized.
    /// @param filename Name of the file.
    /// @return Timestamp when the file was notarized.
    function getFileCreatedAt(
        string memory filename
    ) external view returns (uint256) {
        LibNotarizationDiamondV3.Storage storage s =LibNotarizationDiamondV3
            ._storage();
        return s.files[filename].createdAt;
    }

    /// @notice Retrieves the timestamp when a notarized file was last updated.
    /// @param filename Name of the file.
    /// @return Timestamp when the file was last updated.
    function getFileLastModifiedAt(
        string memory filename
    ) external view returns (uint256) {
        LibNotarizationDiamondV3.Storage storage s =LibNotarizationDiamondV3
            ._storage();
        return s.files[filename].lastModifiedAt;
    }
}
