pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";


contract MultiSig {
  address[] public owners;
  uint public confirmationsRequired;
  mapping (address => bool) public isOwner;

  struct Transaction {
    address to;
    uint value;
    uint confirmations;
    bool executed;
  }

  mapping (uint => Transaction) public transactions;

  modifier onlyOwner() {
    require(isOwner[msg.sender], "not owner");
    _;
  }

  modifier notExecuted(uint _txIndex) {
    require(!transactions[_txIndex].executed, "transaction is already executed");
    _;
  }

  constructor(address[] memory _owners, uint _confirmationsRequired) {
    require(_owners.length > 1, "at least 2 owners required to initialize the multisig wallet");

    require(_confirmationsRequired > 1, 
    "at least 2 confirmations should be required to initialize the multisig wallet");

    for (uint i = 0; i < _owners.length; i++) {
      address owner = owners[i];
      isOwner[owner] = true;
      owners.push(owner);
    }

    confirmationsRequired = _confirmationsRequired;
  }

  receive() external payable {}

  
}
