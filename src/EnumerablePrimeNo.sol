// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Enumerable} from "./Enumerable.sol";

contract EnumerablePrimeNo {
    Enumerable immutable nftContract;

    constructor() {
        nftContract = new Enumerable(msg.sender);
    }

    function addressPrimeNumbers(address user) external view returns (uint8 primeCount) {
        uint256 totalOwned = nftContract.balanceOf(user);

        for (uint256 i = 0; i < totalOwned;) {
            uint256 tokenId = nftContract.tokenOfOwnerByIndex(user, i);
            if (_isPrime(tokenId)) {
                ++primeCount;
            }
            unchecked {
                ++i;
            }
        }
    }

    function _isPrime(uint256 number) internal pure returns (bool) {
        // 0 and 1 are not prime
        if (number < 2) {
            return false;
        }

        // 2 is prime
        if (number == 2) {
            return true;
        }

        /*
          The conventional way to check if a number is even or odd is to do x % 2 == 0 where x is the number in question. 
          You can instead check if x & uint256(1) == 0. where x is assumed to be a uint256. 
          Bitwise and is cheaper than the modulo op code. 
          In binary, the rightmost bit represents "1" whereas all the bits to the are multiples of 2, which are even. 
          Adding "1" to an even number causes it to be odd.
        */
        if (number & uint256(1) == 0) {
            return false;
        }

        // checks if number is divisible by any odd number from 3 to 10. If it finds a divisor, the number is not prime
        // No NFTs > 100 should exist in the contract, so we know they will have a factor <= 10
        for (uint256 i = 3; i <= 10; i += 2) {
            if (number % i == 0) {
                return false;
            }
        }
        return true;
    }
}
