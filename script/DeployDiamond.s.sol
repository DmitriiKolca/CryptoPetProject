// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AdminFacet} from "../src/AdminFacet.sol";
import {DiamondCutFacet} from "../lib/diamond-3-hardhat/contracts/facets/DiamondCutFacet.sol";
import {Diamond} from "../lib/diamond-3-hardhat/contracts/Diamond.sol";
import {IDiamondCut} from "../lib/diamond-3-hardhat/contracts/interfaces/IDiamondCut.sol";
import {InitFacet} from "../src/InitFacet.sol";
import {MintFacet} from "../src/MintFacet.sol";
import {ONFTFacet} from "../src/ONFTFacet.sol";
import {Script} from "forge-std/Script.sol";

contract DeployDiamondScript is Script {
    struct DeploymentResult {
        address diamondAddress;
        AdminFacet adminFacet;
        MintFacet mintFacet;
        ONFTFacet onftFacet;
    }

    function run(address owner) external returns (DeploymentResult memory) {
        vm.startBroadcast(owner);

        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        Diamond diamond = new Diamond(owner, address(diamondCutFacet));

        AdminFacet adminFacet = new AdminFacet();
        InitFacet initFacet = new InitFacet();
        MintFacet mintFacet = new MintFacet();
        ONFTFacet onftFacet = new ONFTFacet();

        bytes4[] memory adminSelectors = getAdminSelectors();
        bytes4[] memory mintSelectors = getMintSelectors();
        bytes4[] memory onftSelectors = getOnftSelectors();

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(adminFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: adminSelectors
        });
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(mintFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mintSelectors
        });
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(onftFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: onftSelectors
        });

        bytes memory initCallData = abi.encodeWithSelector(
            InitFacet.init.selector,
            "My Crypto Game",
            "MCG",
            "https://test.com",
            0x71c241632547D3B8c73154431345672324Ade15a
        );

        IDiamondCut(address(diamond)).diamondCut(cut, address(initFacet), initCallData);

        vm.stopBroadcast();

        return DeploymentResult({
            diamondAddress: address(diamond),
            adminFacet: adminFacet,
            mintFacet: mintFacet,
            onftFacet: onftFacet
        });
    }

    function getAdminSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = AdminFacet.addAdmin.selector;
        selectors[1] = AdminFacet.isAdmin.selector;
        selectors[2] = AdminFacet.removeAdmin.selector;
        selectors[3] = AdminFacet.setBaseURI.selector;
        selectors[4] = AdminFacet.setCustomNftURIByAdmin.selector;

        return selectors;
    }

    function getMintSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](14);
        selectors[0] = MintFacet.mint.selector;
        selectors[1] = bytes4(keccak256("balanceOf(address)"));
        selectors[2] = bytes4(keccak256("ownerOf(uint256)"));
        selectors[3] = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
        selectors[4] = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
        selectors[5] = bytes4(keccak256("transferFrom(address,address,uint256)"));
        selectors[6] = bytes4(keccak256("approve(address,uint256)"));
        selectors[7] = bytes4(keccak256("getApproved(uint256)"));
        selectors[8] = bytes4(keccak256("setApprovalForAll(address,bool)"));
        selectors[9] = bytes4(keccak256("isApprovedForAll(address,address)"));
        selectors[10] = bytes4(keccak256("tokenURI(uint256)"));
        selectors[11] = MintFacet.getNft.selector;
        selectors[12] = MintFacet.getWalletNftIds.selector;
        selectors[13] = bytes4(keccak256("totalSupply()"));

        return selectors;
    }

    function getOnftSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = ONFTFacet.setTrustedPeer.selector;
        selectors[1] = ONFTFacet.quote.selector;
        selectors[2] = ONFTFacet.send.selector;
        selectors[3] = ONFTFacet.lzReceive.selector;
        selectors[4] = ONFTFacet.setLzEndpoint.selector;

        return selectors;
    }


}
