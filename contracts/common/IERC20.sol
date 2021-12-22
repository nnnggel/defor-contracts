// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function transferFrom(address, address, uint256) external;

    function approve(address, uint256) external;

    function allowance(address, address) external view returns (uint256);
}