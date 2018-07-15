pragma solidity ^0.4.23;

contract owned {

    address owner;

    function changeOwner() external onlyOwner {
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
}