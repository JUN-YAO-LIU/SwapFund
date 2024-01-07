// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import { IUniswapV2Factory } from "v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Router01 } from "v2-periphery/interfaces/IUniswapV2Router01.sol";
import { TestWETH9 } from "../../src/test/TestWETH9.sol";
import { TestERC20 } from "../../src/test/TestERC20.sol";
import {CreditPool} from "../src/CreditPool.sol";

contract CreditPoolScript is Script {

    address owner = 0x570D01A5Bd431BdC206038f3cff8E17B22AA3662;

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

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        usdc = new TestERC20("USD Coin", "USDC", 6);
        matic = new TestERC20("Polygon Coin", "MATIC", 6);
        op = new TestERC20("OP", "OP", 6);
        sol = new TestERC20("SOL", "SOL", 6);
        weth = new TestWETH9();

        uniswapV2Factory = _create_uniswap_v2_factory();

        maticUsdcPool = _create_pool(address(uniswapV2Factory), address(matic), address(usdc));
        opUsdcPool = _create_pool(address(uniswapV2Factory), address(op), address(usdc));
        solUsdcPool = _create_pool(address(uniswapV2Factory), address(sol), address(usdc));
        solOpPool = _create_pool(address(uniswapV2Factory), address(sol), address(op));
        maticOpPool = _create_pool(address(uniswapV2Factory), address(matic), address(op));

        uniswapV2Router = _create_uniswap_v2_router(address(uniswapV2Factory), address(weth));

        usdc.mint(owner, 10_000_000 * 10 ** usdc.decimals());
        matic.mint(owner, 10_000_000 * 10 ** matic.decimals());
        op.mint(owner, 10_000_000 * 10 ** op.decimals());
        sol.mint(owner, 10_000_000 * 10 ** op.decimals());

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
            owner,
            block.timestamp + 1800
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
            owner,
            block.timestamp+ 1800
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
            owner,
            block.timestamp+ 1800
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
            owner,
            block.timestamp+ 1800
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
            owner,
            block.timestamp+ 1800
        );

       CreditPool creditPool = new CreditPool(address(uniswapV2Factory),address(uniswapV2Router),address(usdc));
       
        vm.stopBroadcast();
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
