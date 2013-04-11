        *> -------------------------
        *> enterroom.
        *> Takes: Player, RoomId
        *> Sets up player to be in room indicated by RoomId.
        *>   This includes updating Players.lastchat and other Players fields.
        *>   Finally calls getround to initialize roundid to its proper value for
        *>   the room.
        *> Modifies: RoundId
        *> Dependencies: getround

       IDENTIFICATION DIVISION.
       PROGRAM-ID. enterroom.
       DATA DIVISION.
	   WORKING-STORAGE SECTION.
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(255).

       01 ChatId pic 999999.
       01 TmpChatId pic x(8).
       
       LINKAGE SECTION.
       01 Player pic x(16).
       01 pgconn usage pointer.
       01 RoomId pic 99999 usage display.
       01 RoundId pic 99999 usage display.
       
       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId.
       Begin.

        STRING "SELECT MAX(Id) FROM chat", x"00" into querystring end-string
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
           MOVE SPACES to TmpChatId
           string resstr delimited by x"00" into TmpChatId end-string
           IF TmpChatId IS NOT = SPACES THEN
                MOVE TmpChatId TO ChatId
                ADD 1 TO ChatId
           ELSE
                MOVE 0 TO ChatId
           END-IF
       
        String "UPDATE Players SET roomid = ", RoomId, ", lastseen = now(), ready = false, newwords = false, newround = true, lastchat = ", 
            ChatId, " WHERE name = '", function trim(Player), "';", x"00" into Querystring
        END-STRING
       call "PQexec" using
             by value pgconn
             by reference querystring
             returning pgres
       end-call
      
       CALL "getround" USING
          BY REFERENCE pgconn
          BY CONTENT Player
          BY REFERENCE RoomId
          BY REFERENCE RoundId
       END-CALL

            
       EXIT PROGRAM.
	   
