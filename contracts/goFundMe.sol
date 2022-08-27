//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

error invalidState();
error notFactory();
error notOwner();
error failed();

contract goFundMe {
    address immutable factory;
    address public owner;

    uint256 public balance;
    uint256 public amountNeeded;
    uint256 public totalReceived;

    struct funders {
        address funder;
        uint amount;
    }

    enum State {
        StandBy,
        Funding,
        Completed
    }

    State public state;

    funders[] private fundersList;

    modifier onlyFactory() {
        if (msg.sender == factory) {
            _;
        } else {
            revert notFactory();
        }
    }

    modifier onlyOwner() {
        if (msg.sender == owner) {
            _;
        } else {
            revert notOwner();
        }
    }

    modifier inState(State state_) {
        if (state == state_) {
            _;
        } else {
            revert invalidState();
        }
    }

    constructor() {
        factory = msg.sender;
    }

    receive() external payable inState(State.Funding) 
    {
        if ((totalReceived + msg.value) > amountNeeded) {
            balance += msg.value;
            totalReceived += msg.value;
            fundersList.push(funders({funder: msg.sender, amount: msg.value}));
        } else {
            revert failed();
        }
    }

    function startFunding() external onlyOwner inState(State.StandBy) 
    {
        state = State.Funding;
    }

    function endFunding() external onlyOwner inState(State.Funding) 
    {
        state = State.Completed;
    }

    function pullFunds(uint256 _amount)
        external
        onlyOwner
        inState(State.Completed)
    {
        balance -= _amount;
        (bool sent, ) = payable(owner).call{value: _amount}("");
        if (!sent) revert failed();
    }

    function getBalance() external view returns (uint256) 
    {
        return balance;
    }

    function getFunders() external view returns (funders[] memory) 
    {
        return fundersList;
    }

    function initializer(address _owner, uint256 _amount) external onlyFactory 
    {
        owner = _owner;
        amountNeeded = _amount;
    }
}
