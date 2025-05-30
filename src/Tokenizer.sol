// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// custom errors instead of strings for gas efficiency
error Tokenizer__NotAuthorized(address account);
error Tokenizer__TokenAlreadyMinted(uint256 tokenId, bytes32 pdfHash);
error Tokenizer__TokenNotMinted(uint256 tokenId);
error Tokenizer__InvalidHash(bytes32 pdfHash);
error Tokenizer__HashAlreadyStored(uint256 tokenId, bytes32 pdfHash);
error Tokenizer__InvalidTokenId(uint256 tokenId);

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

    /**
     * @dev This event is triggered when a token is burned
     * @param tokenId represents an ID from off-chain database
     * @param pdfHash represents a keccak256 hash generated from the transcript PDF using ethers.js
     * @param timestamp represents the current date and time when the token is minted
     */
    event TokenBurned(uint256 indexed tokenId, bytes32 indexed pdfHash, uint256 timestamp);

    /// @dev Stores the tokenId with the related PDF hash
    /// @notice This simply store the tokenId with the hash, used for verification purposes
    mapping(uint256 => bytes32) private s_transcriptHashes;

    /// @dev Stores the PDF hash with boolean value
    /// @notice This determines if the hash is already stored. This prevents duplication when minting.
    mapping(bytes32 => bool) private s_storedHashes;

    /// @dev Stores the PDF hash with the associated token ID
    /// @notice This determines if the token is already minted. This is for frontend checking.
    mapping(bytes32 => uint256) private s_mintedTokenIds;

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
        if (msg.sender != i_owner) revert Tokenizer__NotAuthorized(msg.sender);
        _;
    }

    /**
     * @dev Mints or create a token with tokenId and store the pdfHash with the tokenId as key-value pair
     * @param tokenId represents an ID from off-chain database
     * @param pdfHash represents a keccak256 hash generated from the transcript PDF using ethers v6
     */
    function mint(uint256 tokenId, bytes32 pdfHash) external onlyAuthorized {
        if (tokenId == 0) revert Tokenizer__InvalidTokenId(tokenId);
        if (pdfHash == bytes32(0)) revert Tokenizer__InvalidHash(pdfHash);
        if (s_storedHashes[pdfHash]) revert Tokenizer__HashAlreadyStored(tokenId, pdfHash);
        if (_ownerOf(tokenId) != address(0)) revert Tokenizer__TokenAlreadyMinted(tokenId, pdfHash);

        _safeMint(i_owner, tokenId);

        s_transcriptHashes[tokenId] = pdfHash;
        s_storedHashes[pdfHash] = true;
        s_mintedTokenIds[pdfHash] = tokenId;

        unchecked {
            mintedTokenCount++;
        }

        emit TokenMinted(tokenId, pdfHash, block.timestamp);
    }

    /**
     * @dev Burns or delete a token based on the tokenId, also deletes the corresponding key-value pair in mappings
     * @param tokenId represents an ID from off-chain database
     */
    function burn(uint256 tokenId) external onlyAuthorized {
        if (tokenId == 0) revert Tokenizer__InvalidTokenId(tokenId);
        if (_ownerOf(tokenId) == address(0)) revert Tokenizer__TokenNotMinted(tokenId);

        bytes32 storedHash = s_transcriptHashes[tokenId];

        _burn(tokenId);

        delete s_transcriptHashes[tokenId];
        delete s_storedHashes[storedHash];
        delete s_mintedTokenIds[storedHash];

        unchecked {
            mintedTokenCount--;
        }

        emit TokenBurned(tokenId, storedHash, block.timestamp);
    }

    /**
     * @dev verifies the hash of transcript PDF stored on-chain with PDF hash from the frontend
     * @param tokenId represents an ID from off-chain database
     * @param pdfHash represents a keccak256 hash generated from the transcript PDF using ethers v6
     * @return True if the input hash matches the on-chain hash, False if not
     */
    function verifyTranscriptHash(uint256 tokenId, bytes32 pdfHash) external view returns (bool) {
        if (pdfHash == bytes32(0)) revert Tokenizer__InvalidHash(pdfHash);
        if (_ownerOf(tokenId) == address(0)) revert Tokenizer__TokenNotMinted(tokenId);

        return pdfHash == s_transcriptHashes[tokenId];
    }

    /**
     * @dev retrives the hash of transcript PDF based on minted token ID
     * @param tokenId represents an ID from off-chain database
     * @return Hash of Transcript PDF
     */
    function getTranscriptHash(uint256 tokenId) external view returns (bytes32) {
        if (_ownerOf(tokenId) == address(0)) revert Tokenizer__TokenNotMinted(tokenId);

        return s_transcriptHashes[tokenId];
    }

    /**
     * @dev retrives the boolean value of the key PDF hash from the mapping
     * @param pdfHash represents a keccak256 hash generated from the transcript PDF using ethers v6
     * @return True if the PDF hash is stored on-chain, False otherwise
     */
    function getStoredHashValue(bytes32 pdfHash) external view returns (bool) {
        if (pdfHash == bytes32(0)) revert Tokenizer__InvalidHash(pdfHash);

        return s_storedHashes[pdfHash];
    }

    /**
     * @dev retrives the token ID of the key PDF hash from the mapping
     * @param pdfHash represents a keccak256 hash generated from the transcript PDF using ethers v6
     * @return TokenID of the PDF hash
     */
    function getTokenIdByHash(bytes32 pdfHash) external view returns (uint256) {
        if (pdfHash == bytes32(0)) revert Tokenizer__InvalidHash(pdfHash);

        return s_mintedTokenIds[pdfHash];
    }

    /// @return Number of minted tokens
    function getTokenMintedCount() external view returns (uint256) {
        return mintedTokenCount;
    }
}
