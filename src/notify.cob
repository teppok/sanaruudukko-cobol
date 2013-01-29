        *> -------------------------
        *> notify.
        *> Takes: RoomId, Player (Standard arguments)
        *> Notifies others that are not the player that wordlist has changed by raising NewWords flag.
        *> Modifies:
        *> Dependencies: 
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. notify.
       DATA DIVISION.
	   WORKING-STORAGE SECTION.
       01 pgres  usage pointer.
       01 querystring pic x(255).

       LINKAGE SECTION.
       01 pgconn usage pointer.
       COPY "init.l".
       
       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId.
       Begin.

        String "UPDATE Players SET NewWords = true WHERE roomid = ", RoomId, " AND NOT Name = '", function trim(Player), "';", x"00" into Querystring
        END-STRING
        call "PQexec" using
               by value pgconn
               by reference querystring
               returning pgres
        end-call
       
       EXIT PROGRAM.
	   
