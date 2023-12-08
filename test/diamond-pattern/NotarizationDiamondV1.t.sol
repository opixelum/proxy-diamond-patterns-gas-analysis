// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {NotarizationDiamond} from "../../src/diamond-pattern/NotarizationDiamond.sol";
import {AddFileFacet} from "../../src/diamond-pattern/facets/v1/AddFileFacet.sol";
import {CompareHashesFacet} from "../../src/diamond-pattern/facets/v1/CompareHashesFacet.sol";
import {GetFileFacet} from "../../src/diamond-pattern/facets/v1/GetFileFacet.sol";
import {IDiamondWritableInternal} from "solidstate-solidity/proxy/diamond/writable/IDiamondWritableInternal.sol";
import {Test} from "forge-std/Test.sol";
import {UpdateFileFacet} from "../../src/diamond-pattern/facets/v2/UpdateFileFacet.sol";
import {Utils} from "../../script/Utils.s.sol";

/// @title NotarizationDiamondV1Test
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract tests all the functions of the facets for the V1 of
/// NotarizationDiamond contract
/// @dev Tests can only be run using Forge
contract NotarizationDiamondV1Test is Test, Utils {
    // Define events emitted by the tested contract for testing
    event FileNotarized(string indexed name, bytes32 indexed hash);
    event FileUpdated(string indexed name, bytes32 indexed oldHash, bytes32 indexed newHash);

    NotarizationDiamond public notarizationDiamond;
    AddFileFacet public addFileFacet;
    CompareHashesFacet public compareHashesFacet;
    GetFileFacet public getFileFacet;

    /// @notice Sets up the test environment
    /// @dev Deploys the diamond & its facets, performs a diamond cut before each test
    function setUp() public {
        notarizationDiamond = new NotarizationDiamond();
        addFileFacet = new AddFileFacet();
        compareHashesFacet = new CompareHashesFacet();
        getFileFacet = new GetFileFacet();

        bytes4[] memory addFileFacetSelectors = getSelectors("AddFileFacet");
        bytes4[] memory compareHashesFacetSelectors = getSelectors("CompareHashesFacet");
        bytes4[] memory getFileFacetSelectors = getSelectors("GetFileFacet");

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](3);
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
        for (uint256 i = 1; i <= 100; i++) {
            string memory fileName = randomString(10);
            bytes32 fileHash = keccak256(abi.encode(fileName));
            bytes32 wrongFileHash = keccak256(abi.encode(randomString(11)));

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileNotarized(fileName, fileHash);
            AddFileFacet(address(notarizationDiamond)).addFile(fileName, fileHash);

            bytes32 fileHashFromContract = GetFileFacet(address(notarizationDiamond)).getFileHash(fileName);
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

            vm.expectEmit(true, true, true, true, address(notarizationDiamond));
            emit FileNotarized(fileName, fileHash);
            AddFileFacet(address(notarizationDiamond)).addFile(fileName, fileHash);

            string memory fileNameFromContract = GetFileFacet(address(notarizationDiamond)).getFileName(fileHash);
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

    /// @notice Tests a diamond cut for adding a facet
    /// @dev Checks if the facet is added to the diamond
    function test7_upgradeToV2() public {
        UpdateFileFacet updateFileFacet = new UpdateFileFacet();
        bytes4[] memory updateFileFacetSelectors = getSelectors("UpdateFileFacet");

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(updateFileFacet),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: updateFileFacetSelectors
        });

        notarizationDiamond.diamondCut(facetCuts, address(0), "");

        // Check if the facet address has been correctly added to the diamond
        assertEq(
            notarizationDiamond.facetAddress(updateFileFacetSelectors[0]),
            address(updateFileFacet),
            "Facet address is not equal to the address of the deployed facet"
        );
        // Check if the facet functions selectors have been correctly added to the diamond
        bytes4[] memory updateFileFacetSelectorsFromContract =
            notarizationDiamond.facetFunctionSelectors(address(updateFileFacet));
        assertTrue(
            sameMembers(updateFileFacetSelectors, updateFileFacetSelectorsFromContract), "Selectors are not equal"
        );
    }
}
