pragma solidity ^0.6.0;
// SPDX-License-Identifier: GPL-3.0-or-later

library xWinLib {
   
    // Info of each pool.
    struct PoolInfo {
        address lpToken;           
        uint256 rewardperblock;       
        uint256 multiplier;       
    }
    
    struct UserInfo {
        uint256 amount;     
        uint256 blockstart; 
    }

    struct TradeParams {
      address xFundAddress;
      uint256 amount;
      uint256 priceImpactTolerance;
      uint256 deadline;
      bool returnInBase;
      address referral;
    }  
   
    struct transferData {
      
      address[] targetNamesAddress;
      uint256 totalTrfAmt;
      uint256 totalUnderlying;
      uint256 qtyToTrfAToken;
    }
    
    struct xWinReward {
      uint256 blockstart;
      uint256 accBasetoken;
      uint256 accMinttoken;
      uint256 previousRealizedQty;
    }
    
    struct xWinReferral {
      address referral;
    }
    
    struct UnderWeightData {
      uint256 activeWeight;
      uint256 fundWeight;
      bool overweight;
      address token;
    }
    
    struct DeletedNames {
      address token;
      uint256 targetWeight;
    }
    
    struct PancakePriceToken {
        string tokenname;
        address addressToken;     
    }

}