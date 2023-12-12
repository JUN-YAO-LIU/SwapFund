// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract SwapFund {
    uint256 public number;
    address public owner;
    
    mapping(address => uint) public poolTokenAmount;

    // user => token => amount
    mapping(address => mapping(address => uint)) public ownerAssets;

    constructor(){
        owner = msg.sender;
    }

    function getPrice(address token) public returns(uint){
       
    }
}
