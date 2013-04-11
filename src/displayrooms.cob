        *> -------------------------
        *> displayrooms.
        *> Takes: player.
        *> Displays room id and room name for each room that contains active players.
        *> Modifies:
        *> Dependencies: 

       IDENTIFICATION DIVISION.
       PROGRAM-ID. displayrooms.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(256).

       01 NRooms usage binary-long.
       01 RoomIdx usage binary-long.
       01 RoomPlayers pic x(6).
       01 ListRoomId pic x(6).
       01 ListRoomName pic x(16).
       
       LINKAGE SECTION.
       01 Player pic x(16).
       01 pgconn usage pointer.

        
       PROCEDURE DIVISION USING pgconn, Player.
       Begin.
       
       STRING "SELECT Rooms.Id, Rooms.Name, count(Players.Name) FROM Rooms, Players WHERE Rooms.Id = Players.RoomId AND lastseen + interval '20 seconds' > now() ",
         "GROUP BY Rooms.Id, Rooms.Name HAVING Count(Players.name) > 0", x"00" INTO QueryString
         END-STRING
           call "PQexec" using by value pgconn
                by reference querystring
                returning pgres
           end-call

       call "PQntuples" using by value pgres returning Nrooms
       PERFORM VARYING RoomIdx FROM 0 BY 1 UNTIL RoomIdx >= NRooms
               DISPLAY "<room>"
               call "PQgetvalue" using
                by value pgres
                   by value RoomIdx
                   by value 0
                   returning resptr
               end-call
               set address of resstr to resptr
               MOVE SPACES to ListRoomId
               string resstr delimited by x"00" into ListRoomId end-string
               DISPLAY "<id>", function trim(ListRoomId), "</id>"

               call "PQgetvalue" using
                by value pgres
                   by value RoomIdx
                   by value 1
                   returning resptr
               end-call
               set address of resstr to resptr
               MOVE SPACES to ListRoomName
               string resstr delimited by x"00" into ListRoomName end-string
               DISPLAY "<roomname>", function trim(ListRoomName), "</roomname>"

               call "PQgetvalue" using
                by value pgres
                   by value RoomIdx
                   by value 2
                   returning resptr
               end-call
               set address of resstr to resptr
               MOVE SPACES to RoomPlayers
               string resstr delimited by x"00" into RoomPlayers end-string
               DISPLAY "<players>", function trim(RoomPlayers), "</players>"

               DISPLAY "</room>"

        END-PERFORM
        EXIT PROGRAM.
       
