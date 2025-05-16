// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// custom errors instead of strings for gas efficiency
error Tokenizer__NotAuthorized();
error Tokenizer__TokenAlreadyMinted();
error Tokenizer__TokenNotMinted();
error Tokenizer__InvalidHash();
error Tokenizer__HashAlreadyStored();

/**
 * @title A minter and verifier for PDF with Keccak256 hash
 * @author Vosya
 * @notice The purpose of this contract is to mint and verify PDF hash of an academic transcript
 * @dev Implements ERC-721 Token Standard
 */
contract Tokenizer is ERC721 {
    /**
     * @dev This event is triggered when a token is minted
     * @param tokenId represents an ID from off-chain database
     * @param pdfHash represents a keccak256 hash generated from the transcript PDF using ethers.js
     * @param timestamp represents the current date and time when the token is minted
     */
    event TokenMinted(uint256 indexed tokenId, bytes32 indexed pdfHash, uint256 timestamp);

    /// @dev Stores the tokenId with the related PDF hash
    /// @notice This simply store the tokenId with the hash, used for verification purposes
    mapping(uint256 => bytes32) private s_transcriptHashes;

    /// @dev Stores the fixed-length hash with boolean value
    /// @notice This determines if the hash is already stored. This prevents duplication when minting.
    mapping(bytes32 => bool) private s_storedHashes;

    /// @dev immutable, can't be modified once initialized
    address private immutable i_owner;

    /// @notice count for minted transcript hash
    uint256 private mintedTokenCount;

    /// @notice sets the name and symbol of the NFT
    /// @dev initializes the deployer as the contract owner
    constructor(address owner) ERC721("TorNFT", "TRNFT") {
        i_owner = owner;
    }

    /// @dev checks if the sender is the owner
    modifier onlyAuthorized() {
        if (msg.sender != i_owner) revert Tokenizer__NotAuthorized();
        _;
    }

    /**
     * @dev Mints the tokenId and store the pdfHash with the tokenId as key-value pair
     * @param tokenId represents an ID from off-chain database
     * @param pdfHash represents a keccak256 hash generated from the transcript PDF using ethers v6
     */
    function mint(uint256 tokenId, bytes32 pdfHash) public onlyAuthorized {
        if (pdfHash == bytes32(0)) revert Tokenizer__InvalidHash();
        if (s_storedHashes[pdfHash]) revert Tokenizer__HashAlreadyStored();
        if (_ownerOf(tokenId) != address(0)) revert Tokenizer__TokenAlreadyMinted();

        _safeMint(i_owner, tokenId);

        s_transcriptHashes[tokenId] = pdfHash;
        s_storedHashes[pdfHash] = true;

        unchecked {
            mintedTokenCount += 1;
        }

        emit TokenMinted(tokenId, pdfHash, block.timestamp);
    }

    /**
     * @dev retrives the hash of transcript PDF based on minted token ID
     * @param tokenId represents an ID from off-chain database
     * @return Hash of Transcript PDF
     */
    function getTranscriptHash(uint256 tokenId) public view returns (bytes32)  {
        if (_ownerOf(tokenId) == address(0)) revert Tokenizer__TokenNotMinted();

        return s_transcriptHashes[tokenId];
    }

    /**
     * @dev verifies the hash of transcript PDF stored on-chain with PDF hash from the frontend
     * @param tokenId represents an ID from off-chain database
     * @param pdfHash represents a keccak256 hash generated from the transcript PDF using ethers v6
     * @return True if the input hash matches the on-chain hash, False if not
     */
    function verifyTranscriptHash(uint256 tokenId, bytes32 pdfHash) public view returns (bool) {
        if (pdfHash == bytes32(0)) revert Tokenizer__InvalidHash();
        if (_ownerOf(tokenId) == address(0)) revert Tokenizer__TokenNotMinted();

        return pdfHash == s_transcriptHashes[tokenId];
    }

    /// @return Number of minted tokens
    function getTokenMintedCount() public view returns (uint256) {
        return mintedTokenCount;
    }
}
