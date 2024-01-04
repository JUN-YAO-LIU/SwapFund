import data from "../out/SwapFund.sol/SwapFund.json" assert { type: 'json' }

// console.log(testNumber)
if (typeof window.ethereum !== 'undefined') {
    console.log('MetaMask is installed!');
}


const provider = new ethers.providers.Web3Provider(window.ethereum)
const signer = provider.getSigner("0x570D01A5Bd431BdC206038f3cff8E17B22AA3662")

const swapFund = new ethers.Contract("0x38A7410130C3aE2CC783A6B8461a1101955967FC", data.abi, signer)

const name = await swapFund.name()
const symbol = await swapFund.symbol()
const decimals = await swapFund.decimals()
const totalSupply = await swapFund.totalSupply()

console.log(swapFund)
console.log(symbol)
console.log(totalSupply)