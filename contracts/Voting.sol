// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting {
    address administratorAddress;
    WorkflowStatus workflowStatus = WorkflowStatus.RegisteringVoters;

    mapping(address => Voter) votersWhitelist;
    Proposal[] proposals;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    enum WorkflowStatus {
        RegisteringVoters, // 0
        ProposalsRegistrationStarted, // 1
        ProposalsRegistrationEnded, // 2
        VotingSessionStarted, // 3
        VotingSessionEnded, // 4
        VotesTallied // 5
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    constructor() {
        administratorAddress = msg.sender;
        votersWhitelist[msg.sender].isRegistered = true;
    }

    modifier isAdmin() {
        require(msg.sender == administratorAddress, "Not the admin");
        _;
    }

    modifier isVoterWhiteListed() {
        require(
            votersWhitelist[msg.sender].isRegistered,
            "Not in the whitelist"
        );
        _;
    }

    function setWorkflowStatus(WorkflowStatus _newWorkflowStatus)
        public
        isAdmin
    {
        WorkflowStatus previousStatus = workflowStatus;
        workflowStatus = _newWorkflowStatus;

        emit WorkflowStatusChange(previousStatus, _newWorkflowStatus);
    }

    function addVoterToWhitelist(address _voterAddress) public isAdmin {
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "Not in the registering voters phase"
        );

        votersWhitelist[_voterAddress].isRegistered = true;

        emit VoterRegistered(_voterAddress);
    }

    function getVoterFromWhitelist(address _voterAddress)
        public
        view
        isVoterWhiteListed
        returns (Voter memory)
    {
        return votersWhitelist[_voterAddress];
    }

    function addProposal(string memory _description) public isVoterWhiteListed {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Not in the registering proposals phase"
        );
        Proposal storage proposal = proposals.push();
        proposal.description = _description;

        uint256 idx = proposals.length - 1;

        emit ProposalRegistered(idx);
    }

    function getProposal(uint256 _idx)
        public
        view
        isVoterWhiteListed
        returns (Proposal memory)
    {
        return proposals[_idx];
    }

    function vote(uint56 _propositionID) public isVoterWhiteListed {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "Not in the voting phase"
        );
        require(
            votersWhitelist[msg.sender].hasVoted == false,
            "You already voted"
        );

        votersWhitelist[msg.sender].votedProposalId = _propositionID;
        votersWhitelist[msg.sender].hasVoted = true;

        proposals[_propositionID].voteCount += 1;

        emit Voted(msg.sender, _propositionID);
    }

    function getWinner() public view returns (Proposal memory) {
        require(
            workflowStatus == WorkflowStatus.VotesTallied,
            "Votes are not taillied"
        );
        uint256 winnerIDX = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > proposals[winnerIDX].voteCount) {
                winnerIDX = i;
            }
        }

        return proposals[winnerIDX];
    }
}
