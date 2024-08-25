// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Distributors {
    ////////////
    // ERRORS //
    ////////////
    error Distributors__BadPayload();
    error Distributors__DoesNotExist();
    error Distributors__NotAuthorized();
    error Distributors__PostDoesNotExist();
    error Distributors__OptionDoesNotExist();

    ////////////
    // STRUCT //
    ////////////
    struct Option {
        string id;
        string imageUrl;
        string affiliated_post; // Post id
    }

    struct Post {
        string id;
        Option[3] options;
        uint64[3] votes;
        string description;
        string affiliated_distributor; // Distributor id
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

        // Emit an event
    }

    function updateFrequency(
        uint256 frequency,
        address distributor_address
    ) public Authorized(msg.sender, distributor_address) {
        Distributor memory distributor = s_Distributors[distributor_address];
        distributor.frequency = frequency;

        // Emit an event
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

        // Emit an event
    }

    // ===================================================================================================================================================
    function updateDescription(
        string memory desc,
        address distributor_address,
        string memory post_id
    ) public Authorized(msg.sender, distributor_address) {
        Distributor memory distributor = s_Distributors[distributor_address];
        Post[] memory allPosts = distributor.posts;
        Post memory req_post;

        for (uint i = 0; i < allPosts.length; i++) {
            if (
                keccak256(abi.encodePacked(post_id)) ==
                keccak256(abi.encodePacked(allPosts[i].id))
            ) {
                req_post = allPosts[i];
            }
        }

        if (isEmpty(req_post.description)) {
            revert Distributors__PostDoesNotExist();
        }

        req_post.description = desc;
        // Emit an event
    }

    function updateOptions(
        Option[] memory options,
        address distributor_address,
        string memory post_id
    ) public Authorized(msg.sender, distributor_address) {
        Distributor memory distributor = s_Distributors[distributor_address];
        Post[] memory allPosts = distributor.posts;
        Post memory req_post;

        if (options.length == 0) {
            revert Distributors__BadPayload();
        }

        for (uint i = 0; i < allPosts.length; i++) {
            if (
                keccak256(abi.encodePacked(post_id)) ==
                keccak256(abi.encodePacked(allPosts[i].id))
            ) {
                req_post = allPosts[i];
            }
        }

        if (isEmpty(req_post.description)) {
            revert Distributors__PostDoesNotExist();
        }

        for (uint i = 0; i < options.length; i++) {
            req_post.options[i] = options[i];
        }

        // ToDo: Emit Event
    }

    function updateVotes(
        uint64[] memory votes,
        address distributor_address,
        string memory post_id
    ) public Authorized(msg.sender, distributor_address) {
        Distributor memory distributor = s_Distributors[distributor_address];
        Post[] memory allPosts = distributor.posts;
        Post memory req_post;

        if (votes.length != 3) {
            revert Distributors__BadPayload();
        }

        for (uint i = 0; i < allPosts.length; i++) {
            if (
                keccak256(abi.encodePacked(post_id)) ==
                keccak256(abi.encodePacked(allPosts[i].id))
            ) {
                req_post = allPosts[i];
            }
        }

        if (isEmpty(req_post.description)) {
            revert Distributors__PostDoesNotExist();
        }

        for (uint i = 0; i < votes.length; i++) {
            req_post.votes[i] = votes[i];
        }

        // ToDo: Emit Event
    }

    // ===================================================================================================================================================

    function updateImageUrl(
        string memory url,
        address distributor_address,
        string memory post_id,
        string memory option_id
    ) public Authorized(msg.sender, distributor_address) {
        Post memory post = getParticularPost(distributor_address, post_id);
        Option memory option;

        for (uint i = 0; i < 3; i++) {
            if (
                keccak256(abi.encodePacked(option_id)) ==
                keccak256(abi.encodePacked(post.options[i].id))
            ) {
                option = post.options[i];
            }
        }

        if (isEmpty(option.id)) {
            revert Distributors__OptionDoesNotExist();
        }

        option.imageUrl = url;

        // ToDo: Emit Event
    }

    //////////////////////
    // METHODS - Getter //
    //////////////////////

    function getBudget(address distributor) public view returns (uint256) {
        return s_Distributors[distributor].budget;
    }

    function getFrequency(address distributor) public view returns (uint256) {
        return s_Distributors[distributor].frequency;
    }

    function getAllPosts(
        address distributor
    ) public view returns (Post[] memory) {
        return s_Distributors[distributor].posts;
    }

    function ownerOfDistributor(
        address distributor
    ) public view returns (address) {
        return s_Distributors[distributor].id;
    }

    // ===================================================================================================================================================

    function getParticularPost(
        address distributor,
        string memory post_id
    ) public view returns (Post memory) {
        Post[] memory posts = getAllPosts(distributor);
        Post memory req_post;

        for (uint i = 0; i < posts.length; i++) {
            if (
                keccak256(abi.encodePacked(post_id)) ==
                keccak256(abi.encodePacked(posts[i].id))
            ) {
                req_post = posts[i];
            }
        }

        return req_post;
    }

    function getAllOptions(
        address distributor,
        string memory post_id
    ) public view returns (Option[3] memory) {
        Post memory req_post = getParticularPost(distributor, post_id);

        return req_post.options;
    }

    function getAllVotes(
        address distributor,
        string memory post_id
    ) public view returns (uint64[3] memory) {
        Post memory req_post = getParticularPost(distributor, post_id);
        return req_post.votes;
    }

    // ===================================================================================================================================================

    function getParticularOption(
        address distributor,
        string memory post_id,
        string memory option_id
    ) public view returns (Option memory) {
        Option[3] memory allOptions = getAllOptions(distributor, post_id);
        Option memory option;

        for (uint i = 0; i < 3; i++) {
            if (
                keccak256(abi.encodePacked(option_id)) ==
                keccak256(abi.encodePacked(allOptions[i].id))
            ) {
                option = allOptions[i];
            }
        }

        return option;
    }

    /////////////
    // METHODS - Pure //
    /////////////
    function isEmpty(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }
}
