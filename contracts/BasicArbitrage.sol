// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract BasicArbitrage is Ownable {
  event Received(address sender, uint256 amount);
  event Arbitraged(uint256 profit);

  constructor () Ownable(msg.sender) {}

  function estimateProfit(
    address tokenA,
    address tokenB,
    address router1,
    address router2,
    uint amount
  ) external view returns(uint profit) {
    address[] memory path = new address[](2);
    address[] memory reversePath = new address[](2);
    
    path[0] = tokenA;
    path[1] = tokenB;

    uint[] memory amountsOut1 = IUniswapV2Router(router1).getAmountsOut(amount, path);

    reversePath[0] = tokenB;
    reversePath[1] = tokenA;
    uint[] memory amountsOut2 = IUniswapV2Router(router2).getAmountsOut(amountsOut1[1], reversePath);

    if (amountsOut2[1] > amount) {
      profit = amountsOut2[1] - amount;
    } else {
      profit = 0;
    }
  }

  function executeArbitrage(
    address tokenA,
    address tokenB,
    address router1,
    address router2,
    uint amount
  ) external onlyOwner {
    uint estimatedProfit = this.estimateProfit(tokenA, tokenB, router1, router2, amount);
    require(estimatedProfit > 0, "No profit for this arbitrage");

    IERC20(tokenA).transferFrom(msg.sender, address(this), amount);
    IERC20(tokenA).approve(router1, amount);

     // Step 1: Swap on Router1
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        uint[] memory amountsOut = IUniswapV2Router(router1).getAmountsOut(amount, path);
        IUniswapV2Router(router1).swapExactTokensForTokens(amount, amountsOut[1], path, address(this), block.timestamp);

        // Step 2: Swap back on Router2
        uint balanceB = IERC20(tokenB).balanceOf(address(this));
        IERC20(tokenB).approve(router2, balanceB);

        address[] memory reversePath = new address[](2);
        reversePath[0] = tokenB;
        reversePath[1] = tokenA;
        uint[] memory reverseAmountsOut = IUniswapV2Router(router2).getAmountsOut(balanceB, reversePath);
        IUniswapV2Router(router2).swapExactTokensForTokens(balanceB, reverseAmountsOut[1], reversePath, address(this), block.timestamp);

        uint finalBalance = IERC20(tokenA).balanceOf(address(this));
        require(finalBalance > amount, "Arbitrage fail to generate profit");
        IERC20(tokenA).transfer(this.owner(), finalBalance);
        emit Arbitraged(finalBalance);
  }

  function withdraw(address payable receipient) external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No funds to withdraw");

    (bool s, ) = receipient.call{ value: balance }("");
    require(s, "Transfer Failed");
  }

  function getBalance() view external returns(uint256) {
    return address(this).balance;
  }

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }
}