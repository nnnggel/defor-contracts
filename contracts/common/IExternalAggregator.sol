// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./IDeforFactory.sol";

abstract contract IExternalAggregator {
    address public immutable deforFactory;
    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor(address _deforFactory) {
        deforFactory = _deforFactory;
        DOMAIN_SEPARATOR = IDeforFactory(_deforFactory).DOMAIN_SEPARATOR();
    }

    function transaction(bytes[] memory data, bytes memory signature, address user, address to, uint256 ercValue, address ercContractAddress) external virtual;
}
