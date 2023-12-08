// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import {SolidStateDiamond} from "solidstate-solidity/proxy/diamond/SolidStateDiamond.sol";

/// @title NotarizationDiamond
/// @author Anto Benedetti (anto.benedetti@cea.fr)
/// @notice This contract is the entry point for the notarization using the
/// diamond pattern
/// @dev This contract uses the diamond pattern
contract NotarizationDiamond is SolidStateDiamond {}
