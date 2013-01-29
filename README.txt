

  Sanaruudukko - Word grid 
  Copyright 2012-2013 Teppo Kankaanp‰‰
  
  Deployment guide for COBOL backend
  
  1. Introduction

    This is the COBOL backend for the game Sanaruudukko (Word grid).
  This backend handles CGI requests from the HTTP server, interacts
  with the database, performs program logic and returns data in
  a freeform XML format.

    The html-javascript side of the program is an another application
  in another repository (sanaruudukko-web).

    File src/README.txt has a couple of insights into the source code.

    The program uses libpq for database connectivity, so it contains
  rather much Postgresql specific library calls.
  
  2. Easy installation
  
    1) Create a database for Postgresql.
	2) Alter src/init.cob and src/registerp.cob PQconnect calls to your database parameters.
	3) Insert initdb.txt into the database.
	4) Install Opencobol beta 1.1 compiler source.
	5) Apply the supplied patch (this patch fixes the bug in random number generator) and
	     make and install the compiler. Or use another cobol compiler and change src/Makefile
		 to reflect this.
	6) Check the cgi-bin directory of your server. It defaults to /usr/lib/cgi-bin, so change
	     src/Makefile if it's different.
    7) Do 'make install' in the src subdirectory.
  
