// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/diamond-3-hardhat/contracts/libraries/LibDiamond.sol";
import "../lib/solidstate-solidity/contracts/token/ERC721/SolidStateERC721.sol";
import "./StorageFacet.sol";
import {ERC721MetadataStorage} from "@solidstate-network/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";
import {ERC165BaseStorage} from "@solidstate-network/contracts/introspection/ERC165/base/ERC165BaseStorage.sol";

contract InitFacet is StorageFacet {
    function init(string memory _name, string memory _symbol, string memory _baseUri) external {
        LibDiamond.enforceIsContractOwner();
        address contractOwner = LibDiamond.contractOwner();

        Admins storage adminStore = getAdmins();
        adminStore.adminList[contractOwner] = true;

        ERC721MetadataStorage.Layout storage metadataLayout = ERC721MetadataStorage.metadataLayout();
        metadataLayout.name = _name;
        metadataLayout.symbol = _symbol;
        metadataLayout.baseURI = _baseUri;

        ERC165BaseStorage.Layout storage erc165Layout = ERC165BaseStorage.metadataLayout();
        erc165Layout.supportedInterfaces[0x01ffc9a7] = true; // ERC165 interface ID
        erc165Layout.supportedInterfaces[0x80ac58cd] = true; // ERC721 interface ID
        erc165Layout.supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata interface ID

    }
}
