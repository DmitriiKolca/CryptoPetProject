// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/diamond-3-hardhat/contracts/libraries/LibDiamond.sol";
import "../lib/solidstate-solidity/contracts/token/ERC721/SolidStateERC721.sol";

import {ILayerZeroEndpointV2, MessagingParams, MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-protocol-v2/interfaces/ILayerZeroEndpointV2.sol";
import {StorageFacet, GameStorage, Omnichain, NftStats} from "./StorageFacet.sol";
import {SolidStateERC721} from "@solidstate-network/contracts/token/ERC721/SolidStateERC721.sol";

contract ONFTFacet is SolidStateERC721, StorageFacet {
    event LzNftSent(uint256 indexed omnichainId, uint32 dstEid, address indexed from, address indexed to);
    event LzNftReceived(uint256 indexed omnichainId, uint32 srcEid, address indexed to);

    function setLzEndpoint(address _lzEndpoint) external {
        LibDiamond.enforceIsContractOwner();

        getOmnichainStore().lzEndpoint = _lzEndpoint;
    }

    function setTrustedPeer(uint32 _endpointId, bytes32 _peer) external {
        LibDiamond.enforceIsContractOwner();

        getOmnichainStore().trustedPeers[_endpointId] = _peer;
    }

    function quote(
        uint32 _dstEid,
        uint256 _omniId,
        bytes calldata _options
    ) external view returns (uint256 nativeFee, uint256 lzTokenFee) {
        GameStorage storage gameStore = getStorage();
        Omnichain storage omnichainStore = getOmnichainStore();
        require(_omniId != 0, "ONFTFacet: token does not exist");

        NftStats memory stats = gameStore.nftStats[_omniId];

        bytes memory payload = abi.encode(_omniId, msg.sender, stats);

        MessagingParams memory params = MessagingParams({
            dstEid: _dstEid,
            receiver: omnichainStore.trustedPeers[_dstEid],
            message: payload,
            options: _options,
            payInLzToken: false
        });

        MessagingFee memory fee = ILayerZeroEndpointV2(omnichainStore.lzEndpoint).quote(params, address(this));
        return (fee.nativeFee, fee.lzTokenFee);
    }

    function send(
        uint32 _dstEid,
        uint256 _omniId,
        bytes calldata _options
    ) external payable returns (MessagingReceipt memory receipt) {
        GameStorage storage gameStore = getStorage();
        Omnichain storage omnichainStore = getOmnichainStore();

        require(_isApprovedOrOwner(msg.sender, _omniId), "ONFTFacet: not owner or approved");

        NftStats storage stats = gameStore.nftStats[_omniId];

        bytes32 peer = omnichainStore.trustedPeers[_dstEid];
        require(peer != bytes32(0), "ONFTFacet: peer not set for target network");

        _transfer(msg.sender, address(this), _omniId);

        stats.owner = address(this);

        bytes memory payload = abi.encode(_omniId, msg.sender, stats);

        MessagingParams memory params = MessagingParams({
            dstEid: _dstEid,
            receiver: peer,
            message: payload,
            options: _options,
            payInLzToken: false
        });

        receipt = ILayerZeroEndpointV2(omnichainStore.lzEndpoint).send{ value: msg.value }(params, msg.sender);

        emit LzNftSent(_omniId, _dstEid, msg.sender, address(this));
    }

    function lzReceive(
        uint32 _srcEid,
        bytes32 _sender,
        uint64 /*_nonce*/,
        bytes32 /*_guid*/,
        bytes calldata _message,
        bytes calldata /*_extraData*/
    ) external payable {
        require(msg.sender == getOmnichainStore().lzEndpoint, "ONFTFacet: caller must be LZ endpoint");

        Omnichain storage omnichainStore = getOmnichainStore();
        require(omnichainStore.trustedPeers[_srcEid] == _sender, "ONFTFacet: invalid sender peer");

        uint256 omniId;
        address originalSender;

        {
            GameStorage storage gameStore = getStorage();
            NftStats memory incomingStats;

            (omniId, originalSender, incomingStats) = abi.decode(
                _message,
                (uint256, address, NftStats)
            );

            NftStats storage localStats = gameStore.nftStats[omniId];

            if (localStats.omnichainId != 0) {
                localStats.wins = incomingStats.wins;
                localStats.losses = incomingStats.losses;
                localStats.ratingPoints = incomingStats.ratingPoints;
                localStats.totalPrizeTokens = incomingStats.totalPrizeTokens;
                localStats.owner = originalSender;

                _transfer(address(this), originalSender, omniId);
            } else {
                gameStore.nftStats[omniId] = incomingStats;
                gameStore.nftStats[omniId].owner = originalSender;

                _mint(originalSender, omniId);
            }
        }

        emit LzNftReceived(omniId, _srcEid, originalSender);
    }
}
