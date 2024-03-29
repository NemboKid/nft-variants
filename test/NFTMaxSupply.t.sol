// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {NFTMaxSupply} from "../src/NFTMaxSupply.sol";
import {Staking} from "../src/Staking.sol";
import "forge-std/Test.sol";

contract NFTTest is Test {
    NFTMaxSupply public nftToken;
    Staking public stakingContract;
    address public alice = address(0x1);

    mapping(address => bool) public bitmap;

    function setUp() public {
        // the root hash calculated by airdrop/createRoot.js
        bytes32 merkleRoot = 0x581a551ee3da46db27b5137205608eeb8e8782a16c59b39b7d3b0f4ce6941e27;
        vm.startPrank(address(0x99));

        // deploy contract with the root
        nftToken = new NFTMaxSupply(merkleRoot);

        stakingContract = new Staking();
        vm.stopPrank();
    }

    function testClaimAirDrop() public {
        bytes32[] memory proof = new bytes32[](3);

        // sibling hashes
        // these are created for the first address in the list by running createRoot.js
        // so this should all be created and generated by our frontend app, based on the connected wallet
        proof[0] = 0xf353f716d3541b880c2a0976e5d2e97e9cc26e94b5047655d70e06fc91226bfc;
        proof[1] = 0xe547c10dc9fba1baaf0fae9c86df305d1a8792e502662c8411a8c5915ef79142;
        proof[2] = 0xace29d2de6f39ce1169949442b8119fbc87383f97ca34b2b273c0bc8649f63fc;

        uint256 index = 0;
        uint256 amount = 1;

        assertEq(nftToken.balanceOf(alice), 0);
        hoax(alice, 5 ether);
        nftToken.mintTokenWithDiscount{value: 0.8 ether}(amount, index, proof);

        assertEq(nftToken.balanceOf(alice), 1);
    }

    function testSuccessfulStaking() public {
        testClaimAirDrop();
        vm.startPrank(alice);
        nftToken.approve(address(stakingContract), 1);
        stakingContract.stake(alice, address(nftToken), 1);
        uint256[] memory userStakings = stakingContract.getUserStakings(alice);
        assertEq(userStakings.length, 1, "Staking count mismatch");
        vm.stopPrank();
    }

    function testUnstakingAndRewardCalculation() public {
        // Simulate staking and then waiting for 2 days
        testSuccessfulStaking();
        vm.warp(block.timestamp + 2 days);

        address preOwner = nftToken.ownerOf(1);
        assertEq(preOwner, address(stakingContract));

        uint256[] memory stakings = stakingContract.getUserStakings(alice);
        for (uint256 i = 0; i < stakings.length; ++i) {
            console.log("staking: ", stakings[i]);
        }

        (address user, address nftAddress, uint256 tokenId, uint256 stakingStartTime) = stakingContract.s_stakings(1);
        console.log(user, nftAddress, tokenId, stakingStartTime);

        vm.startPrank(alice);
        stakingContract.unstake(1);
        uint256 aliceBalance = stakingContract.i_coolToken().balanceOf(alice);
        console.log("alice balance: ", aliceBalance);

        address postOwner = nftToken.ownerOf(1);
        assertEq(postOwner, address(alice));

        assertGt(aliceBalance, 0, "Reward not received");
        vm.stopPrank();
    }
}
