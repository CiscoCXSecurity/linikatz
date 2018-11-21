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

#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <stdio.h>
#include <sys/stat.h>
#include <fcntl.h>

#define STARTFILENAME "ipcreplay-"
#define ENDREPLAYFILENAME ".replay"
#define ENDRESPONSEFILENAME ".response"
#define IPCVERSION 0x03, 0x00, 0x00, 0x00
// this is actually reverse ordered \/ - normally 0x20
#define PACKETSIZE 0x20, 0x00, 0x00, 0x00
#define OPCODE 0x00, 0x00, 0x00, 0x00
#define MAGICBYTES 'V', 'I', 'P', 'C'
#define CHECKCRASHCOMMAND "./checkcrash.sh"

int filecounter = 0;

void replay(const char *pathname, const char *replaybuffer, const int replaylength, const int enabledflag) {
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
	char *filename;
	int filehandle;
	int replaycounter;
	char responsebuffer2[161];
	int responsecounter2;
	char *commandstring;
	printf("replay #%i\n", filecounter);
	if (enabledflag == 1) {
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
		messageheader.msg_name = (char *) NULL;
		messageheader.msg_namelen = 0;
		messageheader.msg_iov = iov;
		messageheader.msg_iovlen = 1;
		messageheader.msg_controllen =  CMSG_SPACE(sizeof(int));
		messageheader.msg_control = controlbuffer;
		controlmessage = NULL;
		controlmessage = CMSG_FIRSTHDR(&messageheader);
		controlmessage->cmsg_level = SOL_SOCKET;
		controlmessage->cmsg_type = SCM_RIGHTS;
		controlmessage->cmsg_len = CMSG_LEN(sizeof(int));
		// looks like this must be a pipe :/, this is how vasd detects who we are
		*((int *) CMSG_DATA(controlmessage)) = idpipehandles[1];
		sendmsg(sockethandle, &messageheader, 0);
		write(sockethandle, headerbuffer, 32);
		printf("responselength = %i\n", read(sockethandle, responsebuffer, 32));
		filename = calloc(strlen(STARTFILENAME) + 5 + strlen(ENDREPLAYFILENAME) + 1, sizeof(char));
		memset(filename, 0, strlen(STARTFILENAME) + 5 + strlen(ENDREPLAYFILENAME) + 1);
		snprintf(filename, strlen(STARTFILENAME) + 5 + strlen(ENDREPLAYFILENAME) + 1, "%s%i%s", STARTFILENAME, filecounter, ENDREPLAYFILENAME);
		filehandle = open(filename, O_CREAT | O_RDWR, 0644);
		write(filehandle, replaybuffer, replaylength);
		close(filehandle);
		free(filename);
		printf("replaylength = %i\n", replaylength);
		printf("replaybuffer = ");
		for (replaycounter = 0; replaycounter < replaylength; replaycounter ++) {
			printf("%02x ", (unsigned char) *((char *) (replaybuffer + replaycounter)));
		}
		printf("\n");
		printf("replaybuffer = ");
		for (replaycounter = 0; replaycounter < replaylength; replaycounter ++) {
			if (isalnum((char) *((char *) (replaybuffer + replaycounter)))) {
				printf("%c", (char) *((char *) (replaybuffer + replaycounter)));
			} else {
				printf(".");
			}
		}
		printf("\n");
		write(sockethandle, replaybuffer, replaylength);
		memset(responsebuffer2, 0, 161);
		printf("responselength2 = %i\n", read(sockethandle, responsebuffer2, 160));
		printf("responsebuffer2 = ");
		for (responsecounter2 = 0; responsecounter2 < 160; responsecounter2 ++) {
			printf("%02x ", (unsigned char) *((char *) (responsebuffer2 + responsecounter2)));
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
		filename = calloc(strlen(STARTFILENAME) + 5 + strlen(ENDRESPONSEFILENAME) + 1, sizeof(char));
		memset(filename, 0, strlen(STARTFILENAME) + 5 + strlen(ENDRESPONSEFILENAME) + 1);
		snprintf(filename, strlen(STARTFILENAME) + 5 + strlen(ENDRESPONSEFILENAME) + 1, "%s%i%s", STARTFILENAME, filecounter, ENDRESPONSEFILENAME);
		filehandle = open(filename, O_CREAT | O_RDWR, 0644);
		write(filehandle, responsebuffer2, 160);
		close(filehandle);
		free(filename);
		close(sockethandle);
		close(idpipehandles[1]);
		close(idpipehandles[0]);
		sleep(3);
		commandstring = calloc(strlen(CHECKCRASHCOMMAND) + 1 + 5 + 1, sizeof(char));
		memset(filename, 0, strlen(CHECKCRASHCOMMAND) + 1 + 5 + 1);
		snprintf(commandstring, strlen(CHECKCRASHCOMMAND) + 1 + 5 + 1, "%s %i", CHECKCRASHCOMMAND, filecounter);
		system(commandstring);
		free(commandstring);
	}
	filecounter ++;
}
	
int main(int argc, char **argv) {
	if (argc < 2) {
		printf("usage: %s <filename>", argv[0]);
		exit(1);
	}
	#include "replay.c"
}
