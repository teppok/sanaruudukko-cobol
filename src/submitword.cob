        *> -------------------------
        *> submitword.
        *> Takes: Standard arguments + word.
        *> Checks if the current round is still going on and if it is, gets the current
        *>   board and calls checkword to see if the word is in the board. If it is,
        *>   queries wordlist (with Language='FI') and adds the word to the player's word list
        *>   possibly with Words.Languagecheck=true if it's in the list and false if it's not.
        *> Modifies:
        *> Dependencies: roundstatus, checkword
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. submitword.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(255).
       
       
       01 RoundOk usage binary-long.
       01 WordExists usage binary-long.
       01 WordOk usage binary-long.
       
       01 Loopstatus pic 9 VALUE 0.
         88 Going VALUE 0.
         88 Invalidword VALUE 1.
         88 Validword VALUE 2.
       
       01 Board PIC x(16) VALUES SPACES.
       
       01 CurrentTime pic 9(8).

       01 RoundStatus pic x.
          88 RoundFinished value "f".
          88 RoundContinues value "t".
       
       LINKAGE SECTION.
       01 pgconn usage pointer.
       01 Word pic x(16).

       COPY "init.l".

       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId, Word.
       Begin.

       CALL "roundstatus" USING BY REFERENCE pgconn Player RoomId RoundId RoundStatus
       
       IF RoundFinished THEN
         EXIT PROGRAM
       END-IF

       IF Word IS NOT = SPACES THEN
       
               STRING "SELECT Word FROM Words WHERE Word = '" function trim(Word), "' AND Player = '", function trim(Player), "' AND ",
                      "RoundId = ", RoundId, " AND RoomId = ", RoomId, ";", x"00" INTO querystring
               END-STRING
               call "PQexec" using
                   by value pgconn
                   by reference querystring
                   returning pgres
               end-call

                call "PQntuples" using by value pgres returning WordExists
                
                IF WordExists > 0 THEN
                  EXIT PROGRAM
                END-IF

               
               string "SELECT Board FROM Rounds WHERE RoundNum = ", RoundId, 
                      "AND Roundstart + interval '3 minutes' >= now() ",
                      "AND RoomId = ", RoomId, ";", x"00" INTO QueryString
                  call "PQexec" using
                   by value pgconn
                   by reference querystring
                   returning pgres
               end-call

                call "PQntuples" using by value pgres returning RoundOk

               IF RoundOk > 0 THEN
          
                   call "PQgetvalue" using
                    by value pgres
                       by value 0
                       by value 0
                       returning resptr
                   end-call
                   set address of resstr to resptr
                   string resstr delimited by x"00" into Board end-string

                   call "checkword" using
                     by content Board
                     by content Word
                     by reference LoopStatus
                   end-call
                   

                   IF ValidWord AND WordExists = 0 THEN

                     STRING "SELECT Word FROM WordList WHERE Word = '", function trim(Word), "' AND LANGUAGE = 'FI';", x"00" INTO QueryString
                     END-STRING
                     call "PQexec" using
                       by value pgconn
                       by reference querystring
                       returning pgres
                     end-call

                     call "PQntuples" using by value pgres returning WordOk

                     
                     IF WordOk > 0 THEN
                     
                         string "insert into words ( Player, RoomId, RoundId, Word, Languagecheck, disabled ) values ( '", 
                         function trim(Player), "', ", RoomId, ", ", RoundId, ", '", function trim(Word), "', true, false );", x"00" INTO querystring
                           END-STRING
                      ELSE
                         string "insert into words ( Player, RoomId, RoundId, Word, Languagecheck, disabled ) values ( '", 
                         function trim(Player), "', ", RoomId, ", ", RoundId, ", '", function trim(Word), "', false, false );", x"00" INTO querystring
                           END-STRING
                      END-IF
                           call "PQexec" using
                               by value pgconn
                               by reference querystring
                               returning resptr
                          end-call
                   END-IF *> validword
               END-IF *> roundok
        END-IF

       EXIT PROGRAM.
       