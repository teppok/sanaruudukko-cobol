        *> -------------------------
        *> newroom.
        *> Takes: RoomName. (Standard arguments, RoomName)
        *> Creates a new room using RoomName either by creating a new roomid in the database
        *> or recycling an old roomid which is empty of active players. It boots inactive players
        *> out of the room and clears its word list.
        *> Modifies: RoomId
        *> Dependencies: 
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. newroom.
       DATA DIVISION.
	   WORKING-STORAGE SECTION.
	   
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(255).
	   
       01 NewRoomId pic 99999.
       01 TmpNewRoomId pic x(16).
	   
       01 Roomtest usage binary-long value 0.
       01 RoomFail usage binary-long value 0.
       
       LINKAGE SECTION.
       01 pgconn usage pointer.
       COPY "init.l".
       01 RoomName pic x(16).
       
       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId, RoomName.
       Begin.

       STRING "SELECT Rooms.Id FROM Rooms LEFT OUTER JOIN ( SELECT * FROM Players WHERE LastSeen + '60 seconds' > now() ) as activeplayers ",
              " ON activeplayers.Roomid = Rooms.Id ",
              "  Group by Rooms.Id HAVING Count(activeplayers.Name) = 0", x"00" INTO QueryString
       END-String
   	   call "PQexec" using by value pgconn
	       by reference querystring
           returning pgres
       end-call

       CALL "PQntuples" using by value pgres returning Roomtest
       END-CALL
       IF RoomTest = 0 THEN
         STRING "SELECT max(rooms.id) FROM Rooms", x"00" INTO QueryString
         END-STRING
         call "PQexec" using by value pgconn
               by reference querystring
               returning pgres
         end-call
         
           call "PQgetisnull" using by value pgres
               by value 0
               by value 0
               returning RoomFail
           end-call
         
           IF RoomFail = 1 THEN
             MOVE 0 To NewRoomId
           ELSE
           
               call "PQgetvalue" using
                by value pgres
                   by value 0
                   by value 0
                   returning resptr
               end-call
               set address of resstr to resptr
               MOVE SPACES TO TmpNewRoomId
               string resstr delimited by x"00" into TmpNewRoomId end-string
               MOVE TmpNewRoomId TO NewRoomId
               ADD 1 TO NewRoomId
           END-IF
      
       
             string "INSERT INTO Rooms ( name, Id ) VALUES ( '", RoomName, "', ", NewRoomId, " );", x"00" INTO Querystring
             END-STRING
             call "PQexec" using
                 by value pgconn
                 by reference querystring
                 returning pgres
            end-call
       ELSE
           call "PQgetvalue" using
            by value pgres
               by value 0
               by value 0
               returning resptr
           end-call
           set address of resstr to resptr
           MOVE SPACES TO TmpNewRoomId
           string resstr delimited by x"00" into TmpNewRoomId end-string
           MOVE TmpNewRoomId TO NewRoomId
           
           STRING "DELETE FROM Chat WHERE RoomId = ", NewRoomId, ";", x"00" INTO Querystring
           END-String
             call "PQexec" using
                 by value pgconn
                 by reference querystring
                 returning pgres
             end-call

           STRING "DELETE FROM Words WHERE RoomId = ", NewRoomId, ";", x"00" INTO Querystring
           END-String
             call "PQexec" using
                 by value pgconn
                 by reference querystring
                 returning pgres
             end-call
             
           STRING "DELETE FROM Rounds WHERE RoomId = ", NewRoomId, ";", x"00" INTO Querystring
           END-String
             call "PQexec" using
                 by value pgconn
                 by reference querystring
                 returning pgres
             end-call

            STRING "UPDATE Rooms SET Name = '", function trim(RoomName), "' WHERE Id = ", NewRoomId, x"00" INTO Querystring
            END-STRING
             call "PQexec" using
                 by value pgconn
                 by reference querystring
                 returning pgres
             end-call

            STRING "UPDATE Players SET RoomId = NULL WHERE RoomId = ", NewRoomId, x"00" INTO Querystring
            END-STRING
             call "PQexec" using
                 by value pgconn
                 by reference querystring
                 returning pgres
             end-call
             
       END-IF

        MOVE NewRoomId to RoomId

        EXIT PROGRAM.
