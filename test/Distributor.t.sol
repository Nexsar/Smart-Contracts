// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Turks.sol";

contract TurksTest is Test {
    Turks private turks;
    address distributor = address(0x123);
    address distributor2 = address(0x456);

    function setUp() public {
        turks = new Turks();
        vm.deal(distributor, 10 ether);
        vm.deal(distributor2, 5 ether);
    }

    // Test initialization of distributor
    function testInitDistributorSuccess() public {
        string[] memory optionIds;
        string[] memory imageUrls;
        optionIds[0] = "option1";
        optionIds[1] = "option2";
        optionIds[2] = "option3";
        imageUrls[0] = "image1";
        imageUrls[1] = "image2";
        imageUrls[2] = "image3";

        // Simulate distributor initialization with valid inputs
        vm.prank(distributor);
        turks.initDistributor{value: 5 ether}(
            true,
            5 ether,
            10,
            "post1",
            "description1",
            optionIds,
            imageUrls
        );

        // Check the distributor exists
        assertTrue(turks.distributorExist[distributor]);

        // Check distributor budget
        assertEq(turks.getBudget(distributor), 5 ether);

        // Check if the post is properly initialized
        Turks.Post memory post = turks.getParticularPost(distributor, "post1");
        assertEq(post.id, "post1");
        assertEq(post.description, "description1");

        // Check if the options are initialized
        Turks.Option[] memory options = turks.getAllOptions("post1");
        assertEq(options[0].id, "option1");
        assertEq(options[1].id, "option2");
        assertEq(options[2].id, "option3");
        assertEq(options[0].imageUrl, "image1");
    }

    // // Test failure on duplicate distributor
    // function testFailInitDuplicateDistributor() public {
    //     turks.initDistributor{value: 5 ether}(true, 5 ether, 10, "post2", "description2", new string , new s );
    //     ould revert because distributor exists
    //     vm.expectRevert(Turks.Turks__DistributorExists.selector);
    //     turks.initDistributor{value: 5 ether}(true, 5 ether, 10, "post2", "description2", new string , new string );}

    // // Teding a post
    // function testAddPost() public {
    //     string[] memory optionIds = ney imageUrls = ne "option1";
    //     optionIds[1] = "option2";
    //     optionIds[2] = "option3";
    //     imageUrls[0] = "image1";
    //     imageUrls[1] = "image2";
    //     imageUrls[2] = "image3";

    //     turks.AddPost("post2", "description2", optionIds, imageUrls, distributor);

    //     Turks.Post memory post = turks.getParticularPost(distributor, "post2");
    //     assertEq(post.id, "post2");
    //     assertEq(post.optionIds[0], "option1");
    // }

    // // Test failure when adding duplicate post
    // function testFailAddDuplicatePost() public {
    //     string[] memory optionIds = ney imageUrls = ne "option1";
    //     optionIds[1] = "option2";
    //     optionIds[2] = "option3";
    //     imageUrls[0] = "image1";
    //     imageUrls[1] = "image2";
    //     imageUrls[2] = "image3";

    //     turks.AddPost("post2", "description2", optionIds, imageUrls, distributor);
    //     // Reverts due to existing postId
    //     vm.expectRevert(Turks.Post_Exist.selector);
    //     turks.AddPost("post2", "description2", optionIds, imageUrls, distributor);
    // }

    // // Test depositing ETH
    // function testDepositETH() public {
    //     uint256 initialBudget = turks.getBudget(distributor);
    //     turks.depositETH{value: 1 ether}();
    //     assertEq(turks.getBudget(distributor), initialBudget + 1 ether);
    // }

    // // Test withdrawal of ETH
    // function testWithdrawETH() public {
    //     uint256 initialBudget = turks.getBudget(distributor);
    //     turks.withdrawETH(1 ether);
    //     assertEq(turks.getBudget(distributor), initialBudget - 1 ether);
    // }

    // // Test failure when withdrawing more than available balance
    // function testFailWithdrawExceedsBalance() public {
    //     turks.withdrawETH(10 ether);
    // }

    // // Test updating post description
    // function testUpdateDescription() public {
    //     turks.updateDescription("new description", "post1", distributor);
    //     Turks.Post memory post = turks.getParticularPost(distributor, "post1");
    //     assertEq(post.description, "new description");
    // }

    // // Test vote updating
    // function testUpdateVotes() public {
    //     uint64[] memory votes = new uiy optionIds = ne "option1";
    //     optionIds[1] = "option2";
    //     optionIds[2] = "option3";
    //     votes[0] = 10;
    //     votes[1] = 20;
    //     votes[2] = 30;

    //     turks.updateVotes(votes, optionIds, distributor, "post1");

    //     Turks.Option[] memory options = turks.getAllOptions("post1");
    //     assertEq(options[0].vote, 10);
    //     assertEq(options[1].vote, 20);
    //     assertEq(options[2].vote, 30);
    // }

    // // Test worker initialization
    // function testInitWorker() public {
    //     turks.initWorker();
    //     assertTrue(turks.s_WorkerListed(worker));
    // }

    // // Test worker rewards
    // function testWorkerRewards() public {
    //     address[] memory workers = new orker;
    //     turks.updateRewards(workers, 100);
    //     assertEq(turks.getRewards(worker), 100);
    // }

    // // Test reward withdrawal
    // function testWithdrawRewards() public {
    //     address[] memory workers = new orker;
    //     turks.updateRewards(workers, 100);
    //     turks.withdrawRewards();
    //     assertEq(turks.getRewards(worker), 0);
    // }

    // // Test failure when reward is 0
    // function testFailWithdrawRewardsWithZero() public {
    //     vm.expectRevert(Turks.Turks__AmountLessThanEqual0.selector);
    //     turks.withdrawRewards();
    // }

    // // Test vote mappings for workers
    // function testVotingMapping() public {
    //     address[] memory workers = new y postIds = new y optionIds = neorker;
    //     postIds[0] = "post1";
    //     optionIds[0] = "option1";

    //     turks.updateVotingMapping(workers, postIds, optionIds);
    //     assertEq(turks.getVotedOption(worker, "post1"), "option1");
    // }

    // // Test failure if worker does not exist
    // function testFailUpdateRewardsWorkerDNE() public {
    //     address[] memory workers = new ddress(0x789);
    //     vm.expectRevert(Turks.Turks__WorkerDNE.selector);
    //     turks.updateRewards(workers, 100);
    // }
}
