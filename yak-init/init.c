#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

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

    printf("executing bash as root shell :3\n");
    execl("/usr/bin/bash", "/usr/bin/bash", "-l", NULL);
    perror("bash failed to execl");

    exit(1);
  }

  for (;;) {
    // make sure pid 1 does not die
    sleep(1000);
  }

  return 0;
}
