// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Distributors {
    ////////////
    // ERRORS //
    ////////////
    error Distributors__DoesNotExist();
    error Distributors__NotAuthorized();

    ////////////
    // STRUCT //
    ////////////
    struct Options {
        string[3] imageUrls;
    }

    struct Post {
        string id;
        Options[3] options;
        uint64[3] votes;
        string description;
    }

    struct Distributor {
        address id;
        bool listed;
        Post[] posts;
        uint256 budget;
        uint256 frequency;
    }

    modifier Authorized(address sender, address distributor_address) {
        Distributor memory distributor = s_Distributors[distributor_address];
        if (distributor.listed == false) {
            revert Distributors__DoesNotExist();
        }
        if (msg.sender != distributor.id) {
            revert Distributors__NotAuthorized();
        }
        _;
    }

    /////////////////////
    // DATA STRUCTURES //
    /////////////////////
    mapping(address distributor => Distributor) public s_Distributors;

    /////////////
    // METHODS - Setter //
    /////////////
    function updateBudget(
        uint256 budget,
        address distributor_address
    ) public Authorized(msg.sender, distributor_address) {
        Distributor memory distributor = s_Distributors[distributor_address];
        distributor.budget = budget;
    }

    function updateFrequency(
        uint256 frequency,
        address distributor_address
    ) public Authorized(msg.sender, distributor_address) {
        Distributor memory distributor = s_Distributors[distributor_address];
        distributor.frequency = frequency;
    }

    function updatePost(
        Post[] memory posts,
        address distributor_address
    ) public Authorized(msg.sender, distributor_address) {
        Distributor memory distributor = s_Distributors[distributor_address];
        uint8 incomingPosts;
        if (uint8(posts.length) > 3) {
            incomingPosts = 3;
        } else {
            incomingPosts = uint8(posts.length);
        }

        for (uint i = 0; i < incomingPosts; i++) {
            distributor.posts[i] = posts[i];
        }
    }

    // ===================================================================================================================================================

    /////////////
    // METHODS - Getter //
    /////////////

    function getBudget(address distributor) public view returns (uint256) {
        return s_Distributors[distributor].budget;
    }

    function getFrequency(address distributor) public view returns (uint256) {
        return s_Distributors[distributor].frequency;
    }
}
