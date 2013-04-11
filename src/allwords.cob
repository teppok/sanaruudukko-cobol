        *> -------------------------
        *> allwords.
        *> Takes: standard arguments.
        *> Goes through database table Wordlist (with argument language='FI') and
        *>   for each word tests whether it is found in the board of the current round
        *>   and prints if it does.
        *> Modifies:
        *> Dependencies: roundstatus to check if the round continues
        *>               checkword to check if the word is in the table

       IDENTIFICATION DIVISION.
       PROGRAM-ID. allwords.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 pgres  usage pointer.
       01 pgres2  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(256).

       01 NWords usage binary-long.
       01 WordIdx usage binary-long.
       
       01 Loopstatus pic 9 VALUE 0.
         88 Going VALUE 0.
         88 Invalidword VALUE 1.
         88 Validword VALUE 2.
       
       01 Board PIC x(16) VALUES SPACES.
       01 ListWord pic x(16).

       LINKAGE SECTION.
       01 pgconn usage pointer.
       01 RoundId pic 99999 usage display.
       
       PROCEDURE DIVISION USING pgconn, RoundId.
       Begin.

       string "SELECT Board FROM Rounds WHERE RoundId = ", RoundId, " ;", x"00" INTO QueryString
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
       string resstr delimited by x"00" into Board end-string
       
       STRING "SELECT Word from WordList WHERE Language = 'FI';", x"00" INTO QueryString
       END-STRING
          call "PQexec" using by value pgconn
            by reference querystring
            returning pgres
       end-call

       call "PQntuples" using by value pgres returning NWords

       PERFORM VARYING WordIdx FROM 0 BY 1 UNTIL WordIdx >= NWords
               call "PQgetvalue" using by value pgres
                   by value WordIdx
                   by value 0
                   returning resptr
               end-call
               set address of resstr to resptr
               move SPACES to ListWord
               string resstr delimited by x"00" into ListWord end-string

               CALL "checkword" using
                 by content Board
                 by content ListWord
                 By reference LoopStatus
               END-CALL
               
               IF ValidWord THEN
                   STRING "INSERT INTO ValidWords (Word, RoundId) VALUES ('", function trim(ListWord), "', ", RoundId,  ");", x"00" INTO QueryString
                   END-STRING
                      call "PQexec" using by value pgconn
                        by reference querystring
                        returning pgres2
                   end-call

        *>          DISPLAY "<word>", function trim(ListWord), "</word>"
               END-IF
               
        END-PERFORM

        EXIT PROGRAM.
        
