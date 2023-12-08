// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {NotarizationClassicV2} from "../../src/classic-pattern/NotarizationClassicV2.sol";
import {Test} from "forge-std/Test.sol";
import {Utils} from "../../script/Utils.s.sol";

/// @title NotarizationClassicV2Test
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract tests all the functions in the NotarizationClassicV2
/// contract
/// @dev Tests can only be run using Forge
contract NotarizationClassicV2Test is Test, Utils {
    // Define events emitted by the tested contract for testing
    event FileNotarized(string indexed name, bytes32 indexed hash);
    event FileUpdated(string indexed name, bytes32 indexed oldHash, bytes32 indexed newHash);

    NotarizationClassicV2 public notarizationClassicV2;

    /// @notice Sets up the test environment
    /// @dev Creates a new instance of the tested contract before each test
    function setUp() public {
        notarizationClassicV2 = new NotarizationClassicV2();
    }

    /// @notice Tests the `addFile` function, with file names of different lengths
    /// @dev Checks if the `FileNotarized` event is emitted & if the file name & file hash are stored in the contract
    function test1_AddFile_variantLengths() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(i);
            bytes32 fileHash = keccak256(abi.encode(fileName));

            vm.expectEmit(true, true, true, true, address(notarizationClassicV2));
            emit FileNotarized(fileName, fileHash);
            notarizationClassicV2.addFile(fileName, fileHash);

            // Check if file name & file hash are stored in the contract
            bytes32 fileHashFromContract = notarizationClassicV2.getFileHash(fileName);
            string memory fileNameFromContract = notarizationClassicV2.getFileName(fileHash);
            assertEq(fileHashFromContract, fileHash, "File hash from contract is not equal to provided one");
            assertEq(fileNameFromContract, fileName, "File name from contract is not equal to provided one");
        }
    }

    /// @notice Tests the `addFile` function, with the same base file name but with a different last character
    /// @dev Checks if the `FileNotarized` event is emitted & if the file name & file hash are stored in the contract
    function test2_AddFile_variantLastCharacter() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory baseFileName = "Jessi31_2022_06_"; // Real use case example
            string memory fileName = string(abi.encodePacked(baseFileName, i)); // Concatenation
            bytes32 fileHash = keccak256(abi.encode(fileName));

            vm.expectEmit(true, true, true, true, address(notarizationClassicV2));
            emit FileNotarized(fileName, fileHash);
            notarizationClassicV2.addFile(fileName, fileHash);

            // Check if file name & file hash are stored in the contract
            bytes32 fileHashFromContract = notarizationClassicV2.getFileHash(fileName);
            string memory fileNameFromContract = notarizationClassicV2.getFileName(fileHash);
            assertEq(fileHashFromContract, fileHash, "File hash from contract is not equal to provided one");
            assertEq(fileNameFromContract, fileName, "File name from contract is not equal to provided one");
        }
    }

    /// @notice Tests the `addFile` function, with the same file name
    /// @dev Checks if the `FileNotarized` event is emitted & if the file name & file hash are stored in the contract
    function test3_AddFile_sameFileName() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(32);
            bytes32 fileHash = keccak256(abi.encode(fileName));

            vm.expectEmit(true, true, true, true, address(notarizationClassicV2));
            emit FileNotarized(fileName, fileHash);
            notarizationClassicV2.addFile(fileName, fileHash);

            // Check if file name & file hash are stored in the contract
            bytes32 fileHashFromContract = notarizationClassicV2.getFileHash(fileName);
            string memory fileNameFromContract = notarizationClassicV2.getFileName(fileHash);
            assertEq(fileHashFromContract, fileHash, "File hash from contract is not equal to provided one");
            assertEq(fileNameFromContract, fileName, "File name from contract is not equal to provided one");
        }
    }

    /// @notice Tests the `getFileHash` function
    /// @dev Since we're already testing it in `test1_AddFile`, we only check if the function returns does not return a
    /// wrong file hash
    function test4_getFileHash() public {
        string memory fileName = randomString(10);
        bytes32 fileHash = keccak256(abi.encode(fileName));
        bytes32 wrongFileHash = keccak256(abi.encode(randomString(11)));

        vm.expectEmit(true, true, true, true, address(notarizationClassicV2));
        emit FileNotarized(fileName, fileHash);
        notarizationClassicV2.addFile(fileName, fileHash);

        bytes32 fileHashFromContract = notarizationClassicV2.getFileHash(fileName);
        assertFalse(fileHashFromContract == wrongFileHash, "File hash from contract is equal to wrong file hash");
    }

    /// @notice Tests the `getFileName` function
    /// @dev Since we're already testing it in `test1_AddFile`, we only check if the function returns does not return a
    /// wrong file name
    function test5_getFileName() public {
        string memory fileName = randomString(10);
        bytes32 fileHash = keccak256(abi.encode(fileName));
        string memory wrongFileName = randomString(11);

        vm.expectEmit(true, true, true, true, address(notarizationClassicV2));
        emit FileNotarized(fileName, fileHash);
        notarizationClassicV2.addFile(fileName, fileHash);

        string memory fileNameFromContract = notarizationClassicV2.getFileName(fileHash);
        assertFalse(
            keccak256(bytes(fileNameFromContract)) == keccak256(bytes(wrongFileName)),
            "File name from contract is equal to wrong file name"
        );
    }

    /// @notice Tests the `compareHashes` function
    /// @dev Checks if the function returns true when comparing two equal hashes & false when comparing two different
    /// hashes
    function test6_compareHashes() public {
        for (uint8 i = 1; i <= 100; i++) {
            bytes32 fileHash = keccak256(abi.encode(randomString(10)));
            bytes32 wrongFileHash = keccak256(abi.encode(randomString(11)));

            assertTrue(
                notarizationClassicV2.compareHashes(fileHash, fileHash),
                "Function returns false when comparing equal hashes"
            );
            assertFalse(
                notarizationClassicV2.compareHashes(fileHash, wrongFileHash),
                "Function returns true when comparing different hashes"
            );
        }
    }

    /// @notice Tests the `updateFile` function
    /// @dev Checks if the `FileUpdated` event is emitted & if the file hash are updated in the contract
    function test7_updateFile() public {
        string memory fileName = randomString(10);
        bytes32 fileHash = keccak256(abi.encode(fileName));

        vm.expectEmit(true, true, true, true, address(notarizationClassicV2));
        emit FileNotarized(fileName, fileHash);
        notarizationClassicV2.addFile(fileName, fileHash);

        for (uint8 i = 1; i <= 100; i++) {
            bytes32 newFileHash = keccak256(abi.encode(i + 1));

            vm.expectEmit(true, true, true, true, address(notarizationClassicV2));
            emit FileUpdated(fileName, fileHash, newFileHash);
            notarizationClassicV2.updateFile(fileName, newFileHash);

            // Check if file name & file hash are updated in the contract
            bytes32 fileHashFromContract = notarizationClassicV2.getFileHash(fileName);
            string memory fileNameFromContract = notarizationClassicV2.getFileName(newFileHash);
            assertEq(fileHashFromContract, newFileHash, "File hash from contract is not equal to provided one");
            assertEq(fileNameFromContract, fileName, "File name from contract is not equal to provided one");

            // Remember old hash for next iteration
            fileHash = newFileHash;
        }
    }
}
