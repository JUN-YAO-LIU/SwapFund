// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {SwapFund} from "../src/SwapFund.sol";
import {FlashSwapSetUp} from "./helper/FlashSwapSetUp.sol";
import {IUniswapV2Factory} from "v2-core/interfaces/IUniswapV2Factory.sol";

contract SwapFundTest is FlashSwapSetUp,SwapFund {

    address maker = makeAddr("maker");
    SwapFund swapFund;

    function setUp() public override {
       super.setUp();

        // mint 100 ETH, 10000 USDC to maker
        vm.deal(maker, 100 ether);
        usdc.mint(maker, 10_000 * 10 ** usdc.decimals());
        matic.mint(maker, 10_000 * 10 ** matic.decimals());

        // maker provide liquidity to wethUsdcPool, wethUsdcSushiPool
        vm.startPrank(maker);
        // maker provide 50 ETH, 4000 USDC to wethUsdcPool
        usdc.approve(address(uniswapV2Router), 4_000 * 10 ** usdc.decimals());
        matic.approve(address(uniswapV2Router), 4_000 * 10 ** matic.decimals());
        uniswapV2Router.addLiquidity(
            address(usdc),
            address(matic),
            4_000 * 10 ** usdc.decimals(),
            4_000 * 10 ** usdc.decimals(),
            0,
            0,
            maker,
            block.timestamp
        );

        // maker provide 50 ETH, 6000 USDC to wethUsdcSushiPool
        // usdc.approve(address(sushiSwapV2Router), 6_000 * 10 ** usdc.decimals());
        // sushiSwapV2Router.addLiquidityETH{ value: 50 ether }(
        //     address(usdc),
        //     6_000 * 10 ** usdc.decimals(),
        //     0,
        //     0,
        //     maker,
        //     block.timestamp
        // );

        swapFund = new SwapFund();
        vm.stopPrank();
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
        // in 10 usdt
        uint price = swapFund.getPrice(address(maticUsdcPool),10);
        console2.log("matic price:",price);
    }
}
