        *> -------------------------
        *> registerp.
        *> Takes: Player name, Passcode.
        *> If the player name doesn't exist in the database, create a new player
        *>   with the supplied passcode.
        *> Modifies:
        *> Dependencies: 
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. registerp.
       DATA DIVISION.
	   WORKING-STORAGE SECTION.
	   
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 result usage binary-long.
       01 querystring pic x(255).
	   
       
	   01 playertest usage binary-long value 0.

       LINKAGE SECTION.
       01 pgconn usage pointer.
       COPY "init.l".
       
       
       PROCEDURE DIVISION USING pgconn, Player, PassCode.
       Begin.

       String "SELECT Name FROM Players WHERE Name = '", function trim(Player), "';", x"00" into Querystring
       END-STRING
   	   call "PQexec" using by value pgconn
	       by reference querystring
           returning pgres
       end-call

       CALL "PQntuples" using by value pgres returning Playertest
       END-CALL	   
       IF Playertest = 0 THEN
                 string "INSERT INTO Players ( name, passcode, roomid, ready, lastseen, newwords, newround, lastchat ) VALUES ( '", function trim(Player), 
                   "', '", function trim(Passcode), "', null, false, now(), false, false, 0 );", x"00" INTO Querystring
                 END-STRING
                 call "PQexec" using
                     by value pgconn
                     by reference querystring
                     returning pgres
                 end-call
	   END-IF
               
       EXIT PROGRAM.
	   
