        *> -------------------------
        *> leaveroom.
        *> Takes: Player (Standard arguments)
        *> Leaves the room the player is currently in.
        *> Modifies:
        *> Dependencies: 
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. leaveroom.
       DATA DIVISION.
	   WORKING-STORAGE SECTION.
	   
       01 pgres  usage pointer.
       01 querystring pic x(255).

       LINKAGE SECTION.
       01 pgconn usage pointer.
       COPY "init.l".
       
       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId.
       Begin.

       String "UPDATE Players SET roomid = null, lastseen = now(), ready = false, newwords = false, newround = false WHERE name = '", function trim(Player), "';", x"00" into Querystring
       END-STRING
       call "PQexec" using
             by value pgconn
             by reference querystring
             returning pgres
       end-call

       EXIT PROGRAM.
