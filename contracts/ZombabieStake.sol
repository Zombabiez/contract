// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZombabieStake is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    uint256 public totalStaked = 0;

    // Interfaces for ERC721
    IERC721 public immutable nftCollection;

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(IERC721 _nftCollection) {
        nftCollection = _nftCollection;
    }

    struct StakedToken {
        address staker;
        uint256 tokenId;
    }

    // Staker info
    struct Staker {
        // Amount of tokens staked by the staker
        uint256 amountStaked;
        // Staked token ids
        StakedToken[] stakedTokens;
        // Last time of the rewards were calculated for this user
        uint256 timeOfLastUpdate;
        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint256 unclaimedRewards;
    }

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;

    // Mapping of Token Id to staker. Made for the SC to remember
    // who to send back the ERC721 Token to.
    mapping(uint256 => address) public stakerAddress;

    // If address already has ERC721 Token/s staked, calculate the rewards.
    // Increment the amountStaked and map msg.sender to the Token Id of the staked
    // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    // value of now.
    function stake(uint256 _tokenId) external nonReentrant {
        // If wallet has tokens staked, calculate the rewards before adding the new token
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }

        // Wallet must own the token they are trying to stake
        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "You don't own this token!"
        );

        // Transfer the token from the wallet to the Smart contract
        nftCollection.transferFrom(msg.sender, address(this), _tokenId);

        // Create StakedToken
        StakedToken memory stakedToken = StakedToken(msg.sender, _tokenId);

        // Add the token to the stakedTokens array
        stakers[msg.sender].stakedTokens.push(stakedToken);

        // Increment the amount staked for this wallet
        stakers[msg.sender].amountStaked++;
        totalStaked++;

        // Update the mapping of the tokenId to the staker's address
        stakerAddress[_tokenId] = msg.sender;

        // Update the timeOfLastUpdate for the staker
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    // If address already has ERC721 Token/s staked, calculate the rewards.
    // Increment the amountStaked and map msg.sender to the Token Ids of the staked
    // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    // value of now.
    function batchStake(uint256[] memory _tokenIds) external nonReentrant {
        // If wallet has tokens staked, calculate the rewards before adding the new tokens
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }

        // Wallet must own the tokens they are trying to stake
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                nftCollection.ownerOf(_tokenIds[i]) == msg.sender,
                "You don't own these tokens!"
            );
        }

        require(
            nftCollection.isApprovedForAll(msg.sender, address(this)) == true,
            "You didn't approve"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // Transfer the token from the wallet to the Smart contract
            nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);

            // Create StakedToken
            StakedToken memory stakedToken = StakedToken(
                msg.sender,
                _tokenIds[i]
            );

            // Add the token to the stakedTokens array
            stakers[msg.sender].stakedTokens.push(stakedToken);

            // Increment the amount staked for this wallet
            stakers[msg.sender].amountStaked++;
            totalStaked++;

            // Update the mapping of the tokenId to the staker's address
            stakerAddress[_tokenIds[i]] = msg.sender;
        }

        // Update the timeOfLastUpdate for the staker
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    // Check if user has any ERC721 Tokens Staked and if they tried to withdraw,
    // calculate the rewards and store them in the unclaimedRewards
    // decrement the amountStaked of the user and transfer the ERC721 token back to them
    function withdraw(uint256 _tokenId) external nonReentrant {
        // Make sure the user has at least one token staked before withdrawing
        require(
            stakers[msg.sender].amountStaked > 0,
            "You have no tokens staked"
        );

        // Wallet must own the token they are trying to withdraw
        require(
            stakerAddress[_tokenId] == msg.sender,
            "You don't own this token!"
        );

        // Update the rewards for this user, as the amount of rewards decreases with less tokens.
        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;

        // Find the index of this token id in the stakedTokens array
        uint256 index = 0;
        for (uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
            if (
                stakers[msg.sender].stakedTokens[i].tokenId == _tokenId &&
                stakers[msg.sender].stakedTokens[i].staker != address(0)
            ) {
                index = i;
                break;
            }
        }

        // Set this token's .staker to be address 0 to mark it as no longer staked
        stakers[msg.sender].stakedTokens[index].staker = address(0);

        // Decrement the amount staked for this wallet
        stakers[msg.sender].amountStaked--;
        totalStaked--;

        // Update the mapping of the tokenId to the be address(0) to indicate that the token is no longer staked
        stakerAddress[_tokenId] = address(0);

        // Transfer the token back to the withdrawer
        nftCollection.transferFrom(address(this), msg.sender, _tokenId);

        // Update the timeOfLastUpdate for the withdrawer
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    // Check if user has any ERC721 Tokens Staked and if they tried to withdraw,
    // calculate the rewards and store them in the unclaimedRewards
    // decrement the amountStaked of the user and transfer the ERC721 token back to them
    function batchWithdraw(uint256[] memory _tokenIds) external nonReentrant {
        // Make sure the user has at least one token staked before withdrawing
        require(
            stakers[msg.sender].amountStaked > 0,
            "You have no tokens staked"
        );

        // Wallet must own the token they are trying to withdraw
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                stakerAddress[_tokenIds[i]] == msg.sender,
                "You don't own these tokens!"
            );
        }

        // Update the rewards for this user, as the amount of rewards decreases with less tokens.
        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // Find the index of this token id in the stakedTokens array
            uint256 index = 0;
            for (
                uint256 j = 0;
                j < stakers[msg.sender].stakedTokens.length;
                j++
            ) {
                if (
                    stakers[msg.sender].stakedTokens[j].tokenId ==
                    _tokenIds[i] &&
                    stakers[msg.sender].stakedTokens[j].staker != address(0)
                ) {
                    index = j;
                    break;
                }
            }

            // Set this token's .staker to be address 0 to mark it as no longer staked
            stakers[msg.sender].stakedTokens[index].staker = address(0);

            // Decrement the amount staked for this wallet
            stakers[msg.sender].amountStaked--;
            totalStaked--;

            // Update the mapping of the tokenId to the be address(0) to indicate that the token is no longer staked
            stakerAddress[_tokenIds[i]] = address(0);

            // Transfer the token back to the withdrawer
            nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }

        // Update the timeOfLastUpdate for the withdrawer
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    // Calculate rewards for the msg.sender, check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        payable(msg.sender).transfer(rewards);
    }

    function withdrawAllFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Receive Funds from external
    receive() external payable {
        // React to receiving ether
    }

    //////////
    // View //
    //////////

    function availableRewards(address _staker) public view returns (uint256) {
        uint256 rewards = calculateRewards(_staker) +
            stakers[_staker].unclaimedRewards;
        return rewards;
    }

    function getTotalStaked() public view returns (uint256) {
        return totalStaked;
    }

    function getMonthlyRate(address _staker) public view returns (uint256) {
        uint256 rewardsPerHour = getRewardPerHour();
        return stakers[_staker].amountStaked * rewardsPerHour * 24 * 30;
    }

    function getStakedTokens(address _user)
        public
        view
        returns (StakedToken[] memory)
    {
        // Check if we know this user
        if (stakers[_user].amountStaked > 0) {
            // Return all the tokens in the stakedToken Array for this user that are not -1
            StakedToken[] memory _stakedTokens = new StakedToken[](
                stakers[_user].amountStaked
            );
            uint256 _index = 0;

            for (uint256 j = 0; j < stakers[_user].stakedTokens.length; j++) {
                if (stakers[_user].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakers[_user].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        }
        // Otherwise, return empty array
        else {
            return new StakedToken[](0);
        }
    }

    //////////////
    // Internal //
    //////////////

    // Calculate rewards for param _staker by calculating the time passed
    // since last update in hours and mulitplying it to ERC721 Tokens Staked
    // and rewardsPerHour.
    function calculateRewards(address _staker) internal view returns (uint256) {
        uint256 rewardsPerHour = getRewardPerHour();
        return (((
            ((block.timestamp - stakers[_staker].timeOfLastUpdate) *
                stakers[_staker].amountStaked)
        ) * rewardsPerHour) / 3600);
    }

    function getRewardPerHour() internal view returns (uint256) {
        if (totalStaked == 0) return 0;
        return address(this).balance / totalStaked / (30 * 24);
    }
}
