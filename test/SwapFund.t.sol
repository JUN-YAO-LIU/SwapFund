// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {SwapFund} from "../src/SwapFund.sol";
import {FlashSwapSetUp} from "./helper/FlashSwapSetUp.sol";
import { IUniswapV2Factory } from "v2-core/interfaces/IUniswapV2Factory.sol";

contract SwapFundTest is FlashSwapSetUp {

    function setUp() public override {
       super.setUp();
    }

    function test_depositIntoMarkets() public {
    }

    function test_swapToMultipleTokens() public {
    }

    function test_getPricesFromUni() public {
    }

    function test_withdrawalTokens() public {
    }

    function test_getMarketSupportTokens() public {
    }

    function test_setTokenInMarket() public {
    }

    function test_setPrice() public {
    }

     function test_getPrice() public {
    }
}
