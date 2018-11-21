#!/usr/bin/perl
# Copyright (c) 2015-2018, Cisco International Ltd
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * Neither the name of the Cisco International Ltd nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#DISCLAIMED. IN NO EVENT SHALL CISCO INTERNATIONAL LTD BE LIABLE FOR ANY
#DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

while (<>) {
	if ($_ =~ /.*vas_ipc_....: Dumping buffer, size=(.*)/) {
		$packetlength = $1;
		$packetleft = $packetlength;
		$packetbuffer = "";
		while (<>) {
			if ($_ =~ /.*: ([0-9a-f]{10}) 0x([0-9a-f]{1,8}) 0x([0-9a-f]{1,8}) 0x([0-9a-f]{1,8}) 0x([0-9a-f]{1,8})  .*/) {
				$packetbuffer .= $2 . $3 . $4 . $5;
				$packetleft = $packetleft - 16;
			} else {
				if ($_ =~ /.*: ([0-9a-f]{10}) 0x([0-9a-f]{1,8}) 0x([0-9a-f]{1,8}) 0x([0-9a-f]{1,8})  .*/) {
					$packetbuffer .= $2 . $3 . $4;
					$packetleft = $packetleft - 12;
				} else {
					if ($_ =~ /.*: ([0-9a-f]{10}) 0x([0-9a-f]{1,8}) 0x([0-9a-f]{1,8})  .*/) {
						$packetbuffer .= $2 . $3;
						$packetleft = $packetleft - 8;
					} else {
						if ($_ =~ /.*: ([0-9a-f]{10}) 0x([0-9a-f]{1,8})  .*/) {
							$packetbuffer .= $2;
							$packetleft = $packetleft - 4;
						}
					}
				}
			}
			if ($packetleft <= 0) {
				print "fuzz(argv[1], \"";
				$bytecounter = 0;
				foreach $packetbyte (split(//, $packetbuffer)) {
					if ($bytecounter % 2 == 0) {
						print "\\x";
					}
					print $packetbyte;
					$bytecounter ++;
				}
				print "\", " . $packetlength . ", 1);\n";
				goto end;
			}
		}
	}
	end:
}
