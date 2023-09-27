// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CardGame is ERC1155, ERC1155Burnable, AccessControl, Pausable {
    using Counters for Counters.Counter;

    bytes32 public constant PRINTER_ROLE = keccak256("PRINTER_ROLE");

    enum CardRarity {
        COMMON,
        INCOMMON,
        RARE,
        LEGENDARY
    }

    struct Set {
        string name;
        string code;
    }

    struct Card {
        string name;
        string description;
        CardRarity rarity;
        uint256 set;
        bool banned;
    }

    Counters.Counter private _setIdCounter;
    Counters.Counter private _cardIdCounter;

    mapping(uint256 => Set) public sets;
    mapping(uint256 => Card) public cards;

    event SetCreated(uint256 indexed setId, string name);
    event CardCreated(uint256 indexed cardId, string name);
    event CardBanned(uint256 indexed cardId);

    constructor(string memory initialBaseURI) ERC1155(initialBaseURI) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PRINTER_ROLE, msg.sender);

        _setIdCounter.increment();
        _cardIdCounter.increment();
    }

    // Print functions
    function print(
        address to,
        uint256 cardId,
        uint256 amount,
        bytes memory data
    ) public onlyRole(PRINTER_ROLE) {
        _mint(to, cardId, amount, data);
    }

    function printBatch(
        address to,
        uint256[] memory cardIds,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(PRINTER_ROLE) {
        _mintBatch(to, cardIds, amounts, data);
    }

    function getAccountPrintedCards(
        address wallet
    ) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_cardIdCounter.current() - 1);
        uint256 indexCounter = 0;

        for (uint256 i = 1; i < _cardIdCounter.current(); i++) {
            if (balanceOf(wallet, i) > 0) {
                balances[indexCounter] = i;
                indexCounter++;
            }
        }

        return balances;
    }

    // Card functions
    function createCard(
        string memory name,
        string memory description,
        CardRarity rarity,
        uint256 setId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        uint256 cardId = _cardIdCounter.current();
        _cardIdCounter.increment();
        cards[cardId] = Card(name, description, rarity, setId, false);

        emit CardCreated(cardId, name);
        return cardId;
    }

    function getCard(uint256 cardId) public view returns (Card memory) {
        return cards[cardId];
    }

    function banCard(uint256 cardId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        cards[cardId].banned = true;

        emit CardBanned(cardId);
    }

    // Set functions
    function createSet(
        string memory name,
        string memory code
    ) public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        uint256 setId = _setIdCounter.current();
        _setIdCounter.increment();
        sets[setId] = Set(name, code);

        emit SetCreated(setId, name);
        return setId;
    }

    function getSet(uint256 setId) public view returns (Set memory) {
        return sets[setId];
    }

    // Contract itself related functions
    function togglePause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
