// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {NotarizationProxyV1} from "../../src/proxy-pattern/NotarizationProxyV1.sol";
import {NotarizationProxyV2} from "../../src/proxy-pattern/NotarizationProxyV2.sol";
import {Test} from "forge-std/Test.sol";
import {Utils} from "../../script/Utils.s.sol";

/// @title NotarizationProxyV1Test
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract tests all the functions in the NotarizationProxyV1
/// contract
/// @dev Tests can only be run using Forge
contract NotarizationProxyV1Test is Test, Utils {
    // Define events emitted by the tested contract for testing
    event FileNotarized(string indexed name, bytes32 indexed hash);
    event Upgraded(address indexed implementation);

    ERC1967Proxy public proxy;
    NotarizationProxyV1 public logicV1;
    NotarizationProxyV1 public castedProxyV1;
    NotarizationProxyV2 public logicV2;

    /// @notice Sets up the test environment
    /// @dev Deploys proxy & logicV1 contracts, links them, casts the proxy contract to the tested contract before each
    /// test
    function setUp() public {
        // Deploy the logicV1 contract
        logicV1 = new NotarizationProxyV1();

        // Deploy the proxy contract & link it to the logicV1 contract
        proxy = new ERC1967Proxy(address(logicV1), "");

        // Cast the proxy contract to the tested contract for more convenient testing
        castedProxyV1 = NotarizationProxyV1(address(proxy));
        castedProxyV1.initialize();
    }

    /// @notice Tests the `addFile` function, with file names of different lengths
    /// @dev Checks if the `FileNotarized` event is emitted & if the file name & file hash are stored in the contract
    function test1_AddFile_variantLengths() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(i);
            bytes32 fileHash = keccak256(abi.encode(fileName));

            vm.expectEmit(true, true, true, true, address(castedProxyV1));
            emit FileNotarized(fileName, fileHash);
            castedProxyV1.addFile(fileName, fileHash);

            // Check if file name & file hash are stored in the contract
            bytes32 fileHashFromContract = castedProxyV1.getFileHash(fileName);
            string memory fileNameFromContract = castedProxyV1.getFileName(fileHash);
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

            vm.expectEmit(true, true, true, true, address(castedProxyV1));
            emit FileNotarized(fileName, fileHash);
            castedProxyV1.addFile(fileName, fileHash);

            // Check if file name & file hash are stored in the contract
            bytes32 fileHashFromContract = castedProxyV1.getFileHash(fileName);
            string memory fileNameFromContract = castedProxyV1.getFileName(fileHash);
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

            vm.expectEmit(true, true, true, true, address(castedProxyV1));
            emit FileNotarized(fileName, fileHash);
            castedProxyV1.addFile(fileName, fileHash);

            // Check if file name & file hash are stored in the contract
            bytes32 fileHashFromContract = castedProxyV1.getFileHash(fileName);
            string memory fileNameFromContract = castedProxyV1.getFileName(fileHash);
            assertEq(fileHashFromContract, fileHash, "File hash from contract is not equal to provided one");
            assertEq(fileNameFromContract, fileName, "File name from contract is not equal to provided one");
        }
    }

    /// @notice Tests the `getFileHash` function
    /// @dev Since we're already testing it in `test1_AddFile`, we only check if the function returns does not return a
    /// wrong file hash
    function test4_getFileHash() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(10);
            bytes32 fileHash = keccak256(abi.encode(fileName));
            bytes32 wrongFileHash = keccak256(abi.encode(randomString(11)));

            vm.expectEmit(true, true, true, true, address(castedProxyV1));
            emit FileNotarized(fileName, fileHash);
            castedProxyV1.addFile(fileName, fileHash);

            bytes32 fileHashFromContract = castedProxyV1.getFileHash(fileName);
            assertFalse(fileHashFromContract == wrongFileHash, "File hash from contract is equal to wrong file hash");
        }
    }

    /// @notice Tests the `getFileName` function
    /// @dev Since we're already testing it in `test1_AddFile`, we only check if the function returns does not return a
    /// wrong file name
    function test5_getFileName() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(10);
            bytes32 fileHash = keccak256(abi.encode(fileName));
            string memory wrongFileName = randomString(11);

            vm.expectEmit(true, true, true, true, address(castedProxyV1));
            emit FileNotarized(fileName, fileHash);
            castedProxyV1.addFile(fileName, fileHash);

            string memory fileNameFromContract = castedProxyV1.getFileName(fileHash);
            assertFalse(
                keccak256(bytes(fileNameFromContract)) == keccak256(bytes(wrongFileName)),
                "File name from contract is equal to wrong file name"
            );
        }
    }

    /// @notice Tests the `compareHashes` function
    /// @dev Checks if the function returns true when comparing two equal hashes & false when comparing two different
    /// hashes
    function test6_compareHashes() public {
        for (uint8 i = 1; i <= 100; i++) {
            bytes32 fileHash = keccak256(abi.encode(randomString(10)));
            bytes32 wrongFileHash = keccak256(abi.encode(randomString(11)));

            assertTrue(castedProxyV1.compareHashes(fileHash, fileHash), "Function returns false when comparing equal hashes");
            assertFalse(
                castedProxyV1.compareHashes(fileHash, wrongFileHash), "Function returns true when comparing different hashes"
            );
        }
    }

    /// @notice Tests an upgrade of the proxy contract
    /// @dev Deploys the new logicV1, then upgrades the proxy contract to the new logicV1 contract
    function test7_upgradeToV2() public {
        // Deploy the new logicV1 contract
        logicV2 = new NotarizationProxyV2();

        vm.expectEmit(true, true, true, true, address(castedProxyV1));
        emit Upgraded(address(logicV2));
        castedProxyV1.upgradeTo(address(logicV2));
    }
}
