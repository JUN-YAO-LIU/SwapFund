import data from "../out/SwapFund.sol/SwapFund.json" assert { type: 'json' }
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
    let usdtBalance = await usdc.balanceOf(myAddress)

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

// const signer = provider.getSigner("0x570D01A5Bd431BdC206038f3cff8E17B22AA3662")
document.getElementById("testBtn").onclick = async() => {
    let swapFund = new ethers.Contract(swapFundAddr, data.abi, signer)
    let usdc = new ethers.Contract(usdcAddr, dataTestERC20.abi, signer)

    const name = await swapFund.name()
    const symbol = await swapFund.symbol()
    const decimals = await swapFund.decimals()
    const totalSupply = await swapFund.totalSupply()

    console.log(swapFund)
    console.log(name)
    console.log(symbol)
    console.log(decimals)
    console.log(totalSupply)

    let checkmatic = document.getElementById("checkmatic");
    let checkop = document.getElementById("checkop"); 
    let checksol = document.getElementById("checksol");

    let inputmatic = document.getElementById("inputmatic").value;
    let inputop = document.getElementById("inputop").value; 
    let inputsol = document.getElementById("inputsol").value;

    await usdc.approve(swapFundAddr, usdc.balanceOf(myAddress));

    let tokens = [];
    let address = [];
    if(checkmatic.checked == true){
        address.push(maticAddr)
        tokens.push(parseInt(inputmatic))
    }

    if(checkop.checked == true){
        address.push(opAddr)
        tokens.push(parseInt(inputop))
    }

    if(checksol.checked == true){
        address.push(solAddr)
        tokens.push(parseInt(inputsol))
    }

    console.log(address)
    console.log(tokens)

    await swapFund.deposit(usdcAddr);
    await swapFund.createFund(address,tokens);
}

// document.getElementById("ownerAddress").value=;