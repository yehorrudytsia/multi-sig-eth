pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";


contract MultiSig {
  address[] public owners;
  uint public confirmationsRequired;
  mapping (address => bool) public isOwner;

  event SubmitTX(
    address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data
  );
  event ConfirmTX(address indexed owner, uint indexed txIndex);
  event ExecuteTX(address indexed owner, uint indexed txIndex);
  event RecieveFunds(address indexed sender, uint amount, uint balance);

  struct Transaction {
    address to;
    uint value;
    uint confirmations;
    bool executed;
    bytes data;
  }

  mapping(uint => mapping(address => bool)) public confirmedTXs; // TX indexing
  Transaction[] transactions;

  modifier onlyOwner() {
    require(isOwner[msg.sender], "not owner");
    _;
  }

  modifier notExecuted(uint _txIndex) {
    require(!transactions[_txIndex].executed, "transaction is already executed");
    _;
  }

  modifier isUnique(uint _txIndex) {
    require(confirmedTXs[_txIndex][msg.sender] == false, "already confirmed by this address");
    _;
  }


  constructor(address[] memory _owners, uint _confirmationsRequired) {
    require(_owners.length > 1, "at least 2 owners required to initialize the multisig wallet");

    require(_confirmationsRequired > 1, 
    "at least 2 confirmations should be required to initialize the multisig wallet");

    for (uint i = 0; i < _owners.length; i++) {
      address owner = _owners[i];
      isOwner[owner] = true;
      owners.push(owner);
    }

    confirmationsRequired = _confirmationsRequired;
  }

  function deposit() external payable {
    emit RecieveFunds(msg.sender, msg.value, address(this).balance);
  }
  receive() external payable {}

  function submitTX (address _to, uint _value, bytes memory _data) public onlyOwner {
    Transaction memory Tx = Transaction({
      to: _to,
      value: _value,
      data: _data,
      executed: false,
      confirmations: 0
    });
    
    transactions.push(Tx);

    emit SubmitTX(msg.sender, transactions.length, _to, _value, _data);
  }

  function confirmTX (uint _index) 
    public 
    onlyOwner 
    notExecuted(_index) 
    isUnique(_index) 
  {
    confirmedTXs[_index][msg.sender] = true;
    transactions[_index].confirmations++;

    emit ConfirmTX(msg.sender, _index);
  }

  function executeTX (uint _index)
    public
    onlyOwner
    notExecuted(_index)
  {
    require((_index < transactions.length), "TX with given index is not exist");
    require(transactions[_index].confirmations >= confirmationsRequired, 
      "not enough confirmations for given TX"
    );
    
    transactions[_index].executed = true;
    (bool success, ) = transactions[_index]
      .to
      .call {value: transactions[_index].value} (transactions[_index].data);
    require(success, "TX failed"); 

    emit ExecuteTX(msg.sender, _index); 
  }

  function getOwners () public view returns(address[] memory) {
    return owners;
  }

  function TXState (uint _index) public view returns (
    address to, uint value, bool executed, uint confirmations)
  {
    Transaction storage Tx = transactions[_index];
    return (Tx.to, Tx.value, Tx.executed, Tx.confirmations);
  }
}

