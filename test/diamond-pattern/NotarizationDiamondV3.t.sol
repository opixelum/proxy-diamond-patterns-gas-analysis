// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {NotarizationDiamond} from "../../src/diamond-pattern/NotarizationDiamond.sol";
import {AddFileFacetV3} from "../../src/diamond-pattern/facets/v3/AddFileFacetV3.sol";
import {DeleteFileFacetV3} from "../../src/diamond-pattern/facets/v3/DeleteFileFacetV3.sol";
import {GettersFacetV3} from "../../src/diamond-pattern/facets/v3/GettersFacetV3.sol";
import {UpdateFileFacetV3} from "../../src/diamond-pattern/facets/v3/UpdateFileFacetV3.sol";
import {IDiamondWritableInternal} from "solidstate-solidity/proxy/diamond/writable/IDiamondWritableInternal.sol";
import {LibNotarizationDiamondV3} from "../../src/diamond-pattern/libraries/LibNotarizationDiamondV3.sol";
import {Test} from "forge-std/Test.sol";
import {Utils} from "../../script/Utils.s.sol";

/// @title NotarizationDiamondV3Test
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract tests all the functions of the V3 facets of the
/// NotarizationDiamond contract
/// @dev Tests can only be run using Forge
contract NotarizationDiamondV3Test is Test, Utils {
    // Define events emitted by the tested contract for testing
    event FileNotarized(
        address indexed owner,
        string indexed filename,
        bytes32 indexed hash
    );
    event FileUpdated(
        string indexed filename,
        bytes32 indexed oldHash,
        bytes32 indexed newHash
    );
    event FileDeleted(string indexed filename, bytes32 indexed hash);

    NotarizationDiamond public notarizationDiamond;
    AddFileFacetV3 public addFileFacetV3;
    DeleteFileFacetV3 public deleteFileFacetV3;
    GettersFacetV3 public gettersFacetV3;
    UpdateFileFacetV3 public updateFileFacetV3;

    /// @notice Sets up the test environment
    /// @dev Deploys the diamond & its facets, performs a diamond cut before each test
    function setUp() public {
        notarizationDiamond = new NotarizationDiamond();
        addFileFacetV3 = new AddFileFacetV3();
        deleteFileFacetV3 = new DeleteFileFacetV3();
        gettersFacetV3 = new GettersFacetV3();
        updateFileFacetV3 = new UpdateFileFacetV3();

        bytes4[] memory addFileFacetV3Selectors = getSelectors("AddFileFacetV3");
        bytes4[] memory deleteFileFacetV3Selectors = getSelectors("DeleteFileFacetV3");
        bytes4[] memory gettersFacetV3Selectors = getSelectors("GettersFacetV3");
        bytes4[] memory updateFileFacetV3Selectors = getSelectors("UpdateFileFacetV3");

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](4);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(addFileFacetV3),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: addFileFacetV3Selectors
        });
        facetCuts[1] = IDiamondWritableInternal.FacetCut({
            target: address(deleteFileFacetV3),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: deleteFileFacetV3Selectors
        });
        facetCuts[2] = IDiamondWritableInternal.FacetCut({
            target: address(gettersFacetV3),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: gettersFacetV3Selectors
        });
        facetCuts[3] = IDiamondWritableInternal.FacetCut({
            target: address(updateFileFacetV3),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: updateFileFacetV3Selectors
        });

        notarizationDiamond.diamondCut(facetCuts, address(0), "");
    }

    /// @notice Tests the `addFile` function, with file names of different lengths
    /// @dev Checks if the `FileNotarized` event is emitted & if the file name & file hash are stored in the contract
    function test01_addFile_variantLengths() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(i);
            bytes32 fileHash = keccak256(abi.encode(fileName));

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileNotarized(address(this), fileName, fileHash);
            AddFileFacetV3(address(notarizationDiamond)).addFile(fileName, fileHash);

            // Check if file name & file hash are stored in the contract
            string memory fileNameFromContract = GettersFacetV3(address(notarizationDiamond))
                .getFilename(fileHash);
            LibNotarizationDiamondV3.File memory fileDetailsFromContract = GettersFacetV3(address(notarizationDiamond))
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

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileNotarized(address(this), fileName, fileHash);
            AddFileFacetV3(address(notarizationDiamond)).addFile(fileName, fileHash);

            // Check if file name & file hash are stored in the contract
            string memory fileNameFromContract = GettersFacetV3(address(notarizationDiamond))
                .getFilename(fileHash);
            LibNotarizationDiamondV3.File memory fileDetailsFromContract = GettersFacetV3(address(notarizationDiamond))
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

        vm.expectEmit(true, true, true, true, address(notarizationDiamond));
        emit FileNotarized(address(this), fileName, fileHash);
        AddFileFacetV3(address(notarizationDiamond)).addFile(fileName, fileHash);

        for (uint256 i = 1; i <= 100; i++) {
            bytes32 newFileHash = keccak256(abi.encode(randomString(i)));

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileUpdated(fileName, fileHash, newFileHash);
            UpdateFileFacetV3(address(notarizationDiamond)).updateFile(fileName, newFileHash);

            bytes32 fileHashFromContract = GettersFacetV3(address(notarizationDiamond)).getFileHash(
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
        UpdateFileFacetV3(address(notarizationDiamond)).updateFile(fileName, newFileHash);
    }

    /// @notice Expect `onlyOwner` modifier to revert when the sender is not the file owner
    /// @dev We "prank" the contract by sending a transaction from a different address,
    /// and check if the revert message is correct
    function test05_expectRevert_onlyOwner() public {
        string memory fileName = "0";
        bytes32 fileHash = keccak256(abi.encode(fileName));

        vm.expectEmit(true, true, true, true, address(notarizationDiamond));
        emit FileNotarized(address(this), fileName, fileHash);
        AddFileFacetV3(address(notarizationDiamond)).addFile(fileName, fileHash);

        bytes32 newFileHash = keccak256(abi.encode(randomString(10)));
        vm.expectRevert("Not the file owner");
        vm.prank(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        UpdateFileFacetV3(address(notarizationDiamond)).updateFile(fileName, newFileHash);
    }

    /// @notice Tests the `deleteFile` function
    /// @dev Checks if the `FileDeleted` event is emitted & if the file is deleted from the contract
    function test06_deleteFile() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(i);
            bytes32 fileHash = keccak256(abi.encode(fileName));

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileNotarized(address(this), fileName, fileHash);
            AddFileFacetV3(address(notarizationDiamond)).addFile(fileName, fileHash);

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileDeleted(fileName, fileHash);
            DeleteFileFacetV3(address(notarizationDiamond)).deleteFile(fileName);

            bytes32 fileHashFromContract = GettersFacetV3(address(notarizationDiamond)).getFileHash(
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

        vm.expectEmit(true, true, true, true, address(notarizationDiamond));
        emit FileNotarized(address(this), fileName, fileHash);
        AddFileFacetV3(address(notarizationDiamond)).addFile(fileName, fileHash);

        string memory fileNameFromContract = GettersFacetV3(address(notarizationDiamond)).getFilename(
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
        LibNotarizationDiamondV3.File memory wrongFileDetails = LibNotarizationDiamondV3.File(keccak256(abi.encode(randomString(11))),
            0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            123456789,
            123456789
        );

        vm.expectEmit(true, true, true, true, address(notarizationDiamond));
        emit FileNotarized(address(this), fileName, fileHash);
        AddFileFacetV3(address(notarizationDiamond)).addFile(fileName, fileHash);

        LibNotarizationDiamondV3.File memory fileDetailsFromContract = GettersFacetV3(address(notarizationDiamond))
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

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileNotarized(address(this), fileName, fileHash);
            AddFileFacetV3(address(notarizationDiamond)).addFile(fileName, fileHash);

            bytes32 fileHashFromContract = GettersFacetV3(address(notarizationDiamond)).getFileHash(
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

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileNotarized(address(this), fileName, fileHash);
            AddFileFacetV3(address(notarizationDiamond)).addFile(fileName, fileHash);

            address fileOwnerFromContract = GettersFacetV3(address(notarizationDiamond)).getFileOwner(
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

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileNotarized(address(this), fileName, fileHash);
            AddFileFacetV3(address(notarizationDiamond)).addFile(fileName, fileHash);

            uint256 fileCreatedAtFromContract = GettersFacetV3(address(notarizationDiamond))
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

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileNotarized(address(this), fileName, fileHash);
            AddFileFacetV3(address(notarizationDiamond)).addFile(fileName, fileHash);

            uint256 fileLastModifiedAtFromContract = GettersFacetV3(address(notarizationDiamond))
                .getFileLastModifiedAt(fileName);
            assertFalse(
                fileLastModifiedAtFromContract == wrongFileLastModifiedAt,
                "File name from contract is equal to wrong file name"
            );
        }
    }
}
