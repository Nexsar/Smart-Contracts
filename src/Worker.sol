// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Workers {
    ////////////
    // ERRORS //
    ////////////
    error Workers__Exist();
    error Workers__NoRewards();
    error Workers__UnAuthorized();
    error Workers__FalsePayload();
    error Workers__WithdrawFailed();
    error Workers__DoesNotExist(address);
    error Workers__WithdrawRewardsBeforeDeleting();

    ////////////
    // EVENTS //
    ////////////
    event WorkerListed(address indexed worker);
    event WorkerRemoved(address indexed worker);
    event RewardWithdrawn(address indexed worker, uint256 amount);
    event RewardGranted(address indexed worker, uint256 indexed rewards);
    event VoteUpdated(address indexed worker, string postId, string optionId);

    ////////////
    // STRUCT //
    ////////////
    struct Worker {
        address id;
        uint256 rewards;
        bool listed;
    }

    /////////////////////
    // DATA STRUCTURES //
    /////////////////////

    mapping(address => bool) public s_WorkerListed; // worker address => Listed
    mapping(address => uint256) private s_turksReward; // worker address => Turk Reward
    mapping(address => mapping(string => string)) private s_votedPostOption; // worker add => Post id => option id

    //////////////
    // MODIFIER //
    //////////////
    modifier Listed(address worker) {
        if (s_WorkerListed[worker]) {
            revert Workers__Exist();
        }
        _;
    }

    modifier WorkersExist(address[] memory workers) {
        for (uint i = 0; i < workers.length; i++) {
            if (!s_WorkerListed[workers[i]]) {
                revert Workers__DoesNotExist(workers[i]);
            }
        }
        _;
    }

    constructor() {}

    ////////////////////////
    // METHODS - Updaters //
    ////////////////////////

    // Add a new worker to the list
    function initWorker() public Listed(msg.sender) {
        s_WorkerListed[msg.sender] = true;
        s_turksReward[msg.sender] = 0;

        emit WorkerListed(msg.sender);
    }

    // Remove a worker from the list
    function removeWorker() public {
        if (!s_WorkerListed[msg.sender]) {
            revert Workers__DoesNotExist(msg.sender);
        }

        if (s_turksReward[msg.sender] != 0) {
            revert Workers__WithdrawRewardsBeforeDeleting();
        }

        s_WorkerListed[msg.sender] = false;
        emit WorkerRemoved(msg.sender);
    }

    // Update rewards for workers
    function updateRewards(
        address[] memory workers,
        uint256[] memory rewards
    ) public WorkersExist(workers) {
        if (workers.length != rewards.length) {
            revert Workers__FalsePayload();
        }

        for (uint i = 0; i < workers.length; i++) {
            s_turksReward[workers[i]] += rewards[i];
            emit RewardGranted(workers[i], rewards[i]);
        }
    }

    // Update voting mappings
    function updateVotingMapping(
        address[] memory workers,
        string[] memory postIds,
        string[] memory optionIds
    ) public WorkersExist(workers) {
        if (
            workers.length != postIds.length ||
            workers.length != optionIds.length
        ) {
            revert Workers__FalsePayload();
        }

        for (uint i = 0; i < workers.length; i++) {
            s_votedPostOption[workers[i]][postIds[i]] = optionIds[i];
            emit VoteUpdated(workers[i], postIds[i], optionIds[i]);
        }
    }

    function withdrawRewards() public {
        uint256 reward = s_turksReward[msg.sender];

        if (reward == 0) {
            revert Workers__NoRewards();
        }

        // Check-Effects-Interactions :: No chance of Renetrancy Attack
        s_turksReward[msg.sender] = 0;
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

// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db

// w_array = ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
// r_array = [20,25,10]
// p_array = ["post1", "post10", "post134"]
// o_array = ["option1", "option2", "option3"]
