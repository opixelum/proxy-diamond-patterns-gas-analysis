// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {LibNotarizationDiamondV3} from "../../libraries/LibNotarizationDiamondV3.sol";

/// @title AddFileFacetV3
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract allows users to notarize a new file
/// @dev This contract uses the diamond pattern
contract AddFileFacetV3 {
    /// @notice Emitted when a new file is notarized.
    /// @param owner Address of the owner who notarized the file.
    /// @param filename Name of the notarized file.
    /// @param hash Hash of the notarized file.
    event FileNotarized(
        address indexed owner,
        string indexed filename,
        bytes32 indexed hash
    );

    /// @notice Notarizes a new file with a given name and hash.
    /// @param filename Name of the file.
    /// @param hash Hash of the file.
    function addFile(string memory filename, bytes32 hash) external {
        LibNotarizationDiamondV3.Storage storage s = LibNotarizationDiamondV3
            ._storage();

        require(
            s.files[filename].createdAt == 0,
            "File with this name already exists"
        );

        s.files[filename] = LibNotarizationDiamondV3.File({
            hash: hash,
            owner: msg.sender,
            createdAt: block.timestamp,
            lastModifiedAt: block.timestamp
        });

        s.hashToFileName[hash] = filename;

        emit FileNotarized(msg.sender, filename, hash);
    }
}
