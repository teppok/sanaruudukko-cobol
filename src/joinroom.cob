        *> -------------------------
        *> joinroom.
        *> Takes: Room. (Standard arguments)
        *> Checks that the room id specified in parameter Room exists and if it does,
        *>   puts it in RoomId. Otherwise puts high-values to RoomId.
        *> Modifies: RoomId
        *> Dependencies: 
        *> XXX Change name to something else?
       IDENTIFICATION DIVISION.
       PROGRAM-ID. joinroom.
       DATA DIVISION.
	   WORKING-STORAGE SECTION.
       01 pgres  usage pointer.
       01 querystring pic x(255).
	   
       01 Roomtest usage binary-long value 0.

       LINKAGE SECTION.
       01 pgconn usage pointer.
       01 Room pic x(16).
       COPY "init.l".
       
       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId, Room.
       Begin.

       String "SELECT Id FROM Rooms WHERE id = ", function trim(Room), ";", x"00" into Querystring
       END-String
   	   call "PQexec" using by value pgconn
	       by reference querystring
           returning pgres
       end-call

       CALL "PQntuples" using by value pgres returning Roomtest
       END-CALL	   
       IF RoomTest > 0 THEN
         MOVE Room to RoomId
       ELSE 
          MOVE HIGH-VALUE TO RoomId
       END-IF
       
       EXIT PROGRAM.
	   
