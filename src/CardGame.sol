// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CardGame is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    enum CardRarity {
        COMMON,
        INCOMMON,
        RARE,
        LEGENDARY
    }

    struct Set {
        string name;
        string code;
        bool legal;
    }

    struct Card {
        string name;
        string description;
        CardRarity rarity;
        uint256 set;
        bool banned;
    }

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _cardIdCounter;
    Counters.Counter private _setIdCounter;
    string public baseURI;

    mapping(uint256 => Set) public sets;
    mapping(uint256 => Card) public cards;
    mapping(uint256 => uint256) public prints; // tokenId => cardId

    event PrintMinted(uint256 indexed tokenId, uint256 indexed cardId);
    event SetCreated(uint256 indexed setId, string name);
    event CardCreated(uint256 indexed cardId, string name);
    event CardBanned(uint256 indexed cardId);

    constructor(string memory initialBaseURI) ERC721("Card Game", "TCG") {
        baseURI = initialBaseURI;
    }

    function printCard(address to, uint256 cardId) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        prints[tokenId] = cardId;

        emit PrintMinted(tokenId, cardId);
    }

    function createSet(
        string memory name,
        string memory code,
        bool legal
    ) public onlyOwner returns (uint256) {
        uint256 setId = _setIdCounter.current();
        _setIdCounter.increment();
        sets[setId] = Set(name, code, legal);

        emit SetCreated(setId, name);
        return setId;
    }

    // Card functions
    function createCard(
        string memory name,
        string memory description,
        CardRarity rarity,
        uint256 setId
    ) public onlyOwner returns (uint256) {
        uint256 cardId = _cardIdCounter.current();
        _cardIdCounter.increment();
        cards[cardId] = Card(name, description, rarity, setId, false);

        emit CardCreated(cardId, name);
        return cardId;
    }

    function getCard(uint256 cardId) public view returns (Card memory) {
        return cards[cardId];
    }

    function banCard(uint256 cardId) public onlyOwner {
        cards[cardId].banned = true;

        emit CardBanned(cardId);
    }

    // Set functions
    function getSet(uint256 setId) public view returns (Set memory) {
        return sets[setId];
    }

    // Printed cards functions
    function getCardPrinted(uint256 tokenId) public view returns (Card memory) {
        return cards[prints[tokenId]];
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _setBaseURI(uri);
    }

    // ERC721 related functions
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        super._requireMinted(tokenId);
        uint256 cardId = prints[tokenId];
        return string(abi.encodePacked(_baseURI(), cardId));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _setBaseURI(string memory uri) internal {
        baseURI = uri;
    }
}
