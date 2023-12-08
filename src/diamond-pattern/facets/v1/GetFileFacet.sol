// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {LibNotarizationDiamond} from "../../libraries/LibNotarizationDiamond.sol";

/// @title GetFileFacet
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract allows users to get the hash of a file from its name
/// and vice-versa
/// @dev This contract uses the diamond pattern
contract GetFileFacet {
    /// @notice Get the hash of a file
    /// @param name The name of the file
    /// @return The hash of the file
    /// @dev Function reading from storage
    function getFileHash(string memory name) external view returns (bytes32) {
        return LibNotarizationDiamond._storage().nameToHash[name];
    }

    /// @notice Get the name of a file
    /// @param hash The hash of the file
    /// @return The name of the file
    /// @dev Function reading from storage
    function getFileName(bytes32 hash) external view returns (string memory) {
        return LibNotarizationDiamond._storage().hashToName[hash];
    }
}
