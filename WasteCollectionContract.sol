// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WasteCollectionContract {
    address private owner;

    // Define a struct to store the details of a waste collection request
    struct CollectionRequest {
        address requester;
        string addressDetails;
        uint256 collectionDate;
        string typeOfWaste;
        bool isCompleted;
        address assignedCollector;
        RequestStatus status;
        string feedback;
    }

    // Enum to represent the status of a request
    enum RequestStatus { Pending, InProgress, Completed, Canceled }

    // Array to store all waste collection requests
    CollectionRequest[] private collectionRequests;

    // Mapping to store the index of a request given its ID (could be a unique identifier)
    mapping(uint256 => uint256) private requestIdToIndex;

    // Modifier to check if the caller is the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    // Modifier to check if the caller is the assigned collector of a request
    modifier onlyAssignedCollector(uint256 requestId) {
        require(
            collectionRequests[requestId].assignedCollector == msg.sender,
            "You are not the assigned collector for this request."
        );
        _;
    }

    // Modifier to check if the request is not already completed or canceled
    modifier requestNotCompletedOrCanceled(uint256 requestId) {
        require(
            collectionRequests[requestId].status != RequestStatus.Completed &&
            collectionRequests[requestId].status != RequestStatus.Canceled,
            "This request is already completed or canceled."
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Event to emit when a new request is created
    event CollectionRequestCreated(uint256 requestId, address requester);

    // Event to emit when a request status is updated
    event CollectionRequestStatusUpdated(uint256 requestId, RequestStatus status);

    // Function to create a waste collection request
    function createCollectionRequest(
        string memory _addressDetails,
        uint256 _collectionDate,
        string memory _typeOfWaste
    ) public {
        // Perform any required validation (e.g., check service area, valid date, etc.)

        // Create a new request and add it to the collectionRequests array
        CollectionRequest memory newRequest = CollectionRequest({
            requester: msg.sender,
            addressDetails: _addressDetails,
            collectionDate: _collectionDate,
            typeOfWaste: _typeOfWaste,
            isCompleted: false,
            assignedCollector: address(0),
            status: RequestStatus.Pending,
            feedback: ""
        });

        uint256 requestId = collectionRequests.length;
        collectionRequests.push(newRequest);
        requestIdToIndex[requestId] = requestId;

        // Emit an event to notify external systems about the new request
        emit CollectionRequestCreated(requestId, msg.sender);
    }

    // Function to assign a collector to a request (can only be called by the contract owner)
    function assignCollector(uint256 requestId, address collector)
        public
        onlyOwner
        requestNotCompletedOrCanceled(requestId)
    {
        require(collector != address(0), "Invalid collector address.");
        require(
            collectionRequests[requestId].assignedCollector == address(0),
            "Collector is already assigned to this request."
        );

        collectionRequests[requestId].assignedCollector = collector;
        collectionRequests[requestId].status = RequestStatus.InProgress;

        // Emit an event to notify external systems about the assignment
        emit CollectionRequestStatusUpdated(requestId, RequestStatus.InProgress);
    }

    // Function for the assigned collector to confirm the completion of a request
    function confirmCompletion(uint256 requestId)
        public
        onlyAssignedCollector(requestId)
        requestNotCompletedOrCanceled(requestId)
    {
        collectionRequests[requestId].isCompleted = true;
        collectionRequests[requestId].status = RequestStatus.Completed;

        // Emit an event to notify external systems about the completion
        emit CollectionRequestStatusUpdated(requestId, RequestStatus.Completed);
    }

    // Function for the requester to cancel a request before it's completed
    function cancelRequest(uint256 requestId)
        public
        requestNotCompletedOrCanceled(requestId)
    {
        require(
            collectionRequests[requestId].requester == msg.sender,
            "You are not the requester of this request."
        );

        collectionRequests[requestId].status = RequestStatus.Canceled;

        // Emit an event to notify external systems about the cancellation
        emit CollectionRequestStatusUpdated(requestId, RequestStatus.Canceled);
    }

    // Function for the requester to leave feedback for a completed request
    function leaveFeedback(uint256 requestId, string memory feedback)
        public
        requestNotCompletedOrCanceled(requestId)
    {
        require(
            collectionRequests[requestId].requester == msg.sender,
            "You are not the requester of this request."
        );

        collectionRequests[requestId].feedback = feedback;
    }

    // Function to retrieve the details of a request
    function getRequestDetails(uint256 requestId)
        public
        view
        returns (
            address requester,
            string memory addressDetails,
            uint256 collectionDate,
            string memory typeOfWaste,
            bool isCompleted,
            address assignedCollector,
            RequestStatus status,
            string memory feedback
        )
    {
        require(requestId < collectionRequests.length, "Invalid request ID.");

        CollectionRequest storage request = collectionRequests[requestId];

        return (
            request.requester,
            request.addressDetails,
            request.collectionDate,
            request.typeOfWaste,
            request.isCompleted,
            request.assignedCollector,
            request.status,
            request.feedback
        );
    }

    // Function to get the total number of requests
    function getNumberOfRequests() public view returns (uint256) {
        return collectionRequests.length;
    }
}
