// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Factory } from "v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Router01 } from "v2-periphery/interfaces/IUniswapV2Router01.sol";
import { CreditToken } from "./CreditToken.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
// import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract SwapFund is ERC20 {
    uint256 public number;
    address public USDC;
    address public _UNISWAP_FACTORY;
    address public _UNISWAP_ROUTER;
    uint constant initialSupply = 1e18;

    // borrower => is locked when he borrow assets.
    mapping(address => bool) public lockBorrowerAssets;

    // borrower address => token => amount
    mapping(address => address) public loanToken;
    mapping(address => mapping(address => uint)) public loanPrice;

    // user => token => amount
    mapping(address => mapping(address => uint)) public ownerAssets;

    // user => token[]
    mapping(address => address[]) public ownerAssetsTokenAddress;

    // level1 => 20% level2 => 10% level3 => 1%
    // x < 10, x <  100, x < 1000 credit token
    uint[] public borrowLevel;
    mapping(RewardStatus => uint16) public rewardStatus;
    mapping(TakeOffRewardStatus => uint16) public rewardStatusTakeOff;

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

    constructor(
        address factory,
        address router,
        address usdc) ERC20("CreditToken","CT") {
        _UNISWAP_FACTORY = factory;
        _UNISWAP_ROUTER = router;
        USDC = usdc;
        _mint(msg.sender, initialSupply);
        setRewardLevel();
        setBorrowLevel();
    }

     function mint(uint amount,address to) internal  {
        _mint(to,amount);
    }

    function burn(uint amount,address to) internal {
        _burn(to,amount);
    }

    function deposit(address token) public {
        IERC20(token).transferFrom(
            msg.sender,
            address(this),
            IERC20(token).allowance(msg.sender, address(this))
        );

        mintCreditToken(RewardStatus.deposit,msg.sender);
    }

    function createFundAndLiquidate(address[] memory tokens,uint[] memory amounts,address borrower) public {

        (uint loanAmount,address loanToken) = swapFund.calculateLoanRepay(borrower);
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

            // whether liquidate the other loan.
            if(loanToken == paths[1] && amountOut[1] > loanAmount){
                liquidateBorrower(borrower,loanAmount,loanToken);
                amountOut[1] = amountOut[1] - loanAmount;
            }

            ownerAssets[msg.sender][paths[1]] += amountOut[1];
            ownerAssetsTokenAddress[msg.sender].push(paths[1]);
        }

        mintCreditToken(RewardStatus.create,msg.sender);
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

            // whether liquidate the other loan.

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
        uint borrowLevels = checkBorrowLevel();
        // calculate not correct.
        (uint totalAssetUsd,)= getTotalAssets(msg.sender);

        uint maxBorrowUsdt;
        if(borrowLevels == 0){
            // collateralfactor 80%
            maxBorrowUsdt = totalAssetUsd * 8 * 1e17;
        }else if(borrowLevels == 1){
            // collateralfactor 90%
            maxBorrowUsdt = totalAssetUsd * 9 * 1e17;
        }else{
            // collateralfactor 99%
            maxBorrowUsdt = totalAssetUsd * 99 * 1e16;
        }

        maxBorrowUsdt = maxBorrowUsdt / 1e18;
        require(totalAssetUsd > maxBorrowUsdt,"user's total assets must be large than borrow.");

        // price:Token/USD
        uint borrowTokenAmount = getPriceWithToken(USDC,token,maxBorrowUsdt);

        // check total borrower assets.
        require(borrowTokenAmount > 0 && IERC20(token).balanceOf(address(this)) >= borrowTokenAmount,"pool must be than Max Borrow Amount.");
        lockBorrowerAssets[msg.sender] = true;

        loanToken[msg.sender] = token;
        loanPrice[msg.sender][token] = borrowTokenAmount;
        mintCreditToken(RewardStatus.borrow,msg.sender);
        IERC20(token).transfer(msg.sender, borrowTokenAmount);
    }

    function liquidateBorrower(address borrower,uint loanAmount,address loanToken) public {
        require(lockBorrowerAssets[borrower],"borrower's assets is lock.");

        // repay Loan
        IERC20(loanToken).transferFrom(
            msg.sender,
            address(this),
            loanAmount
        );

        lockBorrowerAssets[borrower] = false;
        loanPrice[borrower][loanToken] = 0;

        // get all stacking assets to pool and lender
        liquidatePawnAssetsToLiquidater(borrower);

        burnCreditToken(TakeOffRewardStatus.liquidated,borrower);
        mintCreditToken(RewardStatus.repay,msg.sender);
    }

    function repayLoan(uint amount,address token,address borrower) public {
        require(lockBorrowerAssets[borrower],"borrower's assets is lock.");

        uint repay = loanPrice[borrower][loanToken[borrower]];
        require(amount >= repay,"repay price is insufficient");

        IERC20(token).transferFrom(
            borrower,
            address(this),
            amount
        );

        lockBorrowerAssets[borrower] = false;
        loanPrice[borrower][token] = 0;
        mintCreditToken(RewardStatus.repay,borrower);
    }

    function liquidatePawnAssetsToLiquidater(address borrower) public {
        address[] memory paths = new address[](2);

        // get all value in the pool
        for(uint i = 0; ownerAssetsTokenAddress[borrower].length > i;i++){
            address tempToken = ownerAssetsTokenAddress[borrower][i];
            uint256 amountIn = ownerAssets[borrower][tempToken];

            ownerAssets[borrower][tempToken] = 0;
           
            // to liquidater
            IERC20(tempToken).transfer(msg.sender,amountIn / 2);
        }
    }

    // compound
    // loan * close factor = loan need to repay, and 
    // pawn - repay loan * Liquidation incentive = remain pawn.
    function calculateLoanRepay(address borrower) public returns(uint,address){
        
        // get pawn price, loan price
        (uint loanPrice,uint loanAmount,address loanToken) = getLoanAssets(borrower);
        (uint pawnPrice,) = getTotalAssets(borrower);

        // pawn price < loan price
        if(loanPrice > pawnPrice){
            return (loanAmount,loanToken);
        }
        
        return (0,address(0));
    }

    function getPriceWithToken(address token0,address token1,uint256 amountIn) public view returns(uint){
       address pool = IUniswapV2Factory(_UNISWAP_FACTORY).getPair(token0,token1);
       (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pool).getReserves();
       return IUniswapV2Router01(_UNISWAP_ROUTER).getAmountOut(amountIn,reserve0,reserve1);
    }

    function getPrice(address pool,uint256 amountIn) public view returns(uint){
       // address poolAddr = IUniswapV2Factory(factory).getPair(usdt,token);
       (uint256 _usdt, uint256 _tokenOut,) = IUniswapV2Pair(pool).getReserves();
       return _getAmountOut(amountIn,_usdt,_tokenOut);
    }

    function mintCreditToken(RewardStatus status,address sender) private {
        mint(rewardStatus[status],sender);
    }

    function burnCreditToken(TakeOffRewardStatus status,address sender) private {
        if(rewardStatusTakeOff[status] > balanceOf(sender)){
            burn(balanceOf(sender),sender);
        }else{
            burn(rewardStatusTakeOff[status],sender);
        }
    }

    function checkBorrowLevel() public view returns(uint){
       uint creditTokenAmount = balanceOf(msg.sender);

       for(uint i = 0;i < borrowLevel.length;i++){
            if(borrowLevel[i] > creditTokenAmount){
                return i;
            }
       }

       return 2;
    }

    function simpleGetPrice() public returns(uint amount){}

    // function simpleSetPrice(address token,uint price) public returns(uint price){}

    function getTotalAssets(address borrower) public returns(uint,address[] memory){

        address[] memory paths = new address[](2);
        uint total;
            
        for(uint i = 0; ownerAssetsTokenAddress[borrower].length > i;i++){
            address tempToken = ownerAssetsTokenAddress[borrower][i];
            uint256 amountIn = ownerAssets[borrower][tempToken];
 
            paths[0] = USDC;
            paths[1] = tempToken;

            address pool = IUniswapV2Factory(_UNISWAP_FACTORY).getPair(paths[0], paths[1]);
            (uint reserve0,uint reserve1,) = IUniswapV2Pair(pool).getReserves();
            uint tempAmount = IUniswapV2Router01(_UNISWAP_ROUTER).getAmountOut(amountIn,reserve1,reserve0);

            total += tempAmount;
        }

        return (total,ownerAssetsTokenAddress[borrower]);
    }

    function getLoanAssets(address borrower) private returns(uint,uint,address){
        address[] memory paths = new address[](2);
        address borowerToken = loanToken[borrower];
        uint256 amountIn =  loanPrice[borrower][borowerToken];
            
        paths[0] = USDC;
        paths[1] = borowerToken;

        address pool = IUniswapV2Factory(_UNISWAP_FACTORY).getPair(paths[0], paths[1]);
        (uint reserve0,uint reserve1,) = IUniswapV2Pair(pool).getReserves();
        uint price = IUniswapV2Router01(_UNISWAP_ROUTER).getAmountOut(amountIn,reserve1,reserve0);

        return (price,amountIn,borowerToken);
    }

    function setBorrowLevel() private {
        borrowLevel.push(10);
        borrowLevel.push(100);
        borrowLevel.push(1000);
    }

     function setRewardLevel() private {
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
