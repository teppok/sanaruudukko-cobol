        *> -------------------------
        *> newround.
        *> Takes: Standard arguments.
        *> Use roundstatus to check if round is active and if it is, exit.
        *>   Flip the value of Players.ready and call initround, which checks if all players
        *>   have ready flags set and inits a new round. Also uses Players.NewRound to notify
        *>   other players' wordwaiter to refresh their Board info.
        *> Modifies:
        *> Dependencies: roundstatus, initround
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. newround.
       DATA DIVISION.
	   WORKING-STORAGE SECTION.
       
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 querystring pic x(255).

       01 RoundStatus pic x.
          88 RoundFinished value "f".
          88 RoundContinues value "t".

       LINKAGE SECTION.
       01 pgconn usage pointer.
       COPY "init.l".

       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId.
       Begin.

       CALL "roundstatus" USING BY REFERENCE pgconn Player RoomId RoundId RoundStatus.
       
       IF RoundContinues THEN
         EXIT PROGRAM
       END-IF
       
         string "UPDATE Players SET Ready=not Ready WHERE Name = '", function trim(Player), "';", x"00" into querystring
         end-string
   	     call "PQexec" using
             by value pgconn
             by reference querystring
             returning pgres
         end-call

        STRING "UPDATE Players SET NewRound = true WHERE RoomId = ", RoomId, " AND NOT Name = '", function trim(player), "';", x"00" into querystring
        END-STRING
        call "PQexec" using
               by value pgconn
               by reference querystring
               returning resptr
        end-call
        
        CALL "initround" USING
          BY REFERENCE pgconn
          BY CONTENT Player
          BY CONTENT RoomId
          BY REFERENCE RoundID
        END-CALL

     *> RoundEnded vain signaloi kierroksen lopussa
     *> kierroksen loppu: saadaan kellosta
     *> kierroksen alku: updatoidaan muuten vain newwordsia
        
       EXIT PROGRAM.
	   
