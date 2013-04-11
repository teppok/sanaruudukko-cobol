        *> -------------------------
        *> parsechat.
        *> Takes: Cgiquery, query identifier.
        *> Goes through query parameters, searches for the one with identifier. When found,
        *>   changes HTML %xx codes to their real characters and changes HTML-unsafe characters
        *>   to their entity codes.
        *> Modifies: Query result
        *> Dependencies: 
        
       IDENTIFICATION DIVISION.
       PROGRAM-ID. parsechat.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 querytmp pic x(2560).
       01 queryval pic x(2560).
       01 querydata pic x(2560).
       01 newquerydata pic x(5120).
       01 queryindex pic 9999.
       01 newindex pic 9999.
       01 Querypointer pic 9999 value 1.

       01 hex pic x.
       01 hex-value pic 99.
       01 high-hex-value pic 99.
       01 low-hex-value pic 99.
       01 total-hex-value pic 999.
       01 tmpchar pic x.
       01 tmpvalue redefines tmpchar usage binary-char.
       
       LINKAGE SECTION.
       01 Cgiquery pic x(2560).
       01 Query1 pic x(16).
       01 Query1res pic x(2560).

       PROCEDURE DIVISION USING CgiQuery, Query1, Query1res.
       PERFORM WITH TEST BEFORE UNTIL Querypointer >= function length(function trim(cgiquery))
           UNSTRING CgiQuery DELIMITED BY "&" INTO Querytmp WITH Pointer Querypointer 
           UNSTRING Querytmp DELIMITED BY "=" INTO Queryval, Querydata
           IF Query1 NOT = SPACE AND Queryval = Query1 THEN
             PERFORM FixQueryData
             Move NewQueryData to Query1res
           END-IF
       end-perform.
       exit program.
       
       FixQueryData.
       move 1 to newindex
       PERFORM VARYING queryindex FROM 1 BY 1 UNTIL Queryindex > 2560 OR newindex > 5110
           MOVE QueryData(queryindex:1) TO tmpchar
           IF Querydata(queryindex:1) IS = "+" THEN
             MOVE " " TO Tmpchar
           END-IF
           IF Querydata(queryindex:1) IS = "%" THEN
               ADD 1 TO queryindex
               MOVE Querydata(queryindex:1) TO Hex
               Perform ConvertHex
               MOVE Hex-Value to High-Hex-Value
               ADD 1 TO queryindex
               MOVE Querydata(queryindex:1) TO Hex
               Perform ConvertHex
               MOVE Hex-Value to Low-Hex-Value
               COMPUTE Total-hex-value = ( high-hex-value * 16 + low-hex-value )
               MOVE Total-hex-value TO tmpvalue
           END-IF
           EVALUATE tmpchar
             WHEN "&" 
               MOVE "&amp;" TO NewQueryData(newindex:5)
               ADD 5 TO NewIndex
             WHEN "<"
               MOVE "&lt;" TO NewQueryData(newindex:4)
               ADD 4 TO NewIndex
             WHEN ">"
               MOVE "&gt;" TO NewQueryData(newindex:4)
               ADD 4 TO NewIndex
             WHEN x"22"
               MOVE "&quot;" TO NewQueryData(newindex:6)
               ADD 6 TO NewIndex
             WHEN "'"
               MOVE "&#x27;" TO NewQueryData(newindex:6)
               ADD 6 TO NewIndex
             WHEN "/"
               MOVE "&#x2F;" TO NewQueryData(newindex:6)
               ADD 6 TO NewIndex
             WHEN OTHER
               MOVE tmpchar TO newquerydata(newindex:1)
               ADD 1 to newindex
           END-EVALUATE
           
       END-PERFORM.
       
       ConvertHex.
         MOVE 0 to Hex-value
         IF hex IS NUMERIC THEN
           MOVE Hex to Hex-value
         END-IF
         IF hex IS = "A" THEN
           MOVE 10 to hex-value
         END-IF
         IF hex IS = "B" THEN
           MOVE 11 to hex-value
         END-IF
         IF hex IS = "C" THEN
           MOVE 12 to hex-value
         END-IF
         IF hex IS = "D" THEN
           MOVE 13 to hex-value
         END-IF
         IF hex IS = "E" THEN
           MOVE 14 to hex-value
         END-IF
         IF hex IS = "F" THEN
           MOVE 15 to hex-value
         END-IF.
         
         
         