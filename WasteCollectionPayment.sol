// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the OpenZeppelin library for safe math operations and access control
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 


contract WasteCollectionPayment is Ownable {
    using SafeMath for uint256;

    // Define the token used for payments and rewards
    IERC20 public paymentToken;

    // Mapping to store household balances
    mapping(address => uint256) private balances;

    // Event to notify when a payment is made
    event PaymentMade(address indexed household, uint256 amount);

    // Modifier to ensure that only the owner (administrator) can call certain functions
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || isAdmin(msg.sender), "Not authorized");
        _;
    }

    // Set of administrators who can assist in managing the contract (e.g., adding incentives)
    mapping(address => bool) public administrators;

    // Modifier to ensure that only administrators can call certain functions
    modifier onlyAdministrator() {
        require(administrators[msg.sender], "Not authorized");
        _;
    }

    constructor(address _paymentToken) {
        paymentToken = IERC20(_paymentToken);
        // Assign the contract deployer as an administrator
        administrators[msg.sender] = true;
    }

    // Function to add or remove administrators
    function setAdministrator(address _admin, bool _status) external onlyOwner {
        administrators[_admin] = _status;
    }

    // Function to check if an address is an administrator
    function isAdmin(address _address) public view returns (bool) {
        return administrators[_address];
    }

    // Function to allow households to make a payment for waste collection services
    function makePayment(uint256 _amount) external {
        require(_amount > 0, "Payment amount must be greater than zero");
        require(
            paymentToken.balanceOf(msg.sender) >= _amount,
            "Insufficient balance"
        );

        // Transfer the tokens to this contract
        paymentToken.transferFrom(msg.sender, address(this), _amount);

        // Add the payment amount to the household's balance
        balances[msg.sender] = balances[msg.sender].add(_amount);

        emit PaymentMade(msg.sender, _amount);
    }

    // Function to withdraw accumulated rewards
    function withdrawRewards() external {
        uint256 rewardAmount = balances[msg.sender];
        require(rewardAmount > 0, "No rewards to withdraw");

        // Transfer the rewards to the household
        paymentToken.transfer(msg.sender, rewardAmount);

        // Reset the household's balance to zero
        balances[msg.sender] = 0;
    }

    // Function to check the current balance (payments and rewards) of a household
    function getBalance(address _household) external view returns (uint256) {
        return balances[_household];
    }

    // Function to update the payment token (in case of migration to a new token)
    function updatePaymentToken(address _newPaymentToken) external onlyOwner {
        paymentToken = IERC20(_newPaymentToken);
    }
}
