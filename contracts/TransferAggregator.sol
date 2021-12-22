// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./common/IERC20.sol";
import "./common/IUniswapV2Factory.sol";
import "./common/IUniswapV2Router02.sol";
import "./common/IDeforFactory.sol";
import "./common/IAggregator.sol";

contract TransferAggregator is IAggregator {

    address public constant uniswapV2Router02 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant uniswapV2Factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public immutable weth;
    address public immutable usdt;
    address public immutable usdc;
    address public immutable dai;
    address public immutable wbtc;

    bytes32 public constant TRANSACTION_TYPEHASH = keccak256('Transaction(address aggregatorContractAddress,address to,uint256 value,address tokenAddress,uint256 deadline,uint256 protocolFee,uint256 index,address supportAddress)');

    mapping(address => mapping(uint256 => bool)) public randoms;

    event TransferBatch(address, address, uint256);

    struct Trade {
        address fromAddr;
        address toAddr;
        address tokenAddr;
        address supportAddress;
        uint256 value;
        uint256 protocolFee;
        uint256 deadline;
        uint256 index;
        address receivedFeeAddress;
    }

    constructor(address _deforFactory) IAggregator(_deforFactory){
        weth = IDeforFactory(_deforFactory).supportReceivedTokens("WETH");
        usdt = IDeforFactory(_deforFactory).supportReceivedTokens("USDT");
        usdc = IDeforFactory(_deforFactory).supportReceivedTokens("USDC");
        dai = IDeforFactory(_deforFactory).supportReceivedTokens("DAI");
        wbtc = IDeforFactory(_deforFactory).supportReceivedTokens("WBTC");
    }

    /*** WRITE ***/
    function transaction(bytes memory _data, bytes memory _signature) external override onlyFactory {
        Trade memory trade = _transaction(_data, _signature);
        _transferErc20(trade);
    }

    function transaction(bytes[] memory _data, bytes memory _signature) external override onlyFactory {
        Trade memory trade = _transaction(_data[0], _signature);
        _transferErc20(trade);
    }

    function transaction(bytes[] memory _data, bytes[] memory _signature) external override onlyFactory {
        for (uint256 i; i < _data.length; i++) {
            Trade memory trade = _transaction(_data[i], _signature[i]);
            _transferErc20(trade);
        }
    }

    function transaction(bytes[][] memory _data, bytes[] memory _signature) external override onlyFactory {
        for (uint256 i; i < _data[0].length; i++) {
            Trade memory trade = _transaction(_data[0][i], _signature[i]);
            _transferErc20(trade);
        }
    }

    function _transaction(bytes memory _data, bytes memory _signature) private returns (Trade memory){
        (Trade memory trade) = _getTransactionData(_data);
        require(trade.deadline >= block.timestamp, "Trade has expired");
        address user = verifyTransaction(trade.toAddr, trade.value, trade.tokenAddr, trade.deadline, trade.protocolFee, trade.index, trade.supportAddress, _signature);
        trade.fromAddr = user;
        if (trade.index >= 1e30) {
            require(!randoms[user][trade.index], "Index already exists");
            randoms[user][trade.index] = true;
        } else {
            require(indexs[user] == trade.index, "Index is invalid");
            indexs[user] += 1;
        }
        return trade;
    }

    function _transferErc20(Trade memory _trade) private {
        IERC20 erc = IERC20(_trade.tokenAddr);
        uint256 amount = _trade.protocolFee + _trade.value;
        if (erc.balanceOf(_trade.fromAddr) >= amount && erc.allowance(_trade.fromAddr, address(deforFactory)) >= amount) {
            IDeforFactory(deforFactory).transferFromErc(_trade.fromAddr, address(this), amount, _trade.tokenAddr);
            erc.transfer(_trade.toAddr, _trade.value);
            if (_trade.tokenAddr == usdt || _trade.tokenAddr == usdc || _trade.tokenAddr == dai || _trade.tokenAddr == weth || _trade.tokenAddr == wbtc) {
                erc.transfer(_trade.receivedFeeAddress, _trade.protocolFee);
            } else {
                addApproveErc(_trade.tokenAddr, uniswapV2Router02);
                address[] memory path = new address[](2);
                path[0] = _trade.tokenAddr;
                path[1] = _trade.supportAddress;
                IUniswapV2Router02(uniswapV2Router02).swapExactTokensForTokens(_trade.protocolFee, 0, path, _trade.receivedFeeAddress, block.timestamp);
            }

            emit TransferBatch(_trade.fromAddr, _trade.toAddr, _trade.value);
        }
    }


    /*** READ ***/
    function verifyTransaction(address _to, uint256 _value, address _contractAddress, uint256 _deadline, uint256 _protocolFee, uint256 _index, address _supportAddress, bytes memory _signature) public view returns (address){
        (bytes32 _r,bytes32 _s,uint8 _v) = sliceToSignature(_signature);
        return ecrecover(keccak256(abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    TRANSACTION_TYPEHASH,
                    address(this),
                    _to,
                    _value,
                    _contractAddress,
                    _deadline,
                    _protocolFee,
                    _index,
                    _supportAddress
                ))
            )), _v, _r, _s);
    }

    function _getTransactionData(bytes memory _msg) private pure returns (Trade memory){
        (address _to,uint256 _value,address _tokenAddr,uint256 _deadline,uint256 _protocolFee,uint256 _index,address _supportAddress,address _receivedFeeAddress) = getInfoBySlice(_msg);
        Trade memory trade;
        trade.toAddr = _to;
        trade.tokenAddr = _tokenAddr;
        trade.value = _value;
        trade.protocolFee = _protocolFee;
        trade.supportAddress = _supportAddress;
        trade.deadline = _deadline;
        trade.index = _index;
        trade.receivedFeeAddress = _receivedFeeAddress;
        return trade;
    }

    function getInfoBySlice(bytes memory _msg) public pure returns (address _to, uint256 _value, address _tokenAddr, uint256 _deadline, uint256 _protocolFee, uint256 _index, address _supportAddress, address __receivedFeeAddress){
        assembly {
            _to := mload(add(_msg, 32))
            _value := mload(add(_msg, 64))
            _tokenAddr := mload(add(_msg, 96))
            _deadline := mload(add(_msg, 128))
            _protocolFee := mload(add(_msg, 160))
            _index := mload(add(_msg, 192))
            _supportAddress := mload(add(_msg, 224))
            __receivedFeeAddress := mload(add(_msg,256))
        }
    }

    receive() external payable {}
}
