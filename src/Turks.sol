// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Turks {
    // Errors
    error Turks__PostExist();
    error Turks__PostDNE();
    error Turks__BadPayload();
    error Turks__DoesNotExist();
    error Turks__OptionExists();
    error Turks__WorkersExists();
    error Turks__WithdrawFailed();
    error Turks__NotEnoughBudget();
    error Turks__WorkerDNE(address);
    error Turks__PostDoesNotExist();
    error Turks__DistributorExists();
    error Turks__OptionDoesNotExist();
    error Turks__UnAuthorisedAccess();
    error Turks__InsufficientBalance();
    error Turks__AmountLessThanEqual0();
    error Turks__WithdrawRewardsBeforeDeleting();

    // Events
    event DistributorListed(address indexed distributor);
    event PostAdded(address indexed distributor, string postId);
    event ImageUrlUpdated(
        address indexed distributor,
        string postId,
        string optionId,
        string newImageUrl
    );

    event WorkerListed(address indexed worker);
    event WorkerRemoved(address indexed worker);
    event RewardWithdrawn(address indexed worker, uint256 amount);

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
            revert Turks__UnAuthorisedAccess();
        }
        _;
    }

    modifier Listed(address distributor) {
        if (!distributorExist[distributor]) {
            revert Turks__DoesNotExist();
        }
        _;
    }

    modifier ListedWorker(address worker) {
        if (s_WorkerListed[worker]) {
            revert Turks__WorkersExists();
        }
        _;
    }

    modifier WorkersExist(address[] memory workers) {
        for (uint i = 0; i < workers.length; i++) {
            if (!s_WorkerListed[workers[i]]) {
                revert Turks__WorkerDNE(workers[i]);
            }
        }
        _;
    }

    modifier isOwner() {
        if (owner != msg.sender) {
            revert Turks__UnAuthorisedAccess();
        }
        _;
    }

    //Mappings
    address public owner;
    mapping(address => Distributor) private s_Distributors; // distributor add => distributor struct
    mapping(address => uint256) private s_DistributorBudget; // distributor add => distributor budget

    mapping(string => Post) private s_Posts; // post id => post struct
    mapping(string => Option) private s_Options; // option id => option struct

    mapping(string => bool) private optionExist; // to make a check of unique optionIds exist
    mapping(string => bool) private postExist; // to make a check of unique postIds exist
    mapping(address => bool) public distributorExist;

    mapping(string => mapping(string => Option)) private p_Options; // post id => option id => option struct
    mapping(address => mapping(string => Post)) private d_Posts; // distributor add => post id => post struct

    mapping(address => bool) public s_WorkerListed; // worker address => Listed
    mapping(address => uint256) private s_turksReward; // worker address => Turk Reward
    mapping(address => mapping(string => string)) private s_votedPostOption; // worker add => Post id => option id

    //constructor
    constructor() {
        owner = msg.sender;
    }

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
            revert Turks__BadPayload();
        }

        if (msg.value < initialBudget) {
            revert Turks__InsufficientBalance();
        }

        if (distributorExist[msg.sender]) {
            revert Turks__DistributorExists();
        }

        if (postExist[postId]) {
            revert Turks__PostExist();
        }

        // Init new distributor
        Distributor storage distributor = s_Distributors[msg.sender];
        s_DistributorBudget[msg.sender] = msg.value;
        distributor.id = msg.sender;
        distributor.listed = listed;
        distributor.budget = msg.value;
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
                revert Turks__OptionExists();
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
        emit DistributorListed(msg.sender);
    }

    function depositETH()
        public
        payable
        Listed(msg.sender)
        Authorized(msg.sender)
    {
        require(msg.value > 0, "Must send ETH to deposit");
        s_DistributorBudget[msg.sender] += msg.value;
    }

    function withdrawETH(
        uint256 amount
    ) public payable Listed(msg.sender) Authorized(msg.sender) {
        if (!distributorExist[msg.sender]) {
            revert Turks__DoesNotExist();
        }
        if (amount <= 0) {
            revert Turks__AmountLessThanEqual0();
        }
        if (s_DistributorBudget[msg.sender] < amount) {
            revert Turks__InsufficientBalance();
        }

        Distributor storage distributor = s_Distributors[msg.sender];
        distributor.budget -= amount;

        s_DistributorBudget[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function AddPosts(
        string[] memory postIds,
        string[] memory descriptions,
        string[][] memory arrayOptionIds,
        string[][] memory arrayImageUrls,
        address distributorAddress
    ) public Listed(msg.sender) {
        Distributor storage distributor = s_Distributors[distributorAddress];
        for (uint i = 0; i < postIds.length; i++) {
            Post storage post = d_Posts[msg.sender][postIds[i]];

            post.id = postIds[i];
            post.description = descriptions[i];
            post.affiliated_distributor = msg.sender;
            distributor.postIds.push(postIds[i]);

            for (uint j = 0; j < 3; j++) {
                if (optionExist[arrayOptionIds[i][j]]) {
                    revert Turks__OptionExists();
                }

                Option storage option = p_Options[postIds[i]][
                    arrayOptionIds[i][j]
                ];
                post.optionIds.push(arrayOptionIds[i][j]);
                option.id = arrayOptionIds[i][j];
                option.vote = 0;
                option.imageUrl = arrayImageUrls[i][j];
                option.affiliated_post = postIds[i];
                optionExist[arrayOptionIds[i][j]] = true;
                s_Options[arrayOptionIds[i][j]] = option;
            }
            postExist[postIds[i]] = true;
            s_Posts[postIds[i]] = post;
            emit PostAdded(distributorAddress, post.id);
        }
    }

    // function AddPost(
    //     string memory postId,
    //     string memory description,
    //     string[] memory optionIds,
    //     string[] memory imageUrls,
    //     address distributorAddress
    // ) public Listed(msg.sender) Authorized(msg.sender) {
    //     if (!distributorExist[msg.sender]) {
    //         revert Turks__DoesNotExist();
    //     }

    //     if (distributorAddress != msg.sender) {
    //         revert Turks__UnAuthorisedAccess();
    //     }

    //     if (postExist[postId]) {
    //         revert Turks__PostExist();
    //     }

    //     Distributor storage distributor = s_Distributors[distributorAddress];
    //     //init Post
    //     Post storage post = d_Posts[msg.sender][postId];
    //     post.id = postId;
    //     post.description = description;
    //     post.affiliated_distributor = msg.sender;
    //     distributor.postIds.push(postId);

    //     for (uint j = 0; j < 3; j++) {
    //         if (optionExist[optionIds[j]]) {
    //             revert Turks__OptionExists();
    //         }

    //         Option storage option = p_Options[postId][optionIds[j]];
    //         post.optionIds.push(optionIds[j]);
    //         option.id = optionIds[j];
    //         option.vote = 0;
    //         option.imageUrl = imageUrls[j];
    //         option.affiliated_post = postId;
    //         optionExist[optionIds[j]] = true;
    //         s_Options[optionIds[j]] = option;
    //     }
    //     postExist[postId] = true;
    //     s_Posts[postId] = post;
    //     emit PostAdded(distributorAddress, post.id);
    // }

    ///////////////////////////////////////////////Updation/////////////////////////////////////////////////////////////

    // Update Budget;
    function updateBudget(
        uint256 budget,
        address distributorAddress
    ) public payable Listed(distributorAddress) Authorized(distributorAddress) {
        if (!distributorExist[distributorAddress]) {
            revert Turks__DoesNotExist();
        }

        Distributor storage distributor = s_Distributors[distributorAddress];
        if (distributorAddress != msg.sender) {
            revert Turks__UnAuthorisedAccess();
        }

        if (distributor.id != msg.sender) {
            revert Turks__UnAuthorisedAccess();
        }

        distributor.budget += budget;
        s_DistributorBudget[msg.sender] += budget;
    }

    // update description of the post with specific post id
    function updateDescription(
        string memory desc,
        string memory postId,
        address distributorAddress
    ) public Listed(distributorAddress) Authorized(distributorAddress) {
        if (!distributorExist[distributorAddress]) {
            revert Turks__DoesNotExist();
        }
        Post storage req_post = d_Posts[distributorAddress][postId];
        if (msg.sender != distributorAddress) {
            revert Turks__UnAuthorisedAccess();
        }

        if (!postExist[postId]) {
            revert Turks__PostDoesNotExist();
        }

        req_post.description = desc;
    }

    // update votes for all options in a post
    function updateVotes(
        uint64[] memory votes,
        string[] memory optionIds,
        address distributorAddress,
        string memory postId
    ) public Listed(distributorAddress) isOwner {
        if (votes.length != 3 || optionIds.length != 3) {
            revert Turks__BadPayload();
        }
        if (!distributorExist[distributorAddress]) {
            revert Turks__DoesNotExist();
        }

        for (uint256 i = 0; i < votes.length; i++) {
            if (!optionExist[optionIds[i]]) {
                revert Turks__DoesNotExist();
            }

            Option storage option = p_Options[postId][optionIds[i]];
            option.vote += votes[i];
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////Get////////////////////////////////////////////////////////////////////////////////////

    // get the budget of the distributor
    function getBudget(address distributor) public view returns (uint256) {
        return s_DistributorBudget[distributor];
    }

    // get the frequency set by distributor
    function getFrequency(address distributor) public view returns (uint256) {
        if (msg.sender != distributor) {
            revert Turks__UnAuthorisedAccess();
        }
        if (!distributorExist[distributor]) {
            revert Turks__DoesNotExist();
        }
        return s_Distributors[distributor].frequency;
    }

    // get All the posts of the distributer
    function getAllPosts(
        address distributorId
    ) public view returns (Post[] memory) {
        if (!distributorExist[distributorId]) {
            revert Turks__DoesNotExist();
        }

        Distributor memory distributor = s_Distributors[distributorId];
        string[] memory postIds = distributor.postIds;
        Post[] memory postArray = new Post[](postIds.length);

        for (uint i = 0; i < postIds.length; i++) {
            if (!postExist[postIds[i]]) {
                revert Turks__PostDNE();
            }
            Post memory req_post = d_Posts[distributorId][postIds[i]];
            postArray[i] = req_post;
        }
        return postArray;
    }

    // get the particular post of the distributor
    function getParticularPost(
        address distributorId,
        string memory postId
    ) public view returns (Post memory) {
        if (!postExist[postId]) {
            revert Turks__PostDNE();
        }
        Post storage req_post = d_Posts[distributorId][postId];
        return req_post;
    }

    // get all the options of a particular post
    function getAllOptions(
        string memory postId
    ) public view returns (Option[] memory) {
        if (!postExist[postId]) {
            revert Turks__PostDNE();
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
        if (!postExist[postId]) {
            revert Turks__PostDNE();
        }
        Post memory req_post = s_Posts[postId];
        string[] memory optionIds = req_post.optionIds;
        for (uint i = 0; i < 3; i++) {
            Option memory option = p_Options[postId][optionIds[i]];
            totalVotes += option.vote;
        }
    }

    ////////////////
    //// WORKER ////
    ////////////////
    function initWorker() public ListedWorker(msg.sender) {
        s_WorkerListed[msg.sender] = true;
        s_turksReward[msg.sender] = 0;

        emit WorkerListed(msg.sender);
    }

    // Update rewards for workers
    function updateRewards(
        address[] memory workers,
        uint256 rewards
    ) public WorkersExist(workers) isOwner {
        if (workers.length == 0) {
            revert Turks__BadPayload();
        }

        for (uint i = 0; i < workers.length; i++) {
            s_turksReward[workers[i]] += rewards;
        }
    }

    // Update voting mappings
    function updateVotingMapping(
        address[] memory workers,
        string[] memory postIds,
        string[] memory optionIds
    ) public WorkersExist(workers) isOwner {
        if (
            workers.length != postIds.length ||
            workers.length != optionIds.length
        ) {
            revert Turks__BadPayload();
        }

        for (uint i = 0; i < workers.length; i++) {
            s_votedPostOption[workers[i]][postIds[i]] = optionIds[i];
        }
    }

    function withdrawRewards() public {
        uint256 reward = s_turksReward[msg.sender];

        if (reward == 0) {
            revert Turks__AmountLessThanEqual0();
        }

        // Check-Effects-Interactions :: No chance of Renetrancy Attack
        s_turksReward[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: reward}("");
        if (!success) {
            s_turksReward[msg.sender] = reward;
            revert Turks__WithdrawFailed();
        }

        emit RewardWithdrawn(msg.sender, reward);
    }

    /////////////
    // GETTERS //
    /////////////

    function getRewards(address worker) public view returns (uint256) {
        return s_turksReward[worker];
    }

    function getVotedOption(
        address worker,
        string memory postId
    ) public view returns (string memory) {
        return s_votedPostOption[worker][postId];
    }
}
