        *> -------------------------
        *> moretime.
        *> Takes: Standard arguments.
        *> Requests more time for the current round. First checks if the round is active
        *>   using roundstatus, and if it is, flags the player requesting more time.
        *>   Then checks if all players have flagged more time and if they have, grants
        *>   more time.
        *>   XXX This routine is severely non-thread safe. It is possible for two players
        *>   to click simultaneosly more time and enter InitMoreTime procedure simultaneously,
        *>   granting time twice.
        *>   A fix for this would be: - Get remaining round time.
        *>   - Check if time is less than 60 seconds and if it is, increment it by 120 seconds.
        *>   - Overwrite the old time in the database with this value, instead of adding to it.
        *>   This requires coding time operations in COBOL that are compatible with SQL.
        *> Modifies:
        *> Dependencies: roundstatus
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. moretime.
       DATA DIVISION.
	   WORKING-STORAGE SECTION.
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(255).
	   
       01 NPlayers usage binary-long.
       01 PlayerIdx usage binary-long.
       01 State PIC X.
         88 StateFalse VALUE "f".
       01 TotalState PIC 9 VALUE 1.
         88 TotalStateFalse value 0.
         88 TotalStateTrue value 1.

       01 RoundStatus pic x.
          88 RoundFinished value "f".
          88 RoundContinues value "t".
       
       LINKAGE SECTION.
       01 pgconn usage pointer.
       
       COPY "init.l".
         
       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId.
       Begin.

       CALL "roundstatus" USING BY REFERENCE pgconn Player RoomId RoundId RoundStatus.
       
       IF RoundFinished THEN
         EXIT PROGRAM
       END-IF

       *>   Roundstart -- 2 minutes -- 1 minute
       *>                                sallittua lisätä aikaa vain 1 minuutti ennen loppua.
       
       string "SELECT Roundstart + interval '2 minutes' >= now() FROM Rounds WHERE RoundId = ", RoundId, 
              " AND RoomId = ", RoomId, ";", x"00" INTO QueryString
       call "PQexec" using
           by value pgconn
           by reference querystring
           returning pgres
       end-call

       call "PQgetvalue" using by value pgres
           by value 0
           by value 0
           returning resptr
        end-call
        set address of resstr to resptr
        string resstr delimited by x"00" into RoundStatus end-string
       
       IF RoundContinues THEN
         EXIT PROGRAM
       END-IF

       string "UPDATE Players SET MoreTime=not Moretime WHERE Name = '", function trim(Player), "';", x"00" into querystring
       end-string
   	     call "PQexec" using
             by value pgconn
             by reference querystring
             returning pgres
         end-call

       STRING "SELECT MoreTime FROM PLAYERS WHERE LastSeen + interval '20 seconds' > now() AND RoomId = ", RoomId, ";", x"00" INTO QueryString
       END-STRING
       call "PQexec" using
           by value pgconn
           by reference querystring
           returning pgres
       end-call
       
       call "PQntuples" using by value pgres returning Nplayers
       
       Set TotalStateTrue TO True
       PERFORM VARYING PlayerIdx FROM 0 BY 1 UNTIL (PlayerIdx >= NPlayers OR TotalStateFalse)
       
           call "PQgetvalue" using
            by value pgres
               by value PlayerIdx
               by value 0
               returning resptr
           end-call
           set address of resstr to resptr
           string resstr delimited by x"00" into State end-string
           
           IF StateFalse THEN
             Set TotalStateFalse TO True
           END-IF
        END-PERFORM
        IF TotalStateTrue THEN
            PERFORM InitMoreTime
        END-IF
       EXIT PROGRAM.

        InitMoreTime.
        STRING "UPDATE Rounds SET RoundStart = RoundStart + interval '2 minutes' WHERE ",
               " RoundId = ", RoundId, 
               " AND RoomId = ", RoomId, ";", x"00" INTO QueryString
        call "PQexec" using
           by value pgconn
           by reference querystring
           returning pgres
        end-call
        
       string "UPDATE Players SET NewRound = true, MoreTime = false WHERE RoomId = ", RoomId, ";", x"00" INTO querystring
       
       call "PQexec" using
            by value pgconn
            by reference querystring
            returning resptr
       end-call.

        CONTINUE.
        