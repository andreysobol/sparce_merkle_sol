// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Spt {
    bytes public emptyElement;
    mapping(uint256 => bytes32) public cacheEmptyValues; // can be a dynamic array

    uint public depth;
    uint public maxElements;

    // tree level => index inside level => element hash
    mapping(uint256 => mapping(uint256 => bytes32)) public tree;
    mapping(uint256 => bytes) public elementData; 

    constructor(uint _depth) {
        assert(_depth > 0);
        setupDepth(_depth);
        calculateEmptyLeafHash(_depth);
        tree[depth][0] = cacheEmptyValues[depth];
    }

    function setupDepth(uint _depth) internal {
        depth = _depth;
        maxElements = 2**depth;
    }

    function increaseDepth(uint amountOfLevel) internal {
        assert(amountOfLevel > 0);
        uint oldDepth = depth;
        uint newDepth = depth + amountOfLevel;

        calculateEmptyLeafHash(newDepth);

        uint currentIndex = 0;
        for (uint level = oldDepth; level < newDepth; level++) {
            calculateAndUpdateLeaf(level, currentIndex);
        }
        setupDepth(newDepth);
    }

    function decreaseDepth(uint amountOfLevel) internal {
        uint oldDepth = depth;
        uint newDepth = depth - amountOfLevel;
        assert(amountOfLevel > 0);
        assert(newDepth > 0);

        uint checkIndex = 1;
        for (uint level = newDepth; level < oldDepth; level++) {
            assert(tree[level][checkIndex] == 0x00);
        }
        setupDepth(newDepth);
    }

    function getRoot() public view returns (bytes32) {
        if (tree[depth][0] == 0x00) {
            return cacheEmptyValues[depth];
        } else {
            return tree[depth][0];
        }
    }

    function calculateEmptyLeafHash(uint level) internal returns (bytes32) {
        if (cacheEmptyValues[level] != 0x00) {
            return cacheEmptyValues[level];
        }

        if (level == 0) {
            cacheEmptyValues[level] = sha256(emptyElement);
        } else {
            bytes32 prev = calculateEmptyLeafHash(level - 1);
            cacheEmptyValues[level] = sha256(abi.encodePacked(prev, prev));
        }

        return cacheEmptyValues[level];
    }

    function calculateLeaf(uint level, uint i) internal returns (bytes32) {
        uint i0 = 2*i;
        uint i1 = 2*i+1;

        bytes32 v0 = tree[level][i0];
        bytes32 v1 = tree[level][i1];

        if ((v0 == 0) && (v1 == 0)) {
            return 0x00;
        }

        if (v0 == 0) {
            v0 = cacheEmptyValues[level];
        }

        if (v1 == 0) {
            v1 = cacheEmptyValues[level];
        }

        return sha256(abi.encodePacked(v0, v1));
    }

    function calculateAndUpdateLeaf(uint level, uint i) internal {
        tree[level+1][i] = calculateLeaf(level, i);
    }

    function modifyHashedElement(uint index, bytes32 hashedElement) internal {
        tree[0][index] = hashedElement;
        for (uint level = 0; level < depth; level++) {
            uint currentIndex = index / (2**(level+1));
            calculateAndUpdateLeaf(level, currentIndex);
        }
    }

    function modifyElement(uint index, bytes calldata data) internal {
        elementData[index] = data;
        bytes32 hashedElement = sha256(data);
        modifyHashedElement(index, hashedElement);
    }

    function removeElement(uint index) internal {
        elementData[index] = emptyElement;
        modifyHashedElement(index, 0x00);
    }
}
