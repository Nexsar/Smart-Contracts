// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

    //////////////
    // MODIFIER //
    //////////////
    modifier Authorized(address distributor_address) {
        if (msg.sender != distributor_address) {
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

    /////////////////////
    // DATA STRUCTURES //
    /////////////////////
    mapping(bytes32  => Post) public s_Posts;
    mapping(address => mapping(string=>Post)) public d_Posts;
    mapping(string => mapping(string=>Option)) public p_Options;
    mapping(bytes32 => Option) public s_Options;
    mapping(address => Distributor) private s_Distributors;
    mapping(address  => uint256) public s_DistributorBudget;
    mapping(string => bool) private postExist;  // to make a check of unique postIds exist
    mapping(string => bool) private optionExist; // to make a check of unique optionIds exist

    /////////////////
    // CONSTRUCTOR //  Option memory newOption = Option({
            
    /////////////////
    constructor() {}

    ////////////////////////
    // METHODS - Updaters //
    ////////////////////////

    function initDistributor(
        bool listed,
        uint256 initialBudget,
        uint256 initialFrequency,
        string memory  postId,
        string  memory description,
        string[] memory optionIds,
        string[]  memory imageUrls
    ) public payable {

        if(!listed){
            revert Distributors__DoesNotExist();
        }

        // if (msg.value != initialBudget) {
        //     revert Distributors__BadPayload();
        // }

        // Init new distributor
        Distributor storage distributor = s_Distributors[msg.sender];
        s_DistributorBudget[msg.sender] = initialBudget;
        distributor.id = msg.sender;
        distributor.listed = listed;
        distributor.budget = initialBudget;
        distributor.frequency = initialFrequency;
        distributor.postIds.push(postId);

        //init Post
        Post storage post = d_Posts[msg.sender][postId];
        post.id = postId;
        post.description = description;
        post.affiliated_distributor = msg.sender;

        for (uint j = 0; j < 3; j++) {
            Option storage option = p_Options[postId][optionIds[j]];
            post.optionIds.push(optionIds[j]);
            option.id= optionIds[j];
            option.vote= 0;
            option.imageUrl= imageUrls[j];
            option.affiliated_post= postId;
            optionExist[optionIds[j]]=true;
            }
        postExist[postId]=true;

        emit DistributorListed(msg.sender);
       
    }


    // Update Budget;
    function updateBudget(
        uint256 budget,
        address distributor_address
    )
        public
        payable
        Listed(distributor_address)
        Authorized(distributor_address)
    {
        // if (msg.value != budget) {
        //     revert Distributors__BadPayload();
        // }

        Distributor storage distributor = s_Distributors[distributor_address];
        distributor.budget = budget;
        s_DistributorBudget[msg.sender] = budget;

        emit BudgetUpdated(distributor_address, budget);
    }

    // function withdrawFromBudget(
    //     uint256 amount,
    //     address distributor_address
    // ) public Authorized(distributor_address) Listed(distributor_address) Authorized(distributor_address) {
    //     Distributor storage distributor = s_Distributors[distributor_address];

    //     if (amount > distributor.budget) {
    //         revert Distributors__NotEnoughBudget();
    //     }

    //     distributor.budget -= amount;
    //     (bool success, ) = msg.sender.call{value: amount}("");
    //     require(success, "Withdrawal failed");

    //     emit BudgetUpdated(distributor_address, distributor.budget);
    // }

    function updateFrequency(
        uint256 frequency,
        address distributor_address
    )
        public
        Listed(distributor_address)
        Authorized(distributor_address)
    {
        Distributor storage distributor = s_Distributors[distributor_address];
        distributor.frequency = frequency;

        emit FrequencyUpdated(distributor_address, frequency);
    }

    function AddPost(
        string memory  postId,
        string  memory description,
        string[] memory optionIds,
        string[]  memory imageUrls,
        address distributor_address
    )
        public
        Listed(msg.sender)
        Authorized(msg.sender)
    {
        Distributor storage distributor = s_Distributors[distributor_address];
         //init Post
        Post storage post = d_Posts[msg.sender][postId];
        post.id = postId;
        post.description = description;
        post.affiliated_distributor = msg.sender;
        distributor.postIds.push(postId);

        for (uint j = 0; j < 3; j++) {
            if(optionExist[optionIds[j]]){
                revert Distributors__PostDoesNotExist();
            }

            Option storage option = p_Options[postId][optionIds[j]];
            post.optionIds.push(optionIds[j]);
            option.id= optionIds[j];
            option.vote= 0;
            option.imageUrl= imageUrls[j];
            option.affiliated_post= postId;
            optionExist[optionIds[j]] = true;
            }
        postExist[postId] = true;

        emit PostUpdated(distributor_address, post.id);
    }

    // // ===================================================================================================================================================

    function updateDescription(
        string memory desc,
        string memory post_id,
        address distributor_address
    )
        public
        Listed(distributor_address)
        Authorized( distributor_address)
    {
       
        Post storage req_post = d_Posts[distributor_address][post_id] ;

        if (!postExist[post_id]) {
            revert Distributors__PostDoesNotExist();
        }

        req_post.description = desc;
        emit DescriptionUpdated(distributor_address, post_id, desc); // Added event
    }

    // function updateOptions(
    //     string[] memory optionIds,
    //     string[]  memory imageUrls,
    //     address distributor_address,
    //     string memory post_id
    // )
    //     public
    //     Listed(distributor_address)
    //     Authorized(distributor_address)
    // {
    //     // if (options.length == 0 || options.length > 3) {
    //     //     revert Distributors__BadPayload();
    //     // }
    //     Distributor storage distributor = s_Distributors[distributor_address];
    //     Post storage req_post = distributor.posts[post_id];

    //     if (!postExist[post_id]) {
    //         revert Distributors__PostDoesNotExist();
    //     }

    //     for (uint256 i = 0; i < optionIds.length; i++) {
    //         Option storage option = req_post.options[optionIds[i]];
    //         option.imageUrl = imageUrls[i];



    //     }

    //     emit OptionsUpdated(distributor_address, post_id);
    // }

    function updateVotes(
        uint64[] memory votes,
        string[] memory optionIds,
        address distributor_address,
        string memory post_id
    )
        public
        Listed(distributor_address)
        Authorized(distributor_address)
    {
        if (votes.length != 3 || optionIds.length != 3 ) {
            revert Distributors__BadPayload();
        }
      

        for (uint256 i = 0; i < votes.length; i++) {
            Option storage option = p_Options[post_id][optionIds[i]];
            option.vote = votes[i];
            emit VotesUpdated(
                distributor_address,
                post_id,
                optionIds[i],
                votes[i]
            );
        }
    }

    // // ===================================================================================================================================================

    function updateImageUrl(
        string memory url,
        address distributor_address,
        string memory post_id,
        string memory option_id
    )
        public
        Listed(distributor_address)
        Authorized(distributor_address)
    {
       
        
        if (!postExist[post_id]) {
            revert Distributors__PostDoesNotExist();
        }

        if (optionExist[option_id]) {
            revert Distributors__PostDoesNotExist();
        }
        Option storage option = p_Options[post_id][option_id];
        option.imageUrl = url;
        emit ImageUrlUpdated(distributor_address, post_id, option_id, url);
    }

    // //////////////////////
    // // METHODS - Getter //
    // //////////////////////

    function getBudget(address distributor) public view returns (uint256) {
        return s_Distributors[distributor].budget;
    }

    function getFrequency(address distributor) public view returns (uint256) {
        return s_Distributors[distributor].frequency;
    }

    function getAllPosts(
        address distributor_id
    ) public view returns (Post[] memory ) {
        Distributor storage distributor = s_Distributors[distributor_id];
        string[] memory postIds = distributor.postIds;
        Post[] memory postArray = new Post[](postIds.length); 

        for(uint i=0;i<postIds.length;i++){
            Post storage req_post = d_Posts[distributor_id][postIds[i]];
            Post memory post = req_post;
            postArray[i]=post;
        }
        return postArray ;
    }

    function ownerOfDistributor(
        address distributor
    ) public view returns (address) {
        return s_Distributors[distributor].id;
    }

    // // ===================================================================================================================================================

    function getParticularPost(
        address distributor_id,
        string memory post_id
    ) public view returns (Post memory) {

        Post storage req_post = d_Posts[distributor_id][post_id];
        return req_post;
    }

    // function getAllOptions(
    //     address distributor_id,
    //     string memory post_id
    // ) public view returns (Option memory) {
    //     Distributor storage distributor = s_Distributors[distributor_id];
    //     Post storage req_post = distributor.posts[post_id];
    //     return req_post.options;
    // }

    // function getTotalVotesOnPost(
    //     address distributor,
    //     string memory post_id
    // ) public view returns (uint256 totalVotes) {
    //     Post memory req_post = getPostById(distributor, post_id);
    //     for (uint256 i = 0; i < 3; i++) {
    //         totalVotes += req_post.options[i].vote;
    //     }
    // }

    // // ===================================================================================================================================================

    // function getParticularOption(
    //     address distributor,
    //     string memory post_id,
    //     string memory option_id
    // ) public view returns (Option memory) {
    //     return getOptionById(distributor, post_id, option_id);
    // }

    // function getVoteOnOption(
    //     address distributor,
    //     string memory post_id,
    //     string memory option_id
    // ) public view returns (uint256) {
    //     Option memory option = getParticularOption(
    //         distributor,
    //         post_id,
    //         option_id
    //     );
    //     return option.vote;
    // }

    // ////////////////////
    // // METHODS - Pure //
    // ////////////////////
    // function isEmpty(string memory str) internal pure returns (bool) {
    //     return bytes(str).length == 0;
    // }

    // ///////////////////////////////
    // // METHODS - Internal Helper //
    // ///////////////////////////////
    // function getPostById(
    //     address distributor,
    //     string memory post_id
    // ) internal view returns (Post storage) {
    //     Post[] storage posts = s_Distributors[distributor].posts;

    //     for (uint256 i = 0; i < posts.length; i++) {
    //         if (
    //             keccak256(abi.encodePacked(post_id)) ==
    //             keccak256(abi.encodePacked(posts[i].id))
    //         ) {
    //             return posts[i];
    //         }
    //     }
    //     revert Distributors__PostDoesNotExist();
    // }

    // function getOptionById(
    //     address distributor,
    //     string memory post_id,
    //     string memory option_id
    // ) internal view returns (Option storage) {
    //     Post storage post = getPostById(distributor, post_id);

    //     for (uint256 i = 0; i < 3; i++) {
    //         if (
    //             keccak256(abi.encodePacked(option_id)) ==
    //             keccak256(abi.encodePacked(post.options[i].id))
    //         ) {
    //             return post.options[i];
    //         }
    //     }
    //     revert Distributors__PostDoesNotExist();
    // }
}
