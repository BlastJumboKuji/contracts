// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Kuji is Ownable {
    address public rewardToken;
    address public signer;
    uint64 public startAt;
    uint64 public endAt;
    uint256 public price;
    mapping(bytes32 => bool) haveClaimed;

    event TicketBought(address indexed buyer, uint256 amount);
    event KujiInitiated(address indexed owner, address indexed rewardToken, uint64 startAt, uint64 endAt, uint256 price, address indexed signer);

    constructor(address tokenContract, uint64 _startAt, uint64 _endAt, uint256 _price, address _signer) Ownable(msg.sender) {
        rewardToken = tokenContract;
        startAt = _startAt;
        endAt = _endAt;
        signer = _signer;
        price = _price;
        emit KujiInitiated(owner(), tokenContract, _startAt, _endAt, _price, _signer);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function changeTime(uint64 _startAt, uint64 _endAt) external onlyOwner {
        startAt = _startAt;
        endAt = _endAt;
    }

    function buyTicket(uint256 amount) external payable {
        require(block.timestamp >= startAt, 'Not started yet');
        require(block.timestamp <= endAt, 'Ended');
        require(msg.value >= price * amount, 'Insufficient fund');
        if (msg.value > price * amount) {
            payable(msg.sender).transfer(msg.value - price * amount);
        }
        emit TicketBought(msg.sender, amount);
    }

    function claim(uint256 blockNumber, uint256 amount, bytes32 r, bytes32 s, uint8 v) public {
        bytes32 claimer = keccak256(abi.encodePacked(msg.sender, blockNumber));
        require(haveClaimed[claimer] == false, 'Already claimed');
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, blockNumber, amount));
        require(ecrecover(hash, v, r, s) == signer, 'Invalid signature');
        haveClaimed[claimer] = true;
        IERC20 token = IERC20(rewardToken);
        token.transfer(msg.sender, amount);
    }

    function batchClaim(uint256[] memory blockNumbers, uint256[] memory amounts, bytes32[] memory r, bytes32[] memory s, uint8[] memory v) external {
        require(blockNumbers.length == amounts.length, 'Invalid input');
        require(blockNumbers.length == r.length, 'Invalid input');
        require(blockNumbers.length == s.length, 'Invalid input');
        require(blockNumbers.length == v.length, 'Invalid input');
        for (uint256 i = 0; i < blockNumbers.length; i++) {
            claim(blockNumbers[i], amounts[i], r[i], s[i], v[i]);
        }
    }

    function withdraw(uint256 amt) external onlyOwner {
        IERC20 token = IERC20(rewardToken);
        payable(owner()).transfer(address(this).balance);
        token.transfer(owner(), amt);
    }

}
