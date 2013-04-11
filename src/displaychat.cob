        *> -------------------------
        *> displaychat.
        *> Takes: player and room number.
        *> Checks from database Player.lastchat what was the last chat submitted to the
        *>   player, sends all chats that have arrived after that and updates Player.lastchat.
        *> Modifies:
        *> Dependencies: 

       IDENTIFICATION DIVISION.
       PROGRAM-ID. displaychat.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(2560) based.
       01 querystring pic x(2560).

       01 NChat usage binary-long.
       01 ChatIdx usage binary-long.
       01 ChatId pic x(16) VALUE SPACES.
       01 ChatPlayer pic x(16).
       01 ChatLine pic x(2560).
       01 MaxChatId pic 999999.
       
       LINKAGE SECTION.
       01 Player pic x(16).
       01 pgconn usage pointer.
       01 RoomId pic 99999 usage display.
       
       PROCEDURE DIVISION USING pgconn, Player, RoomId.
       Begin.

           STRING "SELECT Id, Player, ChatRow FROM Chat WHERE RoomId = ", RoomId, 
              " AND Id >= ALL ( SELECT LastChat FROM Players WHERE Name = '", function trim(Player), "' );", x"00" into QueryString
           END-STRING
           
           call "PQexec" using by value pgconn
                by reference querystring
                returning pgres
           end-call

           call "PQntuples" using by value pgres returning NChat

           PERFORM VARYING ChatIdx FROM 0 BY 1 UNTIL ChatIdx >= NChat
               DISPLAY "<chatrecord>"
               call "PQgetvalue" using
                by value pgres
                   by value ChatIdx
                   by value 0
                   returning resptr
               end-call
               set address of resstr to resptr
               MOVE SPACES to ChatId
               string resstr delimited by x"00" into ChatId end-string
               Move ChatId to MaxChatId
               DISPLAY "<id>", function trim(ChatId), "</id>"

               call "PQgetvalue" using
                by value pgres
                   by value ChatIdx
                   by value 1
                   returning resptr
               end-call
               set address of resstr to resptr
               MOVE SPACES to ChatPlayer
               string resstr delimited by x"00" into ChatPlayer end-string
               DISPLAY "<player>", function trim(ChatPlayer), "</player>"

               call "PQgetvalue" using
                by value pgres
                   by value ChatIdx
                   by value 2
                   returning resptr
               end-call
               set address of resstr to resptr
               MOVE SPACES to ChatLine
               string resstr delimited by x"00" into ChatLine end-string
               DISPLAY "<line>", function trim(ChatLine), "</line>"

               DISPLAY "</chatrecord>"

        END-PERFORM

        IF ChatId NOT = SPACES THEN
            ADD 1 to MaxChatId
            
            STRING "UPDATE Players SET LastChat = ", MaxChatId, " WHERE Name = '", function trim(Player), "';", x"00" into Querystring
            END-STRING
           call "PQexec" using by value pgconn
                by reference querystring
                returning pgres
           end-call
        END-IF
        
       EXIT PROGRAM.
       
