// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {LibNotarizationDiamond} from "../../libraries/LibNotarizationDiamond.sol";

/// @title UpdateFileFacet
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract allows users to update the hash of an existing file
/// @dev This contract uses the diamond pattern
contract UpdateFileFacet {
    event FileUpdated(string indexed name, bytes32 indexed oldHash, bytes32 indexed newHash);

    /// @notice Update the hash of an existing file
    /// @param name The name of the file
    /// @param newHash The new hash of the file
    /// @dev Function writing to storage
    function updateFile(string memory name, bytes32 newHash) external {
        // Retrieve diamond's storage
        LibNotarizationDiamond.Storage storage s = LibNotarizationDiamond._storage();

        require(s.nameToHash[name] != 0, "File not found");

        bytes32 oldHash = s.nameToHash[name];
        s.nameToHash[name] = newHash;
        s.hashToName[newHash] = name;
        delete s.hashToName[oldHash];

        emit FileUpdated(name, oldHash, newHash);
    }
}
