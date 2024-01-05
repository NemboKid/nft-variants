// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMaxSupply is ERC721, ERC2981, Ownable2Step {
    error ExceedsMaxSupply();
    error WithdrawalFailed();
    error IsNotOwner();
    error FeeNotEnough();
    error AlreadyClaimed();
    error InvalidProof();

    uint256 constant MAX_SUPPLY = 1000;

    uint256 public s_tokenSupply;
    uint256 public s_currentTokenId;
    address public immutable i_owner;

    uint256 public constant STANDARD_FEE = 1 ether;
    uint256 public constant DISCOUNTED_FEE = 0.8 ether;

    BitMaps.BitMap private s_bitmap;
    bytes32 public immutable i_merkleRoot;

    event Withdraw(address indexed to, uint256 amount);

    constructor(bytes32 merkleRoot) ERC721("NFTMaxSupply", "MAX") Ownable(msg.sender) {
        i_merkleRoot = merkleRoot;
        i_owner = msg.sender;

        // set default royalty to 2.5%
        _setDefaultRoyalty(msg.sender, 250);
    }

    function mintToken(uint256 amount) external payable {
        if (msg.value < (STANDARD_FEE * amount)) {
            revert FeeNotEnough();
        }
        if (s_tokenSupply + amount >= MAX_SUPPLY) {
            revert ExceedsMaxSupply();
        }

        s_tokenSupply = s_tokenSupply + amount;
        _safeMint(msg.sender, amount);
    }

    function mintTokenWithDiscount(uint256 amount, uint256 idx, bytes32[] calldata proof) external payable {
        if (msg.value < DISCOUNTED_FEE * amount) {
            revert FeeNotEnough();
        }
        if (s_tokenSupply + amount >= MAX_SUPPLY) {
            revert ExceedsMaxSupply();
        }

        // check if the bit in index is already set to 1
        if (BitMaps.get(s_bitmap, idx)) {
            revert AlreadyClaimed();
        }

        // make sure the proof is valid
        _verifyProof(proof, idx, amount, msg.sender);

        // set index byte as claimed in bitmap
        BitMaps.setTo(s_bitmap, idx, true);

        // update supply
        s_tokenSupply = s_tokenSupply + amount;

        // mint token
        _safeMint(msg.sender, amount);
    }

    function mintTokens(address to, uint256 amount) internal {
        if (amount == 0) {
            return; // No tokens minted if amount is 0
        }

        uint256 tokenId = ++s_tokenSupply;
        for (uint256 i = 0; i < amount;) {
            _safeMint(to, tokenId);
            unchecked {
                ++tokenId;
                ++i;
            }
        }
    }

    // proof is sibling hashes
    // idx, amount and addr is the total leaf
    function _verifyProof(bytes32[] calldata proof, uint256 idx, uint256 amount, address addr) private view {
        // calculate leaf value
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, idx, amount))));

        // process the proof and make sure that proof and leafs match the merkleroot
        if (!MerkleProof.verifyCalldata(proof, i_merkleRoot, leaf)) {
            revert InvalidProof();
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = payable(msg.sender).call{value: balance}("");
        if (!success) {
            revert WithdrawalFailed();
        }
        emit Withdraw(msg.sender, balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
