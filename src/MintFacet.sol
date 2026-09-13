pragma solidity ^0.8.0;

import "./ERC721Facet.sol";

contract MintFacet is ERC721Facet {
    event NftMinted (uint256 nftId);

    function mintNft() external returns(uint256 nftId){
        GameStorage storage gameStore = getStorage();

        gameStore.lastNftId +=1;
        uint256 newId = gameStore.lastNftId;

        gameStore.userNfts[msg.sender].push(newId);
        gameStore.nftOwnedIndex[newId] = gameStore.userNfts[msg.sender].length;

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

        emit NftMinted(newId);
        // emit transfer for marketplaces
        emit Transfer(address(0), msg.sender, newId);
        return newId;
    }
}