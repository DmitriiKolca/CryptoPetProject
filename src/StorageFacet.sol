pragma solidity ^0.8.0;

struct NftStats {
    address owner;
    string nickName;
    string customURI;

    uint32 wins;
    uint32 losses;
    uint32 ratingPoints;
    uint256 totalPrizeTokens;
}

struct GameStorage {
    mapping(uint256 nftId => NftStats stats) nftStats;
}

struct Admins {
    mapping(address userAddresss => bool isAdmin) adminList;
}

contract StorageFacet {
    bytes32 private constant STORAGE_GAME_FACET_POSITION = keccak256("diamond.game.facet.position");

    function getStorage() internal pure returns(GameStorage storage gameStore){
        bytes32 position = STORAGE_GAME_FACET_POSITION;
        assembly{
            gameStore.slot := position
        }
        return gameStore;
    }

    bytes32 private constant STORAGE_ADMINS_FACET_POSITION = keccak256("diamond.admins.facet.position");

    function getAdmins() internal pure returns(Admins storage adminStore){
        bytes32 position = STORAGE_ADMINS_FACET_POSITION;
        assembly{
            adminStore.slot := position
        }
        return adminStore;
    }
}