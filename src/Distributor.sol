// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Distributors {
    // Errors
    error Distributors__Exist();
    error Distributors__PostExists();
    error Distributors__BadPayload();
    error Distributors__DoesNotExist();
    error Distributors__OptionExists();
    error Distributors__NotAuthorized();
    error Distributors__NotEnoughBudget();
    error Distributors__PostDoesnotExist();
    error Distributors__PostDoesNotExist();
    error Distributors__UnAuthorisedAccess();
    error Distributors__OptionDoesNotExist();
    error Distributors__AmountLessThanZero();
    error Distributors__InsufficientBalance();

    // Events
    event DistributorListed(address indexed distributor);
    event BudgetUpdated(address indexed distributor, uint256 newBudget);
    event FrequencyUpdated(address indexed distributor, uint256 newFrequency);
    event PostAdded(address indexed distributor, string postId);
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

    // Structs
    struct Option {
        string id;
        uint256 vote;
        string imageUrl;
        string affiliated_post; // Post id
    }

    struct Post {
        string id;
        string[] optionIds;
        string description;
        address affiliated_distributor; // Distributor id
    }

    struct Distributor {
        address id;
        bool listed;
        uint256 budget;
        uint256 frequency;
        string[] postIds;
    }

    // Modifiers
    modifier Authorized(address distributorAddress) {
        if (msg.sender != distributorAddress) {
            revert Distributors__NotAuthorized();
        }
        _;
    }

    modifier Listed(address distributor) {
        if (!s_Distributors[distributor].listed) {
            revert Distributors__Exist();
        }
        _;
    }

    //Mappings
    mapping(address => Distributor) private s_Distributors; // distributor add => distributor struct
    mapping(address => uint256) private s_DistributorBudget; // distributor add => distributor budget

    mapping(string => Post) private s_Posts; // post id => post struct
    mapping(string => Option) private s_Options; // option id => option struct

    mapping(string => bool) private optionExist; // to make a check of unique optionIds exist
    mapping(string => bool) private postExist; // to make a check of unique postIds exist
    mapping(address => bool) private distributorExist;

    mapping(string => mapping(string => Option)) private p_Options; // post id => option id => option struct
    mapping(address => mapping(string => Post)) private d_Posts; // distributor add => post id => post struct
    mapping(address => uint256) private ethBalances;

    //constructor
    constructor() {}

    // init the distributor

    function initDistributor(
        bool listed,
        uint256 initialBudget,
        uint256 initialFrequency,
        // post
        string memory postId,
        string memory description,
        // option
        string[] memory optionIds,
        string[] memory imageUrls
    ) public payable {
        if (!listed) {
            revert Distributors__DoesNotExist();
        }

        // if (msg.value != initialBudget) {
        //     revert Distributors__BadPayload();
        // }
        if (distributorExist[msg.sender]) {
            revert Distributors__Exist();
        }

        if (postExist[postId]) {
            revert Distributors__PostExists();
        }

        // Init new distributor
        Distributor storage distributor = s_Distributors[msg.sender];
        s_DistributorBudget[msg.sender] = initialBudget;
        distributor.id = msg.sender;
        distributor.listed = listed;
        distributor.budget = initialBudget;
        distributor.frequency = initialFrequency;
        distributor.postIds.push(postId);
        distributorExist[msg.sender] = true;

        //init Post
        Post storage post = d_Posts[msg.sender][postId];
        post.id = postId;
        post.description = description;
        post.affiliated_distributor = msg.sender;

        for (uint j = 0; j < 3; j++) {
            if (optionExist[optionIds[j]]) {
                revert Distributors__OptionExists();
            }
            Option storage option = p_Options[postId][optionIds[j]];
            post.optionIds.push(optionIds[j]);
            option.id = optionIds[j];
            option.vote = 0;
            option.imageUrl = imageUrls[j];
            option.affiliated_post = postId;
            optionExist[optionIds[j]] = true;
            s_Options[optionIds[j]] = option;
        }
        s_Posts[postId] = post;
        postExist[postId] = true;
        depositETH();
        emit DistributorListed(msg.sender);
    }

    function depositETH()
        public
        payable
        Listed(msg.sender)
        Authorized(msg.sender)
    {
        require(msg.value > 0, "Must send ETH to deposit");
        ethBalances[msg.sender] += msg.value;

        s_Distributors[msg.sender].budget -= msg.value;

        emit BudgetUpdated(msg.sender, s_Distributors[msg.sender].budget);
    }

    function withdrawETH(
        uint256 amount
    ) public Listed(msg.sender) Authorized(msg.sender) {
        if (amount <= 0) {
            revert Distributors__AmountLessThanZero();
        }
        if (ethBalances[msg.sender] < amount) {
            revert Distributors__InsufficientBalance();
        }
        if (!distributorExist[msg.sender]) {
            revert Distributors__DoesNotExist();
        }

        Distributor storage distributor = s_Distributors[msg.sender];
        distributor.budget += amount;

        ethBalances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function addPost(
        string memory postId,
        string memory description,
        string[] memory optionIds,
        string[] memory imageUrls,
        address distributorAddress
    ) public Listed(msg.sender) Authorized(msg.sender) {
        if (!distributorExist[distributorAddress]) {
            revert Distributors__DoesNotExist();
        }

        if (distributorAddress != msg.sender) {
            revert Distributors__UnAuthorisedAccess();
        }

        if (postExist[postId]) {
            revert Distributors__PostExists();
        }

        Distributor storage distributor = s_Distributors[distributorAddress];
        //init Post
        Post storage post = d_Posts[msg.sender][postId];
        post.id = postId;
        post.description = description;
        post.affiliated_distributor = msg.sender;
        distributor.postIds.push(postId);

        for (uint j = 0; j < 3; j++) {
            if (optionExist[optionIds[j]]) {
                revert Distributors__OptionExists();
            }

            Option storage option = p_Options[postId][optionIds[j]];
            post.optionIds.push(optionIds[j]);
            option.id = optionIds[j];
            option.vote = 0;
            option.imageUrl = imageUrls[j];
            option.affiliated_post = postId;
            optionExist[optionIds[j]] = true;
            s_Options[optionIds[j]] = option;
        }
        postExist[postId] = true;
        s_Posts[postId] = post;
        emit PostAdded(distributorAddress, post.id);
    }

    ///////////////////////////////////////////////Updation/////////////////////////////////////////////////////////////

    // Update Budget;
    function updateBudget(
        uint256 budget,
        address distributorAddress
    ) public payable Listed(distributorAddress) Authorized(distributorAddress) {
        if (!distributorExist[distributorAddress]) {
            revert Distributors__DoesNotExist();
        }

        Distributor storage distributor = s_Distributors[distributorAddress];
        if (distributorAddress != msg.sender) {
            revert Distributors__UnAuthorisedAccess();
        }

        if (distributor.id != msg.sender) {
            revert Distributors__UnAuthorisedAccess();
        }

        distributor.budget = budget;
        depositETH();

        s_DistributorBudget[msg.sender] = budget;

        emit BudgetUpdated(distributorAddress, budget);
    }

    // update frequency
    function updateFrequency(
        uint256 frequency,
        address distributorAddress
    ) public Listed(distributorAddress) Authorized(distributorAddress) {
        if (!distributorExist[distributorAddress]) {
            revert Distributors__DoesNotExist();
        }
        Distributor storage distributor = s_Distributors[distributorAddress];

        if (distributorAddress != msg.sender) {
            revert Distributors__UnAuthorisedAccess();
        }

        if (distributor.id != msg.sender) {
            revert Distributors__UnAuthorisedAccess();
        }
        distributor.frequency = frequency;

        emit FrequencyUpdated(distributorAddress, frequency);
    }

    // update description of the post with specific post id
    function updateDescription(
        string memory desc,
        string memory postId,
        address distributorAddress
    ) public Listed(distributorAddress) Authorized(distributorAddress) {
        if (!distributorExist[distributorAddress]) {
            revert Distributors__DoesNotExist();
        }
        Post storage req_post = d_Posts[distributorAddress][postId];
        if (msg.sender != distributorAddress) {
            revert Distributors__UnAuthorisedAccess();
        }

        if (!postExist[postId]) {
            revert Distributors__PostDoesNotExist();
        }

        req_post.description = desc;
        emit DescriptionUpdated(distributorAddress, postId, desc); // Added event
    }

    // update votes for all options in a post
    // ToDo: NEED TO MAKE IT MORE GENERIC.....
    function updateVotes(
        uint64[] memory votes,
        string[] memory optionIds,
        string memory postId,
        address distributorAddress
    ) public Listed(distributorAddress) Authorized(distributorAddress) {
        if (votes.length != 3 || optionIds.length != 3) {
            revert Distributors__BadPayload();
        }
        if (!distributorExist[distributorAddress]) {
            revert Distributors__DoesNotExist();
        }

        for (uint256 i = 0; i < votes.length; i++) {
            if (optionExist[optionIds[i]]) {
                revert Distributors__OptionExists();
            }

            Option storage option = p_Options[postId][optionIds[i]];
            option.vote = votes[i];
            emit VotesUpdated(
                distributorAddress,
                postId,
                optionIds[i],
                votes[i]
            );
        }
    }

    // update image url for the post option
    function updateImageUrl(
        string memory url,
        string memory postId,
        string memory optionId,
        address distributorAddress
    ) public Listed(distributorAddress) Authorized(distributorAddress) {
        if (msg.sender != distributorAddress) {
            revert Distributors__UnAuthorisedAccess();
        }
        if (!distributorExist[distributorAddress]) {
            revert Distributors__DoesNotExist();
        }

        if (!postExist[postId]) {
            revert Distributors__PostDoesNotExist();
        }

        if (optionExist[optionId]) {
            revert Distributors__PostDoesNotExist();
        }
        Option storage option = p_Options[postId][optionId];
        option.imageUrl = url;
        emit ImageUrlUpdated(distributorAddress, postId, optionId, url);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////Get////////////////////////////////////////////////////////////////////////////////////

    // get the budget of the distributor
    function getBudget(address distributor) public view returns (uint256) {
        if (msg.sender != distributor) {
            revert Distributors__UnAuthorisedAccess();
        }
        if (!distributorExist[distributor]) {
            revert Distributors__DoesNotExist();
        }
        return s_Distributors[distributor].budget;
    }

    // get the frequency set by distributor
    function getFrequency(address distributor) public view returns (uint256) {
        if (msg.sender != distributor) {
            revert Distributors__UnAuthorisedAccess();
        }
        if (!distributorExist[distributor]) {
            revert Distributors__DoesNotExist();
        }
        return s_Distributors[distributor].frequency;
    }

    // get All the posts of the distributer
    function getAllPosts(
        address distributorAddress
    ) public view returns (Post[] memory) {
        if (!distributorExist[distributorAddress]) {
            revert Distributors__DoesNotExist();
        }

        Distributor memory distributor = s_Distributors[distributorAddress];
        string[] memory postIds = distributor.postIds;
        Post[] memory postArray = new Post[](postIds.length);

        for (uint i = 0; i < postIds.length; i++) {
            if (!postExist[postIds[i]]) {
                revert Distributors__PostDoesnotExist();
            }
            Post memory req_post = d_Posts[distributorAddress][postIds[i]];
            postArray[i] = req_post;
        }
        return postArray;
    }

    // get the particular post of the distributor
    function getParticularPost(
        address distributorAddress,
        string memory postId
    ) public view returns (Post memory) {
        if (postExist[postId]) {
            revert Distributors__PostDoesnotExist();
        }
        Post storage req_post = d_Posts[distributorAddress][postId];
        return req_post;
    }

    // get all the options of a particular post
    function getAllOptions(
        string memory postId
    ) public view returns (Option[] memory) {
        if (!postExist[postId]) {
            revert Distributors__PostDoesnotExist();
        }
        Post memory post = s_Posts[postId];
        string[] memory optionIds = post.optionIds;
        Option[] memory optionArray = new Option[](3);

        for (uint i = 0; i < 3; i++) {
            Option memory option = p_Options[postId][optionIds[i]];
            optionArray[i] = option;
        }
        return optionArray;
    }

    // get total votes on a particular post
    function getTotalVotesOnPost(
        string memory postId
    ) public view returns (uint256 totalVotes) {
        if (postExist[postId]) {
            revert Distributors__PostDoesnotExist();
        }
        Post memory req_post = s_Posts[postId];
        string[] memory optionIds = req_post.optionIds;
        for (uint i = 0; i < 3; i++) {
            Option memory option = p_Options[postId][optionIds[i]];
            totalVotes += option.vote;
        }
    }

    // get all the array of votes for the particular post
    function getAllVotesOnPost(
        string memory postId
    ) public view returns (uint256[] memory) {
        if (postExist[postId]) {
            revert Distributors__PostDoesnotExist();
        }
        Post memory req_post = s_Posts[postId];
        string[] memory optionIds = req_post.optionIds;
        uint256[] memory votes = new uint256[](3);

        for (uint i = 0; i < 3; i++) {
            Option memory option = p_Options[postId][optionIds[i]];
            votes[i] = option.vote;
        }
        return votes;
    }
}
