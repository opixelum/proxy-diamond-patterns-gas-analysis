// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

/// @title A simple notarization contract
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract allows users to link a hash to its corresponding file
/// @dev This contract uses the classic smart contract pattern
contract NotarizationClassicV2 {
    event FileNotarized(string indexed name, bytes32 indexed hash);
    event FileUpdated(string indexed name, bytes32 indexed oldHash, bytes32 indexed newHash);

    mapping(string => bytes32) private nameToHash;
    mapping(bytes32 => string) private hashToName;

    /// @notice Notarize a file on the blockchain
    /// @param name The name of the file
    /// @param hash The hash of the file
    /// @dev Function writing to storage
    function addFile(string memory name, bytes32 hash) external {
        nameToHash[name] = hash;
        hashToName[hash] = name;
        emit FileNotarized(name, hash);
    }

    /// @notice Update the hash of an existing file
    /// @param name The name of the file
    /// @param newHash The new hash of the file
    /// @dev Function writing to storage
    function updateFile(string memory name, bytes32 newHash) external {
        require(nameToHash[name] != 0, "File not found");
        bytes32 oldHash = nameToHash[name];
        nameToHash[name] = newHash;
        hashToName[newHash] = name;
        delete hashToName[oldHash];
        emit FileUpdated(name, oldHash, newHash);
    }

    /// @notice Get the hash of a file
    /// @param name The name of the file
    /// @return The hash of the file
    /// @dev Function reading from storage
    function getFileHash(string memory name) external view returns (bytes32) {
        return nameToHash[name];
    }

    /// @notice Get the name of a file
    /// @param hash The hash of the file
    /// @return The name of the file
    /// @dev Function reading from storage
    function getFileName(bytes32 hash) external view returns (string memory) {
        return hashToName[hash];
    }

    /// @notice Compare two hashes
    /// @param hash1 The first hash
    /// @param hash2 The second hash
    /// @return True if the hashes are equal, false otherwise
    /// @dev Pure function (no storage access)
    function compareHashes(bytes32 hash1, bytes32 hash2) external pure returns (bool) {
        return hash1 == hash2;
    }
}
