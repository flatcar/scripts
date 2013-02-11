#include <unistd.h>
#include <sys/signal.h>
#include <sys/wait.h>
#include <stdlib.h>

int main (int argc, char *argv[]) {
	pid_t pid;

	signal (SIGQUIT, SIG_IGN);
	signal (SIGTERM, SIG_IGN);
	setpgid (0, 0);

	pid=fork ();
	if (pid == 0) {
		int status;
		wait (&status);
		exit (WEXITSTATUS(status));
	}
	else {
		execv (argv[1], &argv[1]);
		exit (1);
	}

	return 0;
}

