        *> -------------------------
        *> removeword.
        *> Takes: Standard arguments, word.
        *> Changes the disabled status of the supplied word for the specified player
        *>   in the specified room (this is possibly redundant) and round.
        *> Modifies:
        *> Dependencies: 
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. removeword.
       DATA DIVISION.
	   WORKING-STORAGE SECTION.
	   
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(255).

       LINKAGE SECTION.
       01 pgconn usage pointer.
       COPY "init.l".
       
       01 Word pic x(16).
       
       PROCEDURE DIVISION USING pgconn, Player, RoomId, RoundId, Word.
       Begin.

       string "UPDATE Words SET Disabled = not disabled WHERE player = '", function trim(Player), "' AND Word = '", function trim(Word), "' AND RoundId = ", RoundId,
              " AND RoomId = ", RoomId, ";", x"00" into querystring end-string
   	     call "PQexec" using
             by value pgconn
             by reference querystring
             returning pgres
         end-call

        EXIT PROGRAM.
