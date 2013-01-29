
DIRS = 

SOURCES=getround.cob init.cob parsequery.cob parsechat.cob checkword.cob joinroom.cob enterroom.cob displaywords.cob displaychat.cob displayrooms.cob displayround.cob displayroom.cob initround.cob submitword.cob newround.cob removeword.cob leaveroom.cob newroom.cob moretime.cob registerp.cob wordwaiter.cob notify.cob allwords.cob roundstatus.cob

OBJS=$(SOURCES:.cob=.o)

all: processq submitchat

%.o: %.cob
	cobc -c -free -static $<

install: all
	sudo -u www-data cp -f submitchat /usr/lib/cgi-bin/submitchat.cgi
	sudo -u www-data cp -f processq /usr/lib/cgi-bin/process.cgi

#all: allwords roundwaiter getrooms submitword removeword newround registerp newroom leaveroom wordwaiter chatwaiter submitchat process

clean:
	rm $(OBJS)
	rm processq submitchat

processq: processq.cob init.o parsequery.o displaywords.o moretime.o getround.o joinroom.o submitword.o displayround.o removeword.o displayrooms.o leaveroom.o enterroom.o checkword.o displayroom.o newroom.o newround.o initround.o registerp.o wordwaiter.o notify.o displaychat.o allwords.o roundstatus.o
	cobc -x -free -static -lpq processq.cob init.o parsequery.o displaywords.o moretime.o getround.o joinroom.o submitword.o displayround.o removeword.o displayrooms.o leaveroom.o enterroom.o checkword.o displayroom.o newroom.o newround.o initround.o registerp.o wordwaiter.o notify.o displaychat.o allwords.o roundstatus.o

submitchat: submitchat.cob init.o parsequery.o displaychat.o parsechat.o getround.o
	cobc -x -free -static -lpq submitchat.cob init.o parsequery.o displaychat.o parsechat.o getround.o

