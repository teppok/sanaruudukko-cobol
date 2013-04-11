        *> -------------------------
        *> init.
        *> Takes: Player, Passcode
        *> Checks that the username and password match.
        *>   After that, calls getround to initialize RoomId and RoundId to their proper values.
        *> Modifies: RoomId, RoundId
        *> Dependencies: getround
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. init.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(255).
       01 PlayerOk usage binary-long.
       
       LINKAGE SECTION.
        01 pgconn usage pointer.
        COPY "init.l".
       PROCEDURE DIVISION USING pgconn, Player, Passcode, RoomId, RoundId.

       String "Select Name From Players where Name = '", function trim(player), "' AND PassCode = '", function trim(passcode), "';", x"00" INTO querystring
       END-STRING
          call "PQexec" using
           by value pgconn
           by reference querystring
           returning pgres
       end-call

       call "PQntuples" using by value pgres returning PlayerOk
       IF PlayerOk = 0 THEN
         call "CBL_OC_NANOSLEEP" using "1000" & "000000" end-call
         MOVE HIGH-VALUES TO Player
         MOVE HIGH-VALUES TO RoomId
         MOVE HIGH-VALUES TO RoundId
         EXIT PROGRAM
       END-IF
       
       CALL "getround" USING
          BY REFERENCE pgconn
          BY CONTENT Player
          BY REFERENCE RoomId
          BY REFERENCE RoundId
       END-CALL.
       
       String "UPDATE Players SET LastSeen = now() where Name = '", function trim(player), "';", x"00" INTO querystring
       END-STRING
          call "PQexec" using
           by value pgconn
           by reference querystring
           returning pgres
       end-call.

