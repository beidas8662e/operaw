#!/bin/bash
## Copyright (c) 2021, Oracle and/or its affiliates.
set -e

##
##  d e p l o y m e n t - m a i n . s h
##  Execute OGG Deployment
##

##
##  a b o r t
##  Terminate with an error message
##
function abort() {
    echo "Error - $*"
    exit 1
}

:     "${OGG_DEPLOYMENT:=Local}"
:     "${OGG_ADMIN:=oggadmin}"
:     "${OGG_LISTEN_ON:=127.0.0.1}"

:     "${OGG_DEPLOYMENT_HOME:?}"
[[ -d "${OGG_DEPLOYMENT_HOME}" ]] || abort "Deployment storage, '${OGG_DEPLOYMENT_HOME}', not found."
:     "${OGG_TEMPORARY_FILES:?}"
[[ -d "${OGG_TEMPORARY_FILES}" ]] || abort "Deployment temporary storage, '${OGG_TEMPORARY_FILES}', not found."
:     "${OGG_HOME:?}"
[[ -d "${OGG_HOME}"            ]] || abort "Deployment runtime, '${OGG_HOME}'. not found."

NGINX_CRT="$(awk '$1 == "ssl_certificate"     { gsub(/;/, ""); print $NF; exit }' < /etc/nginx/nginx.conf)"
NGINX_KEY="$(awk '$1 == "ssl_certificate_key" { gsub(/;/, ""); print $NF; exit }' < /etc/nginx/nginx.conf)"

export OGG_DEPLOYMENT OGG_ADMIN NGINX_CRT NGINX_KEY

##
##  g e n e r a t e P a s s w o r d
##  If not already specified, generate a random password with:
##  - at least one uppercase character
##  - at least one lowercase character
##  - at least one digit character
##
function generatePassword {
    if [[ -n "${OGG_ADMIN_PWD}" || -d  "${OGG_DEPLOYMENT_HOME}/Deployment/etc" ]]; then
        return
    fi
    local password
    password="$(openssl rand -base64 9)-$(openssl rand -base64 3)"
    if [[ "${password}" != "${password/[A-Z]/_}" && \
          "${password}" != "${password/[a-z]/_}" && \
          "${password}" != "${password/[0-9]/_}" ]]; then
        export OGG_ADMIN_PWD="${password}"
        echo "----------------------------------------------------------------------------------"
        echo "--  Password for OGG administrative user '${OGG_ADMIN}' is '${OGG_ADMIN_PWD}'"
        echo "----------------------------------------------------------------------------------"
        return
    fi
    generatePassword
}

##
##  l o c a t e _ j a v a
##  Locate the Java installation and set JAVA_HOME
##
function locate_java() {
    [[ -n "${JAVA_HOME}" ]] && return 0

    local java
    java=$(command -v java)
    [[ -z "${java}" ]] && abort "Java installation not found"

    JAVA_HOME="$(dirname "$(dirname "$(readlink -f "${java}")")")"
    export JAVA_HOME
}

##
##  r u n _ a s _ o g g
##  Return a string used for running a process as the 'ogg' user
##
function run_as_ogg() {
    local user="ogg"
    local uid gid
    uid="$(id -u "${user}")"
    gid="$(id -g "${user}")"
    echo "setpriv --ruid ${uid} --euid ${uid} --groups ${gid} --rgid ${gid} --egid ${gid} -- "
}

##
##  s e t u p _ d e p l o y m e n t _ d i r e c t o r i e s
##  Create and set permissions for directories for the deployment
##
function setup_deployment_directories() {
    rm    -fr        "${OGG_DEPLOYMENT_HOME}"/Deployment/var/{run,temp,lib/db} \
                     "${OGG_TEMPORARY_FILES}"/{run,temp}
    mkdir -p         "${OGG_TEMPORARY_FILES}"/{run,temp,db} \
                     "${OGG_DEPLOYMENT_HOME}"/Deployment/var/lib
    ln -s            "${OGG_TEMPORARY_FILES}"/run  "${OGG_DEPLOYMENT_HOME}"/Deployment/var/run
    ln -s            "${OGG_TEMPORARY_FILES}"/temp "${OGG_DEPLOYMENT_HOME}"/Deployment/var/temp
    ln -s            "${OGG_TEMPORARY_FILES}"/db   "${OGG_DEPLOYMENT_HOME}"/Deployment/var/lib/db

    chown    ogg:ogg "${OGG_DEPLOYMENT_HOME}" "${OGG_TEMPORARY_FILES}"
    chmod    0750    "${OGG_DEPLOYMENT_HOME}" "${OGG_TEMPORARY_FILES}"
    find             "${OGG_DEPLOYMENT_HOME}" "${OGG_TEMPORARY_FILES}" -mindepth 1 -maxdepth 1 -not -name '.*' -exec \
    chown -R ogg:ogg {} \;
}

##
##  s t a r t _ o g g
##  Initialize and start the OGG installation
##
function start_ogg() {
    $(run_as_ogg) python3 /usr/local/bin/deployment-init.py
    $(run_as_ogg) tail -F "${OGG_DEPLOYMENT_HOME}"/ServiceManager/var/log/ServiceManager.log &
    ogg_pid=$!
}

##
##  s t a r t _ n g i n x
##  Start the NGinx reverse proxy daemon
##
function start_nginx() {
    [[ ! -f "${NGINX_CRT}" || ! -f "${NGINX_KEY}" ]] && {
        /usr/local/bin/create-certificate.sh
    }
    replace-variables.sh /etc/nginx/*.conf
    /usr/sbin/nginx -t
    /usr/sbin/nginx
}

##
##  Termination handler
##
function termination_handler() {
    [[ -z "${ogg_pid}" ]] || {
        kill  "${ogg_pid}"
        unset    ogg_pid
    }
    [[ ! -f "/var/run/nginx.pid" ]] || {
        /usr/sbin/nginx -s stop
    }
    exit 0
}

##
##  Signal Handling for this script
##
function signal_handling() {
    trap -                   SIGTERM SIGINT
    trap termination_handler SIGTERM SIGINT
}

##
##  Entrypoint
##
generatePassword
setup_deployment_directories
locate_java
start_ogg
start_nginx
signal_handling
wait
