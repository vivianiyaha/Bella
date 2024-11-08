// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin contracts for security and functionality
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// PancakeSwap interfaces
interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPancakeRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

contract Bella is Ownable, ReentrancyGuard, Pausable {

    address public pancakeRouter;
    address public WBNB;

    // Constructor to set router and WBNB addresses
    constructor(address _pancakeRouter, address _WBNB) {
        pancakeRouter = _pancakeRouter;
        WBNB = _WBNB;
    }

    // Function to check liquidity in the PancakeSwap pair
    function checkLiquidity(address token, uint256 amount) external view returns (bool) {
        address pair = IPancakeFactory(pancakeRouter).getPair(token, WBNB);
        require(pair != address(0), "Liquidity pair does not exist");

        // Get the reserves from the pair contract
        (uint112 reserveToken, uint112 reserveBNB, ) = IPancakePair(pair).getReserves();

        // If the amount to trade is less than the token's liquidity, return true
        if (reserveToken >= amount) {
            return true;
        } else {
            return false;  // Not enough liquidity for the trade
        }
    }

    // Function to check if a token is a honeypot
    function honeypotCheck(address token) external view returns (bool) {
        // Perform a small transfer to check if the contract allows a sell action
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));

        // Try transferring a small amount of tokens (e.g., 1 token)
        bool success = IERC20(token).transfer(address(0), 1);

        // If the transfer failed, it may be a honeypot
        if (!success) {
            return true;  // It is a honeypot
        }

        // Revert the transfer (to restore the contract's token balance)
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(balanceAfter > balanceBefore, "Transfer failed to restore balance");

        return false;  // Not a honeypot
    }

    // Function to check if a token is a honeypot by simulating a swap
    function honeypotSwapCheck(address token, uint256 amount) external view returns (bool) {
        address;
        path[0] = token;  // The token we want to sell
        path[1] = WBNB;   // We want to swap to WBNB

        // Get the expected output from the swap (simulating the swap)
        uint256[] memory amountsOut = IPancakeRouter(pancakeRouter).getAmountsOut(amount, path);

        // If the output amount is too low, it could indicate honeypot behavior
        if (amountsOut[1] < amount) {
            return true;  // Likely a honeypot (not enough output)
        }

        return false;  // Not a honeypot
    }

    // Function to check trade feasibility (liquidity and honeypot check)
    function checkTradeFeasibility(address token, uint256 amount) external view returns (bool) {
        // First, check if the liquidity is available
        bool liquidityAvailable = checkLiquidity(token, amount);

        // Second, check if it's a honeypot
        bool isHoneypot = honeypotCheck(token);

        // If liquidity is available and it is not a honeypot, return true
        if (liquidityAvailable && !isHoneypot) {
            return true;  // Trade is feasible
        } else {
            return false;  // Trade is not feasible
        }
    }

    // Function to start trading (placeholder)
    function startTrading() external onlyOwner whenNotPaused {
        // Implement logic to start the bot trading
    }

    // Function to stop trading (placeholder)
    function stopTrading() external onlyOwner whenNotPaused {
        // Implement logic to stop the bot trading
    }

    // Function to withdraw funds (only owner can withdraw)
    function withdrawFunds(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient balance");
        IERC20(token).transfer(msg.sender, amount);
    }

    // Function to pause the contract (only owner can pause)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (only owner can unpause)
    function unpause() external onlyOwner {
        _unpause();
    }
}
