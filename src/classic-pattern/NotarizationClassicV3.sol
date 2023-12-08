// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

/// @title A simple notarization contract
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract provides advanced notarization functionalities like adding, updating, and deleting file
/// hashes.
/// @dev This contract uses the classic smart contract pattern. Ensure proper access control and file existence
/// checks before performing sensitive operations.
contract NotarizationClassicV3 {
    /// @notice Emitted when a new file is notarized.
    /// @param owner Address of the owner who notarized the file.
    /// @param filename Name of the notarized file.
    /// @param hash Hash of the notarized file.
    event FileNotarized(
        address indexed owner,
        string indexed filename,
        bytes32 indexed hash
    );

    /// @notice Emitted when a notarized file is updated.
    /// @param filename Name of the updated file.
    /// @param oldHash Original hash of the file before update.
    /// @param newHash New hash of the file after update.
    event FileUpdated(
        string indexed filename,
        bytes32 indexed oldHash,
        bytes32 indexed newHash
    );

    /// @notice Emitted when a notarized file is deleted.
    /// @param filename Name of the deleted file.
    /// @param hash Hash of the deleted file.
    event FileDeleted(string indexed filename, bytes32 indexed hash);

    /// @dev Represents a notarized file with its hash, owner, and timestamps of notarization.
    struct File {
        bytes32 hash;
        address owner;
        uint256 createdAt;
        uint256 lastModifiedAt;
    }

    /// @dev Maps a file name to its details.
    mapping(string => File) private files;

    /// @dev Maps a file hash to its name, for reverse lookup.
    mapping(bytes32 => string) private hashToFilename;

    /// @dev Modifier to check if a file with the given name exists.
    /// @param filename Name of the file to check.
    modifier fileExists(string memory filename) {
        require(files[filename].createdAt != 0, "File not found");
        _;
    }

    /// @dev Modifier to ensure only the owner of a file can perform certain operations.
    /// @param filename Name of the file to check.
    modifier onlyOwner(string memory filename) {
        require(files[filename].owner == msg.sender, "Not the file owner");
        _;
    }

    /// @notice Notarizes a new file with a given name and hash.
    /// @param filename Name of the file.
    /// @param hash Hash of the file.
    function addFile(string memory filename, bytes32 hash) external {
        require(
            files[filename].createdAt == 0,
            "File with this name already exists"
        );

        files[filename] = File({
            hash: hash,
            owner: msg.sender,
            createdAt: block.timestamp,
            lastModifiedAt: block.timestamp
        });

        hashToFilename[hash] = filename;

        emit FileNotarized(msg.sender, filename, hash);
    }

    /// @notice Updates the hash of an existing notarized file.
    /// @param filename Name of the file.
    /// @param newHash New hash for the file.
    function updateFile(
        string memory filename,
        bytes32 newHash
    ) external fileExists(filename) onlyOwner(filename) {
        bytes32 oldHash = files[filename].hash;
        delete hashToFilename[oldHash]; // Remove the old hash mapping
        hashToFilename[newHash] = filename; // Add the new hash mapping

        files[filename].hash = newHash;

        emit FileUpdated(filename, oldHash, newHash);
    }

    /// @notice Deletes a notarized file.
    /// @param filename Name of the file to be deleted.
    function deleteFile(
        string memory filename
    ) external fileExists(filename) onlyOwner(filename) {
        bytes32 oldHash = files[filename].hash;
        delete hashToFilename[oldHash];
        delete files[filename];

        emit FileDeleted(filename, oldHash);
    }

    /// @notice Retrieves the name of a file based on its hash.
    /// @param hash Hash of the file.
    /// @return Name of the specified file.
    function getFilename(bytes32 hash) external view returns (string memory) {
        return hashToFilename[hash];
    }

    /// @notice Retrieves detailed information about a notarized file.
    /// @param filename Name of the file.
    /// @return fileDetails File struct containing the hash, owner, and timestamps of notarization.
    function getFileDetails(
        string memory filename
    )
        external
        view
        returns (File memory fileDetails)
    {
        File memory file = files[filename];
        return (File(file.hash, file.owner, file.createdAt, file.lastModifiedAt));
    }

    /// @notice Retrieves the hash of a notarized file.
    /// @param filename Name of the file.
    /// @return Hash of the specified file.
    function getFileHash(
        string memory filename
    ) external view returns (bytes32) {
        return files[filename].hash;
    }

    /// @notice Retrieves the owner of a notarized file.
    /// @param filename Name of the file.
    /// @return Address of the owner who notarized the file.
    function getFileOwner(
        string memory filename
    ) external view returns (address) {
        return files[filename].owner;
    }

    /// @notice Retrieves the timestamp when a notarized file was notarized.
    /// @param filename Name of the file.
    /// @return Timestamp when the file was notarized.
    function getFileCreatedAt(
        string memory filename
    ) external view returns (uint256) {
        return files[filename].createdAt;
    }

    /// @notice Retrieves the timestamp when a notarized file was last updated.
    /// @param filename Name of the file.
    /// @return Timestamp when the file was last updated.
    function getFileLastModifiedAt(
        string memory filename
    ) external view returns (uint256) {
        return files[filename].lastModifiedAt;
    }
}
