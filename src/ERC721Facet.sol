pragma solidity ^0.8.0;

import {StorageFacet, GameStorage} from "./StorageFacet.sol";

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract ERC721Facet is StorageFacet {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function name() external view returns(string memory collectionName){
        GameStorage storage gameStore = getStorage();
        return gameStore.name;
    }

    function symbol() external view returns (string memory collectionSymbol) {
        GameStorage storage gameStore = getStorage();
        return gameStore.symbol;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "ERC721: address zero is not a valid owner");
        return getStorage().userNfts[_owner].length;
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        address owner = getStorage().nftStats[_tokenId].owner;
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function approve(address _to, uint256 _tokenId) external {
        GameStorage storage gameStore = getStorage();
        address owner = gameStore.nftStats[_tokenId].owner;

        require(msg.sender == owner || gameStore.operatorApprovals[owner][msg.sender], "ERC721: approve caller is not token owner or approved for all");

        gameStore.nftApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        GameStorage storage gameStore = getStorage();
        gameStore.operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        GameStorage storage gameStore = getStorage();
        require(gameStore.nftStats[_tokenId].owner != address(0), "ERC721: invalid token ID");
        return gameStore.nftApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return getStorage().operatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
        _transfer(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        GameStorage storage gameStore = getStorage();

        require(gameStore.nftStats[_tokenId].owner == _from, "ERC721: transfer from incorrect owner");
        require(_to != address(0), "ERC721: transfer to the zero address");

        require(
            msg.sender == _from ||
            gameStore.nftApprovals[_tokenId] == msg.sender ||
            gameStore.operatorApprovals[_from][msg.sender],
            "ERC721: caller is not token owner or approved"
        );

        delete gameStore.nftApprovals[_tokenId];

        // 1. УДАЛЯЕМ ИЗ МАССИВА ОТПРАВИТЕЛЯ (Паттерн Swap and Pop)
        uint256 nftIndexPlusOne = gameStore.nftOwnedIndex[_tokenId];
        uint256 nftIndex = nftIndexPlusOne - 1;
        uint256[] storage fromArray = gameStore.userNfts[_from];
        uint256 lastNftIndex = fromArray.length - 1;

        if (nftIndex != lastNftIndex) {
            uint256 lastNftId = fromArray[lastNftIndex];
            fromArray[nftIndex] = lastNftId;
            gameStore.nftOwnedIndex[lastNftId] = nftIndex + 1;
        }
        fromArray.pop();

        gameStore.userNfts[_to].push(_tokenId);
        gameStore.nftOwnedIndex[_tokenId] = gameStore.userNfts[_to].length;

        gameStore.nftStats[_tokenId].owner = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        GameStorage storage gameStore = getStorage();
        require(gameStore.nftStats[_tokenId].owner != address(0), "ERC721: URI query for nonexistent token");

        string memory _customURI = gameStore.nftStats[_tokenId].customURI;
        if (bytes(_customURI).length > 0) {
            return _customURI;
        }

        string memory base = gameStore.baseTokenURI;
        return bytes(base).length > 0 ? string.concat(base, _toString(_tokenId)) : "";
    }

    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private returns (bool) {
        if (_to.code.length > 0) {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
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