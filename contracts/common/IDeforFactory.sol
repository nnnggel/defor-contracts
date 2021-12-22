// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./IERC20.sol";

abstract contract IDeforFactory {
    address public owner;
    bytes32 public immutable DOMAIN_SEPARATOR;
    mapping(string => address) public supportReceivedTokens;

    constructor(address _weth, address _usdt, address _usdc, address _dai, address _wbtc){
        uint256 chainId;
        assembly{
            chainId := chainid()
        }
        owner = msg.sender;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes("Defor Protocol")),
                keccak256(bytes("1.0")),
                chainId,
                address(this)
            ));
        supportReceivedTokens["WETH"] = _weth;
        // weth = _weth;
        // ropsten: WETH 0xc778417E063141139Fce010982780140Aa0cD5Ab       kovan -- WETH 0xd0A1E359811322d97991E03f863a0C30C2cF029C
        supportReceivedTokens["USDT"] = _usdt;
        // usdt = _usdt;
        // ropsten: USDT 0xfA8caA9cF80250e0835c4e6D982671C97f262E52       kovan -- USDT 0xD8d4C4EdbE4Fe6856FF7775d81Aa818cecb2D9da
        supportReceivedTokens["USDC"] = _usdc;
        // usdc = _usdc;
        // ropsten: USDC 0xfDD26b7CfE425E42083bEA36E11250DE25BeDA9b       kovan -- USDC 0xC6A9F564B25900e222f9831FF01c97525a846CCf
        supportReceivedTokens["DAI"] = _dai;
        // dai = _dai;
        // ropsten: DAI  0x31f42841c2db5173425b5223809cf3a38fede360       kovan -- DAI  0xf55d3dce5DE225f500A35F4F116470B5dBd00897
        supportReceivedTokens["WBTC"] = _wbtc;
        // wbtc = _wbtc;
        // ropsten: WBTC                                                  kovan -- WBTC 0x6176ec9A99B87AcB405593Ad85c32A2e21De1AFd
    }

    function transferFromErc(address _from, address _to, uint256 _value, address _contractAddress) public virtual returns (bool);

    // function transferFromErc(address _from,address _to,uint256 _value,address _contractAddress) external returns(bool);
    // function DOMAIN_SEPARATOR() external view returns(bytes32);
    // function owner() external view returns(address);
    // function weth() external view returns(address);
    // function usdt() external view returns(address);
    // function usdc() external view returns(address);
    // function dai() external view returns(address);
    // function wbtc() external view returns(address);
}
