        *> -------------------------
        *> displaywords.
        *> Takes: Standard arguments.
        *> Displays players and words they have typed in the current room of the player.
        *>   Also shows the score for each word and total for the players.
        *>   If the round continues, only shows the count of the words and don't process duplicates.
        *> Modifies:
        *> Dependencies: 
        *> XXX TotalScoreFail tarkista tarvitaanko
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. displaywords.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 pgres  usage pointer.
       01 pgres2  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(2560).

       01 RoundStatus pic x.
          88 RoundFinished value "f".
          88 RoundContinues value "t".
    
       
       01 RoundStatus2 pic 9 VALUE 0.
         88 SkipWords VALUE 1.
       01 NPlayers usage binary-long.
       01 NWords usage binary-long.
       01 PlayerIdx usage binary-long.
       01 WordIdx usage binary-long.
       01 PlayerName pic x(16).
       01 PlayerActive pic x.
       01 PlayerReady pic x.
       01 MoreTime pic x.
       01 WordCount pic x(16).
       01 Listword pic x(16).
       01 WordStatus pic x.
       01 DisableStatus pic x.
       01 WordLength pic 99.
       01 Score pic 99.
       01 TotalScore pic x(6).
       01 TotalScoreFail usage binary-long.
       01 ThisroundScore pic 9999.
       
       01 LanguageCheck pic x.

    *>   01 response pic x(20480).
       
       LINKAGE SECTION.
       01 Player pic x(16).
       01 pgconn usage pointer.
       01 RoomId pic 99999 usage display.
       01 RoundId pic 99999 usage display.
       
       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId.
       Begin.
        *>   MOVE SPACES TO Response
        *>   STRING function trim(Response), "<players>" into Response END-STRING
           DISPLAY "<players>"
           
           STRING "UPDATE Players SET NewWords = false WHERE Name = '", function trim(Player), "';", x"00" into QueryString
           END-STRING
           call "PQexec" using by value pgconn
                by reference querystring
                returning pgres
           end-call

           IF RoundId IS = HIGH-VALUES THEN
             SET SkipWords TO TRUE
             MOVE 0 TO RoundId
           ELSE
               CALL "roundstatus" USING BY REFERENCE pgconn Player RoomId RoundId RoundStatus
           END-IF
           
           
           STRING "select name, lastseen + interval '20 seconds' > now(), ready, sum (score), MoreTime FROM ",
                  "(select player, word, "
                  "CASE WHEN length(word)=3 THEN 1 ",
                  "WHEN length(word)=4 THEN 1 ",
                  "WHEN length(word)=5 THEN 2 ",
                  "WHEN length(word)=6 THEN 3 ",
                  "WHEN length(word)=7 THEN 5 ",
                  "WHEN length(word)>7 THEN 11 ",
                  "ELSE 0 ",
                  "END as score ",
                    "from Words Where ",
                    "(Word, RoundId) in ",
                    "(SELECT Word, RoundId FROM Words GROUP BY Word, RoundId HAVING count(player) = 1) ",
                        "AND RoundId < ", RoundId, " AND RoomId = ", RoomId " AND Disabled = false )",
                  "AS foo RIGHT OUTER JOIN players ON players.name = foo.player WHERE ",
                  "lastseen + interval '40 seconds' > now() AND Players.RoomId = ", RoomId, " ",
                  "GROUP BY players.name, players.ready, players.lastseen, players.moretime ",
                  "ORDER BY Players.name;", x"00" INTO QueryString
           END-STRING

           call "PQexec" using
               by value pgconn
               by reference querystring
               returning pgres
           end-call

            call "PQntuples" using by value pgres returning Nplayers

           PERFORM VARYING PlayerIdx FROM 0 BY 1 UNTIL PlayerIdx >= NPlayers
        *>       STRING function trim(Response), "<player>" into Response END-STRING
               DISPLAY "<player>"
               call "PQgetvalue" using
                by value pgres
                   by value PlayerIdx
                   by value 0
                   returning resptr
               end-call
               set address of resstr to resptr
               MOVE SPACES to PlayerName
               string resstr delimited by x"00" into PlayerName end-string
        *>       STRING function trim(Response), "<name>", function trim(PlayerName), "</name>" into Response END-STRING
               DISPLAY "<name>", function trim(PlayerName), "</name>"

               call "PQgetvalue" using
                by value pgres
                   by value PlayerIdx
                   by value 1
                   returning resptr
               end-call
               set address of resstr to resptr
               string resstr delimited by x"00" into PlayerActive end-string
        *>     STRING function trim(Response), "<active>", function trim(PlayerActive), "</active>" into Response END-STRING
               DISPLAY "<active>", function trim(PlayerActive), "</active>"

               call "PQgetvalue" using
                by value pgres
                   by value PlayerIdx
                   by value 2
                   returning resptr
               end-call
               set address of resstr to resptr
               string resstr delimited by x"00" into PlayerReady end-string
        *>        STRING function trim(Response), "<ready>", function trim(PlayerReady), "</ready>" into Response END-STRING
              DISPLAY "<ready>", function trim(PlayerReady), "</ready>"

         
            *>   call "PQgetisnull" using 
            *>     by value pgres returning TotalScoreFail
            *>   IF TotalScoreFail = 0 THEN
               
                   call "PQgetvalue" using
                    by value pgres
                       by value PlayerIdx
                       by value 3
                       returning resptr
                   end-call
                   set address of resstr to resptr
                   MOVE SPACES to TotalScore
                   string resstr delimited by x"00" into TotalScore end-string
           *>        STRING function trim(Response), "<totalscore>", function trim(TotalScore), "</totalscore>" into Response END-STRING
                   DISPLAY "<totalscore>", function trim(TotalScore), "</totalscore>"
            *>   END-IF

               call "PQgetvalue" using
                by value pgres
                   by value PlayerIdx
                   by value 4
                   returning resptr
               end-call
               set address of resstr to resptr
               string resstr delimited by x"00" into MoreTime end-string
         *>      STRING function trim(Response), "<moretime>", function trim(MoreTime), "</moretime>" into Response END-STRING
               DISPLAY "<moretime>", function trim(MoreTime), "</moretime>"

            
               IF NOT SkipWords THEN
               
                   IF RoundContinues AND PlayerName NOT = Player THEN
               
        *>                   STRING function trim(Response), "<mode>0</mode>" into Response END-STRING
                           DISPLAY "<mode>0</mode>"

                           STRING "SELECT count(word) FROM Words WHERE Disabled = false AND RoomId = ", RoomId, " AND RoundId = ", RoundId, " AND Player = '", function trim(PlayerName), "';", x"00" into querystring
                            END-STRING
                *>       DISPLAY QueryString
                           call "PQexec" using
                               by value pgconn
                               by reference querystring
                               returning pgres2
                           end-call
                          
                           call "PQntuples" using by value pgres2 returning Nwords
                               IF Nwords > 0 THEN 
                                   call "PQgetvalue" using
                                    by value pgres2
                                       by value 0
                                       by value 0
                                       returning resptr
                                   end-call
                                   set address of resstr to resptr
                                   MOVE SPACES to WordCount
                                   string resstr delimited by x"00" into WordCount end-string
                                   
                       *>         STRING function trim(Response), "<wordcount>", function trim(WordCount), "</wordcount>" into Response END-STRING
                                DISPLAY "<wordcount>", function trim(WordCount), "</wordcount>"
                              ELSE
                       *>          STRING function trim(Response), "<wordcount>0</wordcount>" into Response END-STRING
                                 DISPLAY "<wordcount>0</wordcount>"
                              END-IF
                    ELSE
                            
                        *>        STRING function trim(Response), "<mode>1</mode>" into Response END-STRING
                                DISPLAY "<mode>1</mode>"
                            
                                MOVE 0 TO ThisRoundScore
                                
                                STRING "SELECT Word, LanguageCheck, Disabled, Word in (SELECT Word FROM Words WHERE RoundId = ", RoundId, 
                                    " AND RoomId = ", RoomId, " GROUP BY Word HAVING count(player) > 1) FROM Words WHERE RoomId = ", RoomId, 
                                    " AND RoundId = ", RoundId, " AND Player = '" function Trim(PlayerName), "' ORDER BY Word;", x"00" INTO QueryString
                                END-STRING
                        *>       STRING "SELECT Player, Word FROM Words WHERE RoundId = ", RoundId, " AND Player != '", function Trim(player), "' ORDER BY Player, Word;", x"00" into querystring
                        *>       END-STRING
                               call "PQexec" using
                                   by value pgconn
                                   by reference querystring
                                   returning pgres2
                               end-call
                      
                               call "PQntuples" using by value pgres2 returning NWords

                               PERFORM VARYING WordIdx FROM 0 BY 1 UNTIL WordIdx >= NWords

                                   call "PQgetvalue" using
                                        by value pgres2
                                           by value WordIdx
                                           by value 2
                                           returning resptr
                                   end-call
                                   set address of resstr to resptr
                                   string resstr delimited by x"00" into DisableStatus end-string

                                   IF Disablestatus IS = "f" OR PlayerName IS = Player THEN

                       *>                STRING function trim(Response), "<item>", "<disabled>", function trim(DisableStatus), "</disabled>" into Response END-STRING
                                       DISPLAY "<item>"
                                       DISPLAY "<disabled>", function trim(DisableStatus), "</disabled>"
                                      
                                       call "PQgetvalue" using
                                        by value pgres2
                                           by value WordIdx
                                           by value 0
                                           returning resptr
                                       end-call
                                       set address of resstr to resptr
                                       MOVE SPACES to ListWord
                                       string resstr delimited by x"00" into ListWord end-string
                                   
                        *>              STRING function trim(Response), "<word>", function trim(ListWord), "</word>" into Response END-STRING
                                      DISPLAY "<word>", function trim(ListWord), "</word>"

                                      call "PQgetvalue" using
                                        by value pgres2
                                           by value WordIdx
                                           by value 1
                                           returning resptr
                                       end-call
                                       set address of resstr to resptr
                                       string resstr delimited by x"00" into LanguageCheck end-string

                        *>               STRING function trim(Response), "<languagecheck>", function trim(LanguageCheck), "</languagecheck>" into Response END-STRING
                                       DISPLAY "<languagecheck>", function trim(LanguageCheck), "</languagecheck>"

                                       IF RoundFinished THEN
                                           call "PQgetvalue" using
                                            by value pgres2
                                               by value WordIdx
                                               by value 3
                                               returning resptr
                                           end-call
                                           set address of resstr to resptr
                                           string resstr delimited by x"00" into WordStatus end-string
                                       ELSE
                                           MOVE "f" TO WordStatus
                                       END-IF
                                       
                          *>             STRING function trim(Response), "<duplicate>", function trim(WordStatus), "</duplicate>" into Response END-STRING
                                       DISPLAY "<duplicate>", function trim(WordStatus), "</duplicate>"
                                       
                                       COMPUTE WordLength = function length( function trim (ListWord) )
                                       MOVE 0 to Score
                                       EVALUATE WordLength
                                         WHEN 0 THRU 2 MOVE 0 to Score
                                         WHEN 3 Move 1 to Score
                                         WHEN 4 Move 1 to Score
                                         WHEN 5 Move 2 to Score
                                         WHEN 6 Move 3 to Score
                                         WHEN 7 Move 5 to Score
                                         WHEN 8 THRU 16 Move 11 to Score
                                       END-EVALUATE
                                       IF WordStatus = "t" THEN MOVE 0 to Score END-IF
                                       IF DisableStatus = "t" THEN MOVE 0 to Score END-IF
                                       ADD Score TO ThisRoundScore
                           *>            STRING function trim(Response), "<score>", Score, "</score></item>" into Response END-STRING
                                       DISPLAY "<score>", Score, "</score></item>"
                                    END-IF
                                END-PERFORM
                            *>    STRING function trim(Response), "<thisroundscore>", ThisRoundScore, "</thisroundscore>" into Response END-STRING
                                DISPLAY "<thisroundscore>", ThisRoundScore, "</thisroundscore>"
                    END-IF
                    
                END-IF
            *>    STRING function trim(Response), "</player>" into Response END-STRING
                DISPLAY "</player>"

        END-PERFORM
    *>    STRING function trim(Response), "</players>" into Response END-STRING
        DISPLAY "</players>"
    *>    DISPLAY function trim(Response)
       EXIT PROGRAM.
       
