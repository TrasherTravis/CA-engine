// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TokenBuyback is Ownable {
    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    address private wallet1;
    address private wallet2;
    uint private buybackPercentage = 90;
    uint private distributionPercentage1 = 5;
    uint private distributionPercentage2 = 5;
    address private tokenContractAddress;
    IUniswapV2Router02 private uniswapV2Router;
    
    uint private thresholdLimit = 0.01 ether; // Threshold limit to initiate the swap for Tokens
    mapping(address => uint) private accumulatedETH;
    
    event TokensBoughtBack(uint amount);
    event EthDistributed(address indexed wallet, uint amount);
    
    constructor(address _wallet1, address _wallet2, address _tokenContractAddress, address _uniswapRouterAddress) {
        wallet1 = _wallet1;
        wallet2 = _wallet2;
        tokenContractAddress = _tokenContractAddress;
        uniswapV2Router = IUniswapV2Router02(_uniswapRouterAddress);
    }
    
    receive() external payable {
        accumulatedETH[msg.sender] += msg.value;
        if (accumulatedETH[msg.sender] >= thresholdLimit) {
            swapTokens(msg.sender);
            distributeEth();
        }
    }
    
    function swapTokens(address user) private {
        uint accumulatedAmount = accumulatedETH[user];
        accumulatedETH[user] = 0;
        
        uint buybackAmount = (accumulatedAmount * buybackPercentage) / 100;
        
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenContractAddress;
        
        uniswapV2Router.swapExactETHForTokens{value: buybackAmount}(
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
    
    function setParameters(uint _buybackPercentage, uint _distributionPercentage1, uint _distributionPercentage2) public onlyOwner {
        require(_buybackPercentage + _distributionPercentage1 + _distributionPercentage2 <= 100, "Total percentage exceeds 100");
        buybackPercentage = _buybackPercentage;
        distributionPercentage1 = _distributionPercentage1;
        distributionPercentage2 = _distributionPercentage2;
    }
    
    function setTokenContractAddress(address _tokenContractAddress) public onlyOwner {
        tokenContractAddress = _tokenContractAddress;
    }
    
    function setUniswapRouterAddress(address _uniswapRouterAddress) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(_uniswapRouterAddress);
    }
    
    function setThresholdLimit(uint _limit) public onlyOwner {
        thresholdLimit = _limit;
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


