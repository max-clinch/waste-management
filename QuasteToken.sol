// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract QuasteToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public admin;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public recyclingRewards;
    mapping(address => uint256) public exchangeRate;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event RecyclingReward(address indexed user, uint256 value);
    event ExchangeReward(address indexed user, uint256 rewardAmount, address indexed exchangeToken);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * (10**uint256(_decimals));
        balanceOf[msg.sender] = totalSupply;
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Invalid address");
        require(_value <= balanceOf[msg.sender], "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0), "Invalid address");

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        require(_from != address(0), "Invalid address");
        require(_to != address(0), "Invalid address");
        require(_value <= balanceOf[_from], "Insufficient balance");
        require(_value <= allowance[_from][msg.sender], "Allowance exceeded");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function increaseSupply(uint256 _amount) external onlyAdmin {
        totalSupply += _amount * (10**uint256(decimals));
        balanceOf[address(this)] += _amount * (10**uint256(decimals));
        emit Transfer(address(0), address(this), _amount * (10**uint256(decimals)));
    }

    function setExchangeRate(address _exchangeToken, uint256 _rate) external onlyAdmin {
        require(_exchangeToken != address(0), "Invalid exchange token address");
        exchangeRate[_exchangeToken] = _rate;
    }

    function claimRecyclingReward(uint256 _rewardAmount) external {
        require(_rewardAmount > 0, "Reward amount must be greater than zero");
        require(_rewardAmount <= balanceOf[address(this)], "Not enough tokens in the contract");

        balanceOf[msg.sender] += _rewardAmount;
        recyclingRewards[msg.sender] += _rewardAmount;
        balanceOf[address(this)] -= _rewardAmount;

        emit Transfer(address(this), msg.sender, _rewardAmount);
        emit RecyclingReward(msg.sender, _rewardAmount);
    }

    function getRecyclingRewards(address _user) external view returns (uint256) {
        return recyclingRewards[_user];
    }

    function exchangeRewardsForToken(address _exchangeToken) external {
        require(exchangeRate[_exchangeToken] > 0, "Exchange rate not set for this token");
        uint256 rewardAmount = recyclingRewards[msg.sender];
        require(rewardAmount > 0, "No recycling rewards to exchange");

        uint256 exchangeAmount = rewardAmount * exchangeRate[_exchangeToken];
        require(exchangeAmount <= balanceOf[address(this)], "Not enough tokens in the contract");

        recyclingRewards[msg.sender] = 0;
        balanceOf[msg.sender] += exchangeAmount;
        balanceOf[address(this)] -= exchangeAmount;

        emit ExchangeReward(msg.sender, exchangeAmount, _exchangeToken);
        emit Transfer(address(this), msg.sender, exchangeAmount);
    }
}
