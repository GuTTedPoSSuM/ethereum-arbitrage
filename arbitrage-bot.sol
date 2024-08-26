// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/protocol-v2/contracts/flashloan/BaseFlashloanReceiver.sol";
import "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/Address.sol";

contract ArbitrageBot is BaseFlashloanReceiver {
    ILendingPoolAddressesProvider provider;
    IUniswapV2Router02 uniswapRouter;
    address owner;

    constructor(ILendingPoolAddressesProvider _provider, IUniswapV2Router02 _uniswapRouter) {
        provider = _provider;
        uniswapRouter = _uniswapRouter;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function executeArbitrage(uint256 amount) external onlyOwner {
        // Initiate a flashloan on Aave for the specified amount
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        address;
        assets[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI
        uint256;
        amounts[0] = amount;
        uint256;
        modes[0] = 0; // No debt

        lendingPool.flashLoan(address(this), assets, amounts, modes, address(this), "", 0);
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // 1. Swap DAI to ETH on Uniswap
        uint256 daiBalance = IERC20(assets[0]).balanceOf(address(this));
        IERC20(assets[0]).approve(address(uniswapRouter), daiBalance);
        
        address;
        path[0] = assets[0]; // DAI
        path[1] = uniswapRouter.WETH();

        uint256[] memory ethReceived = uniswapRouter.swapExactTokensForETH(
            daiBalance,
            1, // Set a minimum amount for safety
            path,
            address(this),
            block.timestamp
        );

        // 2. Swap ETH back to DAI using 1inch
        address oneInch = 0x11111112542d85b3ef69ae05771c2dccff4faa26; // 1inch Router address
        (bool success, ) = oneInch.call{value: address(this).balance}("");
        require(success, "1inch swap failed");

        // 3. Repay Aave flashloan
        uint256 totalDebt = amounts[0] + premiums[0];
        IERC20(assets[0]).approve(address(provider.getLendingPool()), totalDebt);
        return true;
    }

    // To withdraw profits
    function withdrawProfits() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    receive() external payable {}
}
