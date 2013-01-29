        *> -------------------------
        *> displayroom.
        *> Takes: player and room id.
        *> Gets room name from database and displays room id and name.
        *> Modifies:
        *> Dependencies: 
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. displayroom.
       DATA DIVISION.
	   WORKING-STORAGE SECTION.
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(255).

       01 ListRoomName pic x(16).
       
       LINKAGE SECTION.
       01 Player pic x(16).
       01 pgconn usage pointer.
       01 RoomId pic 99999 usage display.
       
       PROCEDURE DIVISION USING pgconn, Player, RoomId.
       Begin.

       STRING "SELECT Rooms.Name FROM Rooms WHERE Id = ", RoomId, ";", x"00" into Querystring
       END-STRING
       call "PQexec" using
           by value pgconn
           by reference querystring
           returning pgres
       end-call
       
       DISPLAY "<room>"
       DISPLAY "<id>", RoomId, "</id>"

       call "PQgetvalue" using
        by value pgres
           by value 0
           by value 0
           returning resptr
       end-call
       set address of resstr to resptr
       MOVE SPACES to ListRoomName
       string resstr delimited by x"00" into ListRoomName end-string
       DISPLAY "<roomname>", function trim(ListRoomName), "</roomname>"
       DISPLAY "</room>"
       
       EXIT PROGRAM.
	   
