// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {CoolToken} from "./CoolToken.sol";

contract Staking is ERC721Holder {
    using SafeERC20 for IERC20;

    CoolToken public immutable i_coolToken;
    uint8 constant DAILY_TOKEN_REWARD = 10;

    uint256 private s_stakingIdCounter;
    mapping(uint256 => StakedNFT) public s_stakings;
    mapping(address => uint256[]) internal s_userStakings;

    struct StakedNFT {
        address user;
        address nftAddress;
        uint256 tokenId;
        uint256 stakingStartTime;
    }

    event NFTStaked(uint256 indexed tokenId, address indexed nftAddress, address indexed staker);
    event Unstaked(address indexed staker, uint256 stakingId);
    event StakingReward(address indexed payoutAddress, uint256 amount);

    constructor() {
        // deploy erc20 token
        i_coolToken = new CoolToken();
    }

    function stake(address staker, address nftAddress, uint256 tokenId) external {
        require(nftAddress != address(0), "NFT Address not valid");
        uint256 stakingId = ++s_stakingIdCounter;
        s_stakings[stakingId] = StakedNFT(staker, nftAddress, tokenId, block.timestamp);

        // push staking id to the user
        s_userStakings[staker].push(stakingId);

        // transfer nft to staking contract
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        emit NFTStaked(tokenId, nftAddress, msg.sender);
    }

    // withdraw nft function
    function unstake(uint256 stakingId) external {
        StakedNFT memory stakedNft = s_stakings[stakingId];

        require(stakedNft.user == msg.sender, "Not staked by caller");
        require(stakedNft.nftAddress != address(0), "Staking does not exist");

        // withdraw NFT and transfer it back
        IERC721(stakedNft.nftAddress).safeTransferFrom(address(this), msg.sender, stakedNft.tokenId);

        uint256 stakingDurationInSeconds = block.timestamp - stakedNft.stakingStartTime;
        uint256 daysStaked = stakingDurationInSeconds / 1 days;

        // Adjust for decimals: Multiply by 10 to the power of token decimals
        uint256 rewardAmount = daysStaked * DAILY_TOKEN_REWARD * 10 ** i_coolToken.decimals();

        // mint reward
        i_coolToken.mint(msg.sender, rewardAmount);
        emit StakingReward(msg.sender, rewardAmount);

        // cleanup
        delete s_stakings[stakingId];
        _removeStakingIdFromUser(msg.sender, stakingId);

        emit Unstaked(msg.sender, stakingId);
    }

    function getUserStakings(address user) external view returns (uint256[] memory) {
        return s_userStakings[user];
    }

    function _removeStakingIdFromUser(address user, uint256 stakingId) private {
        uint256[] storage userStakingIds = s_userStakings[user];
        for (uint256 i = 0; i < userStakingIds.length;) {
            if (userStakingIds[i] == stakingId) {
                userStakingIds[i] = userStakingIds[userStakingIds.length - 1];
                userStakingIds.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
    }
}
