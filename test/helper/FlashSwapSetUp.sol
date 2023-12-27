// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { IUniswapV2Factory } from "v2-core/interfaces/IUniswapV2Factory.sol";
// import { UniswapV2Factory } from "v2-core/UniswapV2Factory.sol";

import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";

import { IUniswapV2Router01 } from "v2-periphery/interfaces/IUniswapV2Router01.sol";
// import { UniswapV2Router01 } from "v2-periphery/UniswapV2Router01.sol";

import { TestWETH9 } from "../../src/test/TestWETH9.sol";
import { TestERC20 } from "../../src/test/TestERC20.sol";

contract FlashSwapSetUp is Test {
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router01 public uniswapV2Router;

    IUniswapV2Pair public maticUsdcPool;
    IUniswapV2Pair public wethUsdcPool;
    IUniswapV2Pair public opUsdcPool;
    IUniswapV2Pair public solUsdcPool;
    IUniswapV2Pair public solOpPool;
    IUniswapV2Pair public maticOpPool;

    TestWETH9 public weth;
    TestERC20 public usdc;
    TestERC20 public matic;
    TestERC20 public op;
    TestERC20 public sol;

    function setUp() public virtual {

        usdc = _create_erc20("USD Coin", "USDC", 6);
        matic = _create_erc20("Polygon Coin", "MATIC", 6);
        op = _create_erc20("OP", "OP", 6);
        sol = _create_erc20("SOL", "SOL", 6);
        weth = _create_weth9();

        uniswapV2Factory = _create_uniswap_v2_factory();

        maticUsdcPool = _create_pool(address(uniswapV2Factory), address(matic), address(usdc));
        opUsdcPool = _create_pool(address(uniswapV2Factory), address(op), address(usdc));
        solUsdcPool = _create_pool(address(uniswapV2Factory), address(sol), address(usdc));
        solOpPool = _create_pool(address(uniswapV2Factory), address(sol), address(op));
        maticOpPool = _create_pool(address(uniswapV2Factory), address(matic), address(op));

        uniswapV2Router = _create_uniswap_v2_router(address(uniswapV2Factory), address(usdc));

        vm.label(address(uniswapV2Factory), "UniswapV2Factory");
        vm.label(address(uniswapV2Router), "UniswapV2Router");

        vm.label(address(maticUsdcPool), "maticUsdcPool");
        vm.label(address(opUsdcPool), "opUsdcPool");
        vm.label(address(solUsdcPool), "solUsdcPool");
        vm.label(address(solOpPool), "solOpPool");
        vm.label(address(maticOpPool), "maticOpPool");

        vm.label(address(weth), "WETH9");
        vm.label(address(usdc), "USDC");
        vm.label(address(matic), "MATIC");
        vm.label(address(op), "OP");
        vm.label(address(sol), "SOL");
    }

    function _create_weth9() public returns (TestWETH9) {
        weth = new TestWETH9();
        return weth;
    }

    function _create_erc20(string memory name, string memory symbol, uint8 decimals) public returns (TestERC20) {
        return new TestERC20(name, symbol, decimals);
    }

    function _create_pool(address factory, address tokenA, address tokenB) public returns (IUniswapV2Pair) {
        address pool = IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        return IUniswapV2Pair(pool);
    }

    function _create_uniswap_v2_factory() internal returns (IUniswapV2Factory) {
        string memory path = string(
            abi.encodePacked(vm.projectRoot(), "/test/v2-core-build/UniswapV2Factory.json")
        );
        string memory artifact = vm.readFile(path);
        bytes memory creationCode = vm.parseBytes(abi.decode(vm.parseJson(artifact, ".bytecode"), (string)));
        creationCode = abi.encodePacked(creationCode, abi.encode(address(0)));
        address anotherAddress;

        assembly {
            anotherAddress := create(0, add(creationCode, 0x20), mload(creationCode))
        }

        return IUniswapV2Factory(anotherAddress);
    }

    function _create_uniswap_v2_router(address factory, address weth9) internal returns (IUniswapV2Router01) {
        string memory path = string(
            abi.encodePacked(vm.projectRoot(), "/test/v2-periphery-build/UniswapV2Router01.json")
        );
        string memory artifact = vm.readFile(path);
        bytes memory creationCode = vm.parseBytes(abi.decode(vm.parseJson(artifact, ".bytecode"), (string)));

        creationCode = abi.encodePacked(creationCode, abi.encode(factory), abi.encode(weth9));
        address anotherAddress;

        assembly {
            anotherAddress := create(0, add(creationCode, 0x20), mload(creationCode))
        }

        return IUniswapV2Router01(anotherAddress);
    }
}
