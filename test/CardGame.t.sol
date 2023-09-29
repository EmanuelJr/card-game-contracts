// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {CardGame} from "../src/CardGame.sol";

contract GameCardTest is Test {
    CardGame public tcg;

    function setUp() public {
        tcg = new CardGame("http://test.tcg/");
    }

    function testSetCreation() public {
        uint256 setId = tcg.createSet("Test Rite", "It's just a test");

        assertEq(1, setId);
    }

    function testCardCreation() public {
        uint256 cardId = tcg.createCard(
            "Test Rite",
            "It's just a test",
            CardGame.CardRarity.COMMON,
            1
        );

        assertEq(1, cardId);
    }

    function testCardPrinting() public {
        address to = address(1);
        uint256 cardId = 1;

        tcg.print(to, cardId, 1, "");

        assertEq(1, tcg.balanceOf(to, cardId));
    }

    function testGetSet() public {
        uint256 setId = tcg.createSet("Test Rite", "It's just a test");
        CardGame.Set memory set = tcg.getSet(setId);

        assertEq("Test Rite", set.name);
        assertEq("It's just a test", set.code);
    }

    function testGetCard() public {
        uint256 cardId = tcg.createCard(
            "Test Rite",
            "It's just a test",
            CardGame.CardRarity.COMMON,
            1
        );
        CardGame.Card memory card = tcg.getCard(cardId);

        assertEq("Test Rite", card.name);
        assertEq("It's just a test", card.description);
        assertEq(1, card.set);
        assertEq(false, card.banned);
    }

    function testBanCard() public {
        uint256 cardId = tcg.createCard(
            "Test Rite",
            "It's just a test",
            CardGame.CardRarity.COMMON,
            1
        );

        tcg.banCard(cardId);
        CardGame.Card memory card = tcg.getCard(cardId);

        assertEq(true, card.banned);
    }

    function testGetPrintedCardsWithOneCard() public {
        address to = address(1);
        uint256 cardId = tcg.createCard(
            "Test Rite",
            "It's just a test",
            CardGame.CardRarity.COMMON,
            1
        );

        tcg.print(to, cardId, 1, "");

        uint256[] memory balances = tcg.getAccountPrintedCards(to);

        assertEq(1, balances.length);
        assertEq(1, balances[0]);
    }

    function testGetPrintedCardsWithTwoCards() public {
        address to = address(1);
        uint256 cardId = tcg.createCard(
            "Test Rite",
            "It's just a test",
            CardGame.CardRarity.COMMON,
            1
        );
        tcg.createCard(
            "Test Rite 2",
            "It's just a test 2",
            CardGame.CardRarity.COMMON,
            1
        );

        tcg.print(to, cardId, 1, "");

        uint256[] memory balances = tcg.getAccountPrintedCards(to);

        assertEq(2, balances.length);
        assertEq(1, balances[0]);
        assertEq(0, balances[1]);
    }

    function testTogglePause() public {
        tcg.togglePause();
        assertEq(true, tcg.paused());

        tcg.togglePause();
        assertEq(false, tcg.paused());
    }
}
