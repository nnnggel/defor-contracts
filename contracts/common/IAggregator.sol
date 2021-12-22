// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./IDeforFactory.sol";
import "./IERC20.sol";

abstract contract IAggregator {
    address public immutable deforFactory;
    bytes32 public immutable DOMAIN_SEPARATOR;
    mapping(address => mapping(address => bool)) public approveContractAddress;
    mapping(address => uint256) public indexs;

    event AddApproveErc(address, address, address);
    event RemoveApproveErc(address, address, address);

    constructor(address _deforFactory) {
        deforFactory = _deforFactory;
        DOMAIN_SEPARATOR = IDeforFactory(_deforFactory).DOMAIN_SEPARATOR();
    }

    function addApproveErc(address _contractAddress, address _approveContractAddress) public {
        require(_contractAddress != address(0), "contractAddress cannot be zero");
        if (!approveContractAddress[_contractAddress][_approveContractAddress]) {
            IERC20 erc20 = IERC20(_contractAddress);
            erc20.approve(_approveContractAddress, 2 ** 256 - 1);
            approveContractAddress[_contractAddress][_approveContractAddress] = true;
            emit AddApproveErc(msg.sender, _contractAddress, _approveContractAddress);
        }
    }

    function removeApproveErc(address _contractAddress, address _approveContractAddress) public onlyFactoryOwner {
        require(_contractAddress != address(0), "contractAddress cannot be zero");
        IERC20 erc20 = IERC20(_contractAddress);
        erc20.approve(_approveContractAddress, 0);
        approveContractAddress[_contractAddress][_approveContractAddress] = false;
        emit RemoveApproveErc(msg.sender, _contractAddress, _approveContractAddress);
    }

    function withdrawEth() public onlyFactoryOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawErc(address _contractAddress) public onlyFactoryOwner {
        IERC20 erc = IERC20(_contractAddress);
        erc.transfer(msg.sender, erc.balanceOf(address(this)));
    }

    function sliceToSignature(bytes memory _signature) public pure returns (bytes32 _r, bytes32 _s, uint8 _v){
        assembly {
            _r := mload(add(_signature, 32))
            _s := mload(add(_signature, 64))
            _v := and(mload(add(_signature, 65)), 255)
        }
    }

    modifier onlyFactory(){
        require(address(deforFactory) == msg.sender, 'Unauthorized');
        _;
    }

    modifier onlyFactoryOwner(){
        require(IDeforFactory(deforFactory).owner() == msg.sender, "Unauthorized");
        _;
    }

    function transaction(bytes memory, bytes memory) external virtual;

    function transaction(bytes[] memory, bytes memory) external virtual;

    function transaction(bytes[] memory, bytes[] memory) external virtual;

    function transaction(bytes[][] memory, bytes[] memory) external virtual;
}
