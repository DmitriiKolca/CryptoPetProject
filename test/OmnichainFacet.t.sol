// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DeployDiamondScript} from "../script/DeployDiamond.s.sol";
import {ONFTFacet} from "../src/ONFTFacet.sol";
import {MintFacet} from "../src/MintFacet.sol";
import {StorageFacet, NftStats} from "../src/StorageFacet.sol";
import {MessagingReceipt, MessagingParams, MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/interfaces/ILayerZeroEndpointV2.sol";

contract MockLayerZeroEndpointV2 {
    uint32 public localEid;
    mapping(uint32 => address) public remoteEndpoints;

    constructor(uint32 _eid) {
        localEid = _eid;
    }

    function setRemoteEndpoint(uint32 _remoteEid, address _remoteEndpoint) external {
        remoteEndpoints[_remoteEid] = _remoteEndpoint;
    }

    function quote(
        MessagingParams calldata _params,
        address _sender
    ) external pure returns (MessagingFee memory fee) {
        // Симулируем возврат стоимости газа (например, 0.01 ether)
        fee.nativeFee = 0.01 ether;
        fee.lzTokenFee = 0;

        return fee;
    }

    // Вспомогательная функция для прохождения компиляции send
    function send(
        MessagingParams calldata _params,
        address _refundAddress
    ) external payable returns (uint256 nativeFee, uint256 lzTokenFee) {
        return (0, 0);
    }
}

contract OmnichainFacetTest is Test {
    DeployDiamondScript deployer;

    uint32 constant SEPOLIA_EID = 40161;
    uint32 constant ARBITRUM_EID = 40168;

    // Сущности Сети А (Исходная)
    address diamondA;
    MockLayerZeroEndpointV2 endpointA;
    ONFTFacet onftA;
    MintFacet mintA;

    // Сущности Сети Б (Целевая)
    address diamondB;
    MockLayerZeroEndpointV2 endpointB;
    ONFTFacet onftB;
    MintFacet mintB;

    address owner = address(0xABC);
    address user1 = address(0x111);

    function setUp() public {
        deployer = new DeployDiamondScript();

        // ---- НАСТРОЙКА СЕТИ А ----
        endpointA = new MockLayerZeroEndpointV2(SEPOLIA_EID);
        DeployDiamondScript.DeploymentResult memory resultA = deployer.run(owner);
        diamondA = resultA.diamondAddress;
        onftA = ONFTFacet(diamondA);
        mintA = MintFacet(diamondA);

        vm.prank(owner);
        onftA.setLzEndpoint(address(endpointA));

        // ---- НАСТРОЙКА СЕТИ Б ----
        endpointB = new MockLayerZeroEndpointV2(ARBITRUM_EID);
        DeployDiamondScript.DeploymentResult memory resultB = deployer.run(owner);
        diamondB = resultB.diamondAddress;
        onftB = ONFTFacet(diamondB);
        mintB = MintFacet(diamondB);

        vm.prank(owner);
        onftB.setLzEndpoint(address(endpointB));

        // ---- СВЯЗЫВАНИЕ СЕТЕЙ (WIRING) ----
        bytes32 peerA = bytes32(uint256(uint160(diamondA)));
        bytes32 peerB = bytes32(uint256(uint160(diamondB)));

        vm.startPrank(owner);
        onftA.setTrustedPeer(ARBITRUM_EID, peerB); // На Сети А доверяем Сети Б
        onftB.setTrustedPeer(SEPOLIA_EID, peerA); // На Сети Б доверяем Сети А
        vm.stopPrank();
    }

    function test_QuoteSend() public view {
        bytes memory options = "";
        uint256 fakeTokenId = 12345;

        (uint256 nativeFee, ) = onftA.quote(ARBITRUM_EID, fakeTokenId, options);
        assertEq(nativeFee, 0.01 ether);
    }

    function test_CrossChainReceive_NewNFT() public {
        // Симулируем, что на Сети Б (Arbitrum) впервые прилетает токен с ID 99999 от user1
        uint256 crossChainTokenId = 99999;

        // Создаем фейковую структуру характеристик персонажа, которую сгенерировали в Сети А
        NftStats memory incomingStats = NftStats({
            omnichainId: crossChainTokenId,
            uiId: 1,
            originChainId: SEPOLIA_EID,
            creator: user1,
            owner: user1,
            nickName: "CryptoWarrior",
            customURI: "https://metadata.com",
            wins: 15,
            losses: 3,
            ratingPoints: 2200,
            totalPrizeTokens: 500
        });

        // Кодируем пакет данных точно так же, как это делает функция abi.encode в sendNFT
        bytes memory payload = abi.encode(crossChainTokenId, user1, incomingStats);

        bytes32 senderPeer = bytes32(uint256(uint160(diamondA)));

        vm.prank(address(endpointB));
        onftB.lzReceive(
            SEPOLIA_EID,
            senderPeer,
            1, // nonce
            bytes32(0), // guid
            payload,
            "" // extraData
        );

        assertEq(mintB.ownerOf(crossChainTokenId), user1);

        NftStats memory localStats = mintB.getNft(crossChainTokenId);
        assertEq(localStats.wins, 15);
        assertEq(localStats.ratingPoints, 2200);
        assertEq(localStats.owner, user1);
    }
}
