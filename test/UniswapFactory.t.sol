// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {UniswapLibrary} from "../contracts/v2/UniswapLibrary.sol";
import {UniswapFactory} from "../contracts/v2/UniswapFactory.sol";
import {IUniswapPair} from "../contracts/v2/IUniswapPair.sol";
import {console} from "forge-std/console.sol";

contract UniswapFactoryTest is Test {
    UniswapFactory private factory;

    function setUp() public {
        factory = new UniswapFactory(address(0));
    }

    function testBytecode() public view {
        address token0 = address(0x01);
        address token1 = address(0x02);
        address impl = factory.pairImplementation();
        (, bytes memory bytecode) = UniswapLibrary.pairSaltAndBytecode(impl, token0, token1);
        assertEq(
            abi.encodePacked(
                hex"3d605f80600a3d3981f3363d3d373d3d3d363d73", impl, hex"5af43d82803e903d91602b57fd5bf3", token0, token1
            ),
            bytecode
        );
    }

    function testDeployPair() public {
        address expectedToken0 = address(0x01);
        address expectedToken1 = address(0x02);
        address pairExpected = factory.pairAddress(expectedToken0, expectedToken1);
        assertTrue(pairExpected.code.length == 0);
        address pairActual = factory.createPair(expectedToken0, expectedToken1);
        assertEq(pairExpected, pairActual);
        console.logBytes(pairActual.code);
        (address actualToken0, address actualToken1) = IUniswapPair(pairActual).tokens();
        assertEq(expectedToken0, actualToken0);
        assertEq(expectedToken1, actualToken1);
    }
}
