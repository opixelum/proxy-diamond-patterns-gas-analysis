// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title A simple notarization contract
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract allows users to link a hash to its corresponding file
/// @dev This contract uses the proxy pattern with the UUPS upgradeability pattern
contract NotarizationProxyV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    event FileNotarized(string indexed name, bytes32 indexed hash);

    mapping(string => bytes32) private nameToHash;
    mapping(bytes32 => string) private hashToName;

    /// @dev Since proxied contracts do not make use of a constructor, we need to manually initialize the contract
    /// by calling the initializer through the proxy so it will hold initialized data
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @dev Reverts any attempt to upgrade the contract by non-owners
    function _authorizeUpgrade(address newImplementation) internal override(UUPSUpgradeable) onlyOwner {}

    /// @notice Notarize a file on the blockchain
    /// @param name The name of the file
    /// @param hash The hash of the file
    /// @dev Function writing to storage
    function addFile(string memory name, bytes32 hash) external {
        nameToHash[name] = hash;
        hashToName[hash] = name;
        emit FileNotarized(name, hash);
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
