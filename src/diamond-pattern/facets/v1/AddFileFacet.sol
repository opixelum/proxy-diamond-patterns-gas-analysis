// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {LibNotarizationDiamond} from "../../libraries/LibNotarizationDiamond.sol";

/// @title AddFileFacet
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract allows users to link a hash to its corresponding file
/// @dev This contract uses the diamond pattern
contract AddFileFacet {
    event FileNotarized(string indexed name, bytes32 indexed hash);

    /// @notice Notarize a file on the blockchain
    /// @param name The name of the file
    /// @param hash The hash of the file
    /// @dev Function writing to storage
    function addFile(string memory name, bytes32 hash) external {
        // Retrieve diamond's storage
        LibNotarizationDiamond.Storage storage s = LibNotarizationDiamond._storage();

        s.nameToHash[name] = hash;
        s.hashToName[hash] = name;

        emit FileNotarized(name, hash);
    }
}
