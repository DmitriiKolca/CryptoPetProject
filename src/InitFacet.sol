// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/diamond-3-hardhat/contracts/libraries/LibDiamond.sol";
import "./StorageFacet.sol";

contract InitFacet is StorageFacet {
    function init() external {
        LibDiamond.enforceIsContractOwner();
        address contractOwner = LibDiamond.contractOwner();

        Admins storage adminStore = getAdmins();
        GameStorage storage gameStore = getStorage();

        adminStore.adminList[contractOwner] = true;

        if (gameStore.lastNftId == 0) {
            gameStore.name = "Dmitrii Nft";
            gameStore.symbol = "KDLNFT";
            gameStore.baseTokenURI = "avatars.mds.yandex.net/i?id=2730c6b9a82576cad8ea336decd83f47945a5c53-12373036-images-thumbs&n=13";
        }
    }
}
