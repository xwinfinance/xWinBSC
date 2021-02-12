pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./Library/math/SafeMath.sol";
import "./Library/utils/TransferHelper.sol";
import "./Library/token/SafeBEP20.sol";
import "./Library/access/Ownable.sol";


contract xWinTimeLockVault is Ownable{
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address public XWNToken;
    string public name;
    uint256 private startblock;
    uint256 public harvestPeriod;

    event Received(address, uint);

    constructor(
        string memory _name,
        uint256 _harvestPeriod,
        address _XWNToken
        ) public {
        name = _name;
        XWNToken = _XWNToken;
        harvestPeriod = _harvestPeriod;
        startblock = block.number;
    }
    
    /// @dev reclaim xwn token by the team
    function ReclaimXWNToken(
        address payable toAddress
        ) external onlyOwner payable  {

        uint256 transferableQty = this.GetEstimateReclaimToken();
        require(transferableQty > 0, "No Qty To Transfer");
        
        TransferHelper.safeApprove(XWNToken, address(this), transferableQty); 
        TransferHelper.safeTransferFrom(XWNToken, address(this), toAddress, transferableQty);
        
        startblock = block.number;
    }
    
    /// @dev get estimated timelocked XWN token allow to be transfer
    function GetEstimateReclaimToken() external view returns (uint256) {
        
        uint256 transferableQty = 0;
        uint256 blockdiff = block.number.sub(startblock); 
        uint256 one = 1e18;
        uint256 oneblockpercentage = one.div(harvestPeriod);
        uint256 balanceToken = IBEP20(XWNToken).balanceOf(address(this));
        transferableQty = blockdiff.mul(oneblockpercentage).mul(balanceToken).div(1e18);
        uint amountTosend = (balanceToken >= transferableQty) ? transferableQty: balanceToken;
        return amountTosend;
    }
}