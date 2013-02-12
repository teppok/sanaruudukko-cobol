       IDENTIFICATION DIVISION.
       PROGRAM-ID. testdaemon.
       DATA DIVISION.
	   WORKING-STORAGE SECTION.
	   
       01 pid usage binary-long.
       
       PROCEDURE DIVISION.
       Begin.
	   
       DISPLAY "testing"
       
       CALL "close_pipes"
       
       DISPLAY "asdf".
       
       
       