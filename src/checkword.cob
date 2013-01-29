        *> -------------------------
        *> checkword.
        *> Takes: board, word and (as reference) status value.
        *> Goes through the board and test if the word exists.
        *> Modifies: status to indicate whether the word was found or not.
        *> Dependencies: 
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. checkword.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      
       01 wordindex pic 99.
       01 wordlength pic 99.
       

       01 Placestatus pic 9 VALUE 0.
         88 Disallow VALUE 0.
         88 Allow VALUE 1.
       01 Matchlength pic 99 VALUE 0.
       01 Listcounter pic 99 VALUE 0.
       
       01 CoordTable.
         02 Coords occurs 16 times.
           03 x pic 99.
           03 y pic 99.
       01 tmpx pic 99.
       01 tmpy pic 99.

       LINKAGE SECTION.
       01 Board PIC x(16) VALUES SPACES.
       01 Word pic x(16).
       01 Loopstatus pic 9 VALUE 0.
         88 Going VALUE 0.
         88 Invalidword VALUE 1.
         88 Validword VALUE 2.
       
       
       PROCEDURE DIVISION USING Board, Word, Loopstatus.
       Begin.
       move function length(function trim(word)) to wordlength.

       MOVE 1 to wordindex
       MOVE 1 to tmpx
       MOVE 1 to tmpy
       MOVE 0 to matchlength
       SET Going TO TRUE
    *>   DISPLAY Board
       PERFORM UNTIL Validword OR Invalidword
    *>        DISPLAY tmpx, " ", tmpy, " ", matchlength END-DISPLAY
            SET Disallow TO TRUE
            IF matchlength > 0 THEN
              IF function ABS(x(matchlength) - tmpx) < 2 AND function ABS(y(matchlength) - tmpy) < 2 THEN
                SET Allow TO TRUE
              END-IF
              PERFORM CheckList
            ELSE
              SET Allow TO TRUE
            END-IF
    *>        DISPLAY PlaceStatus
            IF Allow AND (word((matchlength + 1):1) = board((tmpy - 1)*4+tmpx:1)) THEN
    *>	       DISPLAY "Match at " tmpx " and " tmpy
               ADD 1 to matchlength
               MOVE tmpx to x(matchlength)
               MOVE tmpy to y(matchlength)
               MOVE 1 to tmpx
               MOVE 1 to tmpy
               ADD 1 to wordindex
               IF matchlength = wordlength THEN
                 SET Validword TO TRUE
               END-IF
           ELSE
             IF tmpx = 4 AND tmpy = 4 THEN
               IF matchlength = 0 THEN
                   SET Invalidword TO TRUE
               ELSE
                   MOVE x(matchlength) to tmpx
                   MOVE y(matchlength) to tmpy
                   SUBTRACT 1 FROM matchlength
               END-IF
            END-IF
    *> Tarvitaan uusi tarkistus, jos x(matchlength)=4 ja y(matchlength)=4, jolloin pitää backtrackata lisää
             IF tmpx = 4 AND tmpy = 4 THEN
               IF matchlength = 0 THEN
                   SET Invalidword TO TRUE
               ELSE
                   MOVE x(matchlength) to tmpx
                   MOVE y(matchlength) to tmpy
                   SUBTRACT 1 FROM matchlength
               END-IF
            END-IF
             
             ADD 1 to tmpx
             IF tmpx > 4 THEN
               ADD 1 to tmpy
               MOVE 1 to tmpx
             END-IF
                   
             
           END-IF
       END-PERFORM.
    *>   DISPLAY LoopStatus.
       
       CheckList.
       PERFORM WITH TEST BEFORE VARYING Listcounter FROM 1 BY 1 UNTIL Listcounter > matchlength
         IF tmpx = x(Listcounter) AND tmpy = y(Listcounter) THEN
           SET Disallow TO TRUE
         END-IF
       END-PERFORM.
       