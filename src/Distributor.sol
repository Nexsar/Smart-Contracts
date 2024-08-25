// SPDX-License-Identifier: MIT
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
    // EVENTS //
    ////////////
    event BudgetUpdated(address indexed distributor, uint256 newBudget);
    event FrequencyUpdated(address indexed distributor, uint256 newFrequency);
    event PostUpdated(address indexed distributor, string postId);
    event DescriptionUpdated(
        address indexed distributor,
        string postId,
        string newDescription
    );
    event OptionsUpdated(address indexed distributor, string postId);
    event VotesUpdated(
        address indexed distributor,
        string postId,
        string optionId,
        uint256 voteCount
    );
    event ImageUrlUpdated(
        address indexed distributor,
        string postId,
        string optionId,
        string newImageUrl
    );

    ////////////
    // STRUCT //
    ////////////
    struct Option {
        string id;
        uint256 vote;
        string imageUrl;
        string affiliated_post; // Post id
    }

    struct Post {
        string id;
        Option[3] options;
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

    ////////////////////////
    // METHODS - Updaters //
    ////////////////////////

    function updateBudget(
        uint256 budget,
        address distributor_address
    ) public Authorized(msg.sender, distributor_address) {
        Distributor storage distributor = s_Distributors[distributor_address];
        distributor.budget = budget;

        emit BudgetUpdated(distributor_address, budget);
    }

    function updateFrequency(
        uint256 frequency,
        address distributor_address
    ) public Authorized(msg.sender, distributor_address) {
        Distributor storage distributor = s_Distributors[distributor_address];
        distributor.frequency = frequency;

        emit FrequencyUpdated(distributor_address, frequency);
    }

    function updatePost(
        Post memory post,
        address distributor_address
    ) public Authorized(msg.sender, distributor_address) {
        Distributor storage distributor = s_Distributors[distributor_address];
        Post storage newPost = distributor.posts.push();
        newPost.id = post.id;
        newPost.description = post.description;
        newPost.affiliated_distributor = post.affiliated_distributor;

        for (uint i = 0; i < 3; i++) {
            newPost.options[i].id = post.options[i].id;
            newPost.options[i].vote = post.options[i].vote;
            newPost.options[i].imageUrl = post.options[i].imageUrl;
            newPost.options[i].affiliated_post = post
                .options[i]
                .affiliated_post;
        }

        emit PostUpdated(distributor_address, post.id);
    }

    // ===================================================================================================================================================

    function updateDescription(
        string memory desc,
        address distributor_address,
        string memory post_id
    ) public Authorized(msg.sender, distributor_address) {
        Post storage req_post = getPostById(distributor_address, post_id);

        if (isEmpty(req_post.description)) {
            revert Distributors__PostDoesNotExist();
        }

        req_post.description = desc;
        emit DescriptionUpdated(distributor_address, post_id, desc); // Added event
    }

    function updateOptions(
        Option[3] memory options,
        address distributor_address,
        string memory post_id
    ) public Authorized(msg.sender, distributor_address) {
        if (options.length == 0 || options.length > 3) {
            revert Distributors__BadPayload();
        }

        Post storage req_post = getPostById(distributor_address, post_id);

        for (uint256 i = 0; i < options.length; i++) {
            req_post.options[i] = options[i];
        }

        emit OptionsUpdated(distributor_address, post_id);
    }

    function updateVotes(
        uint64[] memory votes,
        address distributor_address,
        string memory post_id
    ) public Authorized(msg.sender, distributor_address) {
        if (votes.length != 3) {
            revert Distributors__BadPayload();
        }

        Post storage req_post = getPostById(distributor_address, post_id);

        for (uint256 i = 0; i < votes.length; i++) {
            req_post.options[i].vote = votes[i];
            emit VotesUpdated(
                distributor_address,
                post_id,
                req_post.options[i].id,
                votes[i]
            );
        }
    }

    // ===================================================================================================================================================

    function updateImageUrl(
        string memory url,
        address distributor_address,
        string memory post_id,
        string memory option_id
    ) public Authorized(msg.sender, distributor_address) {
        Option storage option = getOptionById(
            distributor_address,
            post_id,
            option_id
        );

        if (isEmpty(option.id)) {
            revert Distributors__OptionDoesNotExist();
        }

        option.imageUrl = url;
        emit ImageUrlUpdated(distributor_address, post_id, option_id, url);
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
        return getPostById(distributor, post_id);
    }

    function getAllOptions(
        address distributor,
        string memory post_id
    ) public view returns (Option[3] memory) {
        Post memory req_post = getPostById(distributor, post_id);
        return req_post.options;
    }

    function getTotalVotesOnPost(
        address distributor,
        string memory post_id
    ) public view returns (uint256 totalVotes) {
        Post memory req_post = getPostById(distributor, post_id);
        for (uint256 i = 0; i < 3; i++) {
            totalVotes += req_post.options[i].vote;
        }
    }

    // ===================================================================================================================================================

    function getParticularOption(
        address distributor,
        string memory post_id,
        string memory option_id
    ) public view returns (Option memory) {
        return getOptionById(distributor, post_id, option_id);
    }

    function getVoteOnOption(
        address distributor,
        string memory post_id,
        string memory option_id
    ) public view returns (uint256) {
        Option memory option = getParticularOption(
            distributor,
            post_id,
            option_id
        );
        return option.vote;
    }

    ////////////////////
    // METHODS - Pure //
    ////////////////////
    function isEmpty(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }

    ///////////////////////////////
    // METHODS - Internal Helper //
    ///////////////////////////////
    function getPostById(
        address distributor,
        string memory post_id
    ) internal view returns (Post storage) {
        Post[] storage posts = s_Distributors[distributor].posts;

        for (uint256 i = 0; i < posts.length; i++) {
            if (
                keccak256(abi.encodePacked(post_id)) ==
                keccak256(abi.encodePacked(posts[i].id))
            ) {
                return posts[i];
            }
        }
        revert Distributors__PostDoesNotExist();
    }

    function getOptionById(
        address distributor,
        string memory post_id,
        string memory option_id
    ) internal view returns (Option storage) {
        Post storage post = getPostById(distributor, post_id);

        for (uint256 i = 0; i < 3; i++) {
            if (
                keccak256(abi.encodePacked(option_id)) ==
                keccak256(abi.encodePacked(post.options[i].id))
            ) {
                return post.options[i];
            }
        }
        revert Distributors__PostDoesNotExist();
    }
}
