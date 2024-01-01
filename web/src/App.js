import logo from './logo.svg';
import './App.css';
import { Route, Routes, Link } from "react-router-dom";
import { ethers } from "ethers";
import Borrow from './Borrow';

function App() {
  let signer = null;
  let provider;
  
  if (window.ethereum != null) {
    provider = new ethers.BrowserProvider(window.ethereum)
    console.log(provider);
  }

  return (
    <div>
        <h1>Hello</h1>
        <ul className='App-link'>
          <li>
            <Link to='/'>home</Link>
          </li>
          <li>
            <Link to='/borrow'>borrow</Link>
          </li>
        </ul>
        <Routes>
          <Route path='borrow' element={<Borrow />} />
        </Routes>
    </div>
  );
}

export default App;
