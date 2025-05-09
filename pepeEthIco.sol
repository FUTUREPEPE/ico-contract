// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the number of decimals the token uses.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
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
contract PepeETHIco is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using Address for address;

    // Token being sold
    IERC20 public token;

    // USDT stablecoin for purchasing tokens
    IERC20 public usdt;

    // Chainlink price feed for ETH/USD
    AggregatorV3Interface internal priceFeed;

    // Admin wallet to collect funds
    address public adminWallet;
    // fundwallet to send tokens
    mapping(address => bool) public whiteList;

    // List of registered influencer addresses
    address[] public influencers;

    // Determines if fixed pricing is used instead of dynamic stage pricing
    bool public useFixedPrice;

    // Fixed price in USD with 6 decimals (e.g., 3000 = $0.003)
    uint256 public fixedPriceUSD;

    // Sum of all influencer commissions
    uint256 public totalInfluence;

    // Initial and final token prices in USD (6 decimals)
    uint256 public constant INITIAL_PRICE_USD = 3000; // $0.003
    uint256 public constant FINAL_PRICE_USD = 16730;  // $0.01673

    // Total number of pricing stages
    uint256 public constant TOTAL_STAGES = 20;

    // ICO start time
    uint256 public startTime;
    uint256 public constant INTERVAL = 9 days;
 
    // Bonus percentages for purchases over $50 and $100
    uint256 private constant BONUS_5000 = 2;      // 2% bonus for $5000+
    uint256 private constant BONUS_10000 = 4;     // 4% bonus for $10000+

    // These constants represent the bonus thresholds in USDT smallest units (6 decimals)
    uint256 private constant USD_5000 = 5000 * 10 ** 6;
    uint256 private constant USD_10000 = 10000 * 10 **6;
    uint256 constant MULTIPLIER = 1e20;
    uint256 public maxCommissionPercent;

    // Total amount of ETH raised from all purchases (denominated in wei)
    uint256 public ethRaised;

    // Total amount of USDT raised from all purchases (based on USDT decimals)
    uint256 public usdtRaised;

    // Total number of tokens sold across all purchases
    uint256 public totalTokenSold;
    uint256 public totalTokenSoldByCard;
    uint256 public totalTokenCap;

    // Flag indicating whether the ICO is currently active
    bool public isActive;

    // Mapping to track all deposits made by each user address
    // Each address maps to an array of Purchase structs containing deposit details
    mapping(address => Purchase[]) public userDeposits;

    // Mapping to define custom start times for different sale stages
    // The uint8 key represents the stage index (e.g., 0 for Stage 1, etc.),
    // and the uint256 value is the start timestamp for that stage
    mapping(uint8 => uint256) public customStageStartTimes;

    // Struct to store individual purchase details
    struct Purchase {
        uint256 amount;        // Amount paid by user in ETH (in wei) or USDT (based on selected currency)
        string currency;     // Currency used for the purchase: ETH or USDT
        uint256 tokenAmount;   // Amount of tokens received in exchange
        uint256 timeStamp;     // Timestamp when the purchase was made
    }

    // Struct to store commission-related data
    struct commissionData {
        uint256 purchaseCount;    // storing how many times user buy from influencer
        uint256 totalSellInUSD;   // total usd amount
        uint256 commissionUSD;    // Commission amount in USD
        uint256 totalTokenSale;   // Total tokens sold by the referred user or affiliate
    }

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

    ///  Emitted when tokens are manually distributed via card payment.
    event TokensBoughtWithCard(address indexed user, uint256 tokenAmount);

    ///  Emitted when native ETH is withdrawn from the contract.
    event NativeWithdraw(address indexed to, uint256 amount);

    ///  Emitted when an ERC20 token is withdrawn from the contract.
    event TokenWithdraw(address indexed token, address indexed to, uint256 amount);

    // Event declaration for whitelist address update (optional, can help with logging the change)
    event WhiteListUpdated(address indexed newWhiteList);
    event ToggleSale();

    modifier notPaused() {
        require(isActive, "Sale is paused.");
        _;
    }

    /// @dev Constructor to initialize ICO parameters.
    /// @param _token Address of the ERC20 token being sold.
    /// @param _usdt Address of the USDT token used for stable payments.
    /// @param _priceFeed Chainlink price feed address for ETH/USD.
    /// @param _adminWallet Address where collected funds are sent.
    /// @param _startTime Timestamp when the ICO should start.
    constructor(
        address _token,
        address _usdt,
        address _priceFeed,
        address _adminWallet,
        uint256 _startTime
    ) Ownable(msg.sender) {
        token = IERC20(_token);
        usdt = IERC20(_usdt);
        priceFeed = AggregatorV3Interface(_priceFeed);
        adminWallet = _adminWallet;
        startTime = _startTime;
        totalTokenCap = 175_000_000 * 10**18;   // 70% of 250M for ETH-ICO
        maxCommissionPercent = 50; // only real number we gonna support.
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

    // @notice Function to toggle sale if needed only by owner
    function toggleSale() external onlyOwner{
        isActive = !isActive;
        emit ToggleSale();
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

    /// @dev Allows users to purchase tokens using ETH. Applies referral bonuses if applicable.
    /// @param referrer The address of the referrer (if any).
    function buyWithNative(address referrer) external payable notPaused nonReentrant {
        require(msg.value > 0, "Must send ETH to buy tokens");
        uint256 adminAmount = msg.value;
        uint256 tokenAmount = getTokenFromNative(adminAmount);
        require(token.balanceOf(address(this)) >= tokenAmount,"Not enough tokens in contract");
        _checkSupply(tokenAmount);
        if(isReferral[referrer]) {
            uint256 commissionAmount = (msg.value * commissions[referrer]) / 100;
            adminAmount = msg.value - commissionAmount;
            uint256 usdAmount = getUSDValue(commissionAmount);
            uint256 totalUsdAmount = getUSDValue(msg.value);
            commissionCollect[referrer].purchaseCount += 1;
            commissionCollect[referrer].totalSellInUSD += totalUsdAmount;
            commissionCollect[referrer].commissionUSD += usdAmount;
            commissionCollect[referrer].totalTokenSale += tokenAmount;
            Address.sendValue(payable(referrer), commissionAmount);
        }
        userDeposits[msg.sender].push(Purchase({amount: msg.value ,currency: "ETH" ,tokenAmount: tokenAmount,timeStamp: block.timestamp}));
        ethRaised += msg.value;
        totalTokenSold += tokenAmount;
        Address.sendValue(payable(adminWallet), adminAmount);
        token.safeTransfer(msg.sender, tokenAmount);
        emit TokensPurchasedWithNative(msg.sender, msg.value, tokenAmount);
    }

    /// @dev Allows users to purchase tokens using USDT. Applies referral bonuses if applicable.
    /// @param usdtAmount The amount of USDT to spend (in smallest unit, e.g., 6 decimals for USDT).
    /// @param referrer The address of the referrer (if any).
    function buyWithUSDT(uint256 usdtAmount, address referrer) external notPaused nonReentrant {
        require(usdtAmount > 0, "Must send USDT to buy tokens");
        require(usdt.allowance(msg.sender, address(this)) >= usdtAmount,"Insufficient allowance");
        uint256 tokenAmount =  getTokenFromUsdt(usdtAmount);
        require(token.balanceOf(address(this)) >= tokenAmount,"Not enough tokens in contract");
        _checkSupply(tokenAmount);
        uint256 adminAmount = usdtAmount;
        if(isReferral[referrer]) {
            uint256 commissionAmount = (usdtAmount * commissions[referrer]) / 100;
            adminAmount = usdtAmount - commissionAmount;
            commissionCollect[referrer].purchaseCount += 1;
            commissionCollect[referrer].totalSellInUSD += usdtAmount;
            commissionCollect[referrer].commissionUSD += commissionAmount;
            commissionCollect[referrer].totalTokenSale += tokenAmount;
            usdt.safeTransferFrom(msg.sender, referrer, commissionAmount);
        }
        userDeposits[msg.sender].push(Purchase({amount: usdtAmount,currency: "USDT",tokenAmount: tokenAmount,timeStamp: block.timestamp}));
        usdtRaised += usdtAmount ;
        totalTokenSold += tokenAmount;
        usdt.safeTransferFrom(msg.sender, adminWallet, adminAmount);
        token.safeTransfer(msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, usdtAmount, tokenAmount);
    }

    // Function to calculate the token amount based on ETH amount
    function getTokenFromNative(uint256 _ethAmount) public view returns(uint256 ){
        (, uint256 priceETH, , ) = getCurrentStageAndPrice();
        uint256 tokenAmount = (_ethAmount * 1e18) / priceETH;
        uint256 usdtAmount = getUSDValue(_ethAmount);
        if (usdtAmount >= USD_5000) {
            tokenAmount += applyBonuses(tokenAmount, usdtAmount);
        }
        return tokenAmount ;
    }

    // Function to calculate the token amount based on USDT amount
    function getTokenFromUsdt(uint256 _usdtAmount) public view returns(uint256 ){
        (, , uint256 priceUSD, ) = getCurrentStageAndPrice();
        uint256 tokenAmount = (_usdtAmount * 1e18) / priceUSD;
        if (_usdtAmount >= USD_5000) {
            tokenAmount += applyBonuses(tokenAmount, _usdtAmount);
        }
      return tokenAmount;
    }

    /// @dev Applies bonus tokens based on the USD value of the purchase.
    /// @param baseAmount The initial amount of tokens before bonus.
    /// @param usdAmount The equivalent USD amount of the purchase.
    /// @return The total bonus amount to be added.
    function applyBonuses(uint256 baseAmount, uint256 usdAmount)
        public 
        pure
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

    /// @dev Calculates and returns the current stage, token price in ETH and USD, and the stage start time.
    /// @return stage The current ICO stage number (1-based index).
    /// @return priceETH The token price in ETH (wei).
    /// @return priceUSD The token price in USD (with 8 decimals).
    /// @return stageStartTime The timestamp when the current stage started.
    function getCurrentStageAndPrice()
        public
        view
        returns (
            uint8 stage,
            uint256 priceETH,
            uint256 priceUSD,
            uint256 stageStartTime
        )
    {
    uint256 ethPrice = getLatestPrice();
    require(ethPrice > 0, "ETH price is zero");

    if (useFixedPrice) {
        uint256 fixedStagePriceInETH = (fixedPriceUSD * MULTIPLIER) / ethPrice;
        return (0, fixedStagePriceInETH, fixedPriceUSD, startTime);
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
        uint256 initialPrice = (INITIAL_PRICE_USD * MULTIPLIER) / ethPrice;
        return (0, initialPrice, INITIAL_PRICE_USD, actualStartTimes[0]);
    }
    // Step 3: Cap to final stage
    if (currentStage >= TOTAL_STAGES) {
        uint256 finalStagePriceInETH = (FINAL_PRICE_USD * MULTIPLIER) / ethPrice;
        return (
            uint8(TOTAL_STAGES),
            finalStagePriceInETH,
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
    uint256 stagePriceInETH = (priceUSDT * MULTIPLIER) / ethPrice;
    return (
        currentStage,
        stagePriceInETH,
        priceUSDT,
        actualStartTimes[currentStage - 1]
        );
    }

    /**
    * @notice Sets whether to use a fixed price in USD and defines the fixed price value.
    * @dev Can only be called by the contract owner.
    * @param _useFixedPrice Boolean flag to enable or disable the use of a fixed USD price.
    * @param _priceUSD The fixed price value in USD to be used if _useFixedPrice is true.
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
    /// @return pricesETH An array of token prices in ETH (in wei) for each stage.
    /// @return pricesUSD An array of token prices in USD (with 8 decimals) for each stage.
    /// @return startTimes An array of start timestamps for each stage.
    function getAllStagesAndPrices()
        external
        view
        returns (
            uint8[] memory stagesList,
            uint256[] memory pricesETH,
            uint256[] memory pricesUSD,
            uint256[] memory startTimes
        )
    {
        uint8[] memory _stagesList = new uint8[](TOTAL_STAGES);
        uint256[] memory _pricesETH = new uint256[](TOTAL_STAGES);
        uint256[] memory _pricesUSD = new uint256[](TOTAL_STAGES);
        uint256[] memory _startTimes = new uint256[](TOTAL_STAGES);

        uint256 ethPrice = getLatestPrice();
        require(ethPrice > 0, "ETH price is zero");

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
        _pricesETH[i] = (priceUSD * MULTIPLIER) / ethPrice;

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
        return (_stagesList, _pricesETH, _pricesUSD, _startTimes);
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
        return (getUSDValue(ethRaised) + usdtRaised);
    }

    /// @dev Converts an ETH amount to its equivalent USD value using the current price feed.
    /// @param ethAmount The amount of ETH (in wei) to convert.
    /// @return The equivalent USD value (with 8 decimals).
    function getUSDValue(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getLatestPrice(); // Assumes price is in USD with 8 decimals
        return (ethAmount * ethPrice) / MULTIPLIER;
    }

    /// @dev Converts a USD amount to its equivalent ETH value using the current price feed.
    /// @param usdAmount The amount of USD (with 8 decimals) to convert.
    /// @return The equivalent ETH amount (in wei).
    function getEthValue(uint256 usdAmount) external view returns (uint256) {
        uint256 ethPrice = getLatestPrice(); // ETH price in USD with 8 decimals
        return (usdAmount * MULTIPLIER) / ethPrice; // Convert to wei (1 ETH = 1e18 wei)
    }

    /// @dev Retrieves the latest ETH/USD price from the Chainlink price feed.
    /// @return The ETH price in USD (with 8 decimals).
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price); // Price returned with 8 decimals
    }

    /**
     * @dev Allows the owner to whitelist a specific address.
     * @param _whiteList The address to be added to the whitelist.
     * Only the owner can call this function.
     * Emits a WhiteListUpdated event when the whitelist address is changed.
     */
    function whitelistAddress(address _whiteList) external onlyOwner {
        whiteList[_whiteList] = true;
        emit WhiteListUpdated(_whiteList);
    }

    /**
     * @dev Retrieves the transaction data (e.g., purchases) for a specific user.
     * @param user The address of the user whose transaction data is being queried.
     * @return An array of Purchase structs representing the user's transactions.
     * This function is public and view-only, so it can be called without any gas cost.
     */
    function getUserTxData(address user) external view returns (Purchase[] memory) {
        return userDeposits[user];
    }

    /// @dev Allows the owner to distribute tokens manually (e.g., for card payments).
    /// @param _user The address to receive the tokens.
    /// @param _tokenAmount The amount of tokens to send.
    function buyWithCard(address _user, uint256 _tokenAmount) external notPaused nonReentrant {
        require(whiteList[msg.sender], "only whitelist Address can call");
        require(_tokenAmount > 0, "Amount must be greater than zero");
        require(token.balanceOf(address(this)) >= _tokenAmount,"Not enough tokens in contract");
        _checkSupply(_tokenAmount);
        totalTokenSoldByCard +=_tokenAmount;
        token.safeTransfer(_user, _tokenAmount);
        emit TokensBoughtWithCard(_user, _tokenAmount);
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
    function withdrawToken(address _token, uint256 amount) external nonReentrant onlyOwner {
        IERC20 tokenContract = IERC20(_token);
        require(tokenContract.balanceOf(address(this)) >= amount, "Insufficient token balance");
        tokenContract.safeTransfer(adminWallet, amount);
        emit TokenWithdraw(_token, adminWallet, amount);
    }
    
    function _checkSupply(uint256 _tokenAmount) internal view {
        require(totalTokenSold + totalTokenSoldByCard + _tokenAmount <= totalTokenCap,"ICO token cap reached");
    }

    receive() external payable {}
}