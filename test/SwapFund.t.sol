// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {SwapFund} from "../src/SwapFund.sol";
import {FlashSwapSetUp} from "./helper/FlashSwapSetUp.sol";
import {IUniswapV2Factory} from "v2-core/interfaces/IUniswapV2Factory.sol";

contract SwapFundTest is FlashSwapSetUp {

    address maker = makeAddr("maker");
    address user1 = makeAddr("user1");
    SwapFund swapFund;

    function setUp() public override {
       super.setUp();

        // mint 100 ETH, 10000 USDC to maker
        vm.deal(maker, 100 ether);
        usdc.mint(maker, 10_000_000 * 10 ** usdc.decimals());
        matic.mint(maker, 10_000 * 10 ** matic.decimals());
        op.mint(maker, 10_000 * 10 ** op.decimals());
        sol.mint(maker, 1000 * 10 ** op.decimals());

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

        usdc.approve(address(uniswapV2Router), 4_000 * 10 ** usdc.decimals());
        op.approve(address(uniswapV2Router), 3_000 * 10 ** op.decimals());
        uniswapV2Router.addLiquidity(
            address(usdc),
            address(op),
            4_000 * 10 ** usdc.decimals(),
            3_000 * 10 ** usdc.decimals(),
            0,
            0,
            maker,
            block.timestamp
        );

        usdc.approve(address(uniswapV2Router), 4_000 * 10 ** usdc.decimals());
        sol.approve(address(uniswapV2Router), 1_000 * 10 ** sol.decimals());
        uniswapV2Router.addLiquidity(
            address(usdc),
            address(sol),
            4_000 * 10 ** usdc.decimals(),
            200 * 10 ** usdc.decimals(),
            0,
            0,
            maker,
            block.timestamp
        );

        swapFund = new SwapFund(address(uniswapV2Factory),address(uniswapV2Router),address(usdc));
        vm.stopPrank();

        vm.startPrank(user1);
        usdc.mint(user1, 10_000_000 * 10 ** usdc.decimals());
        vm.stopPrank();

        vm.label(user1, "User1");
        vm.label(address(swapFund), "swapFund");
    }

    function test_depositIntoMarkets() public {
        vm.startPrank(user1);
        usdc.approve(address(swapFund), 4_000 * 10 ** usdc.decimals());
        swapFund.deposit(address(usdc));

        console2.log("swapFund usdc:",usdc.balanceOf(address(swapFund)));
        console2.log("create matic markets:",matic.balanceOf(address(maticUsdcPool)));

        address[] memory tokens = new address[](2);
        uint[] memory amounts = new uint[](2);

        // amount in
        amounts[0] = 123;
        amounts[1] = 56;

        tokens[0] = address(matic);
        tokens[1] = address(sol);

        swapFund.createFund(tokens,amounts);
        console2.log("create matic markets:",matic.balanceOf(address(swapFund)));
        console2.log("create sol markets:",sol.balanceOf(address(swapFund)));

        vm.stopPrank();

        assertTrue(matic.balanceOf(address(swapFund)) > 0 , "matic less than zero");
        assertTrue(sol.balanceOf(address(swapFund)) > 0 ,"sol less than zero");
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
        console2.log("matic price:",swapFund.getPrice(address(maticUsdcPool),10));
        console2.log("op price:",swapFund.getPrice(address(opUsdcPool),20));
        console2.log("sol price:",swapFund.getPrice(address(solUsdcPool),123));
    }
}
