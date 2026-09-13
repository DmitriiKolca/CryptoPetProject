pragma solidity ^0.8.0;

import "../lib/diamond-3-hardhat/contracts/libraries/LibDiamond.sol";
import {ERC721Facet} from "./ERC721Facet.sol";

contract AdminFacet is ERC721Facet{
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed oldAdmin);

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

        Admins storage adminStore = getAdmins();
        require(adminStore.adminList[_adminAddress], "Address is not an admin");

        adminStore.adminList[_adminAddress] = false;
        emit AdminRemoved(_adminAddress);
    }

    function setBaseURI(string calldata _newBaseURI) external {
        Admins storage adminsStore = getAdmins();
        require(adminsStore.adminList[msg.sender], "Caller is not Admin");

        GameStorage storage gameStore = getStorage();
        gameStore.baseTokenURI = _newBaseURI;
    }

    function setCustomURIByAdmin(uint256 _tokenId, string calldata _newURI) external {
        GameStorage storage gameStore = getStorage();
        require(gameStore.nftStats[_tokenId].customURI != address(0), "ERC721: token does not exist");

        Admins storage adminsStore = getAdmins();
        require(adminsStore.adminList[msg.sender], "Caller is not Admin");

        gameStore.nftStats[_tokenId].customURI = _newURI;
        emit URI(_newURI, _tokenId);
    }
}