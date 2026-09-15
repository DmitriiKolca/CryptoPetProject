pragma solidity ^0.8.0;

import "../lib/diamond-3-hardhat/contracts/libraries/LibDiamond.sol";
import "../lib/solidstate-solidity/contracts/token/ERC721/SolidStateERC721.sol";
import "./StorageFacet.sol";
import {Admins, GameStorage} from "./StorageFacet.sol";
import {ERC721MetadataStorage} from "@solidstate-network/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";

contract AdminFacet is SolidStateERC721, StorageFacet {
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed oldAdmin);
    event AdminChangeURIEvent(uint256 indexed nftId, address indexed admin, string indexed newUri);

    function addAdmin(address _adminAddress) external {
        LibDiamond.enforceIsContractOwner();
        require(_adminAddress != address(0), "Admin cannot be zero address");

        Admins storage adminStore = getAdmins();
        require(!adminStore.adminList[_adminAddress], "Address is already admin");

        adminStore.adminList[_adminAddress] = true;
        emit AdminAdded(_adminAddress);
    }

    function isAdmin(address _user) external view returns (bool) {
        return getAdmins().adminList[_user];
    }

    function removeAdmin(address _adminAddress) external {
        LibDiamond.enforceIsContractOwner();
        require(_adminAddress != address(0), "Admin cannot be zero address");

        Admins storage adminStore = getAdmins();
        require(adminStore.adminList[_adminAddress], "Address is not an admin");

        adminStore.adminList[_adminAddress] = false;
        emit AdminRemoved(_adminAddress);
    }

    function setBaseURI(string calldata _newBaseURI) external {
        LibDiamond.enforceIsContractOwner();

        ERC721MetadataStorage.Layout storage metadataLayout = ERC721MetadataStorage.metadataLayout();
        metadataLayout.baseURI = _newBaseURI;
    }

    function setCustomNftURIByAdmin(uint256 _tokenId, string calldata _newURI) external {
        GameStorage storage gameStore = getStorage();
        require(gameStore.nftStats[_tokenId].owner != address(0), "ERC721: token does not exist");

        Admins storage adminsStore = getAdmins();
        require(adminsStore.adminList[msg.sender], "Caller is not Admin");

        gameStore.nftStats[_tokenId].customURI = _newURI;
        emit AdminChangeURIEvent(_tokenId, msg.sender, _newURI);
    }
}