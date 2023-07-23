// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ETHWaldo is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _creatorIds;
    Counters.Counter private _sponsorIds;
    Counters.Counter private _dealIds;

    struct Creator {
        uint256 id;
        address payable addr;
        string ipfsHash;
    }

    struct Sponsor {
        uint256 id;
        address payable addr;
        string ipfsHash;
        bool registered;
    }

    enum DealState {
        Pending,
        Approved,
        Rejected,
        Completed
    }

    struct Deal {
        uint256 id;
        string ipfsHash;
        string videoId;
        Creator creator;
        Sponsor sponsor;
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 viewCountRequirement;
        bool readyToRelease;
        DealState state;
        bool active;
    }

    address public manager;
    mapping(address => Creator) public creators;
    mapping(address => Sponsor) public sponsors;
    mapping(uint256 => Deal) public deals;

    event CreatorRegistered(uint256 id, address creator);
    event SponsorRegistered(uint256 id, address sponsor);
    event DealCreated(uint256 dealId, address sponsor, address creator, uint256 amount);
    event DealApproved(uint256 dealId);
    event DealRejected(uint256 dealId);
    event FundsReleased(uint256 dealId, uint256 amount);

    constructor(address _manager)  {
        manager = _manager;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only the manager contract can call this function");
        _;
    }


    function registerCreator(address payable _creator, string memory _ipfsHash) public {
        _creatorIds.increment();
        uint256 newId = _creatorIds.current();
        creators[_creator] = Creator(newId, _creator, _ipfsHash);
        emit CreatorRegistered(newId, _creator);
    }

    function registerSponsor(address payable _sponsor, string memory _ipfsHash) public {
        _sponsorIds.increment();
        uint256 newId = _sponsorIds.current();
        sponsors[_sponsor] = Sponsor(newId, _sponsor, _ipfsHash, true);
        emit SponsorRegistered(newId, _sponsor);
    }

    function createDeal(address payable _creator, uint256 _viewCountRequirement) public payable {
        require(msg.value > 0, "Must sponsor with some amount");
        require(sponsors[msg.sender].registered, "Sponsor not registered");

        Sponsor memory dealSponsor = sponsors[msg.sender];
        Creator memory dealCreator = creators[_creator];

        _dealIds.increment();
        uint256 newId = _dealIds.current();

        Deal memory newDeal = Deal({
            id: newId,
            ipfsHash: "",
            videoId: "",
            creator: dealCreator,
            sponsor: dealSponsor,
            totalAmount: msg.value,
            releasedAmount: 0,
            viewCountRequirement: _viewCountRequirement,
            readyToRelease: false,
            state: DealState.Pending,
            active: true
        });

        deals[newId] = newDeal;
        emit DealCreated(newId, dealSponsor.addr, dealCreator.addr, msg.value);
    }

    function approveDeal(uint256 _dealId) public {
        Deal storage deal = deals[_dealId];

        require(msg.sender == deal.creator.addr, "Only the creator can approve a deal");
        require(deal.state == DealState.Pending, "Deal must be in pending state");

        deal.state = DealState.Approved;

        emit DealApproved(_dealId);
    }

    function rejectDeal(uint256 _dealId) public {
        Deal storage deal = deals[_dealId];

        require(msg.sender == deal.creator.addr, "Only the creator can reject a deal");
        require(deal.state == DealState.Pending, "Deal must be in pending state");

        deal.state = DealState.Rejected;
        deal.sponsor.addr.transfer(deal.totalAmount);

        emit DealRejected(_dealId);
    }

    function setReadyToRelease(uint256 _dealId, uint256 _views) public onlyManager {
        Deal storage deal = deals[_dealId];

        require(_views >= deal.viewCountRequirement, "Views requirement not yet met");

        deal.readyToRelease = true;
    }

    function releaseFunds(uint256 _dealId) public {
        Deal storage deal = deals[_dealId];

        require(msg.sender == deal.sponsor.addr, "Only the sponsor can release funds");
        require(deal.state == DealState.Approved, "Deal not yet approved");
        require(deal.readyToRelease == true, "Deal is not ready to release funds");

        uint256 amountToRelease = deal.totalAmount - deal.releasedAmount;
        require(amountToRelease > 0, "No funds remaining to release");

        deal.releasedAmount += amountToRelease;
        deal.creator.addr.transfer(amountToRelease);

        if (deal.releasedAmount == deal.totalAmount) {
            deal.state = DealState.Completed;
        }

        emit FundsReleased(_dealId, amountToRelease);
    }

    function getDeal(uint256 _dealId) 
    public 
    view 
    returns (
        uint256 id,
        string memory ipfsHash,
        string memory videoId,
        address creator,
        address sponsor,
        uint256 totalAmount,
        uint256 releasedAmount,
        uint256 viewCountRequirement,
        bool readyToRelease,
        DealState state,
        bool active
    ) 
{
    Deal storage deal = deals[_dealId];
    return (
        deal.id,
        deal.ipfsHash,
        deal.videoId,
        deal.creator.addr,
        deal.sponsor.addr,
        deal.totalAmount,
        deal.releasedAmount,
        deal.viewCountRequirement,
        deal.readyToRelease,
        deal.state,
        deal.active
    );
}

}
