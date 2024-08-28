// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Distributors {
    ////////////
    // ERRORS //
    ////////////
    error Distributors__Exist();
    error Distributors__BadPayload();
    error Distributors__DoesNotExist();
    error Distributors__NotAuthorized();
    error Distributors__NotEnoughBudget();
    error Distributors__PostDoesNotExist();
    error Distributors__OptionDoesNotExist();

    ////////////
    // EVENTS //
    ////////////
    event DistributorListed(address indexed distributor);
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

    //////////////
    // MODIFIER //
    //////////////
    modifier Authorized(address sender, address distributor_address) {
        Distributor memory distributor = s_Distributors[distributor_address];
        if (msg.sender != distributor.id) {
            revert Distributors__NotAuthorized();
        }
        _;
    }

    modifier Listed(address distributor) {
        if (s_Distributors[distributor].listed) {
            revert Distributors__Exist();
        }
        _;
    }

    /////////////////////
    // DATA STRUCTURES //
    /////////////////////
    mapping(bytes32 keccakedPostId => Post) public s_Posts;
    mapping(bytes32 keccakedOptionId => Option) public s_Options;
    mapping(address distributor => Distributor) public s_Distributors;
    mapping(address distributor => uint256) public s_DistributorBudget;

    /////////////////
    // CONSTRUCTOR //
    /////////////////
    constructor() {}

    ////////////////////////
    // METHODS - Updaters //
    ////////////////////////

    function initDistributor(
        bool listed,
        uint256 initialBudget,
        uint256 initialFrequency,
        Post[] memory posts
    ) public payable Listed(msg.sender) {
        if (msg.value != initialBudget) {
            revert Distributors__BadPayload(); // Ensuring that the sent value matches the budget
        }

        // Init new distributor
        Distributor storage distributor = s_Distributors[msg.sender];
        s_DistributorBudget[msg.sender] += initialBudget;
        distributor.id = msg.sender;
        distributor.listed = listed;
        distributor.budget = initialBudget;
        distributor.frequency = initialFrequency;

        // Add all posts (usually there will be `1` init Post)
        for (uint i = 0; i < posts.length; i++) {
            Post storage newPost = distributor.posts.push();
            newPost.id = posts[i].id;
            newPost.description = posts[i].description;
            newPost.affiliated_distributor = posts[i].affiliated_distributor;

            // Init Options
            for (uint j = 0; j < 3; j++) {
                newPost.options[j].id = posts[i].options[j].id;
                newPost.options[j].vote = posts[i].options[j].vote;
                newPost.options[j].imageUrl = posts[i].options[j].imageUrl;
                newPost.options[j].affiliated_post = posts[i]
                    .options[j]
                    .affiliated_post;
            }
        }

        emit DistributorListed(msg.sender);
        emit BudgetUpdated(msg.sender, initialBudget);
        emit FrequencyUpdated(msg.sender, initialFrequency);
    }

    // Update Budget;
    function updateBudget(
        uint256 budget,
        address distributor_address
    )
        public
        payable
        Listed(distributor_address)
        Authorized(msg.sender, distributor_address)
    {
        if (msg.value != budget) {
            revert Distributors__BadPayload();
        }
        Distributor storage distributor = s_Distributors[distributor_address];
        distributor.budget += budget;
        s_DistributorBudget[msg.sender] += budget;

        emit BudgetUpdated(distributor_address, budget);
    }

    function withdrawFromBudget(
        uint256 amount,
        address distributor_address
    ) public Authorized(msg.sender, distributor_address) {
        Distributor storage distributor = s_Distributors[distributor_address];

        if (amount > distributor.budget) {
            revert Distributors__NotEnoughBudget();
        }

        distributor.budget -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");

        emit BudgetUpdated(distributor_address, distributor.budget);
    }

    function updateFrequency(
        uint256 frequency,
        address distributor_address
    )
        public
        Listed(distributor_address)
        Authorized(msg.sender, distributor_address)
    {
        Distributor storage distributor = s_Distributors[distributor_address];
        distributor.frequency = frequency;

        emit FrequencyUpdated(distributor_address, frequency);
    }

    function updatePost(
        Post memory post,
        address distributor_address
    )
        public
        Listed(distributor_address)
        Authorized(msg.sender, distributor_address)
    {
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
    )
        public
        Listed(distributor_address)
        Authorized(msg.sender, distributor_address)
    {
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
    )
        public
        Listed(distributor_address)
        Authorized(msg.sender, distributor_address)
    {
        if (options.length == 0 || options.length > 3) {
            revert Distributors__BadPayload();
        }

        Post storage req_post = getPostById(distributor_address, post_id);

        for (uint256 i = 0; i < options.length; i++) {
            req_post.options[i] = options[i];
        }

        emit OptionsUpdated(distributor_address, post_id);
    }

    // ===================================================================================================================================================

    function updateVote(
        uint64 votes,
        address distributor_address,
        string memory post_id,
        string memory option_id
    )
        public
        Listed(distributor_address)
        Authorized(msg.sender, distributor_address)
    {
        Option storage req_option = getOptionById(
            distributor_address,
            post_id,
            option_id
        );

        req_option.vote = votes;

        // Emit Event
    }

    function updateImageUrl(
        string memory url,
        address distributor_address,
        string memory post_id,
        string memory option_id
    )
        public
        Listed(distributor_address)
        Authorized(msg.sender, distributor_address)
    {
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

    function getImageUrlOption(
        address distributor,
        string memory post_id,
        string memory option_id
    ) public view returns (string memory) {
        Option memory option = getParticularOption(
            distributor,
            post_id,
            option_id
        );
        return option.imageUrl;
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
