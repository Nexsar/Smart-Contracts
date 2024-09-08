// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Turks.sol";

contract TurksTest is Test {
    Turks turks;
    address owner;
    address distributor;
    address worker1;
    address worker2;

    function setUp() public {
        turks = new Turks();
        owner = address(this);
        distributor = address(0x1);
        worker1 = address(0x2);
        worker2 = address(0x3);
        vm.deal(distributor, 100 ether);
        vm.deal(worker1, 1 ether);
        vm.deal(worker2, 1 ether);
    }

    function testInitDistributor() public {
        string[] memory optionIds = new string[](3);
        optionIds[0] = "option1";
        optionIds[1] = "option2";
        optionIds[2] = "option3";

        string[] memory imageUrls = new string[](3);
        imageUrls[0] = "url1";
        imageUrls[1] = "url2";
        imageUrls[2] = "url3";

        vm.prank(distributor);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post1",
            "Test post",
            optionIds,
            imageUrls
        );

        assertEq(turks.getBudget(distributor), 10 ether);
        assertTrue(turks.distributorExist(distributor));
    }

    function testFailInitDistributorInsufficientBalance() public {
        string[] memory optionIds = new string[](3);
        string[] memory imageUrls = new string[](3);

        vm.prank(distributor);
        turks.initDistributor{value: 5 ether}(
            true,
            10 ether,
            1,
            "post1",
            "Test post",
            optionIds,
            imageUrls
        );
    }

    function testDepositETH() public {
        testInitDistributor();

        vm.prank(distributor);
        turks.depositETH{value: 5 ether}();

        assertEq(turks.getBudget(distributor), 15 ether);
    }

    function testWithdrawETH() public {
        testInitDistributor();

        uint256 initialBalance = distributor.balance;

        vm.prank(distributor);
        turks.withdrawETH(5 ether);

        assertEq(turks.getBudget(distributor), 5 ether);
        assertEq(distributor.balance, initialBalance + 5 ether);
    }

    function testFailWithdrawETHInsufficientBalance() public {
        testInitDistributor();

        vm.prank(distributor);
        turks.withdrawETH(15 ether);
    }

    function testAddPost() public {
        testInitDistributor();

        string[] memory optionIds = new string[](3);
        optionIds[0] = "option4";
        optionIds[1] = "option5";
        optionIds[2] = "option6";

        string[] memory imageUrls = new string[](3);
        imageUrls[0] = "url4";
        imageUrls[1] = "url5";
        imageUrls[2] = "url6";

        vm.prank(distributor);
        turks.AddPost(
            "post2",
            "Second post",
            optionIds,
            imageUrls,
            distributor
        );

        Turks.Post[] memory posts = turks.getAllPosts(distributor);
        assertEq(posts.length, 2);
        assertEq(posts[1].id, "post2");
    }

    function testUpdateBudget() public {
        testInitDistributor();

        vm.prank(distributor);
        turks.updateBudget{value: 5 ether}(5 ether, distributor);

        assertEq(turks.getBudget(distributor), 15 ether);
    }

    function testUpdateDescription() public {
        testInitDistributor();

        vm.prank(distributor);
        turks.updateDescription("Updated description", "post1", distributor);

        Turks.Post memory post = turks.getParticularPost(distributor, "post1");
        assertEq(post.description, "Updated description");
    }

    function testUpdateVotes() public {
        testInitDistributor();

        uint64[] memory votes = new uint64[](3);
        votes[0] = 10;
        votes[1] = 20;
        votes[2] = 30;

        string[] memory optionIds = new string[](3);
        optionIds[0] = "option1";
        optionIds[1] = "option2";
        optionIds[2] = "option3";

        turks.updateVotes(votes, optionIds, distributor, "post1");

        Turks.Option[] memory options = turks.getAllOptions("post1");
        assertEq(options[0].vote, 10);
        assertEq(options[1].vote, 20);
        assertEq(options[2].vote, 30);
    }

    function testInitWorker() public {
        vm.prank(worker1);
        turks.initWorker();

        assertTrue(turks.s_WorkerListed(worker1));
    }

    function testUpdateRewards() public {
        vm.prank(worker1);
        turks.initWorker();

        vm.prank(worker2);
        turks.initWorker();

        address[] memory workers = new address[](2);
        workers[0] = worker1;
        workers[1] = worker2;

        turks.updateRewards(workers, 1 ether);

        assertEq(turks.getRewards(worker1), 1 ether);
        assertEq(turks.getRewards(worker2), 1 ether);
    }

    function testUpdateVotingMapping() public {
        vm.prank(worker1);
        turks.initWorker();

        address[] memory workers = new address[](1);
        workers[0] = worker1;

        string[] memory postIds = new string[](1);
        postIds[0] = "post1";

        string[] memory optionIds = new string[](1);
        optionIds[0] = "option1";

        turks.updateVotingMapping(workers, postIds, optionIds);

        assertEq(turks.getVotedOption(worker1, "post1"), "option1");
    }

    function testWithdrawRewards() public {
        vm.prank(worker1);
        turks.initWorker();

        address[] memory workers = new address[](1);
        workers[0] = worker1;

        // Fund the contract with ETH
        dealToContract(1 ether);

        turks.updateRewards(workers, 1 ether);

        uint256 initialBalance = worker1.balance;

        vm.prank(worker1);
        turks.withdrawRewards();

        assertEq(worker1.balance, initialBalance + 1 ether);
        assertEq(turks.getRewards(worker1), 0);
    }

    // Helper function to fund the contract with ETH
    function dealToContract(uint256 amount) internal {
        vm.deal(address(turks), amount);
    }

    function testFailWithdrawRewardsNoRewards() public {
        vm.prank(worker1);
        turks.initWorker();

        vm.prank(worker1);
        turks.withdrawRewards();
    }

    function testGetAllPosts() public {
        testAddPost();

        Turks.Post[] memory posts = turks.getAllPosts(distributor);
        assertEq(posts.length, 2);
        assertEq(posts[0].id, "post1");
        assertEq(posts[1].id, "post2");
    }

    function testGetParticularPost() public {
        testInitDistributor();

        Turks.Post memory post = turks.getParticularPost(distributor, "post1");
        assertEq(post.id, "post1");
        assertEq(post.description, "Test post");
    }

    function testGetAllOptions() public {
        testInitDistributor();

        Turks.Option[] memory options = turks.getAllOptions("post1");
        assertEq(options.length, 3);
        assertEq(options[0].id, "option1");
        assertEq(options[1].id, "option2");
        assertEq(options[2].id, "option3");
    }

    function testGetTotalVotesOnPost() public {
        testUpdateVotes();

        uint256 totalVotes = turks.getTotalVotesOnPost("post1");
        assertEq(totalVotes, 60);
    }
}
