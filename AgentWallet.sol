// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AgentWallet
 * @dev Manages budgets and compliance for autonomous AI agents on Pharos L1.
 */
contract AgentWallet {
    address public owner;
    
    // Mapping to store authorized AI agents and their daily spending limits
    mapping(address => uint256) public agentLimits;
    mapping(address => uint256) public agentSpentToday;
    mapping(address => uint256) public lastActiveTimestamp;

    event AgentAuthorized(address indexed agent, uint256 dailyLimit);
    event PaymentRouted(address indexed agent, address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Authorize a new AI agent and set its daily transaction limit
    function authorizeAgent(address _agent, uint256 _dailyLimit) external onlyOwner {
        agentLimits[_agent] = _dailyLimit;
        lastActiveTimestamp[_agent] = block.timestamp;
        emit AgentAuthorized(_agent, _dailyLimit);
    }

    // Execute an autonomous payment initiated by the AI agent
    function executeAgentPayment(address payable _recipient, uint256 _amount) external {
        require(agentLimits[msg.sender] > 0, "Unauthorized agent");
        
        // Reset daily spent amount if 24 hours have passed
        if (block.timestamp >= lastActiveTimestamp[msg.sender] + 1 days) {
            agentSpentToday[msg.sender] = 0;
            lastActiveTimestamp[msg.sender] = block.timestamp;
        }

        require(agentSpentToday[msg.sender] + _amount <= agentLimits[msg.sender], "Daily spending limit exceeded");
        require(address(this).balance >= _amount, "Insufficient wallet balance");

        agentSpentToday[msg.sender] += _amount;
        _recipient.transfer(_amount);

        emit PaymentRouted(msg.sender, _recipient, _amount);
    }

    // Deposit funds into the smart contract
    receive() external payable {}
}
