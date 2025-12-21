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

  setenv("PATH", "/usr/bin:/usr/sbin:/sbin:/bin", 0);
  setenv("HOME", "/root", 0);

  pid_t pid = fork();
  if (pid == 0) {
    printf("Summoned a child and it still works :O\n");
  } else {
    printf("forked to pid=%d\n", pid);
  }

  for (;;) {
    // make sure pid 1 does not die
    sleep(1000);
  }

  return 0;
}
