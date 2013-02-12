        *> -------------------------
        *> get.
        *> Takes: pgconn
        *> Initializes the database.
        *> Mofidies: pgconn
        *> Dependencies:
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. getdb.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

       LINKAGE SECTION.
        01 pgconn usage pointer.
       PROCEDURE DIVISION USING pgconn.

       call "PQconnectdb" using
           by reference "dbname = test" & x"00"
           returning pgconn
       end-call.
