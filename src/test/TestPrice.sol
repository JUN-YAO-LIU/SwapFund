// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { IWETH9 } from "./interfaces/IWETH9.sol";

contract TestPrice  {

    mapping(address => uint) public tokens;

    function setPrice(address _token,uint _price) public {
       tokens[_token] = _price;
    }
}
