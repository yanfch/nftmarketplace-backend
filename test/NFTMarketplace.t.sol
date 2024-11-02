// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

contract NFTMarketplaceTest is Test {
    NFTMarketplace market;
    uint256 listingPrice = 0.0015 ether;
    address owner;
    address seller;
    address buyer;

    event ItemCreated(uint256 indexed tokenId, address seller, address owner, uint256 price, bool sold);

    function setUp() public {
        owner = vm.addr(1);
        seller = vm.addr(2);
        buyer = vm.addr(3);
        vm.deal(seller, 1 ether);
        vm.deal(buyer, 1 ether);
        market = new NFTMarketplace(owner);
    }

    function test_getListingPrice_EqInitialPrice() public view {
        uint256 price = market.getListingPrice();
        assertEq(price, 0.0015 ether);
    }

    function test_updateListingPrice_EqUpdatePrice() public {
        uint256 _listingPrice = 0.002 ether;
        market.updateListingPrice(_listingPrice);
        uint256 price = market.getListingPrice();
        assertEq(price, _listingPrice);
    }

    function test_updateListingPrice_ShouldFailWithOnlyOwnerError() public {
        vm.prank(vm.addr(1));
        uint256 _listingPrice = 0.002 ether;
        vm.expectRevert(abi.encodeWithSelector(NFTMarketplace.OnlyOwnerError.selector));
        market.updateListingPrice(_listingPrice);
    }

    function test_craeteToken() public {
        vm.prank(seller);
        uint256 price = 0.01 ether;
        vm.expectEmit(true, true, true, true);
        emit ItemCreated(1, address(seller), address(market), price, false);

        uint256 tokenId = market.createToken{value: listingPrice}("test uri", 0.01 ether);
        assertTrue(tokenId > 0);
    }

    function test_saleItem() public {
        vm.prank(seller);
        uint256 salePrice = 0.01 ether;

        uint256 tokenId = market.createToken{value: listingPrice}("test uri", salePrice);

        vm.prank(buyer);
        uint256 purchasePrice = 0.01 ether;
        market.saleItem{value: purchasePrice}(tokenId);

        address _owner = market.ownerOf(tokenId);
        assertEq(_owner, buyer);

        uint256 buyerBalance = buyer.balance;
        console.log("buyer banlance: ", buyerBalance);
        assertEq(0.99 ether, buyerBalance);

        uint256 sellerBalance = seller.balance;
        console.log("saller banlance: ", sellerBalance);
        assertEq(1.0085 ether, sellerBalance);

        uint256 ownerBalance = owner.balance;
        console.log("owner banlance: ", ownerBalance);
        assertEq(0.0015 ether, ownerBalance);
    }

    function test_resallItem() public {
        vm.prank(seller);
        uint256 salePrice = 0.01 ether;
        uint256 tokenId = market.createToken{value: listingPrice}("test uri", salePrice);

        vm.prank(buyer);
        uint256 purchasePrice = salePrice;
        market.saleItem{value: purchasePrice}(tokenId);
        assertEq(0.99 ether, buyer.balance);

        vm.prank(buyer);
        uint256 reSallPrice = 0.02 ether;
        market.reSallItem{value: listingPrice}(tokenId, reSallPrice);
        assertEq(0.9885 ether, buyer.balance);

        // 1 on sale
        assertEq(0.0015 ether, address(market).balance);
        // 1 sold
        assertEq(0.0015 ether, owner.balance);
    }

    function test_fetchMarketItem() public {
        vm.startPrank(seller);
        uint256 salePrice = 0.01 ether;
        market.createToken{value: listingPrice}("test uri one", salePrice);
        market.createToken{value: listingPrice}("test uri two", salePrice);
        assertEq(2, market.fetchMarketItem().length);
        vm.stopPrank();
    }

    function test_fetchMyNFT() public {
        vm.startPrank(seller);
        uint256 salePrice = 0.01 ether;
        uint256 tokenOneId = market.createToken{value: listingPrice}("test uri one", salePrice);
        market.createToken{value: listingPrice}("test uri two", salePrice);
        vm.stopPrank();

        vm.prank(address(market));
        assertEq(2, market.fetchMyNFT().length);

        vm.startPrank(buyer);
        uint256 purchasePrice = salePrice;
        market.saleItem{value: purchasePrice}(tokenOneId);
        assertEq(0.99 ether, buyer.balance);
        assertEq(1, market.fetchMyNFT().length);
        vm.stopPrank();
    }

    function test_fetchItemsListed() public {
        uint256 salePrice = 0.01 ether;
        vm.startPrank(seller);
        market.createToken{value: listingPrice}("test uri one", salePrice);
        market.createToken{value: listingPrice}("test uri two", salePrice);
        assertEq(2, market.fetchItemsListed().length);
        vm.stopPrank();
    }
}
