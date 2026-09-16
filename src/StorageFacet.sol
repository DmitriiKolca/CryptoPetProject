pragma solidity ^0.8.0;

struct NftStats {
    uint256 omnichainId;
    uint256 uiId;
    uint256 originChainId;
    address creator;

    address owner;
    string nickName;
    string customURI;

    uint32 wins;
    uint32 losses;
    uint32 ratingPoints;
    uint256 totalPrizeTokens;
}

struct GameStorage {
    mapping(uint256 omnichainId => NftStats stats) nftStats;
}

struct Admins {
    mapping(address userAddresss => bool isAdmin) adminList;
}

struct Omnichain {
    address lzEndpoint; // Адрес контракта LayerZero Endpoint V2 в этой сети
    mapping(uint32 destinationEndpointId  => bytes32 trustedDiamondPeer) trustedPeers; // Доверенные контракты Diamond в других сетях
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

    bytes32 private constant STORAGE_OMNICHAIN_FACET_POSITION = keccak256("diamond.omnichain.facet.position");

    function getOmnichainStore() internal pure returns(Omnichain storage omnichainStore){
        bytes32 position = STORAGE_OMNICHAIN_FACET_POSITION;
        assembly{
            omnichainStore.slot := position
        }
        return omnichainStore;
    }
}