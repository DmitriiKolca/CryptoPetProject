// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/diamond-3-hardhat/contracts/libraries/LibDiamond.sol";
import "../lib/solidstate-solidity/contracts/token/ERC721/SolidStateERC721.sol";
import "./StorageFacet.sol";
import {ERC721MetadataStorage} from "@solidstate-network/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";

contract InitFacet is SolidStateERC721, StorageFacet {
    function init(string calldata _name, string calldata _symbol, string calldata _baseUri) external {
        LibDiamond.enforceIsContractOwner();
        address contractOwner = LibDiamond.contractOwner();

        Admins storage adminStore = getAdmins();

        adminStore.adminList[contractOwner] = true;

        ERC721MetadataStorage.Layout storage metadataLayout = ERC721MetadataStorage.metadataLayout();
        metadataLayout.name = _name;
        metadataLayout.symbol = _symbol;
        metadataLayout.baseURI = _baseUri;
    }
}
