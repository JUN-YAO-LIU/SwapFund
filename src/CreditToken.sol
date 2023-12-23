// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract CreditToken is ERC20 ,Ownable{

    constructor(uint256 initialSupply) ERC20("CreditToken","CT") Ownable(msg.sender){
        _mint(msg.sender, initialSupply);
    }
    
    function mint(uint amount,address to) internal onlyOwner{
        _mint(to,amount);
    }

    function burn(uint amount,address to) internal onlyOwner{
        _burn(to,amount);
    }
}
