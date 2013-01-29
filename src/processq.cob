        *> -------------------------
        *> processq.
        *> Takes: .
        *> Main CGI routine.
        *> - Reads HTTP query parameters from QUERY_STRING
        *> - Returns different status codes if eg. parameters are incorrect. These should not reach users.
        *> - Calls init to initialize db connection.
        *> - Looks at parameter func and calls different functions to do actions based on that
        *> - Then calls display functions to show data based on the performed actions.
        *> Modifies:
        *> Dependencies: parsequery, init, registerp and many more.
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. processq.
       DATA DIVISION.
	   WORKING-STORAGE SECTION.
       01 newline         pic x   value x'0a'.

       01 cgiquery pic x(256).
	   
       01 pgconn usage pointer.
       01 result usage binary-long.
	   
       COPY "init.l".

       01 Func pic x(16).
       01 Room pic x(16).
       01 Word pic x(16).
       01 RoomName pic x(16).
       01 NewChat pic x VALUE "f".
         88 NewChatReceived VALUE "t".
       
       01 NewWords pic x VALUE "f".
         88 NewWordsReceived VALUE "t".

       PROCEDURE DIVISION.
       Begin.

       display
           "Content-type: text/xml"
           newline
           newline
           '<?xml version="1.0" encoding="utf-8" ?>'
       end-display.

	   accept cgiquery from environment "QUERY_STRING"

	   
       CALL "parsequery" USING by reference CgiQuery
         By content "player          "
         By Reference Player
         By content "passcode        "
         By reference Passcode
         By content "func            "
         By reference Func
       END-CALL

       CALL "parsequery" USING by reference CgiQuery
          By content "room            "
          By Reference Room
          By content "roomname        "
          By reference RoomName
          By content "word            "
          By reference Word
       END-CALL

  *> 	   MOVE "Teppo" TO Player
  *>     MOVE "A" TO Passcode
  *>     MOVE "moretime" to Func
  *>     MOVE "test" to RoomName
       
       IF Func IS = SPACES THEN
              DISPLAY "<data><status>100</status></data>"
              STOP RUN
       END-IF
       
       IF Player IS = SPACES OR PassCode IS = SPACES THEN
              DISPLAY "<data><status>1</status></data>"
              STOP RUN
       END-IF

       IF Func IS = "newroom" AND RoomName IS = SPACES THEN
              DISPLAY "<data><status>2</status></data>"
             STOP RUN
       END-IF

       IF ( Func IS = "submitword" OR "removeword" ) AND Word IS = SPACES THEN
              DISPLAY "<data><status>3</status></data>"
             STOP RUN
       END-IF

       IF Func IS = "joinroom" AND Room IS = SPACES THEN
              DISPLAY "<data><status>4</status></data>"
             STOP RUN
       END-IF

       
       IF Func IS = "registerp" THEN
           CALL "registerp" USING Player, PassCode
       END-IF

       CALL "init" USING 
         By reference pgconn 
         By reference Player
         By reference Passcode
         By reference RoomId
         By Reference RoundId
       END-CALL

       IF Player IS = HIGH-VALUES THEN
          DISPLAY "<data><status>1</status></data>"
          call "PQfinish" using by value pgconn returning result end-call
          STOP RUN
       END-IF

       IF RoomId IS = HIGH-VALUES AND ( Func IS = "moretime" OR "newround" OR "removeword" OR "submitword" OR "wordwaiter" OR "allwords" ) THEN
          DISPLAY "<data><status>5</status></data>"
          call "PQfinish" using by value pgconn returning result end-call
          STOP RUN
       END-IF

       IF RoundId IS = HIGH-VALUES AND ( Func IS = "allwords" OR "submitword" OR "removeword" ) THEN
          DISPLAY "<data><status>6</status></data>"
          call "PQfinish" using by value pgconn returning result end-call
          STOP RUN
       END-IF
       
       DISPLAY "<data>"

       *> In theory these procedures should not display any data.
       *> They only perform actions.
       
       EVALUATE Func
         WHEN "moretime" PERFORM MoreTime
         WHEN "newround" PERFORM NewRound
         WHEN "joinroom" PERFORM JoinRoom
         WHEN "submitword" PERFORM SubmitWord
         WHEN "removeword" PERFORM RemoveWord
         WHEN "getrooms" PERFORM GetRooms
         WHEN "leaveroom" PERFORM LeaveRoom
         WHEN "newroom" PERFORM NewRoom
         WHEN "wordwaiter" PERFORM WordWaiter
         WHEN "allwords" PERFORM AllWords
       END-EVALUATE

        IF Func IS = "joinroom" OR "newroom" OR "registerp" THEN
           CALL "enterroom" using
             by reference pgconn
             by content Player
             by content RoomId
             by reference RoundId
           END-CALL
        END-IF
        
       IF RoomId IS = HIGH-VALUES THEN
          DISPLAY "<status>10</status>"
       ELSE
        *> Call notify if we have done something that affects other players view.
           IF Func IS = "joinroom" OR "newroom" OR "registerp" OR "removeword" OR "submitword" OR "leaveroom" OR "moretime" OR "newround" THEN
             CALL "notify" USING BY REFERENCE pgconn Player RoomId RoundId
           END-IF
           
           IF Func IS = "joinroom" OR "newroom" OR "registerp" THEN
                CALL "displayroom" USING
                  BY REFERENCE pgconn
                  BY CONTENT Player
                  BY CONTENT RoomId
                END-CALL
           END-IF

           IF Func IS = "joinroom" OR "newroom" OR "registerp" OR "newround" OR "wordwaiter" THEN
               CALL "displayround" USING
                 BY REFERENCE pgconn
                 BY CONTENT RoundId
               END-CALL

            END-IF
          *> Call displaywords if we have done something that affects our own word list or we have
          *> just entered a room.
           IF Func IS = "joinroom" OR "submitword" OR "newround" OR "removeword" OR "getwords" OR "newroom" OR "registerp" OR "moretime" OR ( Func IS = "wordwaiter" AND NewWordsReceived ) THEN
                   CALL "displaywords" USING
                    By Reference pgconn
                    By Content Player
                    By Content RoomId
                    By Content RoundId
                   END-CALL
            END-IF
            IF Func IS = "wordwaiter" AND NewChatReceived THEN
                CALL "displaychat" USING
                  By Reference pgconn
                  By Content Player
                  By Content RoomId
                END-CALL
            END-IF

        END-IF
        DISPLAY "</data>"
        
        call "PQfinish" using by value pgconn returning result end-call
       
       STOP RUN.

       MoreTime.
        CALL "moretime" USING BY REFERENCE pgconn Player RoomId RoundId.

        NewRound.
        CALL "newround" USING BY REFERENCE pgconn Player RoomId RoundId.

       JoinRoom.
       CALL "joinroom" USING BY REFERENCE pgconn Player RoomId RoundId Room.

        SubmitWord.
        CALL "submitword" USING BY REFERENCE pgconn Player RoomId RoundId Word.
 

        RemoveWord.
       CALL "removeword" USING BY REFERENCE pgconn Player RoomId RoundId Word.
        
        GetRooms.
        CALL "displayrooms" USING
          BY REFERENCE pgconn
          BY CONTENT Player
        END-CALL.

        LeaveRoom.
        CALL "leaveroom" USING BY REFERENCE pgconn Player RoomId RoundId.

        NewRoom.
        CALL "newroom" USING BY REFERENCE pgconn Player RoomId RoundId RoomName.

        WordWaiter.
        CALL "wordwaiter" USING BY REFERENCE pgconn Player RoomId RoundId NewWords NewChat.
        
        AllWords.
        CALL "allwords" USING BY REFERENCE pgconn Player RoomId RoundId.
        