pragma solidity ^0.8.0;
import "./Game.sol";
import "./Bytes32.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";

contract ChessGameCreator is Bytes32{
    using Counters for Counters.Counter;
    mapping (address => uint) private _gamesPlayed;
    mapping (address => uint) private _experience;
    mapping (address => uint) private_userLevel;
    

    Counters.Counter _idCount;
    Chess private CONNECT;
    struct Lobby {
        bytes32 game_code;
        uint gameId;
        address gameAddress;
        address creator;
    }
    Lobby [] _lobbies;

    function createPrivateGame(string memory gameName , address player1 , address player2 , uint betAmount) public{
        require(player1 != address (0) && player2 != address(0));
        require(!_gameNameUsed(gameName) , "That name is already taken");
        Chess newGame = new Chess(_idCount.current() , player1 , player2 , betAmount);
        bytes32 gameCode = _stringToBytes32(gameName);
        _lobbies.push(Lobby(
            gameCode,
            _idCount.current(),
            address(newGame),
            msg.sender
        ));
    }

    function _gameNameUsed(string memory gameName) internal view returns (bool){
        bytes32 gameCode = _stringToBytes32(gameName);
        for(uint i=0 ; i<_lobbies.length ; i++){
            if(_lobbies[i].game_code==gameCode){
                return true;
            }
        }
        return false;
    }

    function getGameCode(string memory gameName) public pure returns(bytes32){
        bytes32 gameCode = _stringToBytes32(gameName);
        return gameCode;
    }
    
    function lobbies() public view returns(Lobby[] memory){
        Lobby[] memory lobbies = new Lobby[](_lobbies.length);
        lobbies = _lobbies;
        return lobbies;
    }


    
}