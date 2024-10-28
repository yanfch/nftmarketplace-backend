// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFTMarketplace is ERC721URIStorage {
    
    uint256 private _tokenIds;
    uint256 private _itemsSold;

    uint256 listingPrice = 0.0015 ether;

    address payable owner;

    mapping(uint256 => Item) private idItem;

    struct Item {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event ItemCreated(uint256 indexed tokenId, address seller, address owner, uint256 price, bool sold);

    error OnlyOwnerError();
    error CreateItemPriceZeroError();
    error ResaleItemError();
    error SaleItemError();

    modifier OnlyOwner() {
        if (msg.sender == owner) {
            revert OnlyOwnerError();
        }
        _;
    }

    constructor(address _owner) ERC721("NFT DD Token", "DDNFT") {
        owner = payable(_owner);
    }

    function updateListingPrice(uint256 _listingPrice) public payable OnlyOwner {
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function createToken(string memory tokenURI, uint256 price) public payable returns (uint256) {
        _tokenIds++;

        uint256 newTokenId = _tokenIds;

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createItem(newTokenId, price);

        return newTokenId;
    }

    function createItem(uint256 tokenId, uint256 price) private {
        if (price == 0) {
            revert CreateItemPriceZeroError();
        }
        if (msg.value != listingPrice) {
            revert CreateItemPriceZeroError();
        }

        idItem[tokenId] = Item(tokenId, payable(msg.sender), payable(address(this)), price, false);

        _transfer(msg.sender, address(this), tokenId);

        emit ItemCreated(tokenId, msg.sender, address(this), price, false);
    }

    function resaleItem(uint256 tokenId, uint256 price) public payable {
        if (idItem[tokenId].owner != msg.sender) {
            revert OnlyOwnerError();
        }
        if (msg.value != listingPrice) {
            revert ResaleItemError();
        }
        idItem[tokenId].sold = false;
        idItem[tokenId].price = price;
        idItem[tokenId].seller = payable(msg.sender);
        idItem[tokenId].owner = payable(address(this));

        _itemsSold--;

        _transfer(msg.sender, address(this), tokenId);
    }

    function saleItem(uint256 tokenId) public payable {
        uint256 price = idItem[tokenId].price;
        if (msg.value == price) {
            revert SaleItemError();
        }

        // ???
        idItem[tokenId].owner = payable(msg.sender);
        idItem[tokenId].sold = true;
        idItem[tokenId].owner = payable(address(0));

        _itemsSold++;

        _transfer(address(this), msg.sender, tokenId);

        payable(owner).transfer(listingPrice);
        payable(idItem[tokenId].seller).transfer(msg.value);
    }

    function fetchItem() public view returns (Item[] memory) {
        uint256 itemCount = _tokenIds;
        uint256 unSoldItemCount = itemCount - _itemsSold;
        uint256 currentIndex;

        Item[] memory items = new Item[](unSoldItemCount);

        for (uint256 i = 0; i < itemCount; i++) {
            if (idItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                Item storage currentItem = idItem[currentId];
                items[currentId] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyNtf() public view returns (Item[] memory) {
        uint256 totalCount = _tokenIds;
        uint256 itemCount;
        uint256 currentIndex;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        Item[] memory items = new Item[](itemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if (idItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                Item storage currentItem = idItem[currentId];
                items[currentId] = currentItem;
                currentIndex += 1;
            }
        }


        return items;
    }

    function fetchItems() public view returns (Item[] memory) {
        uint256 totalCount = _tokenIds;
        uint256 itemCount;
        uint256 currentIndex;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        Item[] memory items = new Item[](itemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if (idItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                Item storage currentItem = idItem[currentId];
                items[currentId] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }
}
