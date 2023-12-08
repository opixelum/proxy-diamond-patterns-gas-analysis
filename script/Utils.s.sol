// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {strings} from "solidity-stringutils/strings.sol";

/// @title Utils
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract contains utility functions
/// @dev This contract is useful for deploying contracts using the diamond
/// pattern
abstract contract Utils is Script {
    using strings for *;

    /// @notice Get function selectors of a smart contract
    /// @param _contractName The name of the smart contract
    function getSelectors(string memory _contractName) public returns (bytes4[] memory selectors) {
        // Build forge command to get function selectors
        string[] memory command_input = new string[](4);
        command_input[0] = "forge";
        command_input[1] = "inspect";
        command_input[2] = _contractName;
        command_input[3] = "methods";
        bytes memory command_output = vm.ffi(command_input);
        string memory stringified_command_output = string(command_output);

        // Parse command output & extract function selector
        strings.slice memory sliced_command_output = stringified_command_output.toSlice();
        strings.slice memory colon = ":".toSlice();
        strings.slice memory comma = ",".toSlice();
        selectors = new bytes4[]((sliced_command_output.count(colon)));
        for (uint256 i = 0; i < selectors.length; i++) {
            sliced_command_output.split('"'.toSlice());
            selectors[i] = bytes4(sliced_command_output.split(colon).until('"'.toSlice()).keccak());
            sliced_command_output.split(comma);
        }

        return selectors;
    }

    function containsElement(bytes4[] memory array, bytes4 el) public pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == el) {
                return true;
            }
        }

        return false;
    }

    function containsElement(address[] memory array, address el) public pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == el) {
                return true;
            }
        }

        return false;
    }

    function sameMembers(bytes4[] memory array1, bytes4[] memory array2) public pure returns (bool) {
        for (uint256 i = 0; i < array1.length; i++) {
            if (containsElement(array1, array2[i])) {
                return true;
            }
        }

        return false;
    }

    /// @notice Check if two bytes arrays have at least one common element
    /// @param _array1 The first bytes array
    /// @param _array2 The second bytes array
    function haveCommonSelectors(bytes4[] memory _array1, bytes4[] memory _array2) public pure returns (bool) {
        for (uint256 i = 0; i < _array1.length; i++) {
            for (uint256 j = 0; j < _array2.length; j++) {
                if (_array1[i] == _array2[j]) return true;
            }
        }
        return false;
    }

    /// @notice Concatenate two arrays of selectors
    /// @param _array1 The first array
    /// @param _array2 The second array
    function concatenateSelectors(bytes4[] memory _array1, bytes4[] memory _array2)
        public
        pure
        returns (bytes4[] memory)
    {
        bytes4[] memory result = new bytes4[](_array1.length + _array2.length);
        uint256 i = 0;
        for (uint256 j = 0; j < _array1.length; j++) {
            result[i++] = _array1[j];
        }
        for (uint256 j = 0; j < _array2.length; j++) {
            result[i++] = _array2[j];
        }
        return result;
    }

    /// @notice Remove duplicates from an array of selectors
    /// @param _array The array of selectors
    function removeDuplicates(bytes4[] memory _array) public pure returns (bytes4[] memory) {
        bytes4[] memory result = new bytes4[](_array.length);
        uint256 i = 0;
        for (uint256 j = 0; j < _array.length; j++) {
            if (!containsElement(result, _array[j])) {
                result[i++] = _array[j];
            }
        }
        return result;
    }

    /// @notice Merge two arrays of selectors
    /// @param _array1 The first array
    /// @param _array2 The second array
    function mergeSelectors(bytes4[] memory _array1, bytes4[] memory _array2) public pure returns (bytes4[] memory) {
        bytes4[] memory result = concatenateSelectors(_array1, _array2);
        return removeDuplicates(result);
    }

    /// @notice Remove common selectors from the second array
    /// @param _array1 The first array
    /// @param _array2 The second array
    function removeCommonSelectors(bytes4[] memory _array1, bytes4[] memory _array2)
        public
        pure
        returns (bytes4[] memory)
    {
        bytes4[] memory result = new bytes4[](_array2.length);
        uint256 resultIndex = 0;
        for (uint256 i = 0; i < _array2.length; i++) {
            for (uint256 j = 0; j < _array1.length; j++) {
                if (_array2[i] != _array1[j]) {
                    result[resultIndex] = _array2[i];
                    resultIndex++;
                    break;
                }
            }
        }
        return result;
    }

    /// @notice Convert a number to a readable character (letters and numbers)
    /// @param _number The number to convert
    function toReadableCharacter(uint8 _number) private pure returns (bytes1) {
        if (_number < 10) {
            return bytes1(_number + 48); // 0-9
        } else if (_number < 36) {
            return bytes1(_number - 10 + 65); // A-Z
        } else {
            return bytes1(_number - 36 + 97); // a-z
        }
    }

    /// @notice Generate a random human-readable string
    /// @param _length The length of the string
    function randomString(uint256 _length) public view returns (string memory) {
        bytes memory randomBytes = new bytes(_length);
        for (uint256 i = 0; i < _length; i++) {
            // Generate a random number between 0 and 61 (inclusive), which is the number of readable characters
            uint8 randomNumber = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, i))) % 62);

            // Convert the generated number to a readable character, and add it to the string
            randomBytes[i] = toReadableCharacter(randomNumber);
        }
        return string(randomBytes);
    }
}
