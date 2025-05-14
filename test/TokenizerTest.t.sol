// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Tokenizer, Tokenizer__NotAuthorized, Tokenizer__TokenAlreadyMinted, Tokenizer__TokenNotMinted, Tokenizer__InvalidHash} from "../src/Tokenizer.sol";
import {DeployTokenizer} from "../script/DeployTokenizer.s.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";


contract TokenizerTest is Test, ZkSyncChainChecker {
	Tokenizer tokenizer;

    uint256 constant TOKENID = 1234;
    bytes32 constant HASH = 0x7c1d39220cfc66b0a8e2357e1a2ff4143c3e560dbdcaa539f6a6d1e9c6cbaf52;
    address immutable OWNER = vm.envAddress("OWNER_ADDRESS");

    modifier isOwner {
        vm.prank(OWNER);
        _;
    }

    function setUp() external {
        if (!isZkSyncChain()) {
            DeployTokenizer deploy = new DeployTokenizer();
            tokenizer = deploy.run();
        }
        else {
            tokenizer = new Tokenizer(OWNER);  
        } 
    }

   function testSenderIsOwner() public skipZkSync {
        vm.expectRevert(Tokenizer__NotAuthorized.selector);

        tokenizer.mintTranscript(TOKENID, HASH);
   }

    function testFirstTimeTokenMinted() public isOwner skipZkSync {
        tokenizer.mintTranscript(TOKENID, HASH);

        address ownerOfToken = tokenizer.ownerOf(TOKENID);

        assertEq(ownerOfToken, OWNER);
    }

    function testTokenAlreadyMinted() public skipZkSync {
        vm.startPrank(OWNER);

        tokenizer.mintTranscript(TOKENID, HASH);
        vm.expectRevert(Tokenizer__TokenAlreadyMinted.selector);
        tokenizer.mintTranscript(TOKENID, HASH);

        vm.stopPrank();
    }

    function testInvalidHash() public isOwner skipZkSync {
        vm.expectRevert(Tokenizer__InvalidHash.selector);

        tokenizer.mintTranscript(TOKENID, bytes32(0));
    }

    function testCorrectTokenMintedCount() public isOwner skipZkSync {
        tokenizer.mintTranscript(TOKENID, HASH);

        assertEq(tokenizer.getTokenMintedCount(), 1);
    }

    function testGettingNotMintedToken() public skipZkSync {
        vm.expectRevert(Tokenizer__TokenNotMinted.selector);
        
        tokenizer.getTranscriptHash(121);
    }

    function testGettingMintedToken() public isOwner skipZkSync {
        tokenizer.mintTranscript(TOKENID, HASH);
        bytes32 hashOfToken = tokenizer.getTranscriptHash(1234);

        assertEq(hashOfToken, HASH);
    }
}

