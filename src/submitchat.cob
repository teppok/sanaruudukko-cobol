        *> -------------------------
        *> submitchat.
        *> Takes: .
        *> The other CGI interface for the program. Reads query values from
        *>   POST data (not QUERY_STRING). Chat lines might be long,
        *>   so this program reserves relatively large amount of memory.
        *>   
        *>   Call PQescapeStringConn to change the chat line to a safe one
        *>   to be inserted in the database (prevents injection).
        *>
        *>   Finally displaychat is called to show this line back to the user (and possibly others).
        *>
        *>   Assumption: player and passcode query values must be before chat line
        *>   in the query string.
        *> Modifies:
        *> Dependencies: parsequery, parsechat, init, displaychat
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. submitchat.
       environment division.
       input-output section.
       file-control.
           select webinput assign to KEYBOARD.
       DATA DIVISION.
       file section.
       fd webinput.
          01 postchunk       pic x(2560).
       WORKING-STORAGE SECTION.
       01 newline         pic x   value x'0a'.

       01 cgiquery pic x(256).
       
       01 pgconn usage pointer.
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 result usage binary-long.
       01 querystring pic x(3560).

       01 SafeChatLine pic x(5120).       
       01 ChatLine pic x(2560).

       01 error-value usage binary-long.
       01 qlen usage binary-long.
       
       COPY "init.l".
       
       PROCEDURE DIVISION.
       Begin.

       display
           "Content-type: text/xml"
           newline
           newline
           '<?xml version="1.0" encoding="utf-8" ?>'
       end-display.

    *>   accept cgiquery from environment "QUERY_STRING"

    *>   MOVE "Teppo" TO PLAYER
    *>   MOVE "A" TO PassCode

        MOVE SPACES TO PostChunk
        open input webinput
       read webinput
           at end move spaces to postchunk
       end-read
       close webinput

       *> Use CgiQuery to call parsequery (that takes a shorter
       *> input variable).
       
       MOVE postchunk to CgiQuery
    
       CALL "parsequery" USING by reference CgiQuery
         By content "player          "
         By Reference Player
         By content "passcode        "
         By reference Passcode
         By content "                "
         By content "                "
       END-CALL

    *>   MOVE "chat=b'b/%20b%26b" to Cgiquery

       CALL "parsechat" USING by reference PostChunk
         By content "chat            "
         By Reference ChatLine
       END-CALL
       
       IF Player IS = Spaces OR ChatLine IS = Spaces THEN
         STOP RUN
       END-IF
       
       CALL "init" USING 
         By reference pgconn 
         By reference Player
         By reference PassCode
         By reference RoomId
         By Reference RoundId
       END-CALL
    
       IF Player IS = HIGH-VALUES OR RoomId IS = HIGH-VALUES THEN
         call "PQfinish" using by value pgconn returning result end-call
         STOP RUN
       END-IF

        COMPUTE qlen = function length (function trim(chatline))

        call "PQescapeStringConn" using
          by value pgconn
          by reference SafeChatLine
          by reference Chatline
          by value qlen
          by reference error-value
        END-CALL

        MOVE ALL SPACES TO ChatLine
        
        STRING SafeChatLine delimited by x"00" into ChatLine end-string
        
       string "insert into chat ( chattime, player, roomid, chatrow ) values ( now(), '", 
             function trim(Player), "', ", RoomId, ", E'", function trim(ChatLine), "' );", x"00" INTO querystring
       END-STRING
          
          
          call "PQexec" using
               by value pgconn
               by reference querystring
               returning resptr
          end-call
              
        DISPLAY "<data>"
        CALL "displaychat" USING
          By Reference pgconn
          By Content Player
          By Content RoomId
        END-CALL
        DISPLAY "</data>"
          
       call "PQfinish" using by value pgconn returning result end-call

       STOP RUN.
       