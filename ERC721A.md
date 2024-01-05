ERC721A by Azuki saves a lot of gas cost compared to OpenZeppelin's Enumerable extension. This is mainly due to the following 3 reasons:

- Removing duplicate storage
- Updating owner balance per batch mint instead of per NFT mint
- Updating token owner data once per batch mint instead of per NFT mint

It does however come with a non-trivial tradeoff - transfers cost more!
