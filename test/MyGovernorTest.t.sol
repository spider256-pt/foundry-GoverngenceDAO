//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Box} from "../src/Box.sol";
import {GovToken} from "../src/GovToken.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {Timelock} from "../src/Timelock.sol";

contract TestMyGovernor is Test {
    MyGovernor governor;
    Box box;
    Timelock timelock;
    GovToken govToken;

    address USER = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 100 ether;
    uint256 public constant MIN_DELAY = 3600;
    // uint256 public constant VOTING_DELAY = 1;
    // uint256 public constant VOTING_PERIOD = 50400;
    address[] proposers;
    address[] executors;
    uint256[] values;
    bytes[] calldatas;
    address[] targets;

    function setUp() public {
        govToken = new GovToken();
        govToken.mint(USER, INITIAL_SUPPLY);
        vm.startPrank(USER);
        govToken.delegate(USER);

        timelock = new Timelock(MIN_DELAY, proposers, executors);
        governor = new MyGovernor(govToken, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.grantRole(adminRole, USER);
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timelock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 420;
        string memory description = "Update box value to 420 for clout";
        bytes memory encodedFunctionCall = abi.encodeWithSignature(
            "store(uint256)",
            valueToStore
        );

        calldatas.push(encodedFunctionCall);
        values.push(0);
        targets.push(address(box));

        // Propose
        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            description
        );

        console.log("Proposal state 1:", uint256(governor.state(proposalId)));
        uint256 currentDelay = governor.votingDelay();
        vm.warp(block.timestamp + currentDelay + 1);
        vm.roll(block.number + currentDelay + 1);
        console.log("Proposal state 2", uint256(governor.state(proposalId)));

        //Vote
        string
            memory reason = "420 is cool number. cool number for cool people";

        vm.startPrank(USER);
        governor.castVoteWithReason(proposalId, 1, reason);
        uint256 currentPeriod = governor.votingPeriod();
        vm.warp(block.timestamp + currentPeriod + 1);
        vm.roll(block.number + currentPeriod + 1);

        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);

        //Execute the Proposal

        governor.execute(targets, values, calldatas, descriptionHash);

        console.log("Box value", box.getNumber());
        assertEq(box.getNumber(), valueToStore);
    }
}
