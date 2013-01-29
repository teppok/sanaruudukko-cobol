

  Sanaruudukko - Word grid 
  Copyright 2012-2013 Teppo Kankaanp‰‰
  
  Backend source code overview.
  
  See ../README.txt for deployment guide.
  
  
  
  1. CGI Interfaces
  
    The program has two basic interfaces for CGI: processq and submitchat.
  Processq handles every task except one: Submitting chat lines to display to others.
  Processq takes one http query parameter, func, and decides which action to perform based on
  that. Player and passcode parameters are also always supplied. 
  Based on the selected action, it may also return some xml formatted data to be
  displayed to the user. For example, when the user submits a word, the program returns
  the list of all players and words so that the browser show this updated data to the user.
  
  
  2. Module (function) categories
  
    The modules are separated in display and action categories. Action modules perform the
  requested actions like submitting a word. Each CGI request performs one action, and they
  are distinct. Display modules are named display*.cob, and they display data in an xml format,
  and for each action several display modules may be called.
  
    Some actions such as wordwaiter don't modify the database. This action waits
  for "new data" flags to be raised and when it sees them, it returns this new data to the user
  using some display actions.
  
    There are also a few utility modules such as init.cob, parsequery.cob and parsechat.cob
  that perform utility functions.
  
  3. Database
  
    The database schema is in initdb.txt. A few Postgresql specific functions have been used
  such as counters and nextval() function.
  
  4. Concurrency considerations
  
    The program is not concurrency safe at the moment, and this can even affect routine use.
  The most glaring issue is that when submitchat is called, displaychat is entered, but at the
  same time, wordwaiter process may also enter displaychat function. This results in both
  submitchat and wordwaiter processes sending the same chat line to the user.
  
    One issue is that if "More time" action is requested by two people at the exact same time,
  it might happen that time is added twice, so we end up with +4 minutes instead of +2 minutes.
  
    There may be other less serious issues with concurrency. Fixing all these issues in COBOL 
  is not easy and considering the program's currently small audience and small impact, fixing
  them is not a priority.
  
  5. Function documentation.

    Function documentation refers to Standard arguments. These are:
  pgconn pointer for the connection and contents of 'init.l' file
  (player pic x(16), passcode pic x(16), roomid pic 9(5) and 
  roundid pic 9(5)).

    Each function documentation lists the arguments the function actually 
  uses to read values from and the arguments the function modifies. The
  latter must thus be called with BY REFERENCE. Functions don't return
  any values. Also dependencies on other functions are listed.

    
  