// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Factory } from "v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Router01 } from "v2-periphery/interfaces/IUniswapV2Router01.sol";
import { CreditToken } from "./CreditToken.sol";

contract SwapFund is CreditToken{
    uint256 public number;
    address public USDC;
    address public _UNISWAP_FACTORY;
    address public _UNISWAP_ROUTER;
    
    mapping(address => uint) public poolTokenAmount;

    // user => token => amount
    mapping(address => mapping(address => uint)) public ownerAssets;

    mapping(address => address[]) public ownerAssetsTokenAddress;

    // level1 => 20% level2 => 10% level3 => 1%
    // x < 10, x <  100, x < 1000 credit token
    mapping(Levels => uint16) public borrowLevel;
    mapping(RewardStatus => int16) public rewardLevel;

    enum Levels {
        level1,
        level2,
        level3
    }

    enum RewardStatus {
        deposit,
        create,
        withdrawal,
        liquidated
    }

    constructor(address factory,address router,address usdc) CreditToken(1e18) {
        _UNISWAP_FACTORY = factory;
        _UNISWAP_ROUTER = router;
        USDC = usdc;
    }

    function deposit(address token) public {
        IERC20(token).transferFrom(
            msg.sender,
            address(this),
            IERC20(token).allowance(msg.sender, address(this))
        );
    }

    function createFund(address[] memory tokens,uint[] memory amounts) public {
        address[] memory paths = new address[](2);
        IERC20(USDC).approve(_UNISWAP_ROUTER,type(uint).max);
        for (uint i=0; i<tokens.length; i++) {
            
            paths[0] = USDC;
            paths[1] = tokens[i];

            address pool = IUniswapV2Factory(_UNISWAP_FACTORY).getPair(paths[0], paths[1]);
            (uint reserve0,uint reserve1,) =  IUniswapV2Pair(pool).getReserves();

            uint tempAmount = IUniswapV2Router01(_UNISWAP_ROUTER).getAmountOut(amounts[i],reserve0,reserve1);
            uint[] memory amountOut = IUniswapV2Router01(_UNISWAP_ROUTER).swapExactTokensForTokens(
                amounts[i],
                tempAmount, // min out
                paths,
                address(this), 
                block.timestamp
            );

            poolTokenAmount[paths[1]] += amountOut[1];
            ownerAssets[msg.sender][paths[1]] += amountOut[1];
            ownerAssetsTokenAddress[msg.sender].push(paths[1]);
        }
    }

    function withdrawalFund(address token) public {
        address[] memory paths = new address[](2);

        // get all value in the pool
        for(uint i = 0; ownerAssetsTokenAddress[msg.sender].length > i;i++){
            address tempToken = ownerAssetsTokenAddress[msg.sender][i];
            uint256 amountIn = ownerAssets[msg.sender][tempToken];

            paths[0] = tempToken;
            paths[1] = token;

            address pool = IUniswapV2Factory(_UNISWAP_FACTORY).getPair(paths[0], paths[1]);
            (uint reserve0,uint reserve1,) = IUniswapV2Pair(pool).getReserves();
            uint tempAmount = IUniswapV2Router01(_UNISWAP_ROUTER).getAmountOut(amountIn,reserve0,reserve1);
            // uint256 tempAmount = getPriceWithToken(tempToken,paths[1],amountIn);

           if(token != tempToken){
                IERC20(tempToken).approve(_UNISWAP_ROUTER,tempAmount);
                uint[] memory amountOut = IUniswapV2Router01(_UNISWAP_ROUTER).swapExactTokensForTokens(
                    amountIn,
                    tempAmount, // min out
                    paths,
                    msg.sender, 
                    block.timestamp
                );
           }
        }
    }

    function getPriceWithToken(address token0,address token1,uint256 amountIn) public view returns(uint){
       address pool = IUniswapV2Factory(_UNISWAP_FACTORY).getPair(token0,token1);
       (uint256 _tokenIn, uint256 _tokenOut,) = IUniswapV2Pair(pool).getReserves();
       return _getAmountOut(amountIn,_tokenIn,_tokenOut);
    }

    function getPrice(address pool,uint256 amountIn) public view returns(uint){
       // address poolAddr = IUniswapV2Factory(factory).getPair(usdt,token);
       (uint256 _usdt, uint256 _tokenOut,) = IUniswapV2Pair(pool).getReserves();
       return _getAmountOut(amountIn,_usdt,_tokenOut);
    }

    function mintCreditToken(uint amount,address sender) private {
        super.mint(1,sender);
    }

    function burnCreditToken(uint amount) private {

    }

    function checkBorrowLevel() external returns(uint level){

    }

    function setBorrowLevel() external {
        borrowLevel[Levels.level1] = 10;
        borrowLevel[Levels.level2] = 100;
        borrowLevel[Levels.level3] = 1000;
    }

     function setRewardLevel() external {
        rewardLevel[RewardStatus.deposit] = 1;
        rewardLevel[RewardStatus.withdrawal] = 3;
        rewardLevel[RewardStatus.create] = 5;
        rewardLevel[RewardStatus.liquidated] = -10;
    }

    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    // copy from UniswapV2Library
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
