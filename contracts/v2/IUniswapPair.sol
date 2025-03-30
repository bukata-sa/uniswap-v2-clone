// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/token/ERC20/IERC20.sol";

interface IUniswapPair {
    function tokens() external view returns (address token0, address token1);
    function getReserves() external view returns (uint256 reserve0, uint256 reserve1);

    function mint(uint256 amount0, uint256 amount1) external returns (uint256 liquidity);
    function burn(uint256 liquidity) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0In, uint256 amount1In, uint256 amount0OutMin, uint256 amount1OutMin) external returns (uint256 amount0Out, uint256 amount1Out);
}