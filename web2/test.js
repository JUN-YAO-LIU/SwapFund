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

document.getElementById("mintUSDC").onclick = async() => {
    // MetaMask requires requesting permission to connect users accounts
    await provider.send("eth_requestAccounts",[])
    signer = provider.getSigner()
    myAddress = await signer.getAddress()

    // 0x570D01A5Bd431BdC206038f3cff8E17B22AA3662
    let usdc = new ethers.Contract(usdcAddr, dataTestERC20.abi, signer)
    let usdtBalance = await usdc.balanceOf(myAddress)
    await usdc.mint(myAddress,100000 * 1000000)
}