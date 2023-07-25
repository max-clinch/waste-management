// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WasteCollectorRating {

    struct Review {
        address reviewer;
        address wasteCollector;
        uint256 rating;
        string reviewText;
        uint256 timestamp;
    }

    mapping(uint256 => Review) public reviews;
    uint256 public totalReviews;

    event ReviewSubmitted(uint256 indexed reviewId, address indexed reviewer, address indexed wasteCollector, uint256 rating, string reviewText);
    event ReviewUpdated(uint256 indexed reviewId, address indexed reviewer, address indexed wasteCollector, uint256 rating, string reviewText);
    event ReviewDeleted(uint256 indexed reviewId, address indexed reviewer, address indexed wasteCollector);

    modifier reviewExists(uint256 reviewId) {
        require(reviewId > 0 && reviewId <= totalReviews, "Review does not exist");
        _;
    }

    modifier onlyReviewOwner(uint256 reviewId) {
        require(msg.sender == reviews[reviewId].reviewer, "You are not the reviewer of this review");
        _;
    }

    function submitReview(address _wasteCollector, uint256 _rating, string memory _reviewText) external {
        require(_wasteCollector != address(0), "Invalid waste collector address");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        totalReviews++;

        reviews[totalReviews] = Review({
            reviewer: msg.sender,
            wasteCollector: _wasteCollector,
            rating: _rating,
            reviewText: _reviewText,
            timestamp: block.timestamp
        });

        emit ReviewSubmitted(totalReviews, msg.sender, _wasteCollector, _rating, _reviewText);
    }

    function updateReview(uint256 reviewId, uint256 _rating, string memory _reviewText) external reviewExists(reviewId) onlyReviewOwner(reviewId) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        reviews[reviewId].rating = _rating;
        reviews[reviewId].reviewText = _reviewText;

        emit ReviewUpdated(reviewId, msg.sender, reviews[reviewId].wasteCollector, _rating, _reviewText);
    }

    function deleteReview(uint256 reviewId) external reviewExists(reviewId) onlyReviewOwner(reviewId) {
        delete reviews[reviewId];
        emit ReviewDeleted(reviewId, msg.sender, reviews[reviewId].wasteCollector);
    }

    function getAverageRating(address _wasteCollector) external view returns (uint256) {
        uint256 totalRating;
        uint256 reviewCount;

        for (uint256 i = 1; i <= totalReviews; i++) {
            if (reviews[i].wasteCollector == _wasteCollector) {
                totalRating += reviews[i].rating;
                reviewCount++;
            }
        }

        if (reviewCount == 0) {
            return 0;
        }

        return totalRating / reviewCount;
    }

    function getReviewsByReviewer(address reviewer) external view returns (Review[] memory) {
        Review[] memory reviewerReviews = new Review[](totalReviews);
        uint256 count = 0;

        for (uint256 i = 1; i <= totalReviews; i++) {
            if (reviews[i].reviewer == reviewer) {
                reviewerReviews[count] = reviews[i];
                count++;
            }
        }

        // Resize the array to remove any empty elements
        assembly {
            mstore(reviewerReviews, count)
        }

        return reviewerReviews;
    }

    function getReviewsForWasteCollector(address _wasteCollector) external view returns (Review[] memory) {
        Review[] memory collectorReviews = new Review[](totalReviews);
        uint256 count = 0;

        for (uint256 i = 1; i <= totalReviews; i++) {
            if (reviews[i].wasteCollector == _wasteCollector) {
                collectorReviews[count] = reviews[i];
                count++;
            }
        }

        // Resize the array to remove any empty elements
        assembly {
            mstore(collectorReviews, count)
        }

        return collectorReviews;
    }

    function getReviewCountByReviewer(address reviewer) external view returns (uint256) {
        uint256 reviewCount;

        for (uint256 i = 1; i <= totalReviews; i++) {
            if (reviews[i].reviewer == reviewer) {
                reviewCount++;
            }
        }

        return reviewCount;
    }

    function getLatestReviewByReviewer(address reviewer) external view returns (Review memory) {
        uint256 latestReviewId;
        uint256 latestTimestamp;

        for (uint256 i = 1; i <= totalReviews; i++) {
            if (reviews[i].reviewer == reviewer && reviews[i].timestamp > latestTimestamp) {
                latestTimestamp = reviews[i].timestamp;
                latestReviewId = i;
            }
        }

        return reviews[latestReviewId];
    }

    function getReviewerByReviewId(uint256 reviewId) external view reviewExists(reviewId) returns (address) {
        return reviews[reviewId].reviewer;
    }
}
