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
       01 SRoundTimestamp.
         02 SRoundIntegerDate    PIC 9(7).
         02 SRoundTime.
           03 SRoundHours PIC 9(2).
           03 SRoundMinutes PIC 9(2).
           03 SRoundSeconds PIC 9(2).
           03 SRoundHunds PIC 9(2).
       01 ERoundTimestamp.
         02 ERoundIntegerDate    PIC 9(7).
         02 ERoundTime.
           03 ERoundHours PIC 9(2).
           03 ERoundMinutes PIC 9(2).
           03 ERoundSeconds PIC 9(2).
           03 ERoundHunds PIC 9(2).
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

       01 RoundState pic 9 VALUE 0.
         88 RoundContinues VALUE 0.
         88 RoundEnded VALUE 1.
         88 RoundStarting VALUE 2.
         
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

       SET RoundContinues TO TRUE
       
       IF RoundId IS = HIGH-VALUES THEN
              SET RoundEnded TO TRUE
       ELSE
          STRING "SELECT RoundStart FROM ROUNDS where RoundId = ", RoundId, ";", x"00" INTO QueryString
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
           COMPUTE SRoundIntegerdate = function Integer-Of-Date(TmpDate)
           Move SqlHours to SRoundHours
           Move SqlMinutes to SRoundMinutes
           Move SqlSeconds to SRoundSeconds
           Move SqlHunds to SRoundHunds

           MOVE SRoundTimeStamp TO ERoundTimeStamp
           ADD 3 TO ERoundMinutes
           PERFORM FixERoundTime
           
           IF CurrentTimeStamp < SRoundTimeStamp
             SET RoundStarting TO TRUE
           END-IF
           
           IF CurrentTimestamp > ERoundtimestamp THEN
             SET RoundEnded TO TRUE
           END-IF

       END-IF
       DISPLAY "<round>"

       IF RoundContinues THEN
           COMPUTE RemainingMinutes = ERoundMinutes - CurrentMinutes
           COMPUTE RemainingSeconds = ERoundSeconds - CurrentSeconds
           COMPUTE RemainingHunds = ERoundHunds - CurrentHunds
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

      IF RoundStarting THEN
           COMPUTE RemainingMinutes = SRoundMinutes - CurrentMinutes
           COMPUTE RemainingSeconds = SRoundSeconds - CurrentSeconds
           COMPUTE RemainingHunds = SRoundHunds - CurrentHunds
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

             COMPUTE PrintHunds = (RemainingMinutes * 60 + RemainingSeconds) * 100 + RemainingHunds
             DISPLAY "<time>", PrintHunds, "</time>"
             DISPLAY "<starting>1</starting>"
      END-IF
      
      IF RoundId IS NOT = HIGH-VALUES AND (RoundContinues OR RoundEnded) THEN
           STRING "SELECT Board FROM Rounds where RoundId = ", RoundId, ";", x"00" INTO QueryString
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
       
       FixERoundTime.
       IF EROUNDMINUTES > 59 THEN 
         ADD 1 TO EROUNDHOURS
         SUBTRACT 60 FROM EROUNDMINUTES
       END-IF.
       IF EROUNDHOURS > 23 THEN
         ADD 1 TO EROUNDINTEGERDATE
         SUBTRACT 24 FROM EROUNDHOURS
       END-IF.
