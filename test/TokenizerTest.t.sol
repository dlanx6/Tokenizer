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
        vm.expectRevert(abi.encodeWithSelector(Tokenizer__NotAuthorized.selector, address(this)));

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
        vm.expectRevert(abi.encodeWithSelector(Tokenizer__TokenAlreadyMinted.selector, TOKENID, HASH2));
        tokenizer.mint(TOKENID, HASH2);

        vm.stopPrank();
    }

    function testMintInvalidTokenId() public isOwner {
        vm.expectRevert(abi.encodeWithSelector(Tokenizer__InvalidTokenId.selector, 0));
        tokenizer.mint(0, HASH);
    }

    function testBurnInvalidTokenId() public isOwner {
        vm.expectRevert(abi.encodeWithSelector(Tokenizer__InvalidTokenId.selector, 0));
        tokenizer.burn(0);
    }

    function testHashAlreadyStored() public {
        vm.startPrank(OWNER);

        tokenizer.mint(TOKENID, HASH);
        vm.expectRevert(abi.encodeWithSelector(Tokenizer__HashAlreadyStored.selector, 100, HASH));
        tokenizer.mint(100, HASH);

        vm.stopPrank();
    }

    function testInvalidHash() public isOwner {
        vm.expectRevert(abi.encodeWithSelector(Tokenizer__InvalidHash.selector, bytes32(0)));

        tokenizer.mint(TOKENID, bytes32(0));
    }

    function testTokenBurned() public {
        vm.startPrank(OWNER);

        tokenizer.mint(TOKENID, HASH);
        tokenizer.burn(TOKENID);

        vm.expectRevert(abi.encodeWithSelector(Tokenizer__TokenNotMinted.selector, TOKENID));
        tokenizer.getTranscriptHash(TOKENID);

        vm.stopPrank();
    }

    function testTokenBurnedNotMinted() public isOwner {
        vm.expectRevert(abi.encodeWithSelector(Tokenizer__TokenNotMinted.selector, TOKENID));

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
        vm.expectRevert(abi.encodeWithSelector(Tokenizer__TokenNotMinted.selector, 121));

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

    function testGetStoredHashValueError() public {
        vm.expectRevert(abi.encodeWithSelector(Tokenizer__InvalidHash.selector, 0));
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

        vm.expectRevert(abi.encodeWithSelector(Tokenizer__InvalidHash.selector, 0));
        tokenizer.verifyTranscriptHash(TOKENID, 0);
    }

    function testInvalidTokenIdVerification() public isOwner {
        tokenizer.mint(TOKENID, HASH);

        vm.expectRevert(abi.encodeWithSelector(Tokenizer__TokenNotMinted.selector, 0));
        tokenizer.verifyTranscriptHash(0, HASH);
    }

    function testGetTokenIdByHash() public isOwner {
        tokenizer.mint(TOKENID, HASH);

        assertEq(tokenizer.getTokenIdByHash(HASH), TOKENID);
    }

    function testGetTokenIdByHashError() public {
        vm.expectRevert(abi.encodeWithSelector(Tokenizer__InvalidHash.selector, bytes32(0)));
        tokenizer.getTokenIdByHash(0);
    }

    function testGetBurnedTokenIdByHash() public {
        vm.startPrank(OWNER);

        tokenizer.mint(TOKENID, HASH);
        tokenizer.burn(TOKENID);

        vm.stopPrank();

        assertEq(tokenizer.getTokenIdByHash(HASH), 0);
    }
}
