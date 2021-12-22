// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./common/IERC20.sol";
import "./common/IUniswapV2Factory.sol";
import "./common/IUniswapV2Router02.sol";
import "./common/IDeforFactory.sol";
import "./common/IAggregator.sol";

contract SwapAggregator is IAggregator {
    address public immutable weth;
    address public immutable usdt;
    address public immutable usdc;
    address public immutable dai;
    address public immutable wbtc;
    address public constant uniswapV2Router02 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant uniswapV2Factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    bytes32 public constant TRANSACTION_TYPEHASH = keccak256('Transaction(address aggregatorContractAddress,address receiver,uint256 sellAmount,uint256 buyAmount,address sellTokenAddress,address transformationAddress,address buyTokenAddress,uint256 protocolFee,uint256 deadline,uint256 index,address supportAddress)');

    struct Trade {
        address receiver;
        uint256 sellAmount;
        uint256 buyAmount;
        address sellTokenAddress;
        address transformationAddress;
        address buyTokenAddress;
        uint256 protocolFee;
        uint256 deadline;
        uint256 index;
        address supportAddress;
        address receivedFeeAddress;
    }

    constructor(address _deforFactory) IAggregator(_deforFactory){
        weth = IDeforFactory(_deforFactory).supportReceivedTokens("WETH");
        usdt = IDeforFactory(_deforFactory).supportReceivedTokens("USDT");
        usdc = IDeforFactory(_deforFactory).supportReceivedTokens("USDC");
        dai = IDeforFactory(_deforFactory).supportReceivedTokens("DAI");
        wbtc = IDeforFactory(_deforFactory).supportReceivedTokens("WBTC");
        // addErc(_USDT); // ropsten -- USDT 0xfA8caA9cF80250e0835c4e6D982671C97f262E52      kovan -- USDT 0xe82757295aF9b519724A2E9419F1Cf759ABE8ec9
        // addErc(_USDC); // ropsten: USDC 0xfDD26b7CfE425E42083bEA36E11250DE25BeDA9b        kovan -- USDC 0x6605314bfca26B15B04D7d4941039a6069195D6E
        // addErc(_CNHC); // ropsten: CNHC 0x41BAcAd6Eb73C3Ad4adCb071b909D6aB17931183        kovan -- CNHC 0x103516a88B148Afb1Cec336903AA7de8E355baeE
        // addErc(_WETH);  // ropsten: WETH 0xc778417E063141139Fce010982780140Aa0cD5Ab       kovan -- WETH 0xd0A1E359811322d97991E03f863a0C30C2cF029C

    }

    /*** WRITE ***/
    /*
        @Params
            _data : receiver + sellAmount + buyAmount + sellTokenAddress + transformationAddress + buyTokenAddress + protocolFee + deadline + index + supprotAddress + receivedFeeAddress
            _signature : r + s + v
    */
    function transaction(bytes memory _data, bytes memory _signature) external override onlyFactory {
        (Trade memory trade) = getInfoBySlice(_data);
        require(trade.deadline >= block.timestamp, "Trade has expired");
        require(trade.sellTokenAddress != trade.buyTokenAddress, "TokenA is equal tokenB");
        if (trade.transformationAddress == address(0)) {
            _transaction(trade.receiver, trade.sellAmount, trade.buyAmount, _getPathBy2(trade.sellTokenAddress, trade.buyTokenAddress), trade.protocolFee, trade.deadline, trade.index, trade.supportAddress, trade.receivedFeeAddress, _signature);
        } else {
            _transaction(trade.receiver, trade.sellAmount, trade.buyAmount, _getPathBy3(trade.sellTokenAddress, trade.transformationAddress, trade.buyTokenAddress), trade.protocolFee, trade.deadline, trade.index, trade.supportAddress, trade.receivedFeeAddress, _signature);
        }
    }

    function transaction(bytes[] memory _data, bytes memory _signature) external override onlyFactory {
        (Trade memory trade) = getInfoBySlice(_data[0]);
        require(trade.deadline >= block.timestamp, "Trade has expired");
        require(trade.sellTokenAddress != trade.buyTokenAddress, "TokenA is equal tokenB");
        if (trade.transformationAddress == address(0)) {
            _transaction(trade.receiver, trade.sellAmount, trade.buyAmount, _getPathBy2(trade.sellTokenAddress, trade.buyTokenAddress), trade.protocolFee, trade.deadline, trade.index, trade.supportAddress, trade.receivedFeeAddress, _signature);
        } else {
            _transaction(trade.receiver, trade.sellAmount, trade.buyAmount, _getPathBy3(trade.sellTokenAddress, trade.transformationAddress, trade.buyTokenAddress), trade.protocolFee, trade.deadline, trade.index, trade.supportAddress, trade.receivedFeeAddress, _signature);
        }
    }

    function transaction(bytes[] memory _data, bytes[] memory _signature) external override onlyFactory {
        for (uint256 i; i < _data.length; i++) {
            bytes memory data = _data[i];
            bytes memory signature = _signature[i];
            (Trade memory trade) = getInfoBySlice(data);
            require(trade.deadline >= block.timestamp, "Trade has expired");
            require(trade.sellTokenAddress != trade.buyTokenAddress, "TokenA is equal tokenB");
            if (trade.transformationAddress == address(0)) {
                _transaction(trade.receiver, trade.sellAmount, trade.buyAmount, _getPathBy2(trade.sellTokenAddress, trade.buyTokenAddress), trade.protocolFee, trade.deadline, trade.index, trade.supportAddress,trade.receivedFeeAddress, signature);
            } else {
                _transaction(trade.receiver, trade.sellAmount, trade.buyAmount, _getPathBy3(trade.sellTokenAddress, trade.transformationAddress, trade.buyTokenAddress), trade.protocolFee, trade.deadline, trade.index, trade.supportAddress,trade.receivedFeeAddress, signature);
            }
        }
    }

    function transaction(bytes[][] memory _data, bytes[] memory _signature) external override onlyFactory {
        for (uint256 i; i < _data[0].length; i++) {
            bytes memory data = _data[0][i];
            bytes memory signature = _signature[i];
            (Trade memory trade) = getInfoBySlice(data);
            require(trade.deadline >= block.timestamp, "Trade has expired");
            require(trade.sellTokenAddress != trade.buyTokenAddress, "TokenA is equal tokenB");
            if (trade.transformationAddress == address(0)) {
                _transaction(trade.receiver, trade.sellAmount, trade.buyAmount, _getPathBy2(trade.sellTokenAddress, trade.buyTokenAddress), trade.protocolFee, trade.deadline, trade.index, trade.supportAddress,trade.receivedFeeAddress, signature);
            } else {
                _transaction(trade.receiver, trade.sellAmount, trade.buyAmount, _getPathBy3(trade.sellTokenAddress, trade.transformationAddress, trade.buyTokenAddress), trade.protocolFee, trade.deadline, trade.index, trade.supportAddress,trade.receivedFeeAddress, signature);
            }
        }
    }

    function _transaction(address _receiver, uint256 _sellAmount, uint256 _buyAmount, address[] memory _path, uint256 _protocolFee, uint256 _deadline, uint256 _index, address _supportAddress, address _receivedFeeAddress, bytes memory _signature) private {
        address user;
        if (_path.length == 2) {
            user = verifyTransaction(_receiver, _sellAmount, _buyAmount, _path[0], address(0), _path[1], _protocolFee, _deadline, _index, _supportAddress, _signature);
        } else {
            user = verifyTransaction(_receiver, _sellAmount, _buyAmount, _path[0], _path[1], _path[2], _protocolFee, _deadline, _index, _supportAddress, _signature);
        }
        require(_receiver != address(0), "Receiver cannot be zero");
        require(indexs[user] == _index, "Index is invalid");
        indexs[user] += 1;

        addApproveErc(_path[0], uniswapV2Router02);

        if (_deadline % 6 == 0) {
            _swapExactTokensForTokens(user, _sellAmount, _buyAmount, _path, _receiver, _deadline);
        } else if (_deadline % 6 == 1) {
            require(_path[_path.length - 1] == ETH_ADDRESS, "Type is not ETH_ADDRESS");
            if (_path[0] == weth) {
                IDeforFactory(deforFactory).transferFromErc(user, address(this), _sellAmount + _protocolFee, _path[0]);
                IWETH(weth).withdraw(_sellAmount + _protocolFee);
                payable(_receiver).transfer(_sellAmount);
                payable(_receivedFeeAddress).transfer(_protocolFee);
                return;
            } else {
                _swapExactTokensForEth(user, _sellAmount, _buyAmount, _getPathBy2(_path[0], weth), _receiver, _deadline);
            }
        } else if (_deadline % 6 == 2) {
            _swapTokensForExactTokens(user, _sellAmount, _buyAmount, _path, _receiver, _deadline);
        } else if (_deadline % 6 == 3) {
            require(_path[_path.length - 1] == ETH_ADDRESS, "Type is not ETH_ADDRESS");
            if (_path[0] == weth) {
                IDeforFactory(deforFactory).transferFromErc(user, address(this), _buyAmount + _protocolFee, _path[0]);
                IWETH(weth).withdraw(_buyAmount + _protocolFee);
                payable(_receiver).transfer(_buyAmount);
                payable(_receivedFeeAddress).transfer(_protocolFee);
                return;
            } else {
                _swapTokensForExactEth(user, _sellAmount, _buyAmount, _getPathBy2(_path[0], weth), _receiver, _deadline);
            }
        } else if (_deadline % 6 == 4) {
            if (_path[2] == ETH_ADDRESS) {
                _swapExactTokensForEth(user, _sellAmount, _buyAmount, _getPathBy3(_path[0], _path[1], weth), _receiver, _deadline);
            } else {
                _swapExactTokensForTokens(user, _sellAmount, _buyAmount, _path, _receiver, _deadline);
            }
        } else if (_deadline % 6 == 5) {
            if (_path[2] == ETH_ADDRESS) {
                _swapExactTokensForEth(user, _sellAmount, _buyAmount, _getPathBy3(_path[0], _path[1], weth), _receiver, _deadline);
            } else {
                _swapTokensForExactTokens(user, _sellAmount, _buyAmount, _path, _receiver, _deadline);
            }
        } else {
            revert("Type is error");
        }

        if (_path[0] == usdt || _path[0] == usdc || _path[0] == dai || _path[0] == weth || _path[0] == wbtc) {
            IDeforFactory(deforFactory).transferFromErc(user, _receivedFeeAddress, _protocolFee, _path[0]);
        } else {
            IDeforFactory(deforFactory).transferFromErc(user, address(this), _protocolFee, _path[0]);
            address[] memory path = new address[](2);
            path[0] = _path[0];
            path[1] = _supportAddress;
            IUniswapV2Router02(uniswapV2Router02).swapExactTokensForTokens(_protocolFee, 0, path, _receivedFeeAddress, block.timestamp);
        }
    }

    function _swapExactTokensForTokens(address _from, uint256 _sellAmount, uint256 _buyAmount, address[] memory _path, address _to, uint256 _deadline) private {
        IDeforFactory(deforFactory).transferFromErc(_from, address(this), _sellAmount, _path[0]);
        IUniswapV2Router02(uniswapV2Router02).swapExactTokensForTokens(_sellAmount, _buyAmount, _path, _to, _deadline);
    }

    function _swapTokensForExactTokens(address _from, uint256 _sellAmount, uint256 _buyAmount, address[] memory _path, address _to, uint256 _deadline) private {
        uint256[] memory amounts = IUniswapV2Router02(uniswapV2Router02).getAmountsIn(_buyAmount, _path);
        require(_sellAmount >= amounts[0], "A amount is not enough");
        IDeforFactory(deforFactory).transferFromErc(_from, address(this), amounts[0], _path[0]);
        IUniswapV2Router02(uniswapV2Router02).swapTokensForExactTokens(_buyAmount, amounts[0], _path, _to, _deadline);
    }

    function _swapExactTokensForEth(address _from, uint256 _sellAmount, uint256 _buyAmount, address[] memory _path, address _to, uint256 _deadline) private {
        IDeforFactory(deforFactory).transferFromErc(_from, address(this), _sellAmount, _path[0]);
        IUniswapV2Router02(uniswapV2Router02).swapExactTokensForETH(_sellAmount, _buyAmount, _path, _to, _deadline);
    }

    function _swapTokensForExactEth(address _from, uint256 _sellAmount, uint256 _buyAmount, address[] memory _path, address _to, uint256 _deadline) private {
        uint256[] memory amounts = IUniswapV2Router02(uniswapV2Router02).getAmountsIn(_buyAmount, _path);
        require(_sellAmount >= amounts[0], "A amount is not enough");
        IDeforFactory(deforFactory).transferFromErc(_from, address(this), amounts[0], _path[0]);
        IUniswapV2Router02(uniswapV2Router02).swapTokensForExactETH(_buyAmount, _sellAmount, _path, _to, _deadline);
    }

    /*** READ ***/
    function _getPathBy2(address _sellTokenAddress, address _buyTokenAddress) private pure returns (address[] memory){
        address[] memory path = new address[](2);
        path[0] = _sellTokenAddress;
        path[1] = _buyTokenAddress;
        return path;
    }

    function _getPathBy3(address _sellTokenAddress, address _token, address _buyTokenAddress) private pure returns (address[] memory){
        address[] memory path = new address[](3);
        path[0] = _sellTokenAddress;
        path[1] = _token;
        path[2] = _buyTokenAddress;
        return path;
    }

    function isETH(address _token) public pure returns (bool) {
        return _token == ETH_ADDRESS;
    }

    function verifyTransaction(address _receiver, uint256 _sellAmount, uint256 _buyAmount, address _sellTokenAddress, address _transformationAddress, address _buyTokenAddress, uint256 _protocolFee, uint256 _deadline, uint256 _index, address _supportAddress, bytes memory _signature) public view returns (address user){
        bytes32 k = keccak256(abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    TRANSACTION_TYPEHASH,
                    address(this),
                    _receiver,
                    _sellAmount,
                    _buyAmount,
                    _sellTokenAddress,
                    _transformationAddress,
                    _buyTokenAddress,
                    _protocolFee,
                    _deadline,
                    _index,
                    _supportAddress
                ))
            ));
        {
            (bytes32 _r,bytes32 _s,uint8 _v) = sliceToSignature(_signature);
            user = ecrecover(k, _v, _r, _s);
        }
    }

    function getInfoBySlice(bytes memory _msg) public pure returns (Trade memory trade){
        (address _receiver,uint256 _sellAmount,uint256 _buyAmount,address _sellTokenAddress,address _transformationAddress,address _buyTokenAddress,uint256 _protocolFee,uint256 _deadline,uint256 _index,address _supportAddress,address _receivedFeeAddress) = _getInfoBySlice(_msg);
        trade = Trade(_receiver, _sellAmount, _buyAmount, _sellTokenAddress, _transformationAddress, _buyTokenAddress, _protocolFee, _deadline, _index, _supportAddress,_receivedFeeAddress);
    }

    function _getInfoBySlice(bytes memory _msg) public pure returns (address _receiver, uint256 _sellAmount, uint256 _buyAmount, address _sellTokenAddress, address _transformationAddress, address _buyTokenAddress, uint256 _protocolFee, uint256 _deadline, uint256 _index, address _supportAddress,address _receivedFeeAddress){
        assembly {
            _receiver := mload(add(_msg, 32))
            _sellAmount := mload(add(_msg, 64))
            _buyAmount := mload(add(_msg, 96))
            _sellTokenAddress := mload(add(_msg, 128))
            _transformationAddress := mload(add(_msg, 160))
            _buyTokenAddress := mload(add(_msg, 192))
            _protocolFee := mload(add(_msg, 224))
            _deadline := mload(add(_msg, 256))
            _index := mload(add(_msg, 288))
            _supportAddress := mload(add(_msg, 320))
            _receivedFeeAddress := mload(add(_msg,352))
        }
    }

    receive() external payable {}
}

interface IWETH {
    function withdraw(uint256) external;
}

interface UniswapV2Pair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

