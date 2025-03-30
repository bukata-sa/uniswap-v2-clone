// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "./Utils.sol";
import {IUniswapPair} from "./IUniswapPair.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {Math} from "@openzeppelin/utils/math/Math.sol";
import {UQ128x128} from "./UQ128x128.sol";

contract UniswapPair is IUniswapPair, ERC20 {
    using SafeTransferLib for address;
    using UQ128x128 for uint256;

    uint16 private constant MINIMUM_LIQUIDITY = 10 ** 3;

    address private immutable i_feeReceiver;

    uint256 private s_reserves0;
    uint256 private s_reserves1;
    uint256 private s_timestamp;
    uint256 private s_kLast;
    uint256 private s_priceCumulative0Last;
    uint256 private s_priceCumulative1Last;

    constructor(address _feeReceiver) {
        i_feeReceiver = _feeReceiver;
    }

    function name() public pure override returns (string memory) {
        return "Uniswap Liquidity Token";
    }

    function symbol() public pure override returns (string memory) {
        return "ULP";
    }

    // tokens are stored in proxy's bytecode
    function tokens() public view returns (address token0, address token1) {
        assembly {
            let ptr := mload(0x40)
            extcodecopy(address(), ptr, 45, 40)
            token0 := shr(96, mload(ptr))
            token1 := shr(96, mload(add(ptr, 20)))
        }
    }

    function feeReceiver() public view returns (address) {
        return i_feeReceiver;
    }

    function getReserves() external view returns (uint256 reserve0, uint256 reserve1) {
        return _reserves();
    }

    function _reserves() private view returns (uint256, uint256) {
        return (s_reserves0, s_reserves1);
    }

    function mint(uint256 amount0, uint256 amount1) external returns (uint256 liquidity) {
        require(amount0 > 0 && amount1 > 0, "both amounts must be greater than zero");
        (address token0, address token1) = tokens();
        (uint256 _r0, uint256 _r1) = _reserves();
        uint256 lpSupply = totalSupply();
        // mint fee before accounting new liquidity
        mintFee(lpSupply, _r0, _r1);
        if (lpSupply == 0) {
            require(
                Math.sqrt(amount0 * amount1) > MINIMUM_LIQUIDITY, "not enough liqidity provided during the initial call"
            );
            _mint(address(this), MINIMUM_LIQUIDITY);
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
        } else {
            liquidity = Math.min(amount0 * lpSupply / _r0, amount1 * lpSupply / _r1);
        }
        token0.safeTransferFrom(msg.sender, address(this), amount0);
        token1.safeTransferFrom(msg.sender, address(this), amount1);
        _mint(msg.sender, liquidity);
        s_reserves0 = _r0 + amount0;
        s_reserves1 = _r1 + amount1;
        if (i_feeReceiver != address(0)) s_kLast = s_reserves0 * s_reserves1;
        return liquidity;
    }

    function burn(uint256 liquidity) external returns (uint256 amount0, uint256 amount1) {
        require(liquidity > 0, "zero liquidity input");
        (address token0, address token1) = tokens();
        (uint256 _r0, uint256 _r1) = _reserves();
        uint256 lpSupply = totalSupply();
        // mint fee before accounting new liquidity
        mintFee(lpSupply, _r0, _r1);
        amount0 = liquidity * _r0 / lpSupply;
        amount1 = liquidity * _r1 / lpSupply;
        _burn(msg.sender, liquidity);
        token0.safeTransfer(msg.sender, amount0);
        token1.safeTransfer(msg.sender, amount1);
        s_reserves0 = _r0 - amount0;
        s_reserves1 = _r1 - amount1;
        if (i_feeReceiver != address(0)) s_kLast = s_reserves0 * s_reserves1;
        return (amount0, amount1);
    }

    function swap(uint256 amount0In, uint256 amount1In, uint256 amount0OutMin, uint256 amount1OutMin)
        external
        returns (uint256 amount0Out, uint256 amount1Out)
    {
        require(amount0In > 0 && amount1In == 0 || amount0In == 0 && amount1In > 0, "one and only one amount must be 0");
        (address token0, address token1) = tokens();
        (uint256 _r0, uint256 _r1) = _reserves();
        amount0Out = 997 * amount0In * _r1 / (1000 * _r0 + 997 * amount0In);
        amount1Out = 997 * amount1In * _r0 / (1000 * _r1 + 997 * amount1In);
        if (amount0In > 0) {
            require(amount1Out >= amount1OutMin, "final amount1Out is less than min");
            token0.safeTransferFrom(msg.sender, address(this), amount0In);
            token1.safeTransfer(msg.sender, amount1Out);
        } else {
            require(amount0Out >= amount0OutMin, "final amount0Out is less than min");
            token1.safeTransferFrom(msg.sender, address(this), amount1In);
            token0.safeTransfer(msg.sender, amount0Out);
        }
        s_reserves0 = _r0 + amount0In - amount0Out;
        s_reserves1 = _r1 + amount1In - amount1Out;
        return (amount0Out, amount1Out);
    }

    function mintFee(uint256 lpSupply, uint256 _r0, uint256 _r1) public returns (uint256 fee) {
        if (i_feeReceiver == address(0)) {
            return 0;
        }
        uint256 rootK = Math.sqrt(_r0 * _r1);
        uint256 rootKLast = Math.sqrt(s_kLast);
        require(rootK >= rootKLast, "invariant rootK >= rootKLast violated");
        if (lpSupply > 0 && rootK > rootKLast) {
            // fee can't be zero
            fee = lpSupply * (rootK - rootKLast) / (5 * rootK + rootKLast);
            _mint(i_feeReceiver, fee);
            return fee;
        }
        return 0;
    }

    function _update(uint128 newR0, uint128 newR1) private {
        uint256 elapsed;
        if (s_timestamp > 0) {
            elapsed = block.timestamp - s_timestamp;
        }
        if (elapsed > 0 && newR0 > 0 && newR1 > 0) {
            uint128 _newR0 = uint128(newR0 % UQ128x128.Q128);
            uint128 _newR1 = uint128(newR1 % UQ128x128.Q128);
            s_priceCumulative0Last += UQ128x128.encode(_newR1).uqdiv(_newR0) * elapsed;
            s_priceCumulative1Last += UQ128x128.encode(_newR0).uqdiv(_newR1) * elapsed;
        }
        s_reserves0 = newR0;
        s_reserves1 = newR1;
        s_timestamp = block.timestamp;
    }
}
