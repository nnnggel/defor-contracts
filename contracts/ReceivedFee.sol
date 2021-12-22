// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./common/IERC20.sol";
import "./common/IAggregator.sol";
import "./common/IUniswapV2Router02.sol";

contract ReceivedFee is IAggregator {
    bytes32 public constant TRANSACTION_TYPEHASH = keccak256('Transaction(address aggregatorContractAddress,address tokenContractAddress,uint256 protocolFee,uint256 index,address supportAddress)');
    mapping(address => bool) public supportReceiveTokens;
    address public constant uniswapV2Router02 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor(address _deforFactory) IAggregator(_deforFactory){
        supportReceiveTokens[IDeforFactory(_deforFactory).supportReceivedTokens("WETH")] = true;
        supportReceiveTokens[IDeforFactory(_deforFactory).supportReceivedTokens("USDT")] = true;
        supportReceiveTokens[IDeforFactory(_deforFactory).supportReceivedTokens("USDC")] = true;
        supportReceiveTokens[IDeforFactory(_deforFactory).supportReceivedTokens("DAI")] = true;
        supportReceiveTokens[IDeforFactory(_deforFactory).supportReceivedTokens("WBTC")] = true;
    }

    /*** WRITE ***/
    function transaction(bytes memory _data, bytes memory _signature) external override onlyFactory {
        (address _tokenContractAddress,uint256 _protocolFee,uint256 _index,address _supportAddress,address _receivedFeeAddress) = getInfoBySlice(_data);
        (bytes32 _r,bytes32 _s,uint8 _v) = sliceToSignature(_signature);
        address user = verifyTransaction(_tokenContractAddress, _protocolFee, _index, _supportAddress, _r, _s, _v);

        require(indexs[user] == _index, "Index is invalid");
        indexs[user] += 1;

        if (supportReceiveTokens[_tokenContractAddress]) {
            IDeforFactory(deforFactory).transferFromErc(user, _receivedFeeAddress, _protocolFee, _tokenContractAddress);
        } else {
            IDeforFactory(deforFactory).transferFromErc(user, address(this), _protocolFee, _tokenContractAddress);
            addApproveErc(_tokenContractAddress, uniswapV2Router02);
            address[] memory path = new address[](2);
            path[0] = _tokenContractAddress;
            path[1] = _supportAddress;
            IUniswapV2Router02(uniswapV2Router02).swapExactTokensForTokens(_protocolFee, 0, path, _receivedFeeAddress, block.timestamp);
        }
    }

    function transaction(bytes[] memory _data, bytes memory _signature) external override onlyFactory {
        (address _tokenContractAddress,uint256 _protocolFee,uint256 _index,address _supportAddress,address _receivedFeeAddress) = getInfoBySlice(_data[0]);
        (bytes32 _r,bytes32 _s,uint8 _v) = sliceToSignature(_signature);
        address user = verifyTransaction(_tokenContractAddress, _protocolFee, _index, _supportAddress, _r, _s, _v);

        require(indexs[user] == _index, "Index is invalid");
        indexs[user] += 1;

        if (supportReceiveTokens[_tokenContractAddress]) {
            IDeforFactory(deforFactory).transferFromErc(user, _receivedFeeAddress, _protocolFee, _tokenContractAddress);
        } else {
            IDeforFactory(deforFactory).transferFromErc(user, address(this), _protocolFee, _tokenContractAddress);
            addApproveErc(_tokenContractAddress, uniswapV2Router02);
            address[] memory path = new address[](2);
            path[0] = _tokenContractAddress;
            path[1] = _supportAddress;
            IUniswapV2Router02(uniswapV2Router02).swapExactTokensForTokens(_protocolFee, 0, path, _receivedFeeAddress, block.timestamp);
        }
    }

    function transaction(bytes[] memory _data, bytes[] memory _signature) external override onlyFactory {
        for (uint256 i = 0; i < _data.length; i++) {
            (address _tokenContractAddress,uint256 _protocolFee,uint256 _index,address _supportAddress,address _receivedFeeAddress) = getInfoBySlice(_data[i]);
            (bytes32 _r,bytes32 _s,uint8 _v) = sliceToSignature(_signature[i]);
            address user = verifyTransaction(_tokenContractAddress, _protocolFee, _index, _supportAddress, _r, _s, _v);

            require(indexs[user] == _index, "Index is invalid");
            indexs[user] += 1;

            if (supportReceiveTokens[_tokenContractAddress]) {
                IDeforFactory(deforFactory).transferFromErc(user, _receivedFeeAddress, _protocolFee, _tokenContractAddress);
            } else {
                IDeforFactory(deforFactory).transferFromErc(user, address(this), _protocolFee, _tokenContractAddress);
                addApproveErc(_tokenContractAddress, uniswapV2Router02);
                address[] memory path = new address[](2);
                path[0] = _tokenContractAddress;
                path[1] = _supportAddress;
                IUniswapV2Router02(uniswapV2Router02).swapExactTokensForTokens(_protocolFee, 0, path, _receivedFeeAddress, block.timestamp);
            }
        }
    }

    function transaction(bytes[][] memory _data, bytes[] memory _signature) external override onlyFactory {
        for (uint256 i = 0; i < _data[0].length; i++) {
            (address _tokenContractAddress,uint256 _protocolFee,uint256 _index,address _supportAddress,address _receivedFeeAddress) = getInfoBySlice(_data[0][i]);
            (bytes32 _r,bytes32 _s,uint8 _v) = sliceToSignature(_signature[i]);
            address user = verifyTransaction(_tokenContractAddress, _protocolFee, _index, _supportAddress, _r, _s, _v);

            require(indexs[user] == _index, "Index is invalid");
            indexs[user] += 1;

            if (supportReceiveTokens[_tokenContractAddress]) {
                IDeforFactory(deforFactory).transferFromErc(user, _receivedFeeAddress, _protocolFee, _tokenContractAddress);
            } else {
                IDeforFactory(deforFactory).transferFromErc(user, address(this), _protocolFee, _tokenContractAddress);
                addApproveErc(_tokenContractAddress, uniswapV2Router02);
                address[] memory path = new address[](2);
                path[0] = _tokenContractAddress;
                path[1] = _supportAddress;
                IUniswapV2Router02(uniswapV2Router02).swapExactTokensForTokens(_protocolFee, 0, path, _receivedFeeAddress, block.timestamp);
            }
        }
    }

    function addSupportReceiveToken(address _tokenContractAddress) external onlyFactoryOwner {
        require(!supportReceiveTokens[_tokenContractAddress], "Token already support");
        supportReceiveTokens[_tokenContractAddress] = true;
    }

    function removeSupportReceiveToken(address _tokenContractAddress) external onlyFactoryOwner {
        require(supportReceiveTokens[_tokenContractAddress], "Token is not exists");
        supportReceiveTokens[_tokenContractAddress] = false;
    }

    /*** READ ***/
    function verifyTransaction(address _tokenContractAddress, uint256 _protocolFee, uint256 _index, address _supportAddress, bytes32 _r, bytes32 _s, uint8 _v) public view returns (address){
        return ecrecover(keccak256(abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    TRANSACTION_TYPEHASH,
                    address(this),
                    _tokenContractAddress,
                    _protocolFee,
                    _index,
                    _supportAddress
                ))
            )), _v, _r, _s);
    }

    function getInfoBySlice(bytes memory _msg) public pure returns (address _tokenContractAddress, uint256 _protocolFee, uint256 _index, address _supportAddress, address _receivedFeeAddress){
        assembly {
            _tokenContractAddress := mload(add(_msg, 32))
            _protocolFee := mload(add(_msg, 64))
            _index := mload(add(_msg, 96))
            _supportAddress := mload(add(_msg, 128))
            _receivedFeeAddress := mload(add(_msg, 160))
        }
    }
}





