// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {AddFileFacet} from "../../src/diamond-pattern/facets/v1/AddFileFacet.sol";
import {AddFileFacetV3} from "../../src/diamond-pattern/facets/v3/AddFileFacetV3.sol";
import {CompareHashesFacet} from "../../src/diamond-pattern/facets/v1/CompareHashesFacet.sol";
import {DeleteFileFacetV3} from "../../src/diamond-pattern/facets/v3/DeleteFileFacetV3.sol";
import {GetFileFacet} from "../../src/diamond-pattern/facets/v1/GetFileFacet.sol";
import {GettersFacetV3} from "../../src/diamond-pattern/facets/v3/GettersFacetV3.sol";
import {IDiamondWritableInternal} from "solidstate-solidity/proxy/diamond/writable/IDiamondWritableInternal.sol";
import {NotarizationDiamond} from "../../src/diamond-pattern/NotarizationDiamond.sol";
import {Test} from "forge-std/Test.sol";
import {UpdateFileFacet} from "../../src/diamond-pattern/facets/v2/UpdateFileFacet.sol";
import {UpdateFileFacetV3} from "../../src/diamond-pattern/facets/v3/UpdateFileFacetV3.sol";
import {Utils} from "../../script/Utils.s.sol";

/// @title NotarizationDiamondV2Test
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract tests all the functions after the addition of the
/// updateFileFacet to the NotarizationDiamond contract
/// @dev Tests can only be run using Forge
contract NotarizationDiamondV2Test is Test, Utils {
    // Define events emitted by the tested contract for testing
    event FileNotarized(string indexed name, bytes32 indexed hash);
    event FileUpdated(string indexed name, bytes32 indexed oldHash, bytes32 indexed newHash);

    NotarizationDiamond public notarizationDiamond;
    AddFileFacet public addFileFacet;
    CompareHashesFacet public compareHashesFacet;
    GetFileFacet public getFileFacet;
    UpdateFileFacet public updateFileFacet;

    // V3 facets
    AddFileFacetV3 public addFileFacetV3;
    DeleteFileFacetV3 public deleteFileFacetV3;
    GettersFacetV3 public gettersFacetV3;
    UpdateFileFacetV3 public updateFileFacetV3;

    /// @notice Sets up the test environment
    /// @dev Deploys the diamond & its facets, performs a diamond cut before each test
    function setUp() public {
        notarizationDiamond = new NotarizationDiamond();
        addFileFacet = new AddFileFacet();
        compareHashesFacet = new CompareHashesFacet();
        getFileFacet = new GetFileFacet();
        updateFileFacet = new UpdateFileFacet();

        bytes4[] memory addFileFacetSelectors = getSelectors("AddFileFacet");
        bytes4[] memory compareHashesFacetSelectors = getSelectors("CompareHashesFacet");
        bytes4[] memory getFileFacetSelectors = getSelectors("GetFileFacet");
        bytes4[] memory updateFileFacetSelectors = getSelectors("UpdateFileFacet");

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](4);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(addFileFacet),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: addFileFacetSelectors
        });
        facetCuts[1] = IDiamondWritableInternal.FacetCut({
            target: address(compareHashesFacet),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: compareHashesFacetSelectors
        });
        facetCuts[2] = IDiamondWritableInternal.FacetCut({
            target: address(getFileFacet),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: getFileFacetSelectors
        });
        facetCuts[3] = IDiamondWritableInternal.FacetCut({
            target: address(updateFileFacet),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: updateFileFacetSelectors
        });

        notarizationDiamond.diamondCut(facetCuts, address(0), "");
    }

    /// @notice Tests the `addFile` function, with file names of different lengths
    /// @dev Checks if the `FileNotarized` event is emitted & if the file name & file hash are stored in the contract
    function test1_AddFile_variantLengths() public {
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(i);
            bytes32 fileHash = keccak256(abi.encode(fileName));

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileNotarized(fileName, fileHash);
            AddFileFacet(address(notarizationDiamond)).addFile(fileName, fileHash);

            // Check if file name & file hash are stored in the contract
            bytes32 fileHashFromContract = GetFileFacet(address(notarizationDiamond)).getFileHash(fileName);
            string memory fileNameFromContract = GetFileFacet(address(notarizationDiamond)).getFileName(fileHash);
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

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileNotarized(fileName, fileHash);
            AddFileFacet(address(notarizationDiamond)).addFile(fileName, fileHash);

            // Check if file name & file hash are stored in the contract
            bytes32 fileHashFromContract = GetFileFacet(address(notarizationDiamond)).getFileHash(fileName);
            string memory fileNameFromContract = GetFileFacet(address(notarizationDiamond)).getFileName(fileHash);
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

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileNotarized(fileName, fileHash);
            AddFileFacet(address(notarizationDiamond)).addFile(fileName, fileHash);

            // Check if file name & file hash are stored in the contract
            bytes32 fileHashFromContract = GetFileFacet(address(notarizationDiamond)).getFileHash(fileName);
            string memory fileNameFromContract = GetFileFacet(address(notarizationDiamond)).getFileName(fileHash);
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

        vm.expectEmit(true, true, true, true, address(notarizationDiamond));
        emit FileNotarized(fileName, fileHash);
        AddFileFacet(address(notarizationDiamond)).addFile(fileName, fileHash);

        bytes32 fileHashFromContract = GetFileFacet(address(notarizationDiamond)).getFileHash(fileName);
        assertFalse(fileHashFromContract == wrongFileHash, "File hash from contract is equal to wrong file hash");
    }

    /// @notice Tests the `getFileName` function
    /// @dev Since we're already testing it in `test1_AddFile`, we only check if the function returns does not return a
    /// wrong file name
    function test5_getFileName() public {
        string memory fileName = randomString(10);
        bytes32 fileHash = keccak256(abi.encode(fileName));
        string memory wrongFileName = randomString(11);

        vm.expectEmit(true, true, true, true, address(notarizationDiamond));
        emit FileNotarized(fileName, fileHash);
        AddFileFacet(address(notarizationDiamond)).addFile(fileName, fileHash);

        string memory fileNameFromContract = GetFileFacet(address(notarizationDiamond)).getFileName(fileHash);
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
                CompareHashesFacet(address(notarizationDiamond)).compareHashes(fileHash, fileHash),
                "Function returns false when comparing equal hashes"
            );
            assertFalse(
                CompareHashesFacet(address(notarizationDiamond)).compareHashes(fileHash, wrongFileHash),
                "Function returns true when comparing different hashes"
            );
        }
    }

    /// @notice Tests the `updateFile` function
    /// @dev Checks if the `FileUpdated` event is emitted & if the file hash are updated in the contract
    function test7_updateFile() public {
        string memory fileName = randomString(10);
        bytes32 fileHash = keccak256(abi.encode(fileName));

        vm.expectEmit(true, true, true, true, address(notarizationDiamond));
        emit FileNotarized(fileName, fileHash);
        AddFileFacet(address(notarizationDiamond)).addFile(fileName, fileHash);

        for (uint8 i = 1; i <= 100; i++) {
            bytes32 newFileHash = keccak256(abi.encode(randomString(i + 1)));

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileUpdated(fileName, fileHash, newFileHash);
            UpdateFileFacet(address(notarizationDiamond)).updateFile(fileName, newFileHash);

            // Check if file name & file hash are updated in the contract
            bytes32 fileHashFromContract = GetFileFacet(address(notarizationDiamond)).getFileHash(fileName);
            string memory fileNameFromContract = GetFileFacet(address(notarizationDiamond)).getFileName(newFileHash);
            assertEq(fileHashFromContract, newFileHash, "File hash from contract is not equal to provided one");
            assertEq(fileNameFromContract, fileName, "File name from contract is not equal to provided one");

            // Remember old hash for next iteration
            fileHash = newFileHash;
        }
    }

    function test8_upgradeToV3() public {
        AddFileFacetV3 addFileFacetV3 = new AddFileFacetV3();
        DeleteFileFacetV3 deleteFileFacetV3 = new DeleteFileFacetV3();
        GettersFacetV3 gettersFacetV3 = new GettersFacetV3();
        UpdateFileFacetV3 updateFileFacetV3 = new UpdateFileFacetV3();

        bytes4[] memory addFileFacetSelectors = getSelectors("AddFileFacet");
        bytes4[] memory compareHashesFacetSelectors = getSelectors("CompareHashesFacet");
        bytes4[] memory getFileFacetSelectors = getSelectors("GetFileFacet");
        bytes4[] memory updateFileFacetSelectors = getSelectors("UpdateFileFacet");
        bytes4[] memory addFileFacetV3Selectors = getSelectors("AddFileFacetV3");
        bytes4[] memory deleteFileFacetV3Selectors = getSelectors("DeleteFileFacetV3");
        bytes4[] memory gettersFacetV3Selectors = getSelectors("GettersFacetV3");
        bytes4[] memory updateFileFacetV3Selectors = getSelectors("UpdateFileFacetV3");

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](8);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(0),
            action: IDiamondWritableInternal.FacetCutAction.REMOVE,
            selectors: addFileFacetSelectors
        });
        facetCuts[1] = IDiamondWritableInternal.FacetCut({
            target: address(0),
            action: IDiamondWritableInternal.FacetCutAction.REMOVE,
            selectors: compareHashesFacetSelectors
        });
        facetCuts[2] = IDiamondWritableInternal.FacetCut({
            target: address(0),
            action: IDiamondWritableInternal.FacetCutAction.REMOVE,
            selectors: getFileFacetSelectors
        });
        facetCuts[3] = IDiamondWritableInternal.FacetCut({
            target: address(0),
            action: IDiamondWritableInternal.FacetCutAction.REMOVE,
            selectors: updateFileFacetSelectors
        });
        facetCuts[4] = IDiamondWritableInternal.FacetCut({
            target: address(addFileFacetV3),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: addFileFacetV3Selectors
        });
        facetCuts[5] = IDiamondWritableInternal.FacetCut({
            target: address(deleteFileFacetV3),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: deleteFileFacetV3Selectors
        });
        facetCuts[6] = IDiamondWritableInternal.FacetCut({
            target: address(gettersFacetV3),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: gettersFacetV3Selectors
        });
        facetCuts[7] = IDiamondWritableInternal.FacetCut({
            target: address(updateFileFacetV3),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: updateFileFacetV3Selectors
        });

        notarizationDiamond.diamondCut(facetCuts, address(0), "");

        // Check if the facet address has been correctly added to the diamond
        assertEq(
            notarizationDiamond.facetAddress(addFileFacetV3Selectors[0]),
            address(addFileFacetV3),
            "Facet address is not equal to the address of the deployed facet"
        );
        assertEq(
            notarizationDiamond.facetAddress(deleteFileFacetV3Selectors[0]),
            address(deleteFileFacetV3),
            "Facet address is not equal to the address of the deployed facet"
        );
        assertEq(
            notarizationDiamond.facetAddress(gettersFacetV3Selectors[0]),
            address(gettersFacetV3),
            "Facet address is not equal to the address of the deployed facet"
        );
        assertEq(
            notarizationDiamond.facetAddress(updateFileFacetV3Selectors[0]),
            address(updateFileFacetV3),
            "Facet address is not equal to the address of the deployed facet"
        );

        // Check if the facet functions selectors have been correctly added to the diamond
        bytes4[] memory addFileFacetV3SelectorsFromContract =
                            notarizationDiamond.facetFunctionSelectors(address(addFileFacetV3));
        assertTrue(
            sameMembers(addFileFacetV3Selectors, addFileFacetV3SelectorsFromContract), "Selectors are not equal"
        );
        bytes4[] memory deleteFileFacetV3SelectorsFromContract =
                            notarizationDiamond.facetFunctionSelectors(address(deleteFileFacetV3));
        assertTrue(
            sameMembers(deleteFileFacetV3Selectors, deleteFileFacetV3SelectorsFromContract), "Selectors are not equal"
        );
        bytes4[] memory gettersFacetV3SelectorsFromContract =
                            notarizationDiamond.facetFunctionSelectors(address(gettersFacetV3));
        assertTrue(
            sameMembers(gettersFacetV3Selectors, gettersFacetV3SelectorsFromContract), "Selectors are not equal"
        );
        bytes4[] memory updateFileFacetV3SelectorsFromContract =
                            notarizationDiamond.facetFunctionSelectors(address(updateFileFacetV3));
        assertTrue(
            sameMembers(updateFileFacetV3Selectors, updateFileFacetV3SelectorsFromContract), "Selectors are not equal"
        );

        // Check if the old facet functions selectors have been correctly removed from the diamond
        bytes4[] memory addFileFacetSelectorsFromContract =
                            notarizationDiamond.facetFunctionSelectors(address(addFileFacet));
        assertTrue(
            addFileFacetSelectorsFromContract.length == 0, "Selectors are not equal"
        );
        bytes4[] memory compareHashesFacetSelectorsFromContract =
                            notarizationDiamond.facetFunctionSelectors(address(compareHashesFacet));
        assertTrue(
            compareHashesFacetSelectorsFromContract.length == 0, "Selectors are not equal"
        );
        bytes4[] memory getFileFacetSelectorsFromContract =
                            notarizationDiamond.facetFunctionSelectors(address(getFileFacet));
        assertTrue(
            getFileFacetSelectorsFromContract.length == 0, "Selectors are not equal"
        );
        bytes4[] memory updateFileFacetSelectorsFromContract =
                            notarizationDiamond.facetFunctionSelectors(address(updateFileFacet));
        assertTrue(
            updateFileFacetSelectorsFromContract.length == 0, "Selectors are not equal"
        );
    }
}
