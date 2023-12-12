// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Factory } from "v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";

contract SwapFund {
    uint256 public number;
    address public owner;
    address public USDT;
    // address public _UNISWAP_FACTORY;
    
    mapping(address => uint) public poolTokenAmount;

    // user => token => amount
    mapping(address => mapping(address => uint)) public ownerAssets;

    constructor(){
        owner = msg.sender;
    }

    function getPrice(address pool,uint256 amountIn) public view returns(uint){
       // address poolAddr = IUniswapV2Factory(factory).getPair(usdt,token);
       (uint256 _usdt, uint256 _tokenOut,) = IUniswapV2Pair(pool).getReserves();
       return _getAmountOut(amountIn,_usdt,_tokenOut);
    }

    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    // copy from UniswapV2Library
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
