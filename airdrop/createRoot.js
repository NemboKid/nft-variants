import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// Load the tree that we generated in createTree.js
const tree = StandardMerkleTree.load(
  JSON.parse(fs.readFileSync("./tree.json"))
);

// Loop through the entries to find the one you're interested in
for (const [i, v] of tree.entries()) {
  if (v[0] === "0x0000000000000000000000000000000000000001") {
    // Generate the proof using the index of the entry.
    // In practice this might be done in a frontend application prior to submitting the proof on-chain,
    // with the address looked up being that of the connected wallet.
    const proof = tree.getProof(i);
    console.log("Value:", v);
    console.log("Proof:", proof);
  }
}
