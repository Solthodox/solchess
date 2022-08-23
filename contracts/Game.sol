pragma solidity ^0.8.0;
import "../node_modules/@openzeppelin/contracts/utils/Timers.sol";

contract Chess {
    using Timers for Timers.Timestamp;
    Timers.Timestamp setUpTime;
    Timers.Timestamp movementTime;
    mapping(address => bool) private _deposited;
    bool public player1Turn;
    address public player1;
    address public player2; 
    uint public playersConnected;
    uint  public bet;
    uint public gameId;
    address public winner;
    mapping (uint8 => mapping(uint8 => Piece)) private _table;
    event movement(address mover);
    event gameEnded(address winner , string  reason);
    GameStatus private _gameStatus;

    struct Piece{
        uint8 player;
        uint8 name;
    }

    enum  GameStatus{
        waiting,
        onGame,
        Ended
    }

    uint8 public PAWN = 1;
    uint8 public ROOK = 2;
    uint8 public BISHOP = 3;
    uint8 public HORSE = 4;
    uint8 public QUEEN = 5;
    uint8 public KING = 6;

    // INITIAL SETUP 

    // [x] [x] [x] [x] [x] [x] [x] [x]  P1
    // [x] [x] [x] [x] [x] [x] [x] [x]  P1
    // [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] 
    // [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] 
    // [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] 
    // [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] 
    // [0] [0] [0] [0] [0] [0] [0] [0]  P2
    // [0] [0] [0] [0] [0] [0] [0] [0]  P2
    
    
    modifier onGame(){
        require(gameStatus()==GameStatus.onGame);
        if(msg.sender==player1){
            require(player1Turn);
        }else{
            require(!player1Turn);
        }
        _;
        
    }

    modifier setUp(){
        require(gameStatus()==GameStatus.waiting);
        _;
    }

    modifier onlyPlayers(){
        require(msg.sender==player1 || msg.sender==player2);
        _;
        
    }

   

    
    constructor(uint  game_id , address _player1 , address _player2 , uint _betAmount){
        require(_player1 != address (0) && _player2 != address(0));
        gameId = game_id;
        player1 = _player1;
        player2 = _player2;
        bet = _betAmount;
        _gameStatus = GameStatus.waiting;
        setUpTime.setDeadline(uint64(block.timestamp + 30 minutes));
        


    }

    function join() public onlyPlayers setUp payable{
        require(!_deposited[msg.sender]);
        require(msg.value==bet , "Incorrect amount");
        _deposited[msg.sender]=true;


    }

    function ready() public onlyPlayers setUp {
        uint8 player = msg.sender==player1 ? 1 : msg.sender==player2 ? 2 : 0;
        _loadTable(player);
        playersConnected++;
        if(playersConnected==2){
            _gameStatus = GameStatus.onGame;
        }
        movementTime.setDeadline(uint64(block.timestamp + 5 minutes));
    }

    

    function move(uint8 positionX, uint8 positionY , int8 moveX , int8 moveY) public onlyPlayers onGame{
        require(!movementTime.isExpired());
        require(moveX!=0 || moveY!=0);
        require( positionX>=0 && positionX<=8 &&  positionY>=0 && positionY<=8);
        require( (int8(positionX) + moveX >=0) 
            && (int8(positionX) + moveX <=8 )  
            && (int8(positionY) + moveY >=0) 
            && (int8(positionY) + moveY <=8 ));
        uint8 playerPiece = msg.sender == player1 ? 1 : 2;
        Piece memory currentPiece = _table[positionX][positionY];
        require(currentPiece.player==playerPiece);

        if(currentPiece.name==PAWN){_movePawn(currentPiece.player , positionX , positionY , moveX , moveY);}
        else if(currentPiece.name==HORSE){_moveHorse(currentPiece.player , positionX , positionY , moveX , moveY);}
        else if(currentPiece.name==BISHOP){_moveBishop(currentPiece.player , positionX , positionY , moveX , moveY);}
        else if(currentPiece.name==QUEEN){_moveQueen(currentPiece.player , positionX , positionY , moveX , moveY);}
        else if(currentPiece.name==KING){_moveKing(currentPiece.player , positionX , positionY , moveX , moveY);}
        else{revert();}
        
        player1Turn = !player1Turn;

        movementTime.setDeadline(uint64(block.timestamp + 5 minutes));

        _checkForWinner();
        
        
    }


    function getWinnerReward() public {
        if(!movementTime.isExpired()){
            require(gameStatus() == GameStatus.Ended);
            require(msg.sender == winner);
            payable(msg.sender).transfer(address(this).balance);
        }else{
            if(msg.sender==player1){
                require(!player1Turn);
            }else{
                require(player1Turn);
            }
            winner = msg.sender ; 
            _gameStatus = GameStatus.Ended;
            emit gameEnded(msg.sender , "Player abandoned");
            payable(msg.sender).transfer(address(this).balance);
        }
    }
    function timeLeftoMove() public view returns(uint64){
        return movementTime.getDeadline() - uint64(block.timestamp);

    }
    function gameStatus() public view returns (GameStatus){
        if(_gameStatus == GameStatus.onGame && movementTime.isExpired()){
            return GameStatus.Ended;
        }
        return _gameStatus;
    }

    function table() public view returns(Piece[] memory){
        Piece[] memory pieces = new Piece[](64);
        uint counter;
        for(uint8 i=1 ; i<=8 ; i++){
            for(uint8 j=1; i<=8 ; i++){
                pieces[counter] = _table[i][j];
                counter++;
            }
        }
        return pieces;

    }

 
    function _moveQueen(uint8 playerPiece , uint8 positionX, uint8 positionY , int8 moveX , int8 moveY) internal {
        uint8 positiveX = moveX<0 ? uint8(-moveX) : uint8(moveX);
        uint8 positiveY = moveY<0 ? uint8(-moveY) : uint8(moveY);
        require(positiveX==positiveY || (moveX==0 || moveY==0) );
        require(!_pieceIsBlockingPath(playerPiece , positionX,  positionY ,  moveX ,  moveY ));
        _updateTable(playerPiece , positionX,  positionY ,  moveX ,  moveY ,QUEEN);
    }

    function _moveKing(uint8 playerPiece , uint8 positionX, uint8 positionY , int8 moveX , int8 moveY) internal{
        require(moveX<=1 && moveY<=1 );
        require(!_pieceIsBlockingPath(playerPiece , positionX,  positionY ,  moveX ,  moveY ));
        _updateTable(playerPiece , positionX,  positionY ,  moveX ,  moveY  , KING);


    }

    function _moveBishop(uint8 playerPiece , uint8 positionX, uint8 positionY , int8 moveX , int8 moveY) internal{
        uint8 positiveX = moveX<0 ? uint8(-moveX) : uint8(moveX);
        uint8 positiveY = moveY<0 ? uint8(-moveY) : uint8(moveY);
        require(positiveX==positiveY);
        require(!_pieceIsBlockingPath(playerPiece , positionX,  positionY ,  moveX ,  moveY ));
        _updateTable(playerPiece , positionX,  positionY ,  moveX ,  moveY , BISHOP );
    }

    function _moveHorse(uint8 playerPiece , uint8 positionX, uint8 positionY , int8 moveX , int8 moveY) internal {
        uint8 positiveX = moveX<0 ? uint8(-moveX) : uint8(moveX);
        uint8 positiveY = moveY<0 ? uint8(-moveY) : uint8(moveY);
        require( (positiveX==1 && positiveY==2) || (positiveX==2 && positiveY==1) );
        require(_table[uint8(int8(positionX) + moveX)][uint8(int8(positionY) + moveY)].player!=playerPiece); 
        _updateTable(playerPiece , positionX,  positionY ,  moveX ,  moveY , HORSE);
    }

    function _moveRook(uint8 playerPiece , uint8 positionX, uint8 positionY , int8 moveX , int8 moveY) internal {
        require(moveX==0 || moveY ==0);
        require(!_pieceIsBlockingPath(playerPiece , positionX,  positionY ,  moveX ,  moveY ));
        _updateTable(playerPiece , positionX,  positionY ,  moveX ,  moveY , ROOK );
    }


    function _movePawn(uint8 playerPiece , uint8 positionX, uint8 positionY , int8 moveX , int8 moveY ) internal{
        bool canGoLeft;
        bool canGoRight;
        if( playerPiece==1){           
            canGoLeft = _table[positionX +1 ][positionY +1].player==2 ; 
            canGoLeft = _table[positionX -1 ][positionY +1].player==2 ;
            require(moveY==1);
            if(moveX == 1){ require(canGoRight);}
            if(moveX == -1){ require(canGoLeft);}
            if(moveX==0){
                require(_table[positionX][positionY+1].player!=0);
            }
            
            
        }else{
            canGoLeft = _table[positionX +1 ][positionY -1].player==1 ; 
            canGoLeft = _table[positionX -1 ][positionY -1].player==1 ;
            require(moveY==-1);
            if(moveX == 1){ require(canGoRight);}
            if(moveX == -1){ require(canGoLeft);}
            if(moveX==0){
                require(_table[positionX][positionY+1].player!=0);
            }
            
        }

       _updateTable(playerPiece , positionX , positionY , moveX , moveY ,PAWN );    
    }

    function _pieceIsBlockingPath(uint8 playerPiece , uint8 positionX , uint8  positionY , int8 moveX , int8 moveY) internal view returns(bool){

        for(uint8 i=1 ; i<=uint8(moveX) ; i++){
            for(uint8 j=1 ; j<=uint8(moveY) ; j++){
                if(_table[positionX + i ][positionY + j].player == playerPiece){
                    return true;
                }
            }
        }
        return false;

    }

    function _updateTable(uint8 playerPiece , uint8 positionX , uint8  positionY , int8 moveX , int8 moveY , uint8  piece) internal{
        delete _table[positionX][positionY];
        _table[uint8(int8(positionX) + moveX)][uint8(int8(positionY) + moveY)] = Piece(playerPiece , piece);
        emit movement(msg.sender);
    }

    function _checkForWinner() internal {
        bool King1Alive;
        bool King2Alive;
        for(uint i=0 ; i< table().length ; i++){
            Piece memory p =table()[i];
            if (p.name == KING){
                if(p.player==1){
                    King1Alive = true;
                }else{
                    King2Alive = true;
                }              
            }
        }
        if(!King1Alive){
            winner=player1;
            _gameStatus = GameStatus.Ended;
        }else if(!King2Alive){
            winner=player2;
            _gameStatus = GameStatus.Ended;
        }
        emit gameEnded( msg.sender , "Opponent beaten");
    }

    function _loadTable(uint8 player) internal {

        if(player==1){
        _table[1][1] = Piece(1 , ROOK);
        _table[2][1] = Piece(1 , HORSE);
        _table[3][1] = Piece(1 , BISHOP);
        _table[4][1] = Piece(1 , QUEEN);
        _table[5][1] = Piece(1 , KING);
        _table[6][1] = Piece(1 , BISHOP);
        _table[7][1] = Piece(1 , HORSE);
        _table[8][1] = Piece(1 , ROOK);
   
       
        _table[1][2] = Piece(1 , PAWN);
        _table[2][2] = Piece(1 , PAWN);
        _table[3][2] = Piece(1 , PAWN);
        _table[4][2] = Piece(1 , PAWN);
        _table[5][2] = Piece(1 , PAWN);
        _table[6][2] = Piece(1 , PAWN);
        _table[7][2] = Piece(1 , PAWN);
        _table[8][2] = Piece(1 , PAWN);

        }else if(player == 2){

        _table[1][8] = Piece(2 , ROOK);
        _table[2][8] = Piece(2 , HORSE);
        _table[3][8] = Piece(2 , BISHOP);
        _table[4][8] = Piece(2 , KING);
        _table[5][8] = Piece(2 , QUEEN);
        _table[6][8] = Piece(2 , BISHOP);
        _table[7][8] = Piece(2 , HORSE);
        _table[8][8] = Piece(2 , ROOK);
   
       
        _table[1][7] = Piece(2 , PAWN);
        _table[2][7] = Piece(2 , PAWN);
        _table[3][7] = Piece(2 , PAWN);
        _table[3][7] = Piece(2 , PAWN);
        _table[5][7] = Piece(2 , PAWN);
        _table[6][7] = Piece(2 , PAWN);
        _table[7][7] = Piece(2 , PAWN);
        _table[8][7] = Piece(2 , PAWN);

        }else{}

    }

}