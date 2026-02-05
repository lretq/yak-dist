#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/signal.h>
#include <sys/statvfs.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <readline/history.h>
#include <readline/readline.h>

void waitpid_test() {
  pid_t pids[3];
  int i;

  printf("parent pid=%d\n", getpid());

  /* create 3 children */
  for (i = 0; i < 3; i++) {
    pid_t pid = fork();
    if (pid < 0) {
      perror("fork");
      exit(1);
    }

    if (pid == 0) {
      /* child */
      printf("child %d: pid=%d exiting with %d\n", i, getpid(), 10 + i);
      _exit(10 + i);
    }

    pids[i] = pid;
  }

  printf("parent: all children created\n");

  /* reap children in any order */
  for (i = 0; i < 3; i++) {
    int status;
    pid_t pid = waitpid(-1, &status, 0);

    if (pid < 0) {
      perror("waitpid");
      exit(1);
    }

    printf("parent: reaped pid=%d", pid);

    if (WIFEXITED(status)) {
      printf(" exited status=%d\n", WEXITSTATUS(status));
    } else if (WIFSIGNALED(status)) {
      printf(" killed by signal %d\n", WTERMSIG(status));
    } else {
      printf(" unknown status=0x%x\n", status);
    }
  }

  /* no children left */
  int status;
  pid_t pid = waitpid(-1, &status, 0);
  if (pid < 0) {
    printf("parent: waitpid after reaping all children -> errno=%d\n", errno);
    assert(errno == ECHILD);
  }
}

int main(int argc, char *argv[]) {
  pid_t sid = setsid();

  int fd = open("/dev/console", O_RDWR);
  dup2(fd, 0);
  dup2(fd, 1);
  dup2(fd, 2);

  printf("Hello World, mlibc world!\n");
  printf("Yak init is running :~)\n");

  chdir("/root");
  setenv("PATH", "/usr/bin:/usr/sbin:/sbin:/bin", 1);
  setenv("PWD", "/root", 1);
  setenv("HOME", "/root", 1);
  setenv("TERM", "linux", 1);

  chdir("/var/log/");
  char *cwd = getcwd(NULL, 0);
  if (!cwd) {
    perror("getcwd");
    exit(1);
  }
  printf("cwd: %s\n", cwd);
  free(cwd);

  chdir("/root");
  cwd = getcwd(NULL, 0);
  if (!cwd) {
    perror("getcwd");
    exit(1);
  }
  printf("new cwd: %s\n", cwd);

  waitpid_test();

  pid_t pid = fork();
  if (pid == 0) {
    printf("Summoned a child and it still works :O\n");

    if (setpgid(0, 0) == -1) {
      perror("setpgid failed");
      exit(1);
    }

    if (tcsetpgrp(0, getpid()) == -1) {
      perror("tcsetpgrp failed");
      exit(1);
    }

#if 0
    char *line;

    while ((line = readline("yak> ")) != NULL) {
      if (*line) {
        add_history(line);
      }

      printf("You typed: [%s]\n", line);

      free(line);
    }

    exit(0);

#else
    printf("executing bash as root shell :3\n");
    execl("/usr/bin/bash", "/usr/bin/bash", "-lv", NULL);
    perror("bash failed to execl");
    exit(1);
#endif
  }

  sleep(10000);

  // Reap zombie children
  sigset_t mask, oldmask;
  sigemptyset(&mask);
  sigaddset(&mask, SIGCHLD);
  sigprocmask(SIG_BLOCK, &mask, &oldmask);

  for (;;) {
    while (waitpid(-1, NULL, WNOHANG) > 0)
      ;

    sigsuspend(&oldmask);
  }

  return 0;
}
