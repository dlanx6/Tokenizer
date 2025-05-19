// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {
    Tokenizer,
    Tokenizer__NotAuthorized,
    Tokenizer__TokenAlreadyMinted,
    Tokenizer__TokenNotMinted,
    Tokenizer__InvalidHash,
    Tokenizer__HashAlreadyStored,
    Tokenizer__InvalidTokenId
} from "../src/Tokenizer.sol";
import {DeployTokenizer} from "../script/DeployTokenizer.s.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";

contract TokenizerTest is Test, ZkSyncChainChecker {
    Tokenizer tokenizer;

    uint256 constant TOKENID = 1234;
    bytes32 constant HASH = 0x7c1d39220cfc66b0a8e2357e1a2ff4143c3e560dbdcaa539f6a6d1e9c6cbaf52;
    bytes32 constant HASH2 = 0x4d5e90aa248ef893e5db44b9352e2e2ad5a519d6bdb8c9f9b384f5ebad13f720;
    address immutable OWNER = vm.envAddress("OWNER_ADDRESS");

    modifier isOwner() {
        vm.prank(OWNER);
        _;
    }

    function setUp() external {
        if (!isZkSyncChain()) {
            DeployTokenizer deploy = new DeployTokenizer();
            tokenizer = deploy.run();
        } else {
            tokenizer = new Tokenizer(OWNER);
        }
    }

    function testSenderIsOwner() public {
        vm.expectRevert(Tokenizer__NotAuthorized.selector);

        tokenizer.mint(TOKENID, HASH);
    }

    function testFirstTimeTokenMinted() public isOwner {
        tokenizer.mint(TOKENID, HASH);

        address ownerOfToken = tokenizer.ownerOf(TOKENID);

        assertEq(ownerOfToken, OWNER);
    }

    function testTokenAlreadyMinted() public {
        vm.startPrank(OWNER);

        tokenizer.mint(TOKENID, HASH);
        vm.expectRevert(Tokenizer__TokenAlreadyMinted.selector);
        tokenizer.mint(TOKENID, HASH2);

        vm.stopPrank();
    }

    function testInvalidTokenId() public isOwner {
        vm.expectRevert(Tokenizer__InvalidTokenId.selector);
        tokenizer.mint(0, HASH);
    }

    function testHashAlreadyStored() public {
        vm.startPrank(OWNER);

        tokenizer.mint(TOKENID, HASH);
        vm.expectRevert(Tokenizer__HashAlreadyStored.selector);
        tokenizer.mint(100, HASH);

        vm.stopPrank();
    }

    function testInvalidHash() public isOwner {
        vm.expectRevert(Tokenizer__InvalidHash.selector);

        tokenizer.mint(TOKENID, bytes32(0));
    }

    function testTokenBurned() public {
        vm.startPrank(OWNER);

        tokenizer.mint(TOKENID, HASH);
        tokenizer.burn(TOKENID);

        vm.expectRevert(Tokenizer__TokenNotMinted.selector);
        tokenizer.getTranscriptHash(TOKENID);

        vm.stopPrank();
    }

    function testTokenBurnedNotMinted() public isOwner {
        vm.expectRevert(Tokenizer__TokenNotMinted.selector);

        tokenizer.burn(TOKENID);
    }

    function testTokenMintedAddCount() public isOwner {
        tokenizer.mint(TOKENID, HASH);

        assertEq(tokenizer.getTokenMintedCount(), 1);
    }

    function testTokenMintedSubtractCount() public {
        vm.startPrank(OWNER);

        tokenizer.mint(TOKENID, HASH);
        tokenizer.burn(TOKENID);

        vm.stopPrank();

        assertEq(tokenizer.getTokenMintedCount(), 0);
    }

    function testGettingNotMintedToken() public {
        vm.expectRevert(Tokenizer__TokenNotMinted.selector);

        tokenizer.getTranscriptHash(121);
    }

    function testGettingMintedToken() public isOwner {
        tokenizer.mint(TOKENID, HASH);
        bytes32 hashOfToken = tokenizer.getTranscriptHash(1234);

        assertEq(hashOfToken, HASH);
    }

    function testStoredHashValueWhenMinted() public isOwner {
        tokenizer.mint(TOKENID, HASH);

        bool boolValue = tokenizer.getStoredHashValue(HASH);

        assertTrue(boolValue);
    }

    function testStoredHashValueWhenBurned() public {
        vm.startPrank(OWNER);
        
        tokenizer.mint(TOKENID, HASH);
        tokenizer.burn(TOKENID);

        vm.stopPrank();

        bool boolValue = tokenizer.getStoredHashValue(HASH);

        assertFalse(boolValue);
    }

    function testGetStoredHashValue() public {
        vm.expectRevert(Tokenizer__InvalidHash.selector);
        tokenizer.getStoredHashValue(0);
    }

    function testHashVerification() public isOwner {
        tokenizer.mint(TOKENID, HASH);

        bool value = tokenizer.verifyTranscriptHash(TOKENID, HASH);

        assertTrue(value);
    }

    function testWrongHashVerification() public isOwner {
        tokenizer.mint(TOKENID, HASH);

        bool value = tokenizer.verifyTranscriptHash(TOKENID, HASH2);

        assertFalse(value);
    }

    function testInvalidHashVerification() public isOwner {
        tokenizer.mint(TOKENID, HASH);

        vm.expectRevert(Tokenizer__InvalidHash.selector);
        tokenizer.verifyTranscriptHash(TOKENID, 0);
    }
    
    function testInvalidTokenIdVerification() public isOwner {
        tokenizer.mint(TOKENID, HASH);

        vm.expectRevert(Tokenizer__TokenNotMinted.selector);
        tokenizer.verifyTranscriptHash(0, HASH);
    }
}
