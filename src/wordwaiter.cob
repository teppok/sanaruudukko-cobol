        *> -------------------------
        *> wordwaiter.
        *> Takes: Standard arguments.
        *> Waits for 15 minutes, or less if polling of database flags returns true.
        *>   If other players have raised NewWords flag, there will be new data in the
        *>   displaywords list.
        *>   If other players have raised NewRound flag, there will be new data in the
        *>   displayroom info (ie. board).
        *>   If other players have entered any new chat messages, we find this by checking
        *>   submitted chat ids. 
        *>   After waiting, do a getround call to make sure we're at the right round.
        *>   This is mainly for a raised NewRound flag (which indicates that the round has
        *>   in fact changed), so doing it for other flags might be redundant.
        *>   If NewRound flag was set, reset it as we now have seen and processed it.
        *> Modifies: NewChat, NewWords.
        *> Dependencies: getround
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. wordwaiter.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(256).

       01 Looped pic 99.
       
       01 NewRound pic x.
         88 NewRoundStarted VALUE "t".
         

       LINKAGE SECTION.
       01 pgconn usage pointer.
       COPY "init.l".
       01 NewChat pic x.
         88 NewChatReceived VALUE "t".
       
       01 NewWords pic x.
         88 NewWordsReceived VALUE "t".
       
         
       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId, NewWords, NewChat.
       Begin.
       MOVE "f" TO NewWords
       MOVE "f" TO NewChat
       MOVE "f" TO NewRound
       
       MOVE 0 TO Looped
       PERFORM WITH TEST BEFORE UNTIL ( NewWordsReceived OR NewChatReceived OR NewRoundStarted OR Looped > 75 )
              STRING "SELECT NewWords from Players WHERE Name = '", function trim(Player), "';", x"00" INTO QueryString
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
               string resstr delimited by x"00" into NewWords end-string

              STRING "SELECT LastChat <= (SELECT MAX(Id) FROM chat WHERE RoomId = ", RoomId, " ) from Players WHERE Name = '", function trim(Player), "';", x"00" INTO QueryString
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
               string resstr delimited by x"00" into NewChat end-string
               
              STRING "SELECT NewRound from Players WHERE Name = '", function trim(Player), "';", x"00" INTO QueryString
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
               
               IF NOT NewWordsReceived AND NOT NewChatReceived AND NOT NewRoundStarted THEN
                  call "CBL_OC_NANOSLEEP" using "200" & "000000" end-call
               END-IF
               ADD 1 TO Looped
           END-PERFORM

        CALL "getround" USING
          BY REFERENCE pgconn
          BY CONTENT Player
          BY REFERENCE RoomId
          BY REFERENCE RoundId
        END-CALL.

        IF NewRoundStarted THEN
           STRING "UPDATE Players SET NewRound=false WHERE Name = '", function trim(Player), "';", x"00" INTO QueryString
           END-STRING
           call "PQexec" using by value pgconn
             by reference querystring
             returning pgres
           end-call
        END-IF

        EXIT PROGRAM.
        
