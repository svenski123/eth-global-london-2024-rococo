// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.21;
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Voucher is Ownable, ERC1155 {

    event PromoterAdded(address indexed promoter,
			uint16 rebateBPS);

    event PromoterRemoved(address indexed promoter);

    event OfferPurchased(address indexed purchaser,
			 address indexed recipient,
			 uint256 indexed offerId,
			 uint256 price,
			 uint256 rebate);

    event OfferRedeembed(address indexed redeemer,
			 uint256 indexed offerId);

    struct Offer {
	uint price;
	uint64 expiry;
	uint32 numIssued;
	uint32 issueLimit;
    }

    struct Promoter {
	address promoter;
	uint16 rebateBPS;
    }

    mapping (uint256 => Offer) public offers;
    mapping (address => Promoter) public promoters;
    uint256 public lastOfferId;

    constructor() Ownable(_msgSender()) ERC1155("") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function addPromoter(address payable _promoter, uint16 _rebateBPS) public onlyOwner {
	require(_promoter != address(0x0));
	require(_rebateBPS <= 10000);
	promoters[_promoter] = Promoter(_promoter, _rebateBPS);
	emit PromoterAdded(_promoter, _rebateBPS);
    }

    function removePromoter(address _promoter) public onlyOwner {
	require(_promoter != address(0x0));
	require(promoters[_promoter].promoter != address(0x0));
	delete promoters[_promoter];
	emit PromoterRemoved(_promoter);
    }

    function queryOffer(uint256 _id) view external returns (Offer memory) {
	require(_id > 0);
	return offers[_id];
    }

    function createOffer(uint64 _expiry,
			 uint _price,
			 uint32 _issueLimit) external onlyOwner {
	require(_expiry > block.timestamp);
	require(_issueLimit > 0);
	lastOfferId++;
	offers[lastOfferId] = Offer(_price, _expiry, 0, _issueLimit);
	emit TransferSingle(_msgSender(), address(0x0), address(0x0), lastOfferId, 0);
    }

    function purchaseOffer(address _deliverTo,
			   address _promoter,
			   uint256 _id) external payable {
	require(_deliverTo != address(0x0));
	require(_promoter != address(0x0));
	require(_id > 0 && _id <= lastOfferId);

	Promoter memory promoter = promoters[_promoter];
	require(promoter.promoter == _promoter);

	Offer memory offer = offers[_id];
	require(offer.expiry >= block.timestamp);
	require(offer.numIssued < offer.issueLimit);
	require(offer.price == msg.value);

	_mint(_deliverTo, _id, 1, "");
	offers[_id].numIssued++;

	uint rebate;
	if (promoter.rebateBPS > 0) {
	    rebate = msg.value / 10000 * promoter.rebateBPS;
	    payable(promoter.promoter).transfer(rebate);
	}

	emit OfferPurchased(_msgSender(),
			    _deliverTo,
			    _id,
			    offer.price,
			    rebate);
    }

    function redeemOffer(uint256 _id) external {
	require(_id > 0 && _id <= lastOfferId);

	_burn(_msgSender(), _id, 1);

	emit OfferRedeembed(_msgSender(), _id);
    }
}
