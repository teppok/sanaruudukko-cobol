        *> -------------------------
        *> getround.
        *> Takes: Player.
        *> Takes player id and initializes RoomId and RoundId to values fetched
        *>   from the database. In case of undefined values, sets them to HIGH-VALUES.
        *> Modifies: RoomId, RoundId
        *> Dependencies: 
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. getround.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(255).

       01 RoundFail usage binary-long.
       01 RoomFail usage binary-long.
       
       01 Tmp pic x(16) VALUE SPACES.
       LINKAGE SECTION.
       01 pgconn usage pointer.
       01 Player pic x(16).
       01 RoomId pic 99999 usage display.
       01 RoundId pic 99999 usage display.

       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId.

       String "Select RoomId From Players where Name = '", function trim(player), "';", x"00" INTO querystring
       END-STRING
          call "PQexec" using
           by value pgconn
           by reference querystring
           returning pgres
       end-call

       call "PQgetisnull" using by value pgres
           by value 0
           by value 0
           returning RoomFail
       end-call
       
       IF RoomFail = 1 THEN
         MOVE HIGH-VALUES TO RoomId
         MOVE HIGH-VALUES TO RoundId
         EXIT PROGRAM
       END-IF
       
       call "PQgetvalue" using
        by value pgres
           by value 0
           by value 0
           returning resptr
       end-call
       set address of resstr to resptr
       MOVE SPACES TO Tmp
       string resstr delimited by x"00" into Tmp end-string
       MOVE Tmp TO RoomId.
       
       String "Select max(RoundId) From Rounds where RoomId = ", function trim(RoomId), ";", x"00" INTO querystring
       END-STRING
          call "PQexec" using
           by value pgconn
           by reference querystring
           returning pgres
       end-call

       call "PQgetisnull" using by value pgres
           by value 0
           by value 0
           returning RoundFail
       end-call
       
    *>   call "PQntuples" using by value pgres returning RoundOk

       IF RoundFail = 1 THEN
         MOVE HIGH-VALUES TO RoundId
         EXIT PROGRAM
       END-IF
       
    
       call "PQgetvalue" using
        by value pgres
           by value 0
           by value 0
           returning resptr
       end-call
       set address of resstr to resptr
       MOVE SPACES TO TMP
       string resstr delimited by x"00" into Tmp end-string
       MOVE Tmp TO RoundId.
       
