// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Enumerable is ERC721Enumerable {
    constructor(address tokenReceiver) ERC721("Enumerable", "ENMRBL") {
        _initBatchMint(tokenReceiver);
    }

    function _initBatchMint(address tokenReceiver) internal {
        for (uint256 i = 1; i <= 20;) {
            _mint(tokenReceiver, i);
            unchecked {
                ++i;
            }
        }
    }
}
