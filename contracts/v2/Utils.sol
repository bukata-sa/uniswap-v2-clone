// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Utils {

    function min(address a, address b) public pure returns (address) {
        if (a <= b) {
            return a;
        }
        return b;
    }

    function max(address a, address b) public pure returns (address) {
        if (a >= b) {
            return a;
        }
        return b;
    }
}
