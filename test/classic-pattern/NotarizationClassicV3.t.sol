// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {NotarizationClassicV3} from "../../src/classic-pattern/NotarizationClassicV3.sol";
import {Test} from "forge-std/Test.sol";
import {Utils} from "../../script/Utils.s.sol";

/// @title NotarizationClassicV3Test
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract tests all the functions in the NotarizationClassicV3
/// contract
/// @dev Tests can only be run using Forge
contract NotarizationClassicV3Test is Test, Utils {
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

    NotarizationClassicV3 public notarizationClassicV3;

    /// @notice Sets up the test environment
    /// @dev Creates a new instance of the tested contract before each test
    function setUp() public {
        notarizationClassicV3 = new NotarizationClassicV3();
    }

    /// @notice Tests the `addFile` function, with file names of different lengths
    /// @dev Checks if the `FileNotarized` event is emitted & if the file name & file hash are stored in the contract
    function test01_addFile_variantLengths() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(i);
            bytes32 fileHash = keccak256(abi.encode(fileName));

            vm.expectEmit(true, true, true, true, address(notarizationClassicV3));
            emit FileNotarized(address(this), fileName, fileHash);
            notarizationClassicV3.addFile(fileName, fileHash);

            // Check if file name & file hash are stored in the contract
            string memory fileNameFromContract = notarizationClassicV3
                .getFilename(fileHash);
            NotarizationClassicV3.File
            memory fileDetailsFromContract = notarizationClassicV3
                .getFileDetails(fileName);
            assertEq(
                fileNameFromContract,
                fileName,
                "File name from contract is not equal to provided one"
            );
            assertEq(
                fileDetailsFromContract.hash,
                fileHash,
                "File hash from contract is not equal to provided one"
            );
            assertEq(
                fileDetailsFromContract.owner,
                address(this),
                "File owner from contract is not equal to sender"
            );
            assertEq(
                fileDetailsFromContract.createdAt,
                block.timestamp,
                "File created at is not equal to current timestamp"
            );
            assertEq(
                fileDetailsFromContract.lastModifiedAt,
                block.timestamp,
                "File last modified at is not equal to current timestamp"
            );
        }
    }

    /// @notice Tests the `addFile` function, with the same base file name but with a different last character
    /// @dev Checks if the `FileNotarized` event is emitted & if the file name & file hash are stored in the contract
    function test02_addFile_variantLastCharacter() public {
        for (uint i = 1; i <= 100; i++) {
            string memory baseFileName = "Jessi31_2022_06_"; // Real use case example
            string memory fileName = string(abi.encodePacked(baseFileName, i)); // Concatenation
            bytes32 fileHash = keccak256(abi.encode(fileName));

            vm.expectEmit(true, true, true, true, address(notarizationClassicV3));
            emit FileNotarized(address(this), fileName, fileHash);
            notarizationClassicV3.addFile(fileName, fileHash);

            // Check if file name & file hash are stored in the contract
            string memory fileNameFromContract = notarizationClassicV3
                .getFilename(fileHash);
            NotarizationClassicV3.File
            memory fileDetailsFromContract = notarizationClassicV3
                .getFileDetails(fileName);
            assertEq(
                fileNameFromContract,
                fileName,
                "File name from contract is not equal to provided one"
            );
            assertEq(
                fileDetailsFromContract.hash,
                fileHash,
                "File hash from contract is not equal to provided one"
            );
            assertEq(
                fileDetailsFromContract.owner,
                address(this),
                "File owner from contract is not equal to sender"
            );
            assertEq(
                fileDetailsFromContract.createdAt,
                block.timestamp,
                "File created at is not equal to current timestamp"
            );
            assertEq(
                fileDetailsFromContract.lastModifiedAt,
                block.timestamp,
                "File last modified at is not equal to current timestamp"
            );
        }
    }

    /// @notice Tests the `updateFile` function
    /// @dev Checks if the `FileUpdated` event is emitted & if the file hash is updated in the contract
    function test03_updateFile() public {
        string memory fileName = "0";
        bytes32 fileHash = keccak256(abi.encode(fileName));

        vm.expectEmit(true, true, true, true, address(notarizationClassicV3));
        emit FileNotarized(address(this), fileName, fileHash);
        notarizationClassicV3.addFile(fileName, fileHash);

        for (uint256 i = 1; i <= 100; i++) {
            bytes32 newFileHash = keccak256(abi.encode(randomString(i)));

            vm.expectEmit(true, true, true, true, address(notarizationClassicV3));
            emit FileUpdated(fileName, fileHash, newFileHash);
            notarizationClassicV3.updateFile(fileName, newFileHash);

            bytes32 fileHashFromContract = notarizationClassicV3.getFileHash(
                fileName
            );
            assertEq(
                fileHashFromContract,
                newFileHash,
                "File hash from contract is not equal to provided one"
            );

            // Remember old hash for next iteration
            fileHash = newFileHash;
        }
    }

    /// @notice Tests `fileExists` modifier to revert when the file does not exist
    /// @dev We check if the revert message is correct
    function test04_expectRevert_fileExists() public {
        string memory fileName = "0";
        bytes32 newFileHash = keccak256(abi.encode(fileName));
        vm.expectRevert("File not found");
        notarizationClassicV3.updateFile(fileName, newFileHash);
    }

    /// @notice Expect `onlyOwner` modifier to revert when the sender is not the file owner
    /// @dev We "prank" the contract by sending a transaction from a different address,
    /// and check if the revert message is correct
    function test05_expectRevert_onlyOwner() public {
        string memory fileName = "0";
        bytes32 fileHash = keccak256(abi.encode(fileName));

        vm.expectEmit(true, true, true, true, address(notarizationClassicV3));
        emit FileNotarized(address(this), fileName, fileHash);
        notarizationClassicV3.addFile(fileName, fileHash);

        bytes32 newFileHash = keccak256(abi.encode(randomString(10)));
        vm.expectRevert("Not the file owner");
        vm.prank(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        notarizationClassicV3.updateFile(fileName, newFileHash);
    }

    /// @notice Tests the `deleteFile` function
    /// @dev Checks if the `FileDeleted` event is emitted & if the file is deleted from the contract
    function test06_deleteFile() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(i);
            bytes32 fileHash = keccak256(abi.encode(fileName));

            vm.expectEmit(true, true, true, true, address(notarizationClassicV3));
            emit FileNotarized(address(this), fileName, fileHash);
            notarizationClassicV3.addFile(fileName, fileHash);

            vm.expectEmit(true, true, true, true, address(notarizationClassicV3));
            emit FileDeleted(fileName, fileHash);
            notarizationClassicV3.deleteFile(fileName);

            bytes32 fileHashFromContract = notarizationClassicV3.getFileHash(
                fileName
            );
            assertEq(
                fileHashFromContract,
                bytes32(0),
                "File hash from contract is not equal to 0"
            );
        }
    }

    /// @notice Tests the `getFileName` function
    /// @dev Since we're already testing it in `addFile` tests, we only check if the function returns does not return a
    /// wrong file name
    function test07_getFileName() public {
        string memory fileName = randomString(10);
        bytes32 fileHash = keccak256(abi.encode(fileName));
        string memory wrongFileName = randomString(11);

        vm.expectEmit(true, true, true, true, address(notarizationClassicV3));
        emit FileNotarized(address(this), fileName, fileHash);
        notarizationClassicV3.addFile(fileName, fileHash);

        string memory fileNameFromContract = notarizationClassicV3.getFilename(
            fileHash
        );
        assertFalse(
            keccak256(bytes(fileNameFromContract)) ==
            keccak256(bytes(wrongFileName)),
            "File name from contract is equal to wrong file name"
        );
    }

    /// @notice Tests the `getFileDetails` function
    /// @dev Since we're already testing it in `addFile` tests, we only check if the function returns does not return
    /// wrong file details
    function test08_getFileDetails() public {
        string memory fileName = randomString(10);
        bytes32 fileHash = keccak256(abi.encode(fileName));
        NotarizationClassicV3.File
        memory wrongFileDetails = NotarizationClassicV3.File(
            keccak256(abi.encode(randomString(11))),
            0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            123456789,
            123456789
        );

        vm.expectEmit(true, true, true, true, address(notarizationClassicV3));
        emit FileNotarized(address(this), fileName, fileHash);
        notarizationClassicV3.addFile(fileName, fileHash);

        NotarizationClassicV3.File
        memory fileDetailsFromContract = notarizationClassicV3
            .getFileDetails(fileName);
        assertFalse(
            keccak256(abi.encode(fileDetailsFromContract)) ==
            keccak256(abi.encode(wrongFileDetails)),
            "File details from contract is equal to wrong file details"
        );
    }

    /// @notice Tests the `getFileHash` function
    function test09_getFileHash() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(i);
            bytes32 fileHash = keccak256(abi.encode(fileName));
            bytes32 wrongFileHash = keccak256(abi.encode(randomString(i + 1)));

            vm.expectEmit(true, true, true, true, address(notarizationClassicV3));
            emit FileNotarized(address(this), fileName, fileHash);
            notarizationClassicV3.addFile(fileName, fileHash);

            bytes32 fileHashFromContract = notarizationClassicV3.getFileHash(
                fileName
            );
            assertFalse(
                fileHashFromContract == wrongFileHash,
                "File hash from contract is equal to wrong file hash"
            );
        }
    }

    /// @notice Tests the `getFileOwner` function
    function test10_getFileOwner() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(i);
            bytes32 fileHash = keccak256(abi.encode(fileName));
            address wrongFileOwner = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

            vm.expectEmit(true, true, true, true, address(notarizationClassicV3));
            emit FileNotarized(address(this), fileName, fileHash);
            notarizationClassicV3.addFile(fileName, fileHash);

            address fileOwnerFromContract = notarizationClassicV3.getFileOwner(
                fileName
            );
            assertFalse(
                fileOwnerFromContract == wrongFileOwner,
                "File name from contract is equal to wrong file name"
            );
        }
    }

    /// @notice Tests the `getFileCreatedAt` function
    function test11_getFileCreatedAt() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(i);
            bytes32 fileHash = keccak256(abi.encode(fileName));
            uint256 wrongFileCreatedAt = 123456789;

            vm.expectEmit(true, true, true, true, address(notarizationClassicV3));
            emit FileNotarized(address(this), fileName, fileHash);
            notarizationClassicV3.addFile(fileName, fileHash);

            uint256 fileCreatedAtFromContract = notarizationClassicV3
                .getFileCreatedAt(fileName);
            assertFalse(
                fileCreatedAtFromContract == wrongFileCreatedAt,
                "File name from contract is equal to wrong file name"
            );
        }
    }

    /// @notice Tests the `getFileLastModifiedAt` function
    function test12_getFileLastModifiedAt() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(i);
            bytes32 fileHash = keccak256(abi.encode(fileName));
            uint256 wrongFileLastModifiedAt = 123456789;

            vm.expectEmit(true, true, true, true, address(notarizationClassicV3));
            emit FileNotarized(address(this), fileName, fileHash);
            notarizationClassicV3.addFile(fileName, fileHash);

            uint256 fileLastModifiedAtFromContract = notarizationClassicV3
                .getFileLastModifiedAt(fileName);
            assertFalse(
                fileLastModifiedAtFromContract == wrongFileLastModifiedAt,
                "File name from contract is equal to wrong file name"
            );
        }
    }
}
