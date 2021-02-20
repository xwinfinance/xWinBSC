pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later
import "./Interface/xWinFundInterface.sol";
import "./Library/access/Ownable.sol";
import "./Interface/BandProtocolInterface.sol";
import "./Interface/BscSwapRouterInterface.sol";
import "./Library/BscSwapLibrary.sol";

contract xWinMaster is Ownable {
    
    string public name;
    address private deployeraddress;
    IStdReference chainPricesFeed;
    IBSCswapRouter02 bscswapRouter;
    
    mapping(address => bool) public pancakePriceToken;
    mapping(address => string) public TokenNames;
    mapping(address => address) public PriceFeeds;
    address private BscRouterV2;// = address(0xd954551853F55deb4Ae31407c423e67B1621424A);
    address private priceFeedAddress;// = address(0xDA7a001b254CD22e46d3eAB04d937489c93174C3);

    constructor(
        address _routerAddress,
        address _priceFeedAddress
        ) public {
        name = "xWin Master";
        deployeraddress = msg.sender;
        BscRouterV2 = address(_routerAddress);
        priceFeedAddress = address(_routerAddress);
        chainPricesFeed = IStdReference(_priceFeedAddress);
        bscswapRouter = IBSCswapRouter02(_routerAddress);
    }
    
    /// @dev return aave and chainlink price address
    function getPriceFeedAddress() external view returns (
            address priceFeedaddress){
         return priceFeedAddress;
    }
    
    /// @dev return aave and chainlink price address
    function getTokenName(address _tokenaddress) external view returns (
            string memory tokenname){
         return TokenNames[_tokenaddress];
    }
    
    /// @dev return BscRouterV2 address
    function getRouterAddress() external view returns (address ){
         return BscRouterV2;
    }

    /// @dev return aave and chainlink price address
    function updateTokenNames(
        address[] calldata underlyingAddress, 
        string[] calldata tokennames) external onlyOwner {
        
        for (uint i = 0; i < underlyingAddress.length; i++) {
            TokenNames[underlyingAddress[i]] = tokennames[i];
        }
    }
    
    function addPancakePriceToken(string [] memory _tokenname, address[] calldata _addressToken, bool [] memory _usePancake) public onlyOwner {
        
        for (uint i = 0; i < _tokenname.length; i++) {
            pancakePriceToken[_addressToken[i]] = _usePancake[i];
        }
    }
    
    function _getTokenName(address _tokenaddress) internal view returns (string memory tokenname){
         return TokenNames[_tokenaddress];
    }

    function getPriceByAddress(address _targetAdd, string memory _toTokenName) external view returns (uint rate){
        
        if(pancakePriceToken[_targetAdd] == true){
            (rate, ) = getQuotes(_targetAdd);
        }else{
            string memory fromToken = TokenNames[_targetAdd];
            IStdReference.ReferenceData memory data = chainPricesFeed.getReferenceData(fromToken, _toTokenName);
            rate = data.rate;
        }
        return rate;
    }

    function getPriceFromBand(string memory _fromToken, string memory _toToken) external view returns (uint){
        IStdReference.ReferenceData memory data = chainPricesFeed.getReferenceData(_fromToken, _toToken);
        return data.rate;
    }
    
    function getQuotes(
        address targetToken
    ) public view 
        returns (uint amountOutB, uint amountOutA) {
        
        (uint reserveA, uint reserveB) = BSCswapLibrary.getReserves(bscswapRouter.factory(), targetToken, bscswapRouter.WBNB());
        amountOutB = BSCswapLibrary.quote(1e18, reserveA, reserveB);
        amountOutA = BSCswapLibrary.quote(1e18, reserveB, reserveA);
        
        return (amountOutB, amountOutA);
        
    }
}