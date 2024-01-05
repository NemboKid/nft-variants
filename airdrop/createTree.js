import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// Get the values to include in the tree (consider reading them from a file)
// NOTE: address, index, amount
const values = [
  ["0x0000000000000000000000000000000000000001", "0", "1"],
  ["0x0000000000000000000000000000000000000002", "1", "2"],
  ["0x0000000000000000000000000000000000000003", "2", "3"],
  ["0x0000000000000000000000000000000000000004", "3", "4"],
  ["0x0000000000000000000000000000000000000005", "4", "5"],
  ["0x0000000000000000000000000000000000000006", "5", "6"],
  ["0x0000000000000000000000000000000000000007", "6", "7"],
  ["0x0000000000000000000000000000000000000008", "7", "8"],
];

// Build the merkle tree. Set the encoding to match the values.
const tree = StandardMerkleTree.of(values, ["address", "uint256", "uint256"]);

// Print the merkle root. You will probably publish this value on chain in a smart contract
console.log("Merkle Root:", tree.root);

// Write a file that describes the tree. You will distribute this to users so they can generate proofs for values in the tree
fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));
