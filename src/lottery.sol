pragma solidity ^0.4.23;

import { owned } from "./owned.sol";
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract Lottery is owned, usingOraclize {

    uint public minEntry = 0.1 ether;
    address[] players;
    uint oraclizeQueryId = 0;

    event MinEntryChanged(address indexed who, uint minEntry);
    event PlayerEntered(address indexed who, uint amount);
    event WinnerSelected(address indexed who, uint reward);
    event NewRoundStarted(uint timestamp);

    constructor(){
        oraclize_setProof(proofType_Ledger);
    }

    function enter() payable external {
        require(msg.value >= minEntry);
        require(oraclizeQueryId == 0);
        require(!_isAlreadyPlaying(msg.sender));
        
        players.push(msg.sender);
        emit PlayerEntered(msg.sender, msg.value);
    }

    function startChooseWinnerProcess() external onlyOwner{
        require(oraclizeQueryId == 0);

        uint executionDelay = 0;
        uint callbackGas = 200000;
        oraclize_newRandomDSQuery(executionDelay, players.length, callbackGas); 
    }

    function __callback(bytes32 _queryId, string _result, bytes _proof) public { 
        require(msg.sender == oraclize_cbAddress());
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) == 0) {
    
            uint maxRange = 2**(8 * players.length);
            uint randomPlayerIndex = uint(keccak256(_result)) % maxRange;

            uint balance = this.balance;
            address winner = players[randomPlayerIndex];

            winner.transfer(balance);

            delete players;
            oraclizeQueryId = 0;

            emit WinnerSelected(winner, balance);
            emit NewRoundStarted(block.timestamp);
        }
    }

    function setMinEntry(uint8 _minEntry) external onlyOwner{
        require(minEntry > 0);

        minEntry = _minEntry;
        emit MinEntryChanged(msg.sender, minEntry);
    }

    function _isAlreadyPlaying(address _player) internal returns(bool){
        for(uint i = 0; i < players.length; i++){
            if(players[i] == _player){
                return true;
            }
        }
        return false;
    }
}