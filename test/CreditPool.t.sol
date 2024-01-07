// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {CreditPool} from "../src/CreditPool.sol";
import {FlashSwapSetUp} from "./helper/FlashSwapSetUp.sol";
import {IUniswapV2Factory} from "v2-core/interfaces/IUniswapV2Factory.sol";

contract CreditPoolTest is FlashSwapSetUp {
    
    address maker = makeAddr("maker");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    CreditPool swapFund;

    function setUp() public override {
       super.setUp();

        // mint 100 ETH, 10000 USDC to maker
        vm.deal(maker, 100 ether);
        usdc.mint(maker, 10_000_000 * 10 ** usdc.decimals());
        matic.mint(maker, 10_000_000 * 10 ** matic.decimals());
        op.mint(maker, 10_000_000 * 10 ** op.decimals());
        sol.mint(maker, 10_000_000 * 10 ** op.decimals());

        // maker provide liquidity to wethUsdcPool, wethUsdcSushiPool
        vm.startPrank(maker);
        // maker provide 50 ETH, 4000 USDC to wethUsdcPool
        usdc.approve(address(uniswapV2Router), 8_000 * 10 ** usdc.decimals());
        matic.approve(address(uniswapV2Router), 9_000 * 10 ** matic.decimals());
        uniswapV2Router.addLiquidity(
            address(usdc),
            address(matic),
            8_000 * 10 ** usdc.decimals(),
            9_000 * 10 ** usdc.decimals(),
            0,
            0,
            maker,
            block.timestamp
        );

        usdc.approve(address(uniswapV2Router), 15_000 * 10 ** usdc.decimals());
        op.approve(address(uniswapV2Router), 23_000 * 10 ** op.decimals());
        uniswapV2Router.addLiquidity(
            address(usdc),
            address(op),
            15_000 * 10 ** usdc.decimals(),
            23_000 * 10 ** usdc.decimals(),
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


        op.approve(address(uniswapV2Router), 500 * 10 ** op.decimals());
        sol.approve(address(uniswapV2Router), 400 * 10 ** sol.decimals());
        uniswapV2Router.addLiquidity(
            address(op),
            address(sol),
            500 * 10 ** usdc.decimals(),
            400 * 10 ** usdc.decimals(),
            0,
            0,
            maker,
            block.timestamp
        );

        op.approve(address(uniswapV2Router), 700 * 10 ** op.decimals());
        matic.approve(address(uniswapV2Router), 200 * 10 ** matic.decimals());
        uniswapV2Router.addLiquidity(
            address(op),
            address(matic),
            700 * 10 ** usdc.decimals(),
            200 * 10 ** usdc.decimals(),
            0,
            0,
            maker,
            block.timestamp
        );

        swapFund = new CreditPool(address(uniswapV2Factory),address(uniswapV2Router),address(usdc));
        swapFund.simpleSetPrice(address(op),4);
        swapFund.simpleSetPrice(address(usdc),1); 
        swapFund.simpleSetPrice(address(matic),2);
        swapFund.simpleSetPrice(address(sol),100);
        vm.stopPrank();

        vm.startPrank(user1);
        usdc.mint(user1, 10_000_000 * 10 ** usdc.decimals());
        vm.stopPrank();

        vm.startPrank(user2);
        usdc.mint(user2, 10_000_000 * 10 ** usdc.decimals());
        vm.stopPrank();

        vm.label(user1, "User1");
        vm.label(user2, "User2");
        vm.label(address(swapFund), "swapFund");
    }

    function test_depositIntoMarkets() public {
        vm.startPrank(user1);
        usdc.approve(address(swapFund), 4_000 * 10 ** usdc.decimals());
        swapFund.deposit(address(usdc));
        vm.stopPrank();

        console2.log("swapFund usdc:",usdc.balanceOf(address(swapFund)));
        console2.log("create matic markets:",matic.balanceOf(address(maticUsdcPool)));

        assertEq(usdc.balanceOf(address(swapFund)),4_000 * 10 ** usdc.decimals());
    }

    function test_swapToMultipleTokens() public {
        test_depositIntoMarkets();

        vm.startPrank(user1);
        address[] memory tokens = new address[](2);
        uint[] memory amounts = new uint[](2);

        // amount in
        amounts[0] = 4000;
        amounts[1] = 1500;

        tokens[0] = address(matic);
        tokens[1] = address(sol);
        
        uint beforeMatic = matic.balanceOf(address(swapFund));
        uint beforeSol = sol.balanceOf(address(swapFund));

        swapFund.createFund(tokens,amounts);
        // console2.log("create matic markets:",matic.balanceOf(address(swapFund)));
        // console2.log("create sol markets:",sol.balanceOf(address(swapFund)));

        uint afterMatic = matic.balanceOf(address(swapFund));
        uint afterSol = sol.balanceOf(address(swapFund));

        assertTrue(afterMatic > 0 , "matic less than zero");
        assertTrue(afterSol > 0 ,"sol less than zero");

        // console2.log("user matic:",swapFund.ownerAssets(user1,address(matic)));
        // console2.log("user sol:",swapFund.ownerAssets(user1,address(sol)));

        // console2.log("user1 fund token address:",swapFund.ownerAssetsTokenAddress(user1,1));

        assertEq(swapFund.ownerAssets(user1,address(matic)), afterMatic - beforeMatic ,
        "tow value should be same.");
        assertEq(swapFund.ownerAssets(user1,address(sol)), afterSol - beforeSol ,
        "tow value should be same.");
        vm.stopPrank();
    }

    // test no cost token swap
    // test cost swap in limit
    // test cost swap over the limit
    function test_withdrawalTokens() public {

        test_swapToMultipleTokens();

        vm.startPrank(user2);
        usdc.approve(address(swapFund), 10_000 * 10 ** usdc.decimals());
        swapFund.deposit(address(usdc));

        address[] memory tokens = new address[](3);
        uint[] memory amounts = new uint[](3);

        // amount in
        amounts[0] = 1000;
        amounts[1] = 2000;
        amounts[2] = 3000;

        tokens[0] = address(matic);
        tokens[1] = address(sol);
        tokens[2] = address(op);
        
        swapFund.createFund(tokens,amounts);

        // console2.log("user2 matic:",swapFund.ownerAssets(user2,address(matic)));
        // console2.log("user2 sol:",swapFund.ownerAssets(user2,address(sol)));
        // console2.log("user2 op:",swapFund.ownerAssets(user2,address(op)));

        vm.stopPrank();

        vm.startPrank(user1);
        // console2.log("user2 op:",swapFund.ownerAssets(user2,address(op)));
        // console2.log("user1 token address 0 :",swapFund.ownerAssetsTokenAddress(user1,0));
        // console2.log("user1 token address 1 :",swapFund.ownerAssetsTokenAddress(user1,1));

        // console2.log("user1 before op:",op.balanceOf(address(user1)));
        swapFund.withdrawalFund(address(op));
        // console2.log("user1 after op:",op.balanceOf(address(user1)));
        vm.stopPrank();
    }

    function test_borrow() public {

        // add Liquidity 
        test_swapToMultipleTokens();

        vm.startPrank(user2);
        usdc.approve(address(swapFund), 10_000 * 10 ** usdc.decimals());
        swapFund.deposit(address(usdc));

        address[] memory tokens = new address[](1);
        uint[] memory amounts = new uint[](1);

        // amount in
        amounts[0] = 10_000;
        tokens[0] = address(op);
        
        swapFund.createFund(tokens,amounts);
        vm.stopPrank();

        // borrow
        vm.startPrank(user1);

        // console2.log("op : ",swapFund.poolTokenAmount(address(op)));
        // console2.log("before user borrow op : ",op.balanceOf(user1));
        swapFund.borrowMax(address(op));
        console2.log("after user borrow op : ",op.balanceOf(user1));
        // console2.log("user1 ct : ",swapFund.balanceOf(user1));
        // console2.log(swapFund.symbol());

        vm.stopPrank();
        assertGe(op.balanceOf(user1), 0);
        assertEq(swapFund.symbol(),"CT");
        assertGe(swapFund.balanceOf(user1),0);
        // console2.log(uint(SwapFund.RewardStatus.liquidate));
        // console2.log(swapFund.rewardStatus(SwapFund.RewardStatus.liquidate));
    }

    function test_repay() public {
        test_borrow();
        vm.startPrank(user1);

        uint beforeCT = swapFund.balanceOf(user1);

        // console2.log(swapFund.loanPrice(user1,address(op)));
        // console2.log("user approve op : ",op.balanceOf(user1));

        op.approve(address(swapFund), op.balanceOf(user1));
        swapFund.repayLoan(op.balanceOf(user1),address(op),user1);

        uint afterCT = swapFund.balanceOf(user1);
        vm.stopPrank();

        assertEq(swapFund.lockBorrowerAssets(user1),false);
        assertEq(swapFund.loanPrice(user1,address(op)),0);
        assertGe(afterCT,beforeCT);
    }

    function test_calculateLoanRepay_notNeedLiquedated() public {
        test_borrow();
        vm.startPrank(user1);

        // uint beforeCT = swapFund.balanceOf(user1);
        (uint loanAmount,address loanToken) = swapFund.calculateLoanRepay(user1);
        (uint totalAssetUsd,)= swapFund.getTotalAssets(user1);
       
        console2.log("checkBorrowLevel:",swapFund.balanceOf(user1));
        console2.log("checkBorrowLevel:",swapFund.checkBorrowLevel());
        console2.log("loanAmount:",loanAmount);
        console2.log("totalAssetUsd:",totalAssetUsd);

        // op.approve(address(swapFund), loanAmount);
        // swapFund.repayLoan(loanAmount,loanToken,user1);

        // uint afterCT = swapFund.balanceOf(user1);
        vm.stopPrank();

        assertEq(loanToken,address(0));
        assertEq(loanAmount,0);
    }

    function test_calculateLoanRepay_needLiquedated() public {
        test_borrow();

        // user2 large swap out the usdt let the matic price down.
        vm.startPrank(user2);
        matic.mint(user2, 10000 * 10 ** matic.decimals());
        usdc.approve(address(uniswapV2Router),type(uint).max);

        (uint reserve00,uint reserve01,) = maticUsdcPool.getReserves();
        uint beforeMatic = uniswapV2Router.getAmountOut(10000 * 10 ** matic.decimals(),reserve01,reserve00);

        address[] memory paths = new address[](2);
        paths[0] = address(usdc);
        paths[1] = address(matic);

        uint[] memory amountOut = uniswapV2Router.swapExactTokensForTokens(
                10000 * 10 ** matic.decimals(),
                beforeMatic, // min out
                paths,
                user2, 
                block.timestamp
            );

        vm.stopPrank();

        // (uint reserve0,uint reserve1,) = maticUsdcPool.getReserves();
        // uint afterMatic = uniswapV2Router.getAmountOut(swapFund.ownerAssets(user1,address(matic)),reserve1,reserve0);
        // console2.log("reserve0",reserve0);
        // console2.log("reserve1",reserve1);
        // console2.log("afterMatic",afterMatic);

        vm.startPrank(user1);
        // uint beforeCT = swapFund.balanceOf(user1);
        (uint loanAmount,address loanToken) = swapFund.calculateLoanRepay(user1);
        (uint totalAssetUsd,)= swapFund.getTotalAssets(user1);
       
        // console2.log("user1 CT amount:",swapFund.balanceOf(user1));
        // console2.log("checkBorrowLevel:",swapFund.checkBorrowLevel());
        // console2.log("loanAmount:",loanAmount);
        // console2.log("totalAssetUsd:",totalAssetUsd);

        vm.stopPrank();

        assertGe(loanAmount,0);
        assertEq(swapFund.lockBorrowerAssets(user1),true);
        assertGe(swapFund.loanPrice(user1,address(op)),0);
    }

    function test_liquidateBorrower() public {
        test_calculateLoanRepay_needLiquedated();

        vm.startPrank(user2);
        op.mint(user2, 10000 * 10 ** op.decimals());
        op.approve(address(swapFund),type(uint).max);

        (uint loanAmount,address loanToken) = swapFund.calculateLoanRepay(user1);

        swapFund.liquidateBorrower(user1,loanAmount,loanToken);
        vm.stopPrank();

        assertEq(swapFund.lockBorrowerAssets(user1),false);
        assertEq(swapFund.loanPrice(user1,address(op)),0);
    }

    function test_createFundAndLiquidate() public {
        test_calculateLoanRepay_needLiquedated();

        vm.startPrank(user2);
        usdc.approve(address(swapFund), 10_000 * 10 ** usdc.decimals());
        swapFund.deposit(address(usdc));

        address[] memory tokens = new address[](2);
        uint[] memory amounts = new uint[](2);

        amounts[0] = 2000;
        amounts[1] = 8000;

        tokens[0] = address(sol);
        tokens[1] = address(op);

        uint beforeLiquidate = matic.balanceOf(user2);
        swapFund.createFundAndLiquidate(tokens,amounts,user1);
        uint afterLiquidate = matic.balanceOf(user2);

        vm.stopPrank();

        assertGe(afterLiquidate,beforeLiquidate,"after reward than before");
        assertEq(swapFund.lockBorrowerAssets(user1),false);
        assertEq(swapFund.loanPrice(user1,address(op)),0);
    }
}
