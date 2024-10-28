// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

contract NFTMarketplaceTest is Test {

    NFTMarketplace market;
    uint256 listingPrice = 0.0015 ether;
    address owner;
    address user1;

    event ItemCreated(uint256 indexed tokenId, address seller, address owner, uint256 price, bool sold);

    function setUp() public {
      owner = vm.addr(1);
      user1 = vm.addr(2);
      vm.deal(user1, 1 ether);
      market = new NFTMarketplace(owner);
    }

    function test_getListingPrice() public view {
      uint256 price = market.getListingPrice();
      assertEq(price, 0.0015 ether);
    }

    function test_updateListingPrice() public {
      uint256 _listingPrice = 0.002 ether;
      market.updateListingPrice(_listingPrice);
      uint256 price = market.getListingPrice();
      assertEq(price, listingPrice);
    }

    function test_updateListingPriceShouldFailWithOnlyOwnerError() public {
      vm.prank(vm.addr(1));
      uint256 _listingPrice = 0.002 ether;
      vm.expectRevert(abi.encodeWithSelector(NFTMarketplace.OnlyOwnerError.selector));
      market.updateListingPrice(_listingPrice);
    }

    function test_craeteToken() public {
      vm.prank(user1);

      vm.expectEmit(true, true, true, true);
      emit ItemCreated(1, address(user1), address(market), listingPrice, false);

      uint256 tokenId = market.createToken{value: listingPrice}("test uri", listingPrice);
      assertTrue(tokenId > 0);
    }

}
