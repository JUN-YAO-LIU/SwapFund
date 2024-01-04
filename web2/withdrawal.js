import data from "../out/SwapFund.sol/SwapFund.json" assert { type: 'json' }
import dataTestERC20 from "../out/TestERC20.sol/TestERC20.json" assert { type: 'json' }

// console.log(testNumber)
if (typeof window.ethereum !== 'undefined') {
    console.log('MetaMask is installed!');
}

const provider = new ethers.providers.Web3Provider(window.ethereum)
var signer;

// async function usdc(){
//     return new ethers.Contract("0x3E826335541543C1234bA0aA1C52c593ae6460a1", dataTestERC20.abi, signer)
// }

document.getElementById("connectBtn").onclick = async() => {
    // MetaMask requires requesting permission to connect users accounts
    await provider.send("eth_requestAccounts",[])
    signer = provider.getSigner()
    let myAddress = await signer.getAddress()

    // 0x570D01A5Bd431BdC206038f3cff8E17B22AA3662
    let usdc = new ethers.Contract("0x3E826335541543C1234bA0aA1C52c593ae6460a1", dataTestERC20.abi, signer)
    let usdtBalance = await usdc.balanceOf(myAddress);

    let matic = new ethers.Contract("0x111c70bF4A7bbfc755809aA888f92367b99192aD", dataTestERC20.abi, signer)
    let maticBalance = await matic.balanceOf(myAddress);

    let sol = new ethers.Contract("0x9240771F06Ad0E8767B8B76596c359005b5eFBd7", dataTestERC20.abi, signer)
    let solBalance = await sol.balanceOf(myAddress);

    let op = new ethers.Contract("0x336187F5EE513abaDfB8E3480928589fE6C96488", dataTestERC20.abi, signer)
    let opBalance = await op.balanceOf(myAddress);

    document.getElementById('ownerAddress').innerHTML = myAddress
    document.getElementById('usdcAmount').innerHTML = usdtBalance
    document.getElementById('maticAmount').innerHTML = maticBalance
    document.getElementById('solAmount').innerHTML = solBalance
    document.getElementById('opAmount').innerHTML = opBalance
}

// const signer = provider.getSigner("0x570D01A5Bd431BdC206038f3cff8E17B22AA3662")
document.getElementById("testBtn").onclick = async() => {
    const swapFund = new ethers.Contract("0x38A7410130C3aE2CC783A6B8461a1101955967FC", data.abi, signer)

    const name = await swapFund.name()
    const symbol = await swapFund.symbol()
    const decimals = await swapFund.decimals()
    const totalSupply = await swapFund.totalSupply()

    console.log(swapFund)
    console.log(name)
    console.log(symbol)
    console.log(decimals)
    console.log(totalSupply)
}

// document.getElementById("ownerAddress").value=;