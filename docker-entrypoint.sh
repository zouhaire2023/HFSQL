#!/bin/bash
set -Eeuo pipefail

file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val=""
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		if [ !-f "${!fileVar}" ]; then
			echo >&2 "error: file $fileVar=<${!fileVar}> does not exist"
			exit -1
		fi
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

# first arg is the bare word `couchdb`
if [ "$1" = 'hfsql' ]; then
	shift
	set -- /opt/hfsql/manta64 --no-daemon "$@"
fi

if [ "$1" = '/opt/hfsql/manta64' ] || [ "$1" = 'createhfsqluser' ]; then
	if [ ! -d "/var/lib/hfsql/__system" ]; then
		file_env 'HFSQL_PASSWORD'
		
		if [ "${HFSQL_RANDOM_PASSWORD:-}" = "yes" ]; then
			if [ ! -z "${HFSQL_PASSWORD}" ]; then
				echo "error: both HFSQL_RANDOM_PASSWORD and HFSQL_PASSWORD[_FILE] are set (but are exclusive)"
				exit -1
			fi
			export "HFSQL_PASSWORD"="$(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1)"
			echo "generated password: $HFSQL_PASSWORD"
		fi
		
		if [ ! -z "${HFSQL_PASSWORD}" ]; then
			/opt/hfsql/manta64 --CREATEUSER "admin" --PWD "$HFSQL_PASSWORD" 
		fi
	fi
	if [ "$1" = 'createhfsqluser' ]; then
		exit 0
	fi
fi
	
exec "$@"




