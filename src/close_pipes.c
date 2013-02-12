
#include <stdio.h>
#include <unistd.h>

void close_pipes() {
		close(STDIN_FILENO);
        close(STDOUT_FILENO);
        close(STDERR_FILENO);
}
/*
int main(int argc, char *argv[]) {
  
	close_pipes();
	
}
*/
