// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WasteManagement {
    struct Location {
        int256 latitude;
        int256 longitude;
    }

    struct Household {
        Location location;
        bool isRegistered;
    }

    struct WasteCollector {
        Location location;
        bool isRegistered;
    }

    struct RecyclingFacility {
        Location location;
        bool isRegistered;
    }

    struct CollectionRoute {
        address[] waypoints;
        address wasteCollector;
        address recyclingFacility;
        uint256 distance;
    }

    mapping(address => Household) public households;
    mapping(address => WasteCollector) public wasteCollectors;
    mapping(address => RecyclingFacility) public recyclingFacilities;
    mapping(address => uint256) public scheduledCollectionTimes;
    mapping(address => CollectionRoute) public collectionRoutes;

    address[] public registeredHouseholdAddresses; // New array to store registered household addresses
    address[] public registeredRecyclingFacilityAddresses; // New array to store registered recycling facility addresses

    uint256 public totalWasteCollected;
    uint256 public totalDistanceCovered;

    // Event to notify when waste is ready for collection
    event WasteReadyForCollection(address indexed household, address indexed wasteCollector);

    // Event to notify when a collection is confirmed
    event CollectionConfirmed(address indexed household, address indexed wasteCollector);

    // Function to register households with their geolocation data
    function registerHousehold(int256 _latitude, int256 _longitude) public {
        require(!households[msg.sender].isRegistered, "Household already registered");
        households[msg.sender] = Household({
            location: Location(_latitude, _longitude),
            isRegistered: true
        });
        registeredHouseholdAddresses.push(msg.sender); // Add the registered household address to the array
    }

    // Function to register waste collectors with their geolocation data
    function registerWasteCollector(int256 _latitude, int256 _longitude) public {
        require(!wasteCollectors[msg.sender].isRegistered, "Waste collector already registered");
        wasteCollectors[msg.sender] = WasteCollector({
            location: Location(_latitude, _longitude),
            isRegistered: true
        });
    }

    // Function to register recycling facilities with their geolocation data
    function registerRecyclingFacility(int256 _latitude, int256 _longitude) public {
        require(!recyclingFacilities[msg.sender].isRegistered, "Recycling facility already registered");
        recyclingFacilities[msg.sender] = RecyclingFacility({
            location: Location(_latitude, _longitude),
            isRegistered: true
        });
        registeredRecyclingFacilityAddresses.push(msg.sender); // Add the registered facility address to the array
    }

    // Function to calculate the distance between two locations
    function calculateDistance(Location memory loc1, Location memory loc2) internal pure returns (uint256) {
        int256 latDiff = loc1.latitude - loc2.latitude;
        int256 lonDiff = loc1.longitude - loc2.longitude;
        return uint256(latDiff * latDiff + lonDiff * lonDiff);
    }

    // Function to get the list of registered household addresses
    function getRegisteredHouseholdAddresses() public view returns (address[] memory) {
        return registeredHouseholdAddresses;
    }

    // Function to get the list of registered recycling facility addresses
    function getRegisteredRecyclingFacilityAddresses() public view returns (address[] memory) {
        return registeredRecyclingFacilityAddresses;
    }

    // Function to find the nearest recycling facility to a given location
    function findNearestRecyclingFacility(Location memory loc) public view returns (address) {
        uint256 minDistance = type(uint256).max;
        address nearestFacility;

        address[] memory registeredFacilities = getRegisteredRecyclingFacilityAddresses();
        for (uint256 i = 0; i < registeredFacilities.length; i++) {
            RecyclingFacility memory facility = recyclingFacilities[registeredFacilities[i]];
            uint256 distance = calculateDistance(loc, facility.location);
            if (distance < minDistance) {
                minDistance = distance;
                nearestFacility = registeredFacilities[i];
            }
        }

        return nearestFacility;
    }

    // Function to optimize a waste collector's collection route
    function optimizeRoute(address _wasteCollector) public {
        require(wasteCollectors[_wasteCollector].isRegistered, "Waste collector not registered");
        require(msg.sender == _wasteCollector, "You can only optimize your own route");

        // Get the waste collector's location
        Location memory collectorLocation = wasteCollectors[_wasteCollector].location;

        // Get a list of registered households and their locations
        address[] memory registeredHouseholds = getRegisteredHouseholdAddresses();
        Location[] memory householdLocations = new Location[](registeredHouseholds.length);

        for (uint256 i = 0; i < registeredHouseholds.length; i++) {
            householdLocations[i] = households[registeredHouseholds[i]].location;
        }

        // Find the optimal route using a simple greedy algorithm (nearest neighbor)
        CollectionRoute memory optimizedRoute;
        optimizedRoute.waypoints = new address[](registeredHouseholds.length);
        optimizedRoute.waypoints[0] = _wasteCollector; // Start at the waste collector's location
        uint256 routeDistance = 0;

        for (uint256 i = 0; i < registeredHouseholds.length; i++) {
            uint256 minDistance = type(uint256).max;
            uint256 nearestIdx;

            for (uint256 j = 0; j < registeredHouseholds.length; j++) {
                if (optimizedRoute.waypoints[j] == address(0)) {
                    uint256 distance = calculateDistance(collectorLocation, householdLocations[j]);
                    if (distance < minDistance) {
                        minDistance = distance;
                        nearestIdx = j;
                    }
                }
            }

            optimizedRoute.waypoints[i + 1] = registeredHouseholds[nearestIdx];
            collectorLocation = householdLocations[nearestIdx];
            routeDistance += minDistance;
        }

        // Create a temporary array to hold the final waypoints (including the recycling facility)
        address[] memory finalWaypoints = new address[](registeredHouseholds.length + 1);
        for (uint256 i = 0; i < registeredHouseholds.length; i++) {
            finalWaypoints[i] = optimizedRoute.waypoints[i];
        }
        finalWaypoints[registeredHouseholds.length] = msg.sender; // Add the recycling facility

        // Update the waste collector's collection route with the optimized one
        optimizedRoute.waypoints = finalWaypoints;
        optimizedRoute.wasteCollector = _wasteCollector;
        optimizedRoute.recyclingFacility = msg.sender;
        optimizedRoute.distance = routeDistance;
        collectionRoutes[_wasteCollector] = optimizedRoute;
    }

    // Function to track the real-time location of a waste collector
    function trackWasteCollector(address _wasteCollector) public view returns (Location memory) {
        require(wasteCollectors[_wasteCollector].isRegistered, "Waste collector not registered");
        return wasteCollectors[_wasteCollector].location;
    }

    // Function to schedule waste collection at specific times
    function scheduleCollection(uint256 timestamp) public {
        require(households[msg.sender].isRegistered, "Household not registered");
        scheduledCollectionTimes[msg.sender] = timestamp;
    }

    // Function for households to notify the waste collector when they have waste ready for collection
    function notifyWasteCollector() public {
        require(households[msg.sender].isRegistered, "Household not registered");
        emit WasteReadyForCollection(msg.sender, msg.sender);
    }

    // Function for waste collectors to confirm the successful collection from a household
    function confirmCollection(address _household) public {
        require(wasteCollectors[msg.sender].isRegistered, "Waste collector not registered");
        require(households[_household].isRegistered, "Household not registered");

        // Perform necessary actions to confirm the collection, e.g., updating waste tracking status, making payments, etc.
        emit CollectionConfirmed(_household, msg.sender);
    }

    // Function to track the entire collection route of a waste collector, including the order of households visited
    function trackCollectionRoute(address _wasteCollector) public view returns (address[] memory) {
        require(wasteCollectors[_wasteCollector].isRegistered, "Waste collector not registered");
        return collectionRoutes[_wasteCollector].waypoints;
    }
}
