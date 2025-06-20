// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: bnbPepeIco.sol




abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}



abstract contract Ownable is Context {
    address private _owner;
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

library SafeERC20 {
    using Address for address;

    error SafeERC20FailedOperation(address token);

    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);


    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

/// @title ICO Smart Contract
/// @notice This contract manages an Initial Coin Offering (ICO) with dynamic pricing, referral commissions, and multi-stage token sales.
/// @dev Supports token purchases using ETH and USDT, with optional referral-based bonuses.
contract FuturePepeICO is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using Address for address;

    // USDT stablecoin for purchasing tokens
    IERC20 public usdt;

    // Chainlink price feed for BNB/USD
    AggregatorV3Interface internal priceFeed;

    // Admin wallet to collect funds
    address public adminWallet;

    // List of registered influencer addresses
    address[] public influencers;
    address[] public allUniqueUsers;

    // Determines if fixed pricing is used instead of dynamic stage pricing
    bool public useFixedPrice;

    // Fixed price in USD with 18 decimals (e.g., 3000 = $0.003)
    uint256 public fixedPriceUSD;

    // Sum of all influencer commissions
    uint256 public totalInfluence;

    // Initial and final token prices in USD (18 decimals)
    uint256 public constant INITIAL_PRICE_USD = 3_000_000_000_000_000; // $0.003
    uint256 public constant FINAL_PRICE_USD = 16_730_000_000_000_000;  // $0.01673
    uint256 constant MULTIPLIER = 1e8;

    // Total number of pricing stages
    uint256 public constant TOTAL_STAGES = 20;

    // ICO start time
    uint256 public startTime;

    // Duration and interval constants (set as placeholder for demo/testing)
    uint256 public constant INTERVAL = 9 days;
 
    // Bonus percentages for purchases over $50 and $100
    uint256 private constant BONUS_5000 = 2;      // 2% bonus for $5000+
    uint256 private constant BONUS_10000 = 4;     // 4% bonus for $10000+
    
    // These constants represent the bonus thresholds in USDT smallest units (18 decimals)
    uint256 private USD_5000 = 5000 * 10 ** 18;
    uint256 private USD_10000 = 10000 * 10 **18;
    uint256 public maxCommissionPercent;

    // Total amount of BNB raised from all purchases (denominated in wei)
    uint256 public bnbRaised;

    // Total amount of USDT raised from all purchases (based on USDT decimals)
    uint256 public usdtRaised;

    // Total number of tokens sold across all purchases
    uint256 public totalTokenSold;
    uint256 public totalTokenCap;

    // Flag indicating whether the ICO is currently active
    bool public isActive;

    // Struct to store commission-related data
    struct commissionData {
        uint256 purchaseCount;    // storing how many times user buy from influencer
        uint256 totalSellInUSD;   // total usd amount
        uint256 commissionUSD;    // Commission amount in USD
        uint256 totalTokenSale;   // Total tokens sold by the referred user or affiliate
    }

    mapping(address => uint256) public userDeposits;

    // Mapping to define custom start times for different sale stages
    // The uint8 key represents the stage index (e.g., 0 for Stage 1, etc.),
    // and the uint256 value is the start timestamp for that stage
    mapping(uint8 => uint256) public customStageStartTimes;

    // Influencer address => commission %
    mapping(address => uint256) public commissions;

    // Influencer address => total commission earned in USD
    mapping(address => commissionData) public commissionCollect;         

    // Tracks which addresses are referrers
    mapping(address => bool) public isReferral;

    // Emitted when tokens are successfully purchased
    event TokensPurchased(
        address indexed buyer,
        uint256 usdAmount,
        uint256 tokenAmount
    );

    event TokensPurchasedWithNative(
        address indexed buyer,
        uint256 ethAmount,
        uint256 tokenAmount
    );

    // Emitted when a stage and time
    event StageTimeUpdate(uint256 stage, uint256 _time);

    // Emitted when a commission is assigned to an influencer
    event CommissionSet(address indexed influencer, uint256 commission);

    ///  Emitted when the fixed price settings are updated.
    event FixedPriceUpdated(bool useFixedPrice, uint256 priceUSD);

    ///  Emitted when native ETH is withdrawn from the contract.
    event NativeWithdraw(address indexed to, uint256 amount);

    ///  Emitted when an ERC20 token is withdrawn from the contract.
    event TokenWithdraw(address indexed token, address indexed to, uint256 amount);

    event ToggleSale();

    modifier notPaused() {
        require(isActive, "Sale is paused.");
        _;
    }

    /// @dev Constructor to initialize ICO parameters.
    /// @param _usdt Address of the USDT token used for stable payments.
    /// @param _priceFeed Chainlink price feed address for BNB/USD.
    /// @param _adminWallet Address where collected funds are sent.
    /// @param _startTime Timestamp when the ICO should start.
    constructor(
        address _usdt,
        address _priceFeed,
        address _adminWallet,
        uint256 _startTime
    ) Ownable(msg.sender) {
        usdt = IERC20(_usdt);
        priceFeed = AggregatorV3Interface(_priceFeed);
        adminWallet = _adminWallet;
        startTime = _startTime;
        totalTokenCap = 75_000_000 *10**18;
        maxCommissionPercent = 50; // only real number we gonna support.
    }

    // @notice Function to toggle sale if needed only by owner
    function toggleSale() external onlyOwner{
        isActive = !isActive;
        emit ToggleSale();
    }

    /// @dev Sets commission percentages for a list of influencer addresses.
    /// @param _influencers Array of influencer addresses to register as referrers.
    /// @param _commissions Array of commission percentages corresponding to each influencer in real number like 2 = 2%
    function setInfluencerCommission(address[] memory _influencers, uint256[] memory _commissions) external onlyOwner {
        require(_influencers.length == _commissions.length, "Mismatched array lengths");
        require(_influencers.length <= 100, "Can't allow more than 100 at a time");
        for (uint256 i = 0; i < _influencers.length; i++) {
            address influencer = _influencers[i];
            uint256 newCommission = _commissions[i];
            require(influencer != address(0), "Invalid influencer address");
            require(newCommission >= 1 && newCommission <= maxCommissionPercent, "Commission out of bounds");
            // Only count new influencers
            if (!isReferral[influencer]) {
                influencers.push(influencer);
                totalInfluence += 1; 
            }
            commissions[influencer] = newCommission;
            isReferral[influencer] = true;
            emit CommissionSet(influencer, newCommission);
        }
    }

    // Returns influencer address and their commission by index
    function getInfluencerByIndex(uint256 index) external view returns (address influencer, uint256 sellCount, uint256 totalUSDSell, uint256 commissionAmount, uint256 tokenAmount) {
        require(index < influencers.length, "Index out of bounds");
        influencer = influencers[index];
        commissionData memory data = commissionCollect[influencer];
        sellCount = data.purchaseCount;
        totalUSDSell = data.totalSellInUSD;
        commissionAmount = data.commissionUSD;
        tokenAmount = data.totalTokenSale;
    }

    // All influencer address and their commission by index
    function getAllInfluencersWithCommission() external view returns (address[] memory influencerList, uint256[] memory sellCount, uint256[] memory totalUSDSell,uint256[] memory commissionList,uint256[] memory tokenAmountList) {
        uint256 len = influencers.length;
        influencerList = new address[](len);
        sellCount = new uint256[](len);
        totalUSDSell = new uint256[](len);
        commissionList = new uint256[](len);
        tokenAmountList = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            address influencer = influencers[i];
            commissionData memory data = commissionCollect[influencer];
            influencerList[i] = influencer;
            sellCount[i]= data.purchaseCount;
            totalUSDSell[i]= data.totalSellInUSD;
            commissionList[i] = data.commissionUSD;
            tokenAmountList[i] = data.totalTokenSale;
        }
        return (influencerList, sellCount ,totalUSDSell, commissionList, tokenAmountList);
    }
        
    /// @dev Allows users to purchase tokens using BNB. Applies referral bonuses if applicable.
    /// @param referrer The address of the referrer (if any).
    function buyWithNative(address referrer) external payable notPaused nonReentrant {
        require(msg.value > 0, "Must send BNB to buy tokens");
        uint256 adminAmount = msg.value;
        uint256 tokenAmount = getTokenFromNative(adminAmount);
        _checkSupply(tokenAmount);
        if (isReferral[referrer]) {
            uint256 commissionAmount = (msg.value * commissions[referrer]) / 100;
            adminAmount = msg.value - commissionAmount;
            Address.sendValue(payable(referrer), commissionAmount);
            uint256 usdAmount = getUSDValue(commissionAmount);
            uint256 totalUsdAmount = getUSDValue(msg.value);
            commissionCollect[referrer].purchaseCount += 1;
            commissionCollect[referrer].totalSellInUSD += totalUsdAmount;
            commissionCollect[referrer].commissionUSD += usdAmount;
            commissionCollect[referrer].totalTokenSale += tokenAmount;
        }
        _storeUniqueUser(msg.sender);
        userDeposits[msg.sender] += tokenAmount;
        bnbRaised += msg.value ;
        totalTokenSold += tokenAmount;
        Address.sendValue(payable(adminWallet), adminAmount);
        emit TokensPurchasedWithNative(msg.sender, msg.value, tokenAmount);
    }

    /// @dev Allows users to purchase tokens using USDT. Applies referral bonuses if applicable.
    /// @param usdtAmount The amount of USDT to spend (in smallest unit, e.g., 6 decimals for USDT).
    /// @param referrer The address of the referrer (if any).
    function buyWithUSDT(uint256 usdtAmount, address referrer) external notPaused nonReentrant {
        require(usdtAmount > 0, "Must send USDT to buy tokens");
        require(usdt.allowance(msg.sender, address(this)) >= usdtAmount,"Insufficient allowance");
        uint256 tokenAmount =  getTokenFromUsdt(usdtAmount);
        _checkSupply(tokenAmount);
        uint256 adminAmount = usdtAmount;
        if (isReferral[referrer]){
            uint256 commissionAmount = (usdtAmount * commissions[referrer]) / 100;
            adminAmount = usdtAmount - commissionAmount;
            commissionCollect[referrer].purchaseCount += 1;
            commissionCollect[referrer].totalSellInUSD += usdtAmount;
            commissionCollect[referrer].commissionUSD += commissionAmount;
            commissionCollect[referrer].totalTokenSale += tokenAmount;
            usdt.safeTransferFrom(msg.sender, referrer, commissionAmount);
        }
        _storeUniqueUser(msg.sender);
        userDeposits[msg.sender] += tokenAmount;
        usdtRaised+= usdtAmount;
        totalTokenSold += tokenAmount;
        usdt.safeTransferFrom(msg.sender, adminWallet, adminAmount);
        emit TokensPurchased(msg.sender, usdtAmount, tokenAmount);
    }

    // Function to calculate the token amount based on ETH amount
    function getTokenFromNative(uint256 _bnbAmount) public view returns(uint256 ){
        (, uint256 priceBNB, , ) = getCurrentStageAndPrice();
        uint256 tokenAmount = (_bnbAmount * 1e18) / priceBNB;
        uint256 usdtAmount = getUSDValue(_bnbAmount);
        if (usdtAmount >= USD_5000) {
            tokenAmount += applyBonuses(tokenAmount, getUSDValue(_bnbAmount));
        }
      return tokenAmount;
    }

    // Function to calculate the token amount based on USDT amount
    function getTokenFromUsdt(uint256 _usdtAmount) public view returns(uint256 ){
        (, , uint256 priceUSD, ) = getCurrentStageAndPrice();
        uint256 tokenPriceUSD = priceUSD;
        uint256 tokenAmount = (_usdtAmount * 1e18) / tokenPriceUSD;
        if (_usdtAmount >= USD_5000) {
            tokenAmount += applyBonuses(tokenAmount, _usdtAmount);
        }
      return tokenAmount ;
    }

    /// @dev Calculates and returns the current stage, token price in ETH and USD, and the stage start time.
    /// @return stage The current ICO stage number (1-based index).
    /// @return priceBNB The token price in ETH (wei).
    /// @return priceUSD The token price in USD (with 8 decimals).
    /// @return stageStartTime The timestamp when the current stage started.
    function getCurrentStageAndPrice() public view returns (uint8 stage,uint256 priceBNB,uint256 priceUSD,uint256 stageStartTime){
        uint256 bnbPrice = getLatestPrice();
        require(bnbPrice > 0, "BNB price is zero");
        if (useFixedPrice) {
            uint256 fixedStagePriceInBNB = (fixedPriceUSD * MULTIPLIER) / bnbPrice;
            return (0, fixedStagePriceInBNB, fixedPriceUSD, startTime);
        }
        // Step 1: Build an array of actual start times (with cascading logic)
        uint256[] memory actualStartTimes = new uint256[](TOTAL_STAGES);
        for (uint8 i = 0; i < TOTAL_STAGES; i++) {
            if (i == 0) {
                actualStartTimes[i] = customStageStartTimes[1] != 0
                    ? customStageStartTimes[1]
                    : startTime;
            } else {
                uint8 stageNum = i + 1;
                if (customStageStartTimes[stageNum] != 0) {
                    actualStartTimes[i] = customStageStartTimes[stageNum];
                } else {
                    actualStartTimes[i] = actualStartTimes[i - 1] + INTERVAL;
                }
            }
        }
        // Step 2: Determine current stage based on timestamps
        uint8 currentStage = 0;
        for (uint8 i = 0; i < TOTAL_STAGES; i++) {
            if (block.timestamp < actualStartTimes[i]) {
                break;
            }
            currentStage = i + 1;
        }
        
        // Handle case where current time is before startTime
        if (currentStage == 0) {
            uint256 initialPriceInBNB = (INITIAL_PRICE_USD * MULTIPLIER) / bnbPrice;
            return (0, initialPriceInBNB, INITIAL_PRICE_USD, actualStartTimes[0]);
        }
        // Step 3: Cap to final stage
        if (currentStage >= TOTAL_STAGES) {
            uint256 finalStagePriceInBNB = (FINAL_PRICE_USD * MULTIPLIER) / bnbPrice;
            return (
                uint8(TOTAL_STAGES),
                finalStagePriceInBNB,
                FINAL_PRICE_USD,
                actualStartTimes[TOTAL_STAGES - 1]
            );
        }

        // Step 4: Calculate USD price for current stage
        uint256 priceUSDT = INITIAL_PRICE_USD;
        for (uint8 i = 0; i < currentStage - 1; i++) {
            if (i + 1 >= 1 && i + 1 <= 4) {
                priceUSDT += (priceUSDT * 10) / 100;
            } else if (i + 1 >= 5 && i + 1 <= 10) {
                priceUSDT += (priceUSDT * 9) / 100;
            } else if (i + 1 >= 11 && i + 1 <= 17) {
                priceUSDT += (priceUSDT * 85) / 1000;
            } else if (i + 1 == 18) {
                priceUSDT += (priceUSDT * 8) / 100;
            } else {
                priceUSDT = FINAL_PRICE_USD;
            }
        }
        uint256 stagePriceInBNB = (priceUSDT * MULTIPLIER) / bnbPrice;
        return (
            currentStage,
            stagePriceInBNB,
            priceUSDT,
            actualStartTimes[currentStage - 1]
        );
    }

    /**
    * @notice Sets whether to use a fixed price in USD and defines the fixed price value.
    * @dev Can only be called by the contract owner.
    * @param _useFixedPrice Boolean flag to enable or disable the use of a fixed USD price.
    * @param _priceUSD The fixed price value in USD(in wei) to be used if _useFixedPrice is true.
    */
    function setUseFixedPrice(bool _useFixedPrice, uint256 _priceUSD)
        external
        onlyOwner
    {
        useFixedPrice = _useFixedPrice;
        fixedPriceUSD = _priceUSD;
        emit FixedPriceUpdated(_useFixedPrice, _priceUSD);
    }

    /// @dev Returns a list of all ICO stages along with their ETH and USD prices, and start times.
    /// @return stagesList An array of stage numbers (1-based index).
    /// @return pricesBNB An array of token prices in ETH (in wei) for each stage.
    /// @return pricesUSD An array of token prices in USD (with 8 decimals) for each stage.
    /// @return startTimes An array of start timestamps for each stage.

    function getAllStagesAndPrices()
        external
        view
        returns (
            uint8[] memory stagesList,
            uint256[] memory pricesBNB,
            uint256[] memory pricesUSD,
            uint256[] memory startTimes
        )
        {
            uint8[] memory _stagesList = new uint8[](TOTAL_STAGES);
            uint256[] memory _pricesBNB = new uint256[](TOTAL_STAGES);
            uint256[] memory _pricesUSD = new uint256[](TOTAL_STAGES);
            uint256[] memory _startTimes = new uint256[](TOTAL_STAGES);

            uint256 bnbPrice = getLatestPrice();
            require(bnbPrice > 0, "BNB price is zero");

            uint256 priceUSD = INITIAL_PRICE_USD;

        for (uint8 i = 0; i < TOTAL_STAGES; i++) {
            _stagesList[i] = i + 1;
            if (i == 0) {
                // First stage: use custom or default
                _startTimes[i] = customStageStartTimes[1] != 0
                    ? customStageStartTimes[1]
                    : startTime;
            } else {
                uint8 stageNum = i + 1;
                if (customStageStartTimes[stageNum] != 0) {
                    _startTimes[i] = customStageStartTimes[stageNum];
                } else {
                    _startTimes[i] = _startTimes[i - 1] + INTERVAL;
                }
            }
            _pricesUSD[i] = priceUSD;
            _pricesBNB[i] = (priceUSD * MULTIPLIER) / bnbPrice;

            // Calculate next price (for i + 1 stage)
            if (i + 1 < TOTAL_STAGES) {
                if (i + 1 >= 1 && i + 1 <= 4) {
                    priceUSD += (priceUSD * 10) / 100;
                } else if (i + 1 >= 5 && i + 1 <= 10) {
                    priceUSD += (priceUSD * 9) / 100;
                } else if (i + 1 >= 11 && i + 1 <= 17) {
                    priceUSD += (priceUSD * 85) / 1000;
                } else if (i + 1 == 18) {
                    priceUSD += (priceUSD * 8) / 100;
                } else {
                    priceUSD = FINAL_PRICE_USD;
                }
            }
        }
        return (_stagesList, _pricesBNB, _pricesUSD, _startTimes);
    }

    /**
    * @notice Sets a custom start time for a specific ICO stage
    * @dev Can only be called by the contract owner
    * @param stage The stage number (must be between 1 and TOTAL_STAGES)
    * @param timestamp The custom start time for the specified stage (Unix timestamp)
    */
    function setCustomStageStartTime(uint8 stage, uint256 timestamp) external onlyOwner {
        require(stage >= 1 && stage <= TOTAL_STAGES, "Invalid stage");
        customStageStartTimes[stage] = timestamp;
        emit StageTimeUpdate(stage, timestamp);
    }

    function setMaxCommissionPercent(uint256 _maxCommissionPercent) external onlyOwner {
        require(_maxCommissionPercent < 100, "Can't allow 100 percent");
        maxCommissionPercent = _maxCommissionPercent;
    }

    /**
    * @notice Returns the total amount raised in USDT equivalent (ETH + USDT)
    * @dev ETH is converted to USD using getUSDValue function
    * @return Total amount raised in USD across both currencies
    */
    function totalUsdtRaised() external view returns (uint256) {
        return (getUSDValue(bnbRaised) + usdtRaised);
    }

    /// @dev Converts an ETH amount to its equivalent USD value using the current price feed.
    /// @param bnbAmount The amount of ETH (in wei) to convert.
    /// @return The equivalent USD value (with 8 decimals).
    function getUSDValue(uint256 bnbAmount) public view returns (uint256) {
        uint256 bnbPrice = getLatestPrice(); // Assumes price is in USD with 8 decimals
        return (bnbAmount * bnbPrice) / MULTIPLIER;
    }

    /// @dev Converts a USD amount to its equivalent ETH value using the current price feed.
    /// @param usdAmount The amount of USD (with 8 decimals) to convert.
    /// @return The equivalent BNB amount (in wei).
    function getBNBValue(uint256 usdAmount) public view returns (uint256) {
        uint256 bnbPrice = getLatestPrice(); // ETH price in USD with 8 decimals
        return (usdAmount * MULTIPLIER) / bnbPrice; // Convert to wei (1 ETH = 1e18 wei)
    }

    /// @dev Retrieves the latest ETH/USD price from the Chainlink price feed.
    /// @return The ETH price in USD (with 8 decimals).

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price); // Price returned with 8 decimals
    }

    /// @dev Applies bonus tokens based on the USD value of the purchase.
    /// @param baseAmount The initial amount of tokens before bonus.
    /// @param usdAmount The equivalent USD amount of the purchase.
    /// @return The total bonus amount to be added.
    function applyBonuses(uint256 baseAmount, uint256 usdAmount)
        public
        view
        returns (uint256)
    {
        uint256 bonus = 0;
        if (usdAmount >= USD_10000) {
            bonus = (baseAmount * BONUS_10000) / 100;
        } else if (usdAmount >= USD_5000) {
            bonus = (baseAmount * BONUS_5000) / 100;
        }
        return bonus;
    }

    /**
     * @dev Retrieves the transaction data (e.g., purchases) for a specific user.
     * @param user The address of the user whose transaction data is being queried.
     * @return An array of Purchase structs representing the user's transactions.
     * This function is public and view-only, so it can be called without any gas cost.
     */
    function getUserTxData(address user) external view returns (uint256) {
        return userDeposits[user];
    }

    /// @dev Owner-only function to withdraw native ETH from the contract.
    /// @param amount The amount of ETH (in wei) to withdraw.
    function withdrawNative(uint256 amount) external nonReentrant onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        Address.sendValue(payable(adminWallet), amount);
        emit NativeWithdraw(adminWallet, amount);
    }

    /// @dev Owner-only function to withdraw any ERC20 token.
    /// @param _token The address of the ERC20 token to withdraw.
    /// @param amount The amount of tokens to withdraw in wei
    function withdrawToken(address _token, uint256 amount) external nonReentrant onlyOwner  {
        IERC20 tokenContract = IERC20(_token);
        require(tokenContract.balanceOf(address(this)) >= amount, "Insufficient token balance");
        tokenContract.safeTransfer(adminWallet, amount);
        emit TokenWithdraw(_token, adminWallet, amount);
    }

    function updateTotalTokenCap(uint256 _newTotalTokenCap) external onlyOwner {
        totalTokenCap = _newTotalTokenCap;
    }

    function _storeUniqueUser(address uniqueUserWallet) internal {
        if(userDeposits[uniqueUserWallet] <= 0) {
            allUniqueUsers.push(uniqueUserWallet);
        }  
    }

    function _checkSupply(uint256 _tokenAmount) internal view {
        require(totalTokenSold + _tokenAmount <= totalTokenCap,"Token cap reached");
    }

    receive() external payable {}
}