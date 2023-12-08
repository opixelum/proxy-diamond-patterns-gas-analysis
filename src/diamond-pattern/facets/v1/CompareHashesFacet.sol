// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

/// @title CompareHashesFacet
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract allows users to compare two hashes
/// @dev This contract uses the diamond pattern
contract CompareHashesFacet {
    /// @notice Compare two hashes
    /// @param hash1 The first hash
    /// @param hash2 The second hash
    /// @return True if the hashes are equal, false otherwise
    /// @dev Pure function (no storage access)
    function compareHashes(bytes32 hash1, bytes32 hash2) external pure returns (bool) {
        return hash1 == hash2;
    }
}
