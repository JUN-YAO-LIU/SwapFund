import data from "../out/CreditPool.sol/CreditPool.json" assert { type: 'json' }
import dataTestERC20 from "../out/TestERC20.sol/TestERC20.json" assert { type: 'json' }

// console.log(testNumber)
if (typeof window.ethereum !== 'undefined') {
    console.log('MetaMask is installed!');
}

const provider = new ethers.providers.Web3Provider(window.ethereum)
var signer;
var myAddress;
const swapFundAddr = "0x38A7410130C3aE2CC783A6B8461a1101955967FC"
const usdcAddr = "0x3E826335541543C1234bA0aA1C52c593ae6460a1"
const opAddr = "0x336187F5EE513abaDfB8E3480928589fE6C96488"
const solAddr = "0x9240771F06Ad0E8767B8B76596c359005b5eFBd7"
const maticAddr = "0x111c70bF4A7bbfc755809aA888f92367b99192aD"

// async function usdc(){
//     return new ethers.Contract("0x3E826335541543C1234bA0aA1C52c593ae6460a1", dataTestERC20.abi, signer)
// }

document.getElementById("connectBtn").onclick = async() => {
    // MetaMask requires requesting permission to connect users accounts
    await provider.send("eth_requestAccounts",[])
    signer = provider.getSigner()
    myAddress = await signer.getAddress()

    // 0x570D01A5Bd431BdC206038f3cff8E17B22AA3662
    let usdc = new ethers.Contract(usdcAddr, dataTestERC20.abi, signer)
    let usdtBalance = await usdc.balanceOf(myAddress);

    let swapFund = new ethers.Contract(swapFundAddr, data.abi, signer)

    let maticBalance = await swapFund.ownerAssets(myAddress,maticAddr)
    let solBalance = await swapFund.ownerAssets(myAddress,solAddr)
    let opBalance = await swapFund.ownerAssets(myAddress,opAddr)

    document.getElementById('ownerAddress').innerHTML = myAddress
    document.getElementById('usdcAmount').innerHTML = usdtBalance
    document.getElementById('maticAmount').innerHTML = maticBalance
    document.getElementById('solAmount').innerHTML = solBalance
    document.getElementById('opAmount').innerHTML = opBalance
}

document.getElementById("RepayBtn").onclick = async() => {
    const swapFund = new ethers.Contract(swapFundAddr, data.abi, signer)

    let checkmatic = document.getElementById("radioRepayMATIC");
    let checkop = document.getElementById("radioRepayOP"); 
    let checksol = document.getElementById("radioRepaySOL");
    let repayValue = document.getElementById("repayValue").value;

    let token = "";

    if(checkmatic.checked == true){
        token = maticAddr
        let matic = new ethers.Contract(maticAddr, dataTestERC20.abi, signer)
        matic.approve(swapFundAddr, repayValue)
    }

    if(checkop.checked == true){
        token = opAddr
        let op = new ethers.Contract(opAddr, dataTestERC20.abi, signer)
        op.approve(swapFundAddr, repayValue)
    }

    if(checksol.checked == true){
        token = solAddr
        let sol = new ethers.Contract(solAddr, dataTestERC20.abi, signer)
        sol.approve(swapFundAddr, repayValue)
    }
    
    await swapFund.repayLoan(repayValue,token,myAddress)
}

document.getElementById("borrowBtn").onclick = async() => {
    const swapFund = new ethers.Contract(swapFundAddr, data.abi, signer)

    const name = await swapFund.name()
    const symbol = await swapFund.symbol()
    const decimals = await swapFund.decimals()
    const totalSupply = await swapFund.totalSupply()

    console.log(swapFund)
    console.log(name)
    console.log(symbol)
    console.log(decimals)
    console.log(totalSupply)

    let checkmatic = document.getElementById("radioBorrowMATIC");
    let checkop = document.getElementById("radioBorrowOP"); 
    let checksol = document.getElementById("radioBorrowSOL");
    
    let token = "";

    if(checkmatic.checked == true){
        token = maticAddr
    }

    if(checkop.checked == true){
        token = opAddr
    }

    if(checksol.checked == true){
        token = solAddr
    }
    
    swapFund.borrowMax(token)
}