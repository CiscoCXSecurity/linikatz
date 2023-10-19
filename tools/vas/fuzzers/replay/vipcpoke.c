/*
Copyright (c) 2015-2018, Cisco International Ltd

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Cisco International Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL CISCO INTERNATIONAL LTD BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <sys/socket.h>
#include <sys/un.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <ctype.h>

#define IPCVERSION 0x03, 0x00, 0x00, 0x00
// this is actually reverse ordered \/ - normally 0x20
#define PACKETSIZE 0x20, 0x00, 0x00, 0x00
#define OPCODE 0x00, 0x00, 0x00, 0x00
#define MAGICBYTES 'V', 'I', 'P', 'C'

void poke(const char *pathname, const char *pokebuffer, const int pokelength) {
	int idpipehandles[2];
	int sockethandle;
	struct sockaddr_un serveraddress;
	struct msghdr messageheader;
	/* \/ fixme \/ */
	struct iovec iov[1];
	struct cmsghdr *controlmessage;
	char controlbuffer[CMSG_SPACE(sizeof(int))];
	char data[1];
	/* /\ fixme /\ */
	char headerbuffer[] = { IPCVERSION, PACKETSIZE, OPCODE, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, MAGICBYTES, 0x01, 0x00, 0x00, 0x00, 0x0f, 0x00, 0x00, 0x00 };
	char responsebuffer[32];
	int pokecounter;
	char responsebuffer2[1064];
	int responsecounter2;
	pipe(idpipehandles);
	sockethandle = socket(AF_UNIX, SOCK_STREAM, 0);
	serveraddress.sun_family = AF_UNIX;
	strcpy(serveraddress.sun_path, pathname);
	connect(sockethandle, (struct sockaddr *) &serveraddress, sizeof(struct sockaddr_un));
	memset(&messageheader, 0, sizeof(struct msghdr));
	memset(controlbuffer, 0, CMSG_SPACE(sizeof(int)));
	data[0] = 0x01;
	iov[0].iov_base = data;
	iov[0].iov_len = sizeof(data);
	messageheader.msg_name = NULL;
	messageheader.msg_namelen = 0;
	messageheader.msg_iov = iov;
	messageheader.msg_iovlen = 1;
	messageheader.msg_controllen =  CMSG_SPACE(sizeof(int));
	messageheader.msg_control = controlbuffer;
	controlmessage = CMSG_FIRSTHDR(&messageheader);
	controlmessage->cmsg_level = SOL_SOCKET;
	controlmessage->cmsg_type = SCM_RIGHTS;
	controlmessage->cmsg_len = CMSG_LEN(sizeof(int));
	// looks like this must be a pipe :/, this is how vasd detects who we are
	*((int *) CMSG_DATA(controlmessage)) = idpipehandles[1];
	sendmsg(sockethandle, &messageheader, 0);
	write(sockethandle, headerbuffer, 32);
	printf("%i\n", read(sockethandle, responsebuffer, 32));
	printf("pokelength = %i\n", pokelength);
	printf("pokebuffer = ");
	for (pokecounter = 0; pokecounter < pokelength; pokecounter ++) {
		printf("%02x ", (unsigned char) *((char *) (pokebuffer + pokecounter)));
	}
	printf("\n");
	printf("pokebuffer = ");
	for (pokecounter = 0; pokecounter < pokelength; pokecounter ++) {
		if (isalnum((char) *((char *) (pokebuffer + pokecounter)))) {
			printf("%c", (char) *((char *) (pokebuffer + pokecounter)));
		} else {
			printf(".");
		}
	}
	printf("\n");
	write(sockethandle, pokebuffer, pokelength);
	memset(responsebuffer2, 0, 1064);
	printf("responselength2 = %i\n", read(sockethandle, responsebuffer2, 160));
	printf("responsebuffer2 = ");
	for (responsecounter2 = 0; responsecounter2 < 160; responsecounter2 ++) {
		printf("%02x ", responsebuffer2[responsecounter2]);
	}
	printf("\n");
	printf("responsebuffer2 = ");
	for (responsecounter2 = 0; responsecounter2 < 160; responsecounter2 ++) {
		if (isalnum((char) *((char *) (responsebuffer2 + responsecounter2)))) {
			printf("%c", (char) *((char *) (responsebuffer2 + responsecounter2)));
		} else {
			printf(".");
		}
	}
	printf("\n");
	close(sockethandle);
	close(idpipehandles[1]);
	close(idpipehandles[0]);
	sleep(3);
}

int main(int argc, char **argv) {
	struct stat filestatus;
	int filehandle;
	char *filebuffer;
	if (argc < 3) {
		printf("usage: %s <filename> <filename>", argv[0]);
		exit(EXIT_FAILURE);
	}
	stat(argv[2], &filestatus);
	filebuffer = calloc(filestatus.st_size, sizeof(char));
	memset(filebuffer, 0, filestatus.st_size);
	filehandle = open(argv[2], O_RDONLY);
	read(filehandle, filebuffer, filestatus.st_size);
	close(filehandle);
	poke(argv[1], filebuffer, filestatus.st_size);
	free(filebuffer);
}
