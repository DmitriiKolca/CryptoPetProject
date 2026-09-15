pragma solidity ^0.8.0;

import {NftStats, GameStorage} from "./StorageFacet.sol";
import {StorageFacet} from "./StorageFacet.sol";
import {SolidStateERC721} from "@solidstate-network/contracts/token/ERC721/SolidStateERC721.sol";
import {ERC721Metadata} from "@solidstate-network/contracts/token/ERC721/metadata/ERC721Metadata.sol";
import {IERC721Metadata} from "@solidstate-network/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import {ERC721MetadataStorage} from "@solidstate-network/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";

contract MintFacet is SolidStateERC721, StorageFacet {
    event NftMinted(uint256 indexed nftId, address indexed owner);

    function mint() external returns(uint256 nftId){
        uint256 newId = totalSupply() + 1;
        _mint(msg.sender, newId);

        GameStorage storage gameStore = getStorage();
        string memory uniqueNick = string.concat("Nft_", _toString(newId));

        gameStore.nftStats[newId] = NftStats({
            owner: msg.sender,
            nickName: uniqueNick,
            customURI: "",
            wins: 0,
            losses: 0,
            ratingPoints: 100,
            totalPrizeTokens: 0
        });

        emit NftMinted(newId, msg.sender);
        return newId;
    }

    function getNft(uint256 _nftId) external view returns(NftStats memory _nft){
        if (!_exists(_nftId)) revert ERC721Base__NonExistentToken();

        return getStorage().nftStats[_nftId];
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721Metadata, IERC721Metadata) returns (string memory) {
        if (!_exists(tokenId)) revert ERC721Base__NonExistentToken();

        GameStorage storage gameStore = getStorage();
        string memory customUri = gameStore.nftStats[tokenId].customURI;

        if (bytes(customUri).length > 0) {
            return customUri;
        }

        string memory base = ERC721MetadataStorage.metadataLayout().baseURI;
        if (bytes(base).length == 0) {
            return _toString(tokenId); // Если baseURI вообще пустой, возвращаем просто ID в виде строки
        }

        return string.concat(base, "_", _toString(tokenId));
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}