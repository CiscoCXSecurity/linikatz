#!/bin/sh

git log ../../linikatz.sh | grep "commit " | awk '{print $2}' | while read commithash
do
	git show "${commithash}:../../linikatz.sh" >"linikatz.sh.${commithash}"
	if [ -x /usr/bin/sha256sum ]
	then
		sha256sum "linikatz.sh.${commithash}"
	else
		if [ -x /usr/bin/shasum ]
		then
			shasum -a 256 "linikatz.sh.${commithash}"
		fi
	fi
	rm "linikatz.sh.${commithash}"
done
