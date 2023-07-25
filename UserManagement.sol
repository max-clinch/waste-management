// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserManagement {
    struct User {
        string username;
        bytes32 passwordHash;
        bool registered;
        bool isActive;
    }

    mapping(address => User) private users;
    mapping(string => address) private usernameToAddress;

    event UserRegistered(address indexed userAddress, string username);
    event UserLoggedIn(address indexed userAddress);
    event PasswordChanged(address indexed userAddress);
    event AccountDeactivated(address indexed userAddress);
    event AccountActivated(address indexed userAddress);

    modifier onlyRegisteredUser() {
        require(users[msg.sender].registered == true, "User not registered");
        _;
    }

    modifier onlyActiveUser() {
        require(users[msg.sender].isActive == true, "Account deactivated");
        _;
    }

    // Hash a password using SHA-256
    function hashPassword(string memory password) internal pure returns (bytes32) {
        return sha256(bytes(password));
    }

    function registerUser(string memory username, string memory password) external {
        require(users[msg.sender].registered == false, "User already registered");
        require(usernameToAddress[username] == address(0), "Username already taken");

        bytes32 passwordHash = hashPassword(password);

        users[msg.sender] = User(username, passwordHash, true, true);
        usernameToAddress[username] = msg.sender;

        emit UserRegistered(msg.sender, username);
    }

    function loginUser(string memory password) external onlyRegisteredUser {
        bytes32 passwordHash = hashPassword(password);

        require(users[msg.sender].passwordHash == passwordHash, "Invalid credentials");

        emit UserLoggedIn(msg.sender);
    }

    function changePassword(string memory newPassword) external onlyActiveUser {
        bytes32 newPasswordHash = hashPassword(newPassword);
        users[msg.sender].passwordHash = newPasswordHash;

        emit PasswordChanged(msg.sender);
    }

    function deactivateAccount() external onlyActiveUser {
        users[msg.sender].isActive = false;

        emit AccountDeactivated(msg.sender);
    }

    function activateAccount() external onlyRegisteredUser {
        users[msg.sender].isActive = true;

        emit AccountActivated(msg.sender);
    }

    function isUserRegistered(address userAddress) external view returns (bool) {
        return users[userAddress].registered;
    }

    function isUserActive(address userAddress) external view returns (bool) {
        return users[userAddress].isActive;
    }

    function getUserInfo() external view onlyActiveUser returns (string memory) {
        return users[msg.sender].username;
    }

    function getUsername(address userAddress) external view onlyActiveUser returns (string memory) {
        return users[userAddress].username;
    }

    function isUsernameTaken(string memory username) external view returns (bool) {
        return usernameToAddress[username] != address(0);
    }
}
