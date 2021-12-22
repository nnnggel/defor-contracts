// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./common/IERC20.sol";
import "./common/IDeforFactory.sol";
import "./common/IAggregator.sol";
import "./common/IExternalAggregator.sol";

contract DeforFactory is IDeforFactory {
    bool public paused = false;
    uint256 public unlocked = 1;
    address public pendingOwner;

    mapping(address => bool) public aggregators;

    mapping(string => address) public aggregatorNames;

    bytes32 public constant TRANSACTION_CHANNEL = keccak256('Transaction(address aggregatorContractAddress,bytes data,address user,address receivedFeeAddress,uint256 ercValue,address ercContractAddress)');

    mapping(address => bool) public resolvers;

    event Pause();
    event Unpause();

    constructor(address _weth, address _usdt, address _usdc, address _dai, address _wbtc) IDeforFactory(_weth, _usdt, _usdc, _dai, _wbtc){}

    /*** WRITE ***/
    function transactionChannel(address _aggregatorContractAddress, bytes memory _data, bytes memory _signature) external lock onlyResolvers {
        require(aggregators[_aggregatorContractAddress], "Aggregator is not exists");
        IAggregator aggregator = IAggregator(_aggregatorContractAddress);
        aggregator.transaction(_data, _signature);
    }

    function transactionChannel(address _aggregatorContractAddress, bytes[] memory _data, bytes memory _signature) external lock onlyResolvers {
        require(aggregators[_aggregatorContractAddress], "Aggregator is not exists");
        IAggregator aggregator = IAggregator(_aggregatorContractAddress);
        aggregator.transaction(_data, _signature);
    }

    function transactionChannel(address _aggregatorContractAddress, bytes[] memory _data, bytes[] memory _signature) external lock onlyResolvers {
        require(aggregators[_aggregatorContractAddress], "Aggregator is not exists");
        IAggregator aggregator = IAggregator(_aggregatorContractAddress);
        aggregator.transaction(_data, _signature);
    }

    function transactionChannel(address _aggregatorContractAddress, bytes[][] memory _data, bytes[] memory _signature) external lock onlyResolvers {
        require(aggregators[_aggregatorContractAddress], "Aggregator is not exists");
        IAggregator aggregator = IAggregator(_aggregatorContractAddress);
        aggregator.transaction(_data, _signature);
    }

    function transactionChannelExternal(address _aggregatorContractAddress, bytes[] memory _data, bytes memory _signature, address _ercContractAddress, address _receivedFeeAddress, uint256 _ercValue) external lock whenNotPaused {
        require(!aggregators[_aggregatorContractAddress], "Aggregator is already exists");
        (bytes32 r,bytes32 s,uint8 v) = sliceToSignature(_signature);
        address user = verifyTransaction(_aggregatorContractAddress, _data, _ercValue, _ercContractAddress, r, s, v);
        IERC20(_ercContractAddress).transferFrom(user, _receivedFeeAddress, _ercValue);
        IExternalAggregator(_aggregatorContractAddress).transaction(_data, _signature, user, _receivedFeeAddress, _ercValue, _ercContractAddress);
    }

    function transferFromErc(address _from, address _to, uint256 _value, address _contractAddress) public override onlyAggregator returns (bool){
        IERC20 erc20 = IERC20(_contractAddress);
        erc20.transferFrom(_from, _to, _value);
        return true;
    }

    function withdrawEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawErc(address _contractAddress) external onlyOwner {
        IERC20 erc = IERC20(_contractAddress);
        erc.transfer(msg.sender, erc.balanceOf(address(this)));
    }


    /*** READ ***/
    function sliceToSignature(bytes memory _signature) public pure returns (bytes32 _r, bytes32 _s, uint8 _v){
        assembly {
            _r := mload(add(_signature, 32))
            _s := mload(add(_signature, 64))
            _v := and(mload(add(_signature, 65)), 255)
        }
    }
    function verifyTransaction(address _aggregatorContractAddress,bytes[] memory _data, uint256 _ercValue, address _ercContractAddress, bytes32 _r, bytes32 _s, uint8 _v) public view returns (address){
        return ecrecover(keccak256(abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    TRANSACTION_CHANNEL,
                    _aggregatorContractAddress,
                    keccak256(abi.encode(_data)),
                    _ercValue,
                    _ercContractAddress
                ))
            )), _v, _r, _s);
    }

    /*** UPDATE PROPERTIES ***/
    function addAggregatorContract(string memory _name, address _aggregatorAddress) external onlyOwner {
        require(aggregatorNames[_name] == address(0), "Name already exists");
        aggregatorNames[_name] = _aggregatorAddress;
        aggregators[_aggregatorAddress] = true;
    }

    function updateAggregatorContract(string memory _name,address _aggregatorAddress) external onlyOwner {
        require(aggregatorNames[_name] != address(0), "Name is not exists");
        if(_aggregatorAddress == address(0)){
            aggregators[aggregatorNames[_name]] = false;
        }
        aggregatorNames[_name] = _aggregatorAddress;
    }

    function addCaller(address _caller) external onlyOwner {
        require(!isContract(_caller), "Caller cannot be a contract");
        require(!resolvers[_caller], "Caller already exists");
        resolvers[_caller] = true;
    }
    function removeCaller(address _caller) external onlyOwner {
        require(resolvers[_caller], "Caller is not exists");
        resolvers[_caller] = false;
    }

    function pause() external onlyOwner {
        paused = true;
        emit Pause();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpause();
    }

    function updatePendingOwner(address _pendingOwner) external onlyOwner {
        require(_pendingOwner != address(0), "PendingOwner cannot be zero");
        pendingOwner = _pendingOwner;
    }
    function updateOwner() external onlyPendingOwner {
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /*** MODIFIERS ***/
    modifier onlyAggregator(){
        require(aggregators[msg.sender], 'Unauthorized');
        _;
    }

    modifier onlyResolvers(){
        require(resolvers[msg.sender], 'Unauthorized');
        _;
    }

    modifier whenNotPaused() {
        require(!paused, 'Paused');
        _;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, 'Unauthorized');
        _;
    }

    modifier onlyPendingOwner(){
        require(pendingOwner == msg.sender, 'Unauthorized');
        _;
    }

    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    function isContract(address _account) public view returns (bool){
        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        return size > 0;
    }

    receive() external payable {}
}
