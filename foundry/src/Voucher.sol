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
    uint256 public numOffers;

    constructor() Ownable(_msgSender()) ERC1155("") {}

    function _purchaseOfferTo(address _deliverTo,
			      address _promoter,
			      uint256 _id) internal {
	require(_deliverTo != address(0x0));
	require(_promoter != address(0x0));
	require(_id > 0 && _id <= numOffers);

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

    function _updatePromoter(address payable _promoter, uint16 _rebateBPS) internal onlyOwner {
	require(_promoter != address(0x0));
	require(_rebateBPS <= 10000);
	promoters[_promoter] = Promoter(_promoter, _rebateBPS);
	emit PromoterAdded(_promoter, _rebateBPS);
    }

    function _updatePromoters(address payable[] calldata _promoters, uint16[] calldata _rebatesBPS) internal onlyOwner {
	require(_promoters.length == _rebatesBPS.length);
	for (uint256 i = 0; i < _promoters.length; ++i) {
	    address promoter = _promoters[i];
	    require(promoter != address(0x0));
	    uint16 rebateBPS = _rebatesBPS[i];
	    require(_rebatesBPS[i] <= 10000);
            promoters[promoter] = Promoter(promoter, rebateBPS);
	    emit PromoterAdded(promoter, rebateBPS);
        }
    }

    function _removePromoter(address _promoter) internal onlyOwner {
	require(_promoter != address(0x0));
	require(promoters[_promoter].promoter != address(0x0));
	delete promoters[_promoter];
	emit PromoterRemoved(_promoter);
    }

    function _removePromoters(address[] calldata _promoters) public onlyOwner {
	for (uint256 i = 0; i < _promoters.length; ++i) {
	    address promoter = _promoters[i];
	    require(promoter != address(0x0));
	    require(promoters[promoter].promoter != address(0x0));
	    delete promoters[promoter];
	    emit PromoterRemoved(promoter);
	}
    }

    function setURI(string memory newuri) external onlyOwner {
        return _setURI(newuri);
    }

    function addPromoter(address payable _promoter, uint16 _rebateBPS) external onlyOwner {
	return _updatePromoter(_promoter, _rebateBPS);
    }

    function addPromoters(address payable[] calldata _promoters, uint16[] calldata _rebateBPS) external onlyOwner {
	return _updatePromoters(_promoters, _rebateBPS);
    }

    function removePromoter(address _promoter) public onlyOwner {
	return _removePromoter(_promoter);
    }

    function removePromoters(address[] calldata _promoters) public onlyOwner {
	return _removePromoters(_promoters);
    }

    function queryOffer(uint256 _id) view external returns (Offer memory) {
	require(_id > 0 && _id <= numOffers);
	return offers[_id];
    }

    function createOffer(uint64 _expiry,
			 uint _price,
			 uint32 _issueLimit) external onlyOwner {
	require(_expiry > block.timestamp);
	require(_issueLimit > 0);
	numOffers++;
	offers[numOffers] = Offer(_price, _expiry, 0, _issueLimit);
	emit TransferSingle(_msgSender(), address(0x0), address(0x0), numOffers, 0);
    }

    function extendOffer(uint256 _id,
			 uint64 _expiry,
			 uint32 _issueLimit) external onlyOwner {
	require(_id > 0 && _id <= numOffers);
	Offer memory offer = offers[_id];
	require(offer.expiry >= block.timestamp);
	if (_expiry > offer.expiry)
	    offers[_id].expiry = _expiry;
	if (_issueLimit > offer.issueLimit)
	    offers[_id].issueLimit = _issueLimit;
    }

    function purchaseOffer(address _promoter,
			   uint256 _id) external payable {
	return _purchaseOfferTo(_msgSender(), _promoter, _id);
    }

    function purchaseOfferTo(address _deliverTo,
			     address _promoter,
			     uint256 _id) external payable {
	return _purchaseOfferTo(_deliverTo, _promoter, _id);
    }

    function redeemOffer(uint256 _id) external {
	require(_id > 0 && _id <= numOffers);

	_burn(_msgSender(), _id, 1);

	emit OfferRedeembed(_msgSender(), _id);
    }

    function withdraw() external onlyOwner {
	require(address(this).balance > 0);
	payable(_msgSender()).transfer(address(this).balance);
    }

    function execute(address to, uint256 value, bytes calldata data, uint8 operation) external payable onlyOwner returns (bytes memory result) {
	require(operation == 0);
	bool success;
	(success, result) = to.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}
