pragma solidity >=0.8.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**128 - 1]
// resolution: 1 / 2**128

library UQ128x128 {
    uint256 public constant Q128 = 2 ** 128;

    // encode a uint128 as a UQ128x128
    function encode(uint128 y) internal pure returns (uint256 z) {
        z = uint256(y) * Q128; // never overflows
    }

    // divide a UQ128x128 by a uint128, returning a UQ128x128
    function uqdiv(uint256 x, uint128 y) internal pure returns (uint256 z) {
        z = x / uint256(y);
    }
}
