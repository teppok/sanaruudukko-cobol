        *> -------------------------
        *> roundstartwaiter.
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. roundstartwaiter.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(256).

       01 NewRound pic x.
         88 NewRoundStarted VALUE "t".

       LINKAGE SECTION.
       01 pgconn usage pointer.
       COPY "init.l".
       
       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId.
       Begin.
       MOVE "f" TO NewRound
    *>   STRING "INSERT INTO Status VALUES ('Debug', '1');", x"00" INTO QueryString
    *>   call "PQexec" using by value pgconn
    *>     by reference querystring
    *>     returning pgres
    *>   end-call

       PERFORM WITH TEST BEFORE UNTIL ( NewRoundStarted )
              STRING "SELECT now() > RoundStart from Rounds WHERE RoundId = ", RoundId, " ;", x"00" INTO QueryString
              END-STRING
              call "PQexec" using by value pgconn
                by reference querystring
                returning pgres
              end-call

               call "PQgetvalue" using by value pgres
                   by value 0
                   by value 0
                   returning resptr
               end-call
               set address of resstr to resptr
               string resstr delimited by x"00" into NewRound end-string

               IF NOT NewRoundStarted THEN
                  call "CBL_OC_NANOSLEEP" using "200" & "000000" end-call
               END-IF
        END-PERFORM

        IF NewRoundStarted THEN
           STRING "UPDATE Players SET NewRound=true WHERE RoomId = ", RoomId, ";", x"00" INTO QueryString
           END-STRING
           call "PQexec" using by value pgconn
             by reference querystring
             returning pgres
           end-call
        END-IF

        EXIT PROGRAM.
        
