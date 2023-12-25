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

    // borrower => is locked when he borrow assets.
    mapping(address => bool) public lockBorrowerAssets;

    // borrower address => token => amount
    mapping(address => address) public loanToken;
    mapping(address => mapping(address => uint)) public loanPrice;
   
    
    // token amount in pool
    mapping(address => uint) public poolTokenAmount;

    // user => token => amount
    mapping(address => mapping(address => uint)) public ownerAssets;

    // user => token[]
    mapping(address => address[]) public ownerAssetsTokenAddress;

    // level1 => 20% level2 => 10% level3 => 1%
    // x < 10, x <  100, x < 1000 credit token
    mapping(Levels => uint16) public borrowLevel;
    mapping(RewardStatus => int16) public rewardStatus;
    mapping(TakeOffRewardStatus => int16) public rewardStatusTakeOff;

    // uint public collateralfactor;

    enum Levels {
        level1,
        level2,
        level3
    }

    enum RewardStatus {
        deposit,
        create,
        withdrawal,
        borrow,
        repay,
        liquidate
    }

    enum TakeOffRewardStatus {
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

        mintCreditToken(RewardStatus.deposit,msg.sender);
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

        mintCreditToken(RewardStatus.create,msg.sender);
    }

    // redeem
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

        mintCreditToken(RewardStatus.withdrawal,msg.sender);
    }

    // not design multiple borrow.
    function borrowMax(address token) public {
        Levels borrowLevels = checkBorrowLevel();
        // calculate not correct.
        uint totalAsset = getTotalAssets(msg.sender);

        uint maxBorrowAmount;
        if(borrowLevels == Levels.level1){
            // collateralfactor 80%
            maxBorrowAmount = totalAsset * 8 * 1e17;
        }else if(borrowLevels == Levels.level2){
            // collateralfactor 90%
            maxBorrowAmount = totalAsset * 9 * 1e17;
        }else{
            // collateralfactor 99%
            maxBorrowAmount = totalAsset * 99 * 1e17;
        }

        // check total borrower assets.
        require(maxBorrowAmount > 0 && poolTokenAmount[token] >= maxBorrowAmount);
        lockBorrowerAssets[msg.sender] = true;

        loanToken[msg.sender] = token;
        loanPrice[msg.sender][token] = maxBorrowAmount;
        mintCreditToken(RewardStatus.borrow,msg.sender);
        IERC20(token).transfer(msg.sender, maxBorrowAmount);
    }

    function repayLoan(uint amount,address token) public {
        require(lockBorrowerAssets[msg.sender]);

        uint repay = loanPrice[msg.sender][loanToken[msg.sender]];
        require(amount >= repay);

        IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        lockBorrowerAssets[msg.sender] = false;
        loanPrice[msg.sender][token] = 0;
        mintCreditToken(RewardStatus.repay,msg.sender);
    }

    // 
    function liquidate(address borrower,address token,uint amount) public {
        uint repay = loanPrice[borrower][loanToken[borrower]];

        IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        burnCreditToken(TakeOffRewardStatus.liquidated,borrower);
        mintCreditToken(RewardStatus.repay,msg.sender);
    }

    // compound
    // loan * close factor = loan need to repay, and 
    // pawn - repay loan * Liquidation incentive = remain pawn.
    function calculateLoanRepay(address borrower) public returns(uint,address,uint,address[]){
        // get pawn price, loan price
        (uint loan,address loanToken) = getLoanAssets(borrower);
        (uint pawn,address pawnTokens) = getTotalAssets(borrower);

        // pawn price < loan price
        if(loan > pawn){
            return (loan,loanToken,pawn,pawnTokens);
        }
        
        retrun (0,address(0),0,address(0));
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

    function mintCreditToken(RewardStatus status,address sender) private {
        super.mint(uint256(uint16(rewardStatus[status])),sender);
    }

    function burnCreditToken(TakeOffRewardStatus status,address sender) private {
        super.burn(uint256(uint16(rewardStatusTakeOff[status])),sender);
    }

    function checkBorrowLevel() public view returns(Levels level){
       uint creditTokenAmount = super.balanceOf(msg.sender);

       for(int i = 0;i < 3;i++){
            if(borrowLevel[Levels(i)] > creditTokenAmount){
                return Levels(i);
            }
       }

       return Levels.level1;
    }

    function simpleGetPrice() public returns(uint amount){}

    function simpleSetPrice(address token,uint price) public returns(uint price){}

    function getTotalAssets(address borrower) private returns(uint total,address[] memory pawnTokens){

        address[] memory paths = new address[](2);
            
        for(uint i = 0; ownerAssetsTokenAddress[borrower].length > i;i++){
            address tempToken = ownerAssetsTokenAddress[borrower][i];
            uint256 amountIn = ownerAssets[borrower][tempToken];

            paths[0] = USDC;
            paths[1] = tempToken;
            pawnTokens.push(tempToken);

            address pool = IUniswapV2Factory(_UNISWAP_FACTORY).getPair(paths[0], paths[1]);
            (uint reserve0,uint reserve1,) = IUniswapV2Pair(pool).getReserves();
            uint tempAmount = IUniswapV2Router01(_UNISWAP_ROUTER).getAmountOut(amountIn,reserve0,reserve1);

            total += tempAmount;
        }
    }

    function getLoanAssets(address borrower) private returns(uint total,address borowerToken){
        address[] memory paths = new address[](2);
        borowerToken = loanToken[borrower];
        uint256 amountIn =  loanPrice[borrower][borowerToken];
            
        paths[0] = USDC;
        paths[1] = tempToken;

        address pool = IUniswapV2Factory(_UNISWAP_FACTORY).getPair(paths[0], paths[1]);
        (uint reserve0,uint reserve1,) = IUniswapV2Pair(pool).getReserves();
        uint tempAmount = IUniswapV2Router01(_UNISWAP_ROUTER).getAmountOut(amountIn,reserve0,reserve1);

        total += tempAmount;
    }

    function setBorrowLevel() external {
        borrowLevel[Levels.level1] = 10;
        borrowLevel[Levels.level2] = 100;
        borrowLevel[Levels.level3] = 1000;
    }

     function setRewardLevel() external {
        rewardStatus[RewardStatus.deposit] = 1;
        rewardStatus[RewardStatus.withdrawal] = 1;
        rewardStatus[RewardStatus.borrow] = 3;
        rewardStatus[RewardStatus.create] = 2;
        rewardStatus[RewardStatus.repay] = 5;
        rewardStatus[RewardStatus.liquidate] = 6;
        rewardStatusTakeOff[TakeOffRewardStatus.liquidated] = 10;
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
