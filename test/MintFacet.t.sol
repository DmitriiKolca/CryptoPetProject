// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import "../src/StorageFacet.sol";
import {MintFacet} from "../src/MintFacet.sol";
import {IDiamondCut} from "../lib/diamond-3-hardhat/contracts/interfaces/IDiamondCut.sol";
import {Diamond} from "../lib/diamond-3-hardhat/contracts/Diamond.sol";
import {DiamondCutFacet} from "../lib/diamond-3-hardhat/contracts/facets/DiamondCutFacet.sol";
import {ERC721MetadataStorage} from "@solidstate-network/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";

import {DeployDiamondScript} from "../script/DeployDiamond.s.sol";

import {console} from "../lib/forge-std/src/console.sol";

contract MintFacetTest is Test {
    Diamond public diamond;
    DiamondCutFacet public diamondCutFacetInstance;
    MintFacet public mintFacetAsDiamond;
    MintFacet public mintFacetInstance;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    function setUp() public {
        DeployDiamondScript deployer = new DeployDiamondScript();
        DeployDiamondScript.DeploymentResult memory result = deployer.run(owner);

        mintFacetAsDiamond = MintFacet(result.diamondAddress);
    }

    /*  Tests for getNft function */
    function test_getNft_ShouldRevert_WhenNftNotExist() public {
        uint256 notExistNftId = 2;

        vm.expectRevert(bytes4(keccak256("ERC721Base__NonExistentToken()")));
        mintFacetAsDiamond.getNft(notExistNftId);
    }
    function test_getNft_ShouldSuccess() public {
        vm.prank(user1);
        uint256 firstTokenId = mintFacetAsDiamond.mint();

        NftStats memory firstNftStats = mintFacetAsDiamond.getNft(firstTokenId);
        assertEq(firstNftStats.owner, user1);
        assertEq(firstNftStats.ratingPoints, 100);
        assertEq(firstNftStats.wins, 0);
        assertEq(firstNftStats.losses, 0);
    }

    /*  Tests for getWalletNftIds function */
    function test_getWalletNftIds_ShouldReturnEmptyArray_WhenUserHaveNotNfts() public {
        uint256[] memory initialNfts = mintFacetAsDiamond.getWalletNftIds(user1);
        assertEq(initialNfts.length, 0);
    }
    function test_getWalletNftIds_ShouldReturnCorrectArray_WhenUserHaveNfts() public {
        vm.startPrank(user1);
        uint256 id1 = mintFacetAsDiamond.mint();
        uint256 id2 = mintFacetAsDiamond.mint();
        uint256 id3 = mintFacetAsDiamond.mint();
        vm.stopPrank();

        uint256[] memory playerNfts = mintFacetAsDiamond.getWalletNftIds(user1);

        assertEq(playerNfts.length, 3);
        assertEq(playerNfts[0], id1);
        assertEq(playerNfts[1], id2);
        assertEq(playerNfts[2], id3);
    }

    /*  Tests for mint function */
    function test_mint_Success_And_StatsInitialization() public {
        vm.prank(user1);
        uint256 firstTokenId = mintFacetAsDiamond.mint();
        assertEq(firstTokenId, 1);
        assertEq(mintFacetAsDiamond.ownerOf(firstTokenId), user1);
        assertEq(mintFacetAsDiamond.balanceOf(user1), 1);

        NftStats memory firstNftStats = mintFacetAsDiamond.getNft(firstTokenId);
        assertEq(firstNftStats.owner, user1);
        assertEq(firstNftStats.ratingPoints, 100);
        assertEq(firstNftStats.wins, 0);
        assertEq(firstNftStats.losses, 0);

        vm.prank(user2);
        uint256 secondTokenId = mintFacetAsDiamond.mint();
        assertEq(secondTokenId, 2);
        assertEq(mintFacetAsDiamond.ownerOf(secondTokenId), user2);
        assertEq(mintFacetAsDiamond.balanceOf(user1), 1);
        assertEq(mintFacetAsDiamond.balanceOf(user2), 1);

        NftStats memory secondNftStats = mintFacetAsDiamond.getNft(secondTokenId);
        assertEq(secondNftStats.owner, user2);
        assertEq(secondNftStats.ratingPoints, 100);
        assertEq(secondNftStats.wins, 0);
        assertEq(secondNftStats.losses, 0);
    }
}
