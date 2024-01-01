import logo from './logo.svg';
import './App.css';
import { ethers } from "ethers";

function Borrow() {
  let signer = null;
  let provider;
  
  if (window.ethereum != null) {
    provider = new ethers.BrowserProvider(window.ethereum)
    console.log(provider);
  }

  return (
    <div>
     <h1>123</h1>
    </div>
  );
}

export default Borrow;
