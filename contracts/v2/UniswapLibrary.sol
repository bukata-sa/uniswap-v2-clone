// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Utils.sol";

library UniswapLibrary {
    function pairSaltAndBytecode(address impl, address token0, address token1)
        public
        pure
        returns (bytes32 salt, bytes memory bytecode)
    {
        salt = keccak256(abi.encode(token0, token1));
        bytes20 _impl = bytes20(impl);
        bytes20 _token0 = bytes20(token0);
        bytes20 _token1 = bytes20(token1);
        // bytecode = 3d60<implsize>80600a3d3981f3363d3d373d3d3d363d73 || impl || 5af43d82803e903d91602b57fd5bf3 || token0 || token1
        // bytecode = 20 bytes + 20 bytes + 15 bytes + 20 bytes + 20 bytes = 95
        // implsize = 0x5f (0x2d in EIP-1127)
        bytecode = new bytes(95);
        assembly {
            // implsize here is 0x5f (offset 0x22)
            mstore(add(bytecode, 0x20), hex"3d605f80600a3d3981f3363d3d373d3d3d363d73")
            mstore(add(bytecode, 0x34), _impl)
            mstore(add(bytecode, 0x48), hex"5af43d82803e903d91602b57fd5bf3")
            mstore(add(bytecode, 0x57), _token0)
            mstore(add(bytecode, 0x6B), _token1)
        }
    }
}
