// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Turks} from "../src/Turks.sol";

contract TurksTest is Test {
    Turks turks;
    address owner;
    address distributor1;
    address distributor2;
    address worker1;
    address worker2;

    function setUp() public {
        turks = new Turks();
        owner = address(this);
        distributor1 = address(0x1);
        distributor2 = address(0x2);
        worker1 = address(0x3);
        worker2 = address(0x4);
        vm.deal(distributor1, 100 ether);
        vm.deal(distributor2, 100 ether);
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

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post1",
            "Test post",
            optionIds,
            imageUrls
        );

        assertEq(turks.getBudget(distributor1), 10 ether);
        assertTrue(turks.distributorExist(distributor1));
    }

    function testFailInitDistributorInsufficientBalance() public {
        string[] memory optionIds = new string[](3);
        string[] memory imageUrls = new string[](3);

        vm.prank(distributor1);
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

        vm.prank(distributor1);
        turks.depositETH{value: 5 ether}();

        assertEq(turks.getBudget(distributor1), 15 ether);
    }

    function testWithdrawETH() public {
        testInitDistributor();

        uint256 initialBalance = distributor1.balance;

        vm.prank(distributor1);
        turks.withdrawETH(5 ether);

        assertEq(turks.getBudget(distributor1), 5 ether);
        assertEq(distributor1.balance, initialBalance + 5 ether);
    }

    function testFailWithdrawETHInsufficientBalance() public {
        testInitDistributor();

        vm.prank(distributor1);
        turks.withdrawETH(15 ether);
    }

    function testAddPost() public {
        testInitDistributor();

        string[] memory postIds = new string[](2);
        postIds[0] = "post2";
        postIds[1] = "post3";

        string[] memory descriptions = new string[](2);
        descriptions[0] = "Second post";
        descriptions[1] = "Third post";

        string[][] memory arrayOptionIds = new string[][](2);
        string[][] memory arrayImageUrls = new string[][](2);

        for (uint i = 0; i < 2; i++) {
            arrayOptionIds[i] = new string[](3);
            arrayImageUrls[i] = new string[](3);

            for (uint j = 0; j < 3; j++) {
                arrayOptionIds[i][j] = string(
                    abi.encodePacked("option", i + 1, j + 1)
                );
                arrayImageUrls[i][j] = string(
                    abi.encodePacked("url", i + 1, j + 1)
                );
            }
        }

        vm.prank(distributor1);
        turks.AddPosts(
            postIds,
            descriptions,
            arrayOptionIds,
            arrayImageUrls,
            distributor1
        );

        Turks.Post[] memory posts = turks.getAllPosts(distributor1);
        assertEq(posts.length, 3);
        assertEq(posts[1].id, "post2"); // As first post was already created by initDistributor in `testInitDistributor`
        assertEq(posts[2].id, "post3");
        assertEq(posts[1].description, "Second post");
        assertEq(posts[2].description, "Third post");
    }

    function testUpdateBudget() public {
        testInitDistributor();

        vm.prank(distributor1);
        turks.updateBudget{value: 5 ether}(5 ether, distributor1);

        assertEq(turks.getBudget(distributor1), 15 ether);
    }

    function testUpdateDescription() public {
        testInitDistributor();

        vm.prank(distributor1);
        turks.updateDescription("Updated description", "post1", distributor1);

        Turks.Post memory post = turks.getParticularPost(distributor1, "post1");
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

        turks.updateVotes(votes, optionIds, distributor1, "post1");

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

        Turks.Post[] memory posts = turks.getAllPosts(distributor1);
        assertEq(posts.length, 3); // 1 already created by `testInitDistributor`(1) in `AddPost`(2)
        assertEq(posts[0].id, "post1");
        assertEq(posts[1].id, "post2");
        assertEq(posts[2].id, "post3");
    }

    function testGetParticularPost() public {
        testInitDistributor();

        Turks.Post memory post = turks.getParticularPost(distributor1, "post1");
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

    function testMultipleDistributors() public {
        string[] memory optionIds1 = new string[](3);
        optionIds1[0] = "option11";
        optionIds1[1] = "option12";
        optionIds1[2] = "option13";

        string[] memory optionIds2 = new string[](3);
        optionIds2[0] = "option21";
        optionIds2[1] = "option22";
        optionIds2[2] = "option23";

        string[] memory imageUrls = new string[](3);
        imageUrls[0] = "url1";
        imageUrls[1] = "url2";
        imageUrls[2] = "url3";

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post1",
            "Test post 1",
            optionIds1,
            imageUrls
        );

        vm.prank(distributor2);
        turks.initDistributor{value: 20 ether}(
            true,
            20 ether,
            2,
            "post2",
            "Test post 2",
            optionIds2,
            imageUrls
        );

        assertEq(turks.getBudget(distributor1), 10 ether);
        assertEq(turks.getBudget(distributor2), 20 ether);

        Turks.Post[] memory posts1 = turks.getAllPosts(distributor1);
        Turks.Post[] memory posts2 = turks.getAllPosts(distributor2);

        assertEq(posts1.length, 1);
        assertEq(posts2.length, 1);
        assertEq(posts1[0].id, "post1");
        assertEq(posts2[0].id, "post2");
    }

    function testMultipleDistributorsCannotHaveSamePostId() public {
        string[] memory optionIds1 = new string[](3);
        optionIds1[0] = "option11";
        optionIds1[1] = "option12";
        optionIds1[2] = "option13";

        string[] memory optionIds2 = new string[](3);
        optionIds2[0] = "option21";
        optionIds2[1] = "option22";
        optionIds2[2] = "option23";

        string[] memory imageUrls = new string[](3);
        imageUrls[0] = "url1";
        imageUrls[1] = "url2";
        imageUrls[2] = "url3";

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post1",
            "Test post 1",
            optionIds1,
            imageUrls
        );

        vm.prank(distributor2);
        vm.expectRevert(Turks.Turks__PostExist.selector);
        turks.initDistributor{value: 20 ether}(
            true,
            20 ether,
            2,
            "post1",
            "Test post 2",
            optionIds2,
            imageUrls
        );
    }

    function testMultipleDistributorsCannotHaveSameOptionIds() public {
        string[] memory optionIds = new string[](3);
        optionIds[0] = "option1";
        optionIds[1] = "option2";
        optionIds[2] = "option3";

        string[] memory imageUrls = new string[](3);
        imageUrls[0] = "url1";
        imageUrls[1] = "url2";
        imageUrls[2] = "url3";

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post1",
            "Test post 1",
            optionIds,
            imageUrls
        );

        vm.prank(distributor2);
        vm.expectRevert(Turks.Turks__OptionExists.selector);
        turks.initDistributor{value: 20 ether}(
            true,
            20 ether,
            2,
            "post2",
            "Test post 2",
            optionIds,
            imageUrls
        );
    }

    function testComplexVotingScenario() public {
        testInitDistributor();

        vm.prank(worker1);
        turks.initWorker();
        vm.prank(worker2);
        turks.initWorker();

        address[] memory workers = new address[](2);
        workers[0] = worker1;
        workers[1] = worker2;

        string[] memory postIds = new string[](2);
        postIds[0] = "post1";
        postIds[1] = "post1";

        string[] memory optionIds = new string[](2);
        optionIds[0] = "option1";
        optionIds[1] = "option2";

        turks.updateVotingMapping(workers, postIds, optionIds);

        uint64[] memory votes = new uint64[](3);
        votes[0] = 1;
        votes[1] = 1;
        votes[2] = 0;

        string[] memory allOptionIds = new string[](3);
        allOptionIds[0] = "option1";
        allOptionIds[1] = "option2";
        allOptionIds[2] = "option3";

        turks.updateVotes(votes, allOptionIds, distributor1, "post1");

        Turks.Option[] memory options = turks.getAllOptions("post1");
        assertEq(options[0].vote, 1);
        assertEq(options[1].vote, 1);
        assertEq(options[2].vote, 0);

        assertEq(turks.getTotalVotesOnPost("post1"), 2);
        assertEq(turks.getVotedOption(worker1, "post1"), "option1");
        assertEq(turks.getVotedOption(worker2, "post1"), "option2");
    }

    function testRewardDistributionAndWithdrawal() public {
        testInitDistributor();

        vm.prank(worker1);
        turks.initWorker();
        vm.prank(worker2);
        turks.initWorker();

        address[] memory workers = new address[](2);
        workers[0] = worker1;
        workers[1] = worker2;

        // Fund the contract
        dealToContract(3 ether);

        // Distribute rewards
        turks.updateRewards(workers, 1 ether);

        // Check rewards
        assertEq(turks.getRewards(worker1), 1 ether);
        assertEq(turks.getRewards(worker2), 1 ether);

        // Withdraw rewards
        uint256 initialBalance1 = worker1.balance;
        uint256 initialBalance2 = worker2.balance;

        vm.prank(worker1);
        turks.withdrawRewards();
        vm.prank(worker2);
        turks.withdrawRewards();

        // Check balances after withdrawal
        assertEq(worker1.balance, initialBalance1 + 1 ether);
        assertEq(worker2.balance, initialBalance2 + 1 ether);

        // Check rewards are reset
        assertEq(turks.getRewards(worker1), 0);
        assertEq(turks.getRewards(worker2), 0);

        // Try to withdraw again (should fail)
        vm.expectRevert(Turks.Turks__AmountLessThanEqual0.selector);
        vm.prank(worker1);
        turks.withdrawRewards();
    }

    function testPostLifecycle() public {
        testInitDistributor();

        // Add a new post
        string[] memory postIds = new string[](1);
        postIds[0] = "post2";

        string[] memory descriptions = new string[](1);
        descriptions[0] = "Second post";

        string[][] memory arrayOptionIds = new string[][](1);
        arrayOptionIds[0] = new string[](3);
        arrayOptionIds[0][0] = "option4";
        arrayOptionIds[0][1] = "option5";
        arrayOptionIds[0][2] = "option6";

        string[][] memory arrayImageUrls = new string[][](1);
        arrayImageUrls[0] = new string[](3);
        arrayImageUrls[0][0] = "url4";
        arrayImageUrls[0][1] = "url5";
        arrayImageUrls[0][2] = "url6";

        vm.prank(distributor1);
        turks.AddPosts(
            postIds,
            descriptions,
            arrayOptionIds,
            arrayImageUrls,
            distributor1
        );

        // Update post description
        vm.prank(distributor1);
        turks.updateDescription("Updated second post", "post2", distributor1);

        // Vote on the post
        uint64[] memory votes = new uint64[](3);
        votes[0] = 5;
        votes[1] = 3;
        votes[2] = 2;

        string[] memory optionIds = new string[](3);
        optionIds[0] = "option4";
        optionIds[1] = "option5";
        optionIds[2] = "option6";

        turks.updateVotes(votes, optionIds, distributor1, "post2");

        // Check post details
        Turks.Post memory post = turks.getParticularPost(distributor1, "post2");
        assertEq(post.description, "Updated second post");

        Turks.Option[] memory options = turks.getAllOptions("post2");
        assertEq(options[0].vote, 5);
        assertEq(options[1].vote, 3);
        assertEq(options[2].vote, 2);

        assertEq(turks.getTotalVotesOnPost("post2"), 10);
    }

    function testUnauthorizedAccess() public {
        testMultipleDistributors();

        // Try to add posts as non-distributor1
        string[] memory postIds = new string[](1);
        postIds[0] = "post21";
        string[] memory descriptions = new string[](1);
        descriptions[0] = "Unauthorized post";
        string[][] memory arrayOptionIds = new string[][](1);
        arrayOptionIds[0] = new string[](3);
        arrayOptionIds[0][0] = "option21_1";
        arrayOptionIds[0][1] = "option21_2";
        arrayOptionIds[0][2] = "option21_3";
        string[][] memory arrayImageUrls = new string[][](1);
        arrayImageUrls[0] = new string[](3);

        vm.prank(distributor1);
        turks.AddPosts(
            postIds,
            descriptions,
            arrayOptionIds,
            arrayImageUrls,
            distributor2
        );

        // Try to update description as non-distributor1
        vm.expectRevert(Turks.Turks__UnAuthorisedAccess.selector);
        vm.prank(distributor2);
        turks.updateDescription("Unauthorized update", "post1", distributor1);

        // Try to update budget as non-distributor1
        vm.expectRevert(Turks.Turks__UnAuthorisedAccess.selector);
        vm.prank(distributor2);
        turks.updateBudget(1 ether, distributor1);

        // Try to update votes as non-owner
        uint64[] memory votes = new uint64[](3);
        string[] memory optionIds = new string[](3);
        vm.expectRevert(Turks.Turks__UnAuthorisedAccess.selector);
        vm.prank(distributor2);
        turks.updateVotes(votes, optionIds, distributor1, "post1");
    }

    function testNonDistributorCannotCreatePost() public {
        string[] memory postIds = new string[](1);
        postIds[0] = "post2";
        string[] memory descriptions = new string[](1);
        descriptions[0] = "Unauthorized post";
        string[][] memory arrayOptionIds = new string[][](1);
        arrayOptionIds[0] = new string[](3);
        string[][] memory arrayImageUrls = new string[][](1);
        arrayImageUrls[0] = new string[](3);

        vm.expectRevert(Turks.Turks__DoesNotExist.selector);
        vm.prank(worker1);
        turks.AddPosts(
            postIds,
            descriptions,
            arrayOptionIds,
            arrayImageUrls,
            worker1
        );
    }

    function testFailInitDistributorNotListed() public {
        string[] memory optionIds0 = new string[](3);
        string[] memory imageUrls0 = new string[](3);

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post2",
            "Test post 2",
            optionIds0,
            imageUrls0
        );

        address random = makeAddr("Random");
        vm.deal(random, 11 ether);

        string[] memory optionIds = new string[](3);
        string[] memory imageUrls = new string[](3);

        vm.expectRevert(Turks.Turks__BadPayload.selector);
        vm.prank(random);
        turks.initDistributor{value: 10 ether}(
            false, // not listed
            10 ether,
            1,
            "post1",
            "Test post",
            optionIds,
            imageUrls
        );
    }

    function testFailInitDistributorAlreadyExists() public {
        string[] memory optionIds = new string[](3);
        string[] memory imageUrls = new string[](3);

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post2",
            "Test post 2",
            optionIds,
            imageUrls
        );

        vm.prank(distributor1);
        vm.expectRevert(Turks.Turks__DistributorExists.selector);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post21",
            "Test post 2",
            optionIds,
            imageUrls
        );
    }

    function testFailUpdateDescriptionNonExistentPost() public {
        string[] memory optionIds = new string[](3);
        string[] memory imageUrls = new string[](3);

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post2",
            "Test post 2",
            optionIds,
            imageUrls
        );

        vm.prank(distributor1);
        vm.expectRevert(Turks.Turks__PostDoesNotExist.selector);
        turks.updateDescription(
            "Updated description",
            "nonexistentpost",
            distributor1
        );
    }

    function testFailUpdateVotesNonExistentOption() public {
        string[] memory optionIds0 = new string[](3);
        string[] memory imageUrls0 = new string[](3);

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post2",
            "Test post 2",
            optionIds0,
            imageUrls0
        );

        uint64[] memory votes = new uint64[](3);
        string[] memory optionIds = new string[](3);
        optionIds[0] = "option1";
        optionIds[1] = "option2";
        optionIds[2] = "nonexistentoption";

        vm.expectRevert(Turks.Turks__DoesNotExist.selector);
        turks.updateVotes(votes, optionIds, distributor1, "post1");
    }

    function testFailGetAllPostsNonExistentDistributor() public {
        string[] memory optionIds0 = new string[](3);
        string[] memory imageUrls0 = new string[](3);

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post2",
            "Test post 2",
            optionIds0,
            imageUrls0
        );

        vm.expectRevert(Turks.Turks__DoesNotExist.selector);
        turks.getAllPosts(distributor2);
    }

    function testFailGetParticularPostNonExistent() public {
        string[] memory optionIds0 = new string[](3);
        string[] memory imageUrls0 = new string[](3);

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post2",
            "Test post 2",
            optionIds0,
            imageUrls0
        );

        vm.expectRevert(Turks.Turks__PostDNE.selector);
        turks.getParticularPost(distributor1, "nonexistentpostcncpaihf-qp");
    }

    function testFailGetAllOptionsNonExistentPost() public {
        string[] memory optionIds0 = new string[](3);
        string[] memory imageUrls0 = new string[](3);

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post2",
            "Test post 2",
            optionIds0,
            imageUrls0
        );

        vm.expectRevert(Turks.Turks__PostDNE.selector);
        turks.getAllOptions("nonexistentpost");
    }

    function testFailGetTotalVotesOnPostNonExistent() public {
        string[] memory optionIds0 = new string[](3);
        string[] memory imageUrls0 = new string[](3);

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post2",
            "Test post 2",
            optionIds0,
            imageUrls0
        );

        vm.expectRevert(Turks.Turks__PostDNE.selector);
        turks.getTotalVotesOnPost("nonexistentpost");
    }

    function testFailInitWorkerTwice() public {
        string[] memory optionIds0 = new string[](3);
        string[] memory imageUrls0 = new string[](3);

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post2",
            "Test post 2",
            optionIds0,
            imageUrls0
        );

        vm.prank(worker1);
        turks.initWorker();

        vm.expectRevert(Turks.Turks__WorkersExists.selector);
        vm.prank(worker1);
        turks.initWorker();
    }

    function testFailUpdateRewardsNonExistentWorker() public {
        address[] memory workers = new address[](1);
        workers[0] = worker1; // worker1 is not initialized

        vm.expectRevert(Turks.Turks__WorkerDNE.selector);
        turks.updateRewards(workers, 1 ether);
    }

    function testFailUpdateVotingMappingMismatchedArrays() public {
        address[] memory workers = new address[](2);
        string[] memory postIds = new string[](1);
        string[] memory optionIds = new string[](2);

        vm.expectRevert(Turks.Turks__BadPayload.selector);
        turks.updateVotingMapping(workers, postIds, optionIds);
    }

    function testFailWithdrawETHUnauthorized() public {
        testInitDistributor();

        vm.prank(worker1);
        vm.expectRevert(Turks.Turks__UnAuthorisedAccess.selector);
        turks.withdrawETH(1 ether);
    }

    function testGetFrequency() public {
        testInitDistributor();

        vm.prank(distributor1);
        uint256 frequency = turks.getFrequency(distributor1);
        assertEq(frequency, 1);
    }

    function testFailGetFrequencyUnauthorized() public {
        string[] memory optionIds0 = new string[](3);
        string[] memory imageUrls0 = new string[](3);

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post2",
            "Test post 2",
            optionIds0,
            imageUrls0
        );

        vm.prank(worker1);
        vm.expectRevert(Turks.Turks__UnAuthorisedAccess.selector);
        turks.getFrequency(distributor1);
    }

    function testFailGetFrequencyNonExistentDistributor() public {
        string[] memory optionIds0 = new string[](3);
        string[] memory imageUrls0 = new string[](3);

        vm.prank(distributor1);
        turks.initDistributor{value: 10 ether}(
            true,
            10 ether,
            1,
            "post2",
            "Test post 2",
            optionIds0,
            imageUrls0
        );

        // Unauthorized
        vm.expectRevert(Turks.Turks__UnAuthorisedAccess.selector);
        vm.prank(worker1);
        turks.getFrequency(distributor1);

        // Non Existent
        vm.expectRevert(Turks.Turks__DoesNotExist.selector);
        vm.prank(distributor2);
        turks.getFrequency(distributor2);
    }
}
