// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Utils} from "./Utils.sol";
import {UniswapPair} from "./UniswapPair.sol";
import {UniswapLibrary} from "./UniswapLibrary.sol";

contract UniswapFactory {
    address private immutable i_pairImpl;

    constructor(address feeReceiver) {
        i_pairImpl = address(new UniswapPair(feeReceiver));
    }

    function pairImplementation() public view returns (address) {
        return i_pairImpl;
    }

    function pairAddress(address token0, address token1) public view returns (address) {
        address _token0 = Utils.min(token0, token1);
        address _token1 = Utils.max(token0, token1);
        (bytes32 salt, bytes memory bytecode) = UniswapLibrary.pairSaltAndBytecode(i_pairImpl, _token0, _token1);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xFF), address(this), salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }

    function safePairAddress(address token0, address token1) public view returns (address) {
        require(token0 != token1, "tokens must be different");
        require(token0 != address(0) && token1 != address(0), "tokens must be non-zero");
        address pair = pairAddress(token0, token1);
        if (pair.code.length == 0) {
            // TODO
            revert(string(abi.encode("no code for pair", token0, token1)));
        }
        return pair;
    }

    function createPair(address token0, address token1) public returns (address) {
        require(token0 != token1, "tokens must be different");
        require(token0 != address(0) && token1 != address(0), "tokens must be non-zero");
        address _token0 = Utils.min(token0, token1);
        address _token1 = Utils.max(token0, token1);
        (bytes32 salt, bytes memory bytecode) = UniswapLibrary.pairSaltAndBytecode(i_pairImpl, _token0, _token1);
        address pair;
        assembly {
            pair := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(pair)) { revert(0, 0) }
        }
        return pair;
    }
}
