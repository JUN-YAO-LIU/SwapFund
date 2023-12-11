// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "../lib/openzepplin-contracts/contracts/token/ERC20/IERC20.sol";
import { ChainId, Token, WETH9 } from "../node_modules/@uniswap/sdk-core";
import { Route } from "../node_modules/@uniswap/v3-sdk";

contract SwapFund {
    uint256 public number;
    address public owner;
    
    mapping(address => uint) public poolTokenAmount;

    // user => token => amount
    mapping(address => mapping(address => uint)) public ownerAssets;

    constructor(){
        owner = msg.sender;
    }

    function getPrice(address token) public {
       
    }
}
