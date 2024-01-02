// const provider = new ethers.providers.Web3Provider(window.ethereum)
// let testNumber = await provider.getBlockNumber()

// console.log(testNumber)
if (typeof window.ethereum !== 'undefined') {
    console.log('MetaMask is installed!');
}