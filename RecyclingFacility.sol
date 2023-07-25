// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecyclingFacility {
    struct Facility {
        string name;
        string location;
        string[] recyclableMaterials;
        uint256 maxCapacity;
        uint256 currentCapacity;
        bool isOpen;
    }

    mapping(address => Facility) public facilities;
    address[] public facilityAddresses;

    event FacilityRegistered(address indexed facilityAddress, string name, string location);
    event FacilitySignaled(address indexed facilityAddress, bool isOpen);
    event MaterialDelivered(address indexed facilityAddress, address indexed collectorAddress, uint256 amount);
    event RewardDistributed(address indexed facilityAddress, address indexed recipient, uint256 amount);

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier onlyFacilityOwner(address facilityAddress) {
        require(msg.sender == facilityAddress, "You are not the owner of this facility");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Facility Registration
    function registerFacility(
        string memory _name,
        string memory _location,
        string[] memory _recyclableMaterials,
        uint256 _maxCapacity
    ) external {
        Facility storage newFacility = facilities[msg.sender];
        newFacility.name = _name;
        newFacility.location = _location;
        newFacility.recyclableMaterials = _recyclableMaterials;
        newFacility.maxCapacity = _maxCapacity;
        newFacility.currentCapacity = 0;
        newFacility.isOpen = false;
        facilityAddresses.push(msg.sender);

        emit FacilityRegistered(msg.sender, _name, _location);
    }

    // Facility Signaling
    function signalFacility(bool _isOpen) external onlyFacilityOwner(msg.sender) {
        Facility storage facility = facilities[msg.sender];
        facility.isOpen = _isOpen;

        emit FacilitySignaled(msg.sender, _isOpen);
    }

    // Facility Capacity Management
    function checkCapacity(address _facilityAddress, uint256 _amount) external view returns (bool) {
        Facility storage facility = facilities[_facilityAddress];
        return (facility.currentCapacity + _amount <= facility.maxCapacity);
    }

    // Communication between Collectors and Recyclers
    function requestFacilityInfo(address _facilityAddress) external view returns (string memory, string memory, bool) {
        Facility storage facility = facilities[_facilityAddress];
        return (facility.name, facility.location, facility.isOpen);
    }

    // Material Delivery and Handling
    function deliverMaterials(address _facilityAddress, uint256 _amount) external {
        Facility storage facility = facilities[_facilityAddress];
        require(facility.isOpen, "The facility is currently closed");

        require(facility.currentCapacity + _amount <= facility.maxCapacity, "Delivery exceeds facility capacity");

        facility.currentCapacity += _amount;
        emit MaterialDelivered(_facilityAddress, msg.sender, _amount);
    }

    // Reward Distribution (optional)
    function distributeReward(address _recipient, uint256 _amount) external onlyFacilityOwner(msg.sender) {
        // Implement reward distribution logic here
        emit RewardDistributed(msg.sender, _recipient, _amount);
    }

    // Security Measures - Access Control
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }
}
