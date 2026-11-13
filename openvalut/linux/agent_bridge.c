/*
 * openvalut-agent-bridge: forwards between the Unix socket ssh clients expect
 * (~/.openvalut/agent.sock) and the openvalut SSH agent's loopback TCP port.
 *
 * Pure-Dart cannot create Unix domain sockets, so this tiny helper does it:
 *   openvalut-agent-bridge <tcp-port> <socket-path>
 *
 * It listens on <socket-path>, and for every accepted connection opens a TCP
 * connection to 127.0.0.1:<tcp-port> and pumps bytes in both directions.
 * Build: cc -O2 -o openvalut-agent-bridge agent_bridge.c
 */
#include <arpa/inet.h>
#include <errno.h>
#include <netinet/in.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>

static int pump(int a, int b) {
  char buf[8192];
  ssize_t n = recv(a, buf, sizeof(buf), 0);
  if (n <= 0) {
    return -1;
  }
  ssize_t off = 0;
  while (off < n) {
    ssize_t w = send(b, buf + off, n - off, MSG_NOSIGNAL);
    if (w <= 0) {
      return -1;
    }
    off += w;
  }
  return 0;
}

static void handle_client(int unix_fd, int tcp_port) {
  struct sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_port = htons((uint16_t)tcp_port);
  inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);

  int tcp = socket(AF_INET, SOCK_STREAM, 0);
  if (tcp < 0) {
    close(unix_fd);
    return;
  }
  if (connect(tcp, (struct sockaddr *)&addr, sizeof(addr)) != 0) {
    close(tcp);
    close(unix_fd);
    return;
  }

  struct pollfd fds[2];
  fds[0].fd = unix_fd;
  fds[0].events = POLLIN;
  fds[1].fd = tcp;
  fds[1].events = POLLIN;

  while (1) {
    int rc = poll(fds, 2, -1);
    if (rc <= 0) {
      break;
    }
    if (fds[0].revents & (POLLIN | POLLHUP)) {
      if (pump(unix_fd, tcp) != 0) {
        break;
      }
    }
    if (fds[1].revents & (POLLIN | POLLHUP)) {
      if (pump(tcp, unix_fd) != 0) {
        break;
      }
    }
  }

  close(tcp);
  close(unix_fd);
}

int main(int argc, char **argv) {
  if (argc != 3) {
    fprintf(stderr, "usage: %s <tcp-port> <socket-path>\n", argv[0]);
    return 1;
  }
  int tcp_port = atoi(argv[1]);
  const char *socket_path = argv[2];

  unlink(socket_path);
  int fd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (fd < 0) {
    perror("socket");
    return 1;
  }
  struct sockaddr_un un;
  memset(&un, 0, sizeof(un));
  un.sun_family = AF_UNIX;
  strncpy(un.sun_path, socket_path, sizeof(un.sun_path) - 1);
  if (bind(fd, (struct sockaddr *)&un, sizeof(un)) != 0) {
    perror("bind");
    return 1;
  }
  chmod(socket_path, 0600);
  if (listen(fd, 16) != 0) {
    perror("listen");
    return 1;
  }

  while (1) {
    int client = accept(fd, NULL, NULL);
    if (client < 0) {
      continue;
    }
    handle_client(client, tcp_port);
  }
}
