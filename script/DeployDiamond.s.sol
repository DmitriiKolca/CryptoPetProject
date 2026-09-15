// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Diamond} from "../lib/diamond-3-hardhat/contracts/Diamond.sol";
import {DiamondCutFacet} from "../lib/diamond-3-hardhat/contracts/facets/DiamondCutFacet.sol";
import {AdminFacet} from "../src/AdminFacet.sol";
import {MintFacet} from "../src/MintFacet.sol";
import {InitFacet} from "../src/InitFacet.sol";
import {IDiamondCut} from "../lib/diamond-3-hardhat/contracts/interfaces/IDiamondCut.sol";

contract DeployDiamondScript is Script {
    struct DeploymentResult {
        address diamondAddress;
        AdminFacet adminFacet;
        MintFacet mintFacet;
    }

    function run(address owner) external returns (DeploymentResult memory) {
        vm.startBroadcast(owner);

        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        Diamond diamond = new Diamond(owner, address(diamondCutFacet));

        AdminFacet adminFacet = new AdminFacet();
        InitFacet initFacet = new InitFacet();
        MintFacet mintFacet = new MintFacet();

        bytes4[] memory adminSelectors = getAdminSelectors();
        bytes4[] memory mintSelectors = getMintSelectors();

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);
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

       bytes memory initCallData = abi.encodeWithSignature(
            "init(string,string,string)",
            "My Crypto Game",
            "MCG",
            "https://avatars.mds.yandex.net/i?id=2730c6b9a82576cad8ea336decd83f47945a5c53-12373036-images-thumbs&n=13"
        );

        IDiamondCut(address(diamond)).diamondCut(cut, address(initFacet), initCallData);

        vm.stopBroadcast();

        return DeploymentResult({
            diamondAddress: address(diamond),
            adminFacet: adminFacet,
            mintFacet: mintFacet
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
        bytes4[] memory selectors = new bytes4[](12);
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
        return selectors;
    }
}
