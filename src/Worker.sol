// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Distributors} from "./Distributor.sol";

contract Workers {
    ////////////
    // ERRORS //
    ////////////
    error Workers__Exist();
    error Workers__DoesNotExist();
    error Workers__FalsePayload();
    error Workers__NoRewards();
    error Workers__WithdrawFailed();

    ////////////
    // EVENTS //
    ////////////
    event WorkerListed(address indexed worker);
    event RewardGranted(string indexed post_id);
    event VoteUpdated(address indexed worker, string post_id, string option_id);
    event WorkerRemoved(address indexed worker);
    event RewardWithdrawn(address indexed worker, uint256 amount);

    ////////////
    // STRUCT //
    ////////////
    struct Worker {
        address id;
        bool listed;
    }

    /////////////////////
    // DATA STRUCTURES //
    /////////////////////

    mapping(address worker => Worker worker_struct) public s_Workers;
    mapping(address worker => uint256 rewards) public s_turks_reward;
    mapping(address worker => mapping(bytes32 post_id => bytes32 option_id))
        public s_voted_post_option;

    //////////////
    // MODIFIER //
    //////////////
    modifier Listed(address worker) {
        if (s_Workers[worker].listed) {
            revert Workers__Exist();
        }
        _;
    }

    modifier WorkersExist(address[] memory workers) {
        for (uint i = 0; i < workers.length; i++) {
            if (!s_Workers[workers[i]].listed) {
                revert Workers__DoesNotExist();
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
        Worker storage worker = s_Workers[msg.sender];
        worker.id = msg.sender;
        worker.listed = true;

        emit WorkerListed(msg.sender);
    }

    // Remove a worker from the list
    function removeWorker(address worker) public {
        if (!s_Workers[worker].listed) {
            revert Workers__DoesNotExist();
        }
        delete s_Workers[worker];
        emit WorkerRemoved(worker);
    }

    // Update rewards for workers
    function updateRewards(
        address[] memory workers,
        uint256 prizepool,
        string memory post_id
    ) public WorkersExist(workers) {
        uint256 reward = prizepool / workers.length;

        for (uint i = 0; i < workers.length; i++) {
            s_turks_reward[workers[i]] += reward;
        }

        emit RewardGranted(post_id);
    }

    // Update voting mappings
    function updateVotingMapping(
        address[] memory workers,
        string[] memory post_id,
        string[] memory option_id
    ) public WorkersExist(workers) {
        if (
            workers.length != post_id.length ||
            workers.length != option_id.length
        ) {
            revert Workers__FalsePayload();
        }

        for (uint i = 0; i < workers.length; i++) {
            s_voted_post_option[workers[i]][
                keccak256(abi.encodePacked(post_id[i]))
            ] = keccak256(abi.encodePacked(option_id[i]));

            emit VoteUpdated(workers[i], post_id[i], option_id[i]);
        }
    }

    function withdrawRewards() public {
        uint256 reward = s_turks_reward[msg.sender];

        if (reward == 0) {
            revert Workers__NoRewards();
        }

        // Check-Effects-Interactions :: No chance of Renetrancy Attack
        s_turks_reward[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: reward}("");
        if (!success) {
            s_turks_reward[msg.sender] = reward;
            revert Workers__WithdrawFailed();
        }

        emit RewardWithdrawn(msg.sender, reward);
    }

    /////////////
    // GETTERS //
    /////////////

    function getWorker(address worker) public view returns (Worker memory) {
        return s_Workers[worker];
    }

    function getRewards(address worker) public view returns (uint256) {
        return s_turks_reward[worker];
    }

    function getVotedOption(
        address worker,
        string memory post_id
    ) public view returns (bytes32) {
        return
            s_voted_post_option[worker][keccak256(abi.encodePacked(post_id))];
    }

    function getAllWorkersRewards(
        address[] memory workers
    ) public view returns (uint256[] memory rewards) {
        rewards = new uint256[](workers.length);
        for (uint i = 0; i < workers.length; i++) {
            rewards[i] = s_turks_reward[workers[i]];
        }
    }

    // Function to allow contract to receive ETH
    receive() external payable {}
}
