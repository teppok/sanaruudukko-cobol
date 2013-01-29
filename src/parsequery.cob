        *> -------------------------
        *> parsequery.
        *> Takes: Cgiquery, query1 identifier, query2 identifier, query3 identifier.
        *> Goes through the cgi query parameters, finds identifiers and moves their
        *>   values to result fields. Strips all non-alphabetic and non-numeric 
        *>   characters from the results.
        *> Modifies: Query1 result, Query2 result, Query3 result.
        *> Dependencies: 
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. parsequery INITIAL.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 querytmp pic x(256).
       01 queryval pic x(256).
       01 querydata pic x(256).
       01 newquerydata pic x(16).
       01 queryindex pic 99.
       01 newindex pic 99.
       01 Querypointer pic 999 value 1.

       LINKAGE SECTION.
       01 Cgiquery pic x(256).
       01 Query1 pic x(16).
       01 Query1res pic x(16).
       01 Query2 pic x(16).
       01 Query2res pic x(16).
       01 Query3 pic x(16).
       01 Query3res pic x(16).

       PROCEDURE DIVISION USING CgiQuery, Query1, Query1res, Query2, Query2res, Query3, Query3res.
       PERFORM WITH TEST BEFORE UNTIL Querypointer >= function length(function trim(cgiquery))
           UNSTRING CgiQuery DELIMITED BY "&" INTO Querytmp WITH Pointer Querypointer 
           UNSTRING Querytmp DELIMITED BY "=" INTO Queryval, Querydata
           IF Query1 NOT = SPACE AND Queryval = Query1 THEN
             PERFORM FixQueryData
             Move NewQueryData to Query1res
           END-IF
           IF Query2 NOT = SPACE AND Queryval = Query2 THEN
             PERFORM FixQueryData
             Move NewQueryData to Query2res
           END-IF
           IF Query3 NOT = SPACE AND Queryval = Query3 THEN
             PERFORM FixQueryData
             Move NewQueryData to Query3res
           END-IF
       end-perform.
       exit program.
       
       FixQueryData.
       move 1 to newindex
       PERFORM VARYING queryindex FROM 1 BY 1 UNTIL Queryindex > 16
         IF Querydata(queryindex:1) IS ALPHABETIC OR Querydata(queryindex:1) IS NUMERIC THEN
         move querydata(queryindex:1) to newquerydata(newindex:1)
         add 1 to newindex
         END-IF
       END-PERFORM.
       
