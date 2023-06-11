// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TokenBuyback is Ownable {
    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    address private wallet1;
    address private wallet2;
    uint private buybackPercentage = 40;  // Swap the ETH for the Tokens and sends it to 0xdead
    uint private distributionPercentage1 = 30; // Wallet 1 to receive ETH share
    uint private distributionPercentage2 = 30; // Wallet 2 to receive ETH share
    address private tokenContractAddress;
    IUniswapV2Router02 private uniswapV2Router;
    
    event TokensBoughtBack(uint amount);
    event EthDistributed(address indexed wallet, uint amount);
    
    constructor(address _wallet1, address _wallet2, address _tokenContractAddress, address _uniswapRouterAddress) {
        wallet1 = _wallet1;
        wallet2 = _wallet2;
        tokenContractAddress = _tokenContractAddress;
        uniswapV2Router = IUniswapV2Router02(_uniswapRouterAddress);
    }
    
    receive() external payable {
        buyTokens();
        distributeEth();
    }
    
    function buyTokens() private {
        require(msg.value > 0, "No ETH sent");
        
        uint buybackAmount = (msg.value * buybackPercentage) / 100;
        
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenContractAddress;
        
        uniswapV2Router.swapExactETHForTokens{value: buybackAmount}(    // Swap executes here
            0,
            path,
            BURN_ADDRESS,
            block.timestamp
        );
        
        emit TokensBoughtBack(buybackAmount);
    }
    
    function distributeEth() private {
        require(msg.value > 0, "No ETH sent");
        
        uint distributeAmount = (msg.value * distributionPercentage1) / 100;
        payable(wallet1).transfer(distributeAmount);
        emit EthDistributed(wallet1, distributeAmount);
        
        distributeAmount = (msg.value * distributionPercentage2) / 100;
        payable(wallet2).transfer(distributeAmount);
        emit EthDistributed(wallet2, distributeAmount);
    }
    
    function setWallet1(address _wallet) public onlyOwner {
        wallet1 = _wallet;
    }
    
    function setWallet2(address _wallet) public onlyOwner {
        wallet2 = _wallet;
    }
    
    function setBuybackPercentage(uint _percentage) public onlyOwner {
        require(_percentage <= 100, "Percentage exceeds 100");
        buybackPercentage = _percentage;
    }
    
    function setDistributionPercentage1(uint _percentage) public onlyOwner {
        require(_percentage <= 100, "Percentage exceeds 100");
        distributionPercentage1 = _percentage;
    }
    
    function setDistributionPercentage2(uint _percentage) public onlyOwner {
        require(_percentage <= 100, "Percentage exceeds 100");
        distributionPercentage2 = _percentage;
    }
    
    function setTokenContractAddress(address _tokenContractAddress) public onlyOwner {
        tokenContractAddress = _tokenContractAddress;
    }
    
    function setUniswapRouterAddress(address _uniswapRouterAddress) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(_uniswapRouterAddress);
    }
    
    function withdrawToken(address _token, uint _amount) public onlyOwner {
        IERC20 tokenContract = IERC20(_token);
        tokenContract.transfer(owner(), _amount);
    }
    
    function withdrawETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getTokenBalance(address _token) public view returns (uint) {
        IERC20 tokenContract = IERC20(_token);
        return tokenContract.balanceOf(address(this));
    }
}


