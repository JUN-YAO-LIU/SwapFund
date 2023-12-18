import logo from './logo.svg';
import './App.css';
import { ethers } from "ethers";

function App() {
  let signer = null;
  let provider;
  
  if (window.ethereum != null) {
    provider = new ethers.BrowserProvider(window.ethereum)
    console.log(provider);
  }



  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

export default App;
