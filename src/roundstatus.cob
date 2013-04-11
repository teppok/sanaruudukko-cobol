        *> -------------------------
        *> roundstatus.
        *> Takes: Standard arguments.
        *> Query database to see if the supplied roundid is still ongoing and
        *>   return RoundStatus indicating this.
        *> Modifies: RoundStatus
        *> Dependencies: 
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. roundstatus.
       DATA DIVISION.
	   WORKING-STORAGE SECTION.
       
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(255).

       LINKAGE SECTION.
       01 pgconn usage pointer.
       COPY "init.l".
       01 RoundStatus pic x.
          88 RoundFinished value "f".
          88 RoundContinues value "t".
       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId, RoundStatus.
       Begin.
       IF RoundId IS = HIGH-VALUES THEN
         SET RoundFinished TO TRUE
         EXIT PROGRAM
       END-IF
       
       string "SELECT Roundstart + interval '3 minutes' >= now() FROM Rounds WHERE RoundId = ", RoundId, 
              " AND RoomId = ", RoomId, ";", x"00" INTO QueryString
       call "PQexec" using
           by value pgconn
           by reference querystring
           returning pgres
       end-call

       call "PQgetvalue" using by value pgres
           by value 0
           by value 0
           returning resptr
        end-call
        set address of resstr to resptr
        string resstr delimited by x"00" into RoundStatus end-string

        
       EXIT PROGRAM.
	   
