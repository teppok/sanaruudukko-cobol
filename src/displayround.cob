        *> -------------------------
        *> displayround.
        *> Takes: Round id.
        *> Displays remaining hundredths of seconds of the current round and
        *>   the current board.
        *> Modifies:
        *> Dependencies: 

       IDENTIFICATION DIVISION.
       PROGRAM-ID. displayround.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 pgres  usage pointer.
       01 resptr usage pointer.
       01 resstr pic x(80) based.
       01 querystring pic x(256).

       01 TmpDate2.
         02 TmpYear PIC 9999.
         02 TmpMonth PIC 99.
         02 TmpDay PIC 99.
       01 TmpDate redefines TmpDate2 pic 9(8) .
       01 CurrentTimestamp.
         02 CurrentIntegerDate    PIC 9(7).
         02 CurrentTime.
           03 CurrentHours PIC 9(2).
           03 CurrentMinutes PIC 9(2).
           03 CurrentSecMill.
             04 CurrentSeconds PIC 9(2).
             04 CurrentHunds PIC 9(2).
       01 RoundTimestamp.
         02 RoundIntegerDate    PIC 9(7).
         02 RoundTime.
           03 RoundHours PIC 9(2).
           03 RoundMinutes PIC 9(2).
           03 RoundSeconds PIC 9(2).
           03 RoundHunds PIC 9(2).
       01 SqlTimestamp.
         02 Sqlyear pic 9999.
         02 filler pic x.
         02 Sqlmonth pic 99.
         02 filler pic x.
         02 Sqlday pic 99.
         02 filler pic x.
         02 Sqlhours pic 99.
         02 filler pic x.
         02 Sqlminutes pic 99.
         02 filler pic x.
         02 Sqlseconds pic 99.
         02 filler pic x.
         02 Sqlhunds pic 99.
         02 filler pic 999.

       01 NewRoundState pic 9 VALUE 0.
         88 StartNewRound VALUE 1.
         
       01 RemainingMinutes PIC s9(2).
       01 RemainingSeconds PIC s9(2).
       01 RemainingHunds PIC s9(2).
       01 PrintHunds PIC 9(5).
       
       01 Board pic x(16).
       
       LINKAGE SECTION.
       01 pgconn usage pointer.
       01 RoundId pic 99999 usage display.
       
       PROCEDURE DIVISION USING pgconn, RoundId.
       Begin.

       ACCEPT TmpDate FROM DATE YYYYMMDD.
       MOVE FUNCTION INTEGER-OF-DATE(TmpDate) to CurrentIntegerDate.
       ACCEPT CurrentTime FROM TIME.
       
       IF RoundId IS = HIGH-VALUES THEN
              SET StartNewRound TO TRUE
       ELSE
          STRING "SELECT RoundStart FROM ROUNDS where RoundNum = ", RoundId, ";", x"00" INTO QueryString
          END-STRING
          call "PQexec" using by value pgconn
            by reference querystring
            returning pgres
          end-call

           call "PQgetvalue" using by value pgres
               by value 0
               by value 0
               returning resptr
           end-call
           set address of resstr to resptr
           MOVE SPACES TO SqlTimestamp
           string resstr delimited by x"00" into SqlTimestamp end-string

           Move SqlYear to TmpYear
           Move SqlMonth to Tmpmonth
           Move SqlDay to Tmpday
           COMPUTE RoundIntegerdate = function Integer-Of-Date(TmpDate)
           Move SqlHours to RoundHours
           Move SqlMinutes to RoundMinutes
           Move SqlSeconds to RoundSeconds
           Move SqlHunds to RoundHunds
           
       *>    display roundtimestamp
           
           ADD 3 TO RoundMinutes

           PERFORM FixRoundTime

           IF CurrentTimestamp > Roundtimestamp THEN
             SET StartNewRound TO TRUE
           END-IF

       END-IF
       DISPLAY "<round>"

       IF NOT StartNewRound THEN
           COMPUTE RemainingMinutes = RoundMinutes - CurrentMinutes
           COMPUTE RemainingSeconds = RoundSeconds - CurrentSeconds
           COMPUTE RemainingHunds = RoundHunds - CurrentHunds
           *>  DISPLAY RemainingMinutes
           *>  DISPLAY RemainingSeconds
           *>  DISPLAY RemainingHunds
           *> DISPLAY RemainingMinutes
           *> DISPLAY RemainingSeconds
             IF RemainingHunds < 0 THEN
               SUBTRACT 1 FROM RemainingSeconds
               ADD 100 to RemainingHunds
             END-IF
             IF RemainingSeconds < 0 THEN
               SUBTRACT 1 FROM RemainingMinutes
                 ADD 60 TO RemainingSeconds
             END-IF
             IF RemainingMinutes < 0 THEN
               ADD 60 to RemainingMinutes
             END-IF

        *>       MOVE RemainingSeconds TO Printseconds
        *>     MOVE RemainingMinutes TO PrintMinutes
             COMPUTE PrintHunds = (RemainingMinutes * 60 + RemainingSeconds) * 100 + RemainingHunds
          *>   MOVE TotalRemainingSeconds to PrintSeconds
             DISPLAY "<time>", PrintHunds, "</time>"
      END-IF

      IF RoundId IS NOT = HIGH-VALUES THEN
           STRING "SELECT Board FROM Rounds where roundnum = ", RoundId, ";", x"00" INTO QueryString
           END-STRING
           call "PQexec" using
               by value pgconn
               by reference querystring
               returning pgres
           end-call
           
           call "PQgetvalue" using
            by value pgres
               by value 0
               by value 0
               returning resptr
           end-call
           set address of resstr to resptr
           string resstr delimited by x"00" into Board end-string
           
           DISPLAY "<board>", function trim(Board), "</board>"
       ELSE
          DISPLAY "<board>????????????????", "</board>"
       END-IF
       
       DISPLAY "</round>"
       
       EXIT PROGRAM.
       
       FixRoundTime.
       IF ROUNDMINUTES > 59 THEN 
         ADD 1 TO ROUNDHOURS
         SUBTRACT 60 FROM ROUNDMINUTES
       END-IF.
       IF ROUNDHOURS > 23 THEN
         ADD 1 TO ROUNDINTEGERDATE
         SUBTRACT 24 FROM ROUNDHOURS
       END-IF.
