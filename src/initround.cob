        *> -------------------------
        *> initround.
        *> Takes: Standard arguments.
        *> This is called from NewRound. This subprogram checks if the round has ended
        *>   and if it has, increments the round counter and initializes the board with
        *>   a new randomized board.
        *>   This routine is not thread safe in a sense that two players may enter initround
        *>   simultaneously. However, they get different new round values from the database
        *>   (nextval() is assumed to be an atomic operation), so the round that the first
        *>   player initializes gets overwritten by the round from the second player.
        *> Modifies:
        *> Dependencies: 
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. initround.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 dices.
         02 dice-values.
		   03 filler pic x(6) value "AISBUJ".
		   03 filler pic x(6) value "AEENEA".
		   03 filler pic x(6) value "aIoNST".
		   03 filler pic x(6) value "ANPFSK".
		   03 filler pic x(6) value "APHSKO".
		   03 filler pic x(6) value "DESRIL".
		   03 filler pic x(6) value "EIENUS".
		   03 filler pic x(6) value "HIKNMU".
		   03 filler pic x(6) value "AGAaLa".
		   03 filler pic x(6) value "CIOTMU".
		   03 filler pic x(6) value "AJTOTO".
		   03 filler pic x(6) value "EITOSS".
		   03 filler pic x(6) value "ELYTTR".
		   03 filler pic x(6) value "AKITMV".
		   03 filler pic x(6) value "AILKVY".
		   03 filler pic x(6) value "ALRNNU".

           02 diceset redefines dice-values.
          03 dice occurs 16 times.
            04 diceside pic x occurs 6 times.
            
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(256).

       01 NPlayers usage binary-long.
       01 PlayerIdx usage binary-long.
       01 Readystate PIC X.
         88 ReadystateFalse VALUE "f".
       01 TotalReadyState PIC 9 VALUE 1.
         88 TotalReadyStateFalse value 0.
         88 TotalReadyStateTrue value 1.
         
       01 CurrentTime pic 9(8).
       
       01 Board pic x(16).
       01 Moveloc pic 99.
       01 Moveindex pic 99.
       01 boardtmp pic x.
    *>   01 Randomseed pic 9V9(12).
    *>   01 Randomint pic 9.
       
       01 Roll pic 9.
       
       01 Tmp pic x(8) value SPACES.
       
       LINKAGE SECTION.
       01 pgconn usage pointer.
       01 Player pic x(16).
       01 RoomId pic 99999 usage display.
       01 RoundId pic 99999 usage display.

       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId.
       Begin.
       STRING "SELECT Ready FROM PLAYERS WHERE LastSeen + interval '20 seconds' > now() AND RoomId = ", RoomId, ";", x"00" INTO QueryString
       END-STRING
       call "PQexec" using
           by value pgconn
           by reference querystring
           returning pgres
       end-call
       
       call "PQntuples" using by value pgres returning Nplayers
       
       Set TotalReadyStateTrue TO True
       PERFORM VARYING PlayerIdx FROM 0 BY 1 UNTIL (PlayerIdx >= NPlayers OR TotalReadyStateFalse)
       
           call "PQgetvalue" using
            by value pgres
               by value PlayerIdx
               by value 0
               returning resptr
           end-call
           set address of resstr to resptr
           string resstr delimited by x"00" into Readystate end-string
           
           IF ReadyStateFalse THEN
             Set TotalReadyStateFalse TO True
           END-IF
        END-PERFORM
        IF TotalReadyStateTrue THEN
            PERFORM InitNewRound
        END-IF
       EXIT PROGRAM.

       InitNewRound.
       PERFORM RandomizeBoard.
       STRING "SELECT nextval('rounds_roundnum_seq');", x"00" INTO QueryString
       END-STRING
       call "PQexec" using
           by value pgconn
           by reference querystring
           returning pgres
       end-call

       call "PQgetvalue" using
            by value pgres
               by value 0
               by value 0
               returning resptr
       end-call
       set address of resstr to resptr
       MOVE SPACES TO TMP
       string resstr delimited by x"00" into Tmp end-string
       MOVE Tmp TO RoundId

       string "insert into rounds ( roundnum, roundstart, board, roomid ) values ( ", RoundId, ", now(), '", Board, "', ", RoomId, " ) ;", x"00" INTO querystring
       END-STRING

       call "PQexec" using
                by value pgconn
                by reference querystring
                returning resptr
       end-call

       string "UPDATE Players SET Ready = false, RoundEnded = false, MoreTime = false WHERE RoomId = ", RoomId, ";", x"00" INTO querystring
       END-STRING
       
       call "PQexec" using
            by value pgconn
            by reference querystring
            returning resptr
       end-call.

       
       RandomizeBoard.
       ACCEPT CurrentTime FROM TIME.

       MOVE "ABCDEFGHIJKLMNOP" to Board.
       COMPUTE Moveloc = function RANDOM(CurrentTime)
    *>   MOVE Randomseed to Randomint
    *>   COMPUTE Randomseed = Randomseed - function integer-part (Randomseed)
    *>   DISPLAY Randomseed, " ", randomint
       PERFORM VARYING Moveindex FROM 16 BY -1 UNTIL MoveIndex = 1
    *>     COMPUTE Randomseed = (function RANDOM * 10)
    *>     MOVE Randomseed to Randomint
    *>     COMPUTE Randomseed = Randomseed - function integer-part (Randomseed)
       
         COMPUTE Moveloc = (function Random * (Moveindex)) + 1 END-COMPUTE
    *>	 DISPLAY Moveindex, " ", Moveloc, " ", Randomseed END-DISPLAY
         MOVE Board(Moveloc:1) TO boardtmp
         MOVE Board(Moveindex:1) TO Board(Moveloc:1)
         MOVE boardtmp TO Board(Moveindex:1)
       END-PERFORM.
    *>   DISPLAY Board.
       PERFORM VARYING Moveindex FROM 1 BY 1 UNTIL Moveindex > 16
    *>     COMPUTE Randomseed = (function RANDOM * 10)
    *>     MOVE Randomseed to Randomint
    *>     COMPUTE Randomseed = Randomseed - function integer-part (Randomseed)
         COMPUTE Roll = (function Random * 6) + 1 END-COMPUTE
    *>	 DISPLAY Roll
         EVALUATE Board(Moveindex:1)
           WHEN "A" MOVE Diceside(1,Roll) to Board(Moveindex:1)
           WHEN "B" MOVE Diceside(2,Roll) to Board(Moveindex:1)
           WHEN "C" MOVE Diceside(3,Roll) to Board(Moveindex:1)
           WHEN "D" MOVE Diceside(4,Roll) to Board(Moveindex:1)
           WHEN "E" MOVE Diceside(5,Roll) to Board(Moveindex:1)
           WHEN "F" MOVE Diceside(6,Roll) to Board(Moveindex:1)
           WHEN "G" MOVE Diceside(7,Roll) to Board(Moveindex:1)
           WHEN "H" MOVE Diceside(8,Roll) to Board(Moveindex:1)
           WHEN "I" MOVE Diceside(9,Roll) to Board(Moveindex:1)
           WHEN "J" MOVE Diceside(10,Roll) to Board(Moveindex:1)
           WHEN "K" MOVE Diceside(11,Roll) to Board(Moveindex:1)
           WHEN "L" MOVE Diceside(12,Roll) to Board(Moveindex:1)
           WHEN "M" MOVE Diceside(13,Roll) to Board(Moveindex:1)
           WHEN "N" MOVE Diceside(14,Roll) to Board(Moveindex:1)
           WHEN "O" MOVE Diceside(15,Roll) to Board(Moveindex:1)
           WHEN "P" MOVE Diceside(16,Roll) to Board(Moveindex:1)
        END-EVALUATE
       END-PERFORM.
    *>   DISPLAY Board.
       
       