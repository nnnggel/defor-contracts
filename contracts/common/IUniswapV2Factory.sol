// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IUniswapV2Factory {
    function getPair(address, address) external view returns (address);
}