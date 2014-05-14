#!/usr/bin/env bash
#
# NAME
#   sendNscaWrapper.sh -   custom script to send NSCA events to Nagios
#                          passive monitoring checks
# SYNOPSIS
#   sendNscaWrapper.sh <script> <nagiosHostname> <svcdescription> [<options>]
#
# DESCRIPTION
#    -c, --nscacfg   <send_nsca config file>
#           Specify send_nsca config file
#           (default /etc/nagios/send_nsca.cfg)
#    -m, --nscadelim <send_nsca field delimiter>
#           Specify send_nsca field delimiter
#           (default "\t")
#    -t, --nscato    <send_nsca timeout>
#           Specify send_nsca timeout
#           (default 10 seconds)
#    -p, --nscaport  <send_nsca nagios target port>
#           Specify send_nsca target port
#           (default 5667)
#
#    -s, --sendnsca  <send_nsca bin location>
#           Specify send_nsca bin location
#           By default send_nsca is searched in /usr/bin/send_nsca and then
#           in the $PATH structure
#    -n, --hostname  <send_nsca sender hostname>
#           Specify send_nsca sender hostname
#           By default send_nsca will use the result of `hostname -f`
#    -b, --bookmark  <bookmark file>
#           Specify a file to use as a bookmark, to contain last status
#           and send events ONLY on status change or status != (OK/0)
#           (if you want to send first event, empty the bookmark file)
#    -q, --quiet
#           Avoid printing any (non-debug) statement
#    -h, --help
#           Output this help text
#    -d, --debug
#           Enable debug statements
#
# LICENSE
#
#   Copyright (C) 2012-2013 Emanuele 'Lele aka eldios' Calo'
#   Mail address: lele at sshadm dot in
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by the
#   Free Software Foundation, either version 3 of the License,
#   or (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful, 
#   but WITHOUT ANY WARRANTY; without even the implied warranty 
#   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License 
#   along with this program. If not, see http://www.gnu.org/licenses/
#
# EXAMPLES
#   [.. to be filled soon ..]
#


###############################################################################
# last blank line is used to determine end of documentation
###############################################################################
set -o errexit -o noclobber -o nounset -o pipefail
set -u

# Defaults
debug=false
cmdname="$(basename -- $0)"
directory="$(dirname -- "$0")"
sendnscaLocation=$(command -v send_nsca) || $(echo "")
quiet=false
nscaPort=""     # default 5667
nscaTimeout=""  # default 10 seconds
nscaDelim=""    # default "\t"
nscaCfg=""      # default /etc/nagios/send_nsca.cfg
nscaCfgDef="/etc/nagios/send_nsca.cfg" # default /etc/nagios/send_nsca.cfg location
hostname=""     # default 'hostname -f'
svcdesc=""      # mandatory
bookmarkfile="" # default not used


# Process parameters
params="$(getopt \
          -o c:m:t:p:s:n:b:qhd \
          -l nscacfg:,nscadelim:,nscato:,nscaport:,sendnsca:,hostname:,bookmark:,quiet,help,debug \
          --name "$cmdname" -- "$@")"

# Custom errors
EX_CRITICAL="2"
EX_WARNING="1"
EX_OK="0"
EX_UNKNOWN="$EX_CRITICAL"
# helper methods
# Exit codes from /usr/include/sysexits.h, as recommended by
# http://www.faqs.org/docs/abs/HTML/exitcodes.html
EX_USAGE="64"

error()
{
  # Output error messages with optional exit code
  # @param $1...: Messages
  # @param $N: Exit code (optional)

  local -a messages=( "$@" )

  # If the last parameter is a number, it's not part of the messages
  local -r last_parameter="${@: -1}"
  if [[ "$last_parameter" =~ ^[0-9]*$ ]]
  then
    local -r exit_code="$last_parameter"
    unset messages[$((${#messages[@]} - 1))]
  fi

  echo "${messages[@]}"

  exit "${exit_code:-$EX_UNKNOWN}"
}

outputDebug()
{
  # outputdebug statement
  # @param $1: debug statement text (mandatory)
  # @param $2: debug status value (mandatory)
  local message=("${1}");
  local debug=("${2}");
  local timestamp="$(date +%d-%m-%Y_%T_\(%z\))"

  if ( "$debug" )
  then
    echo "$timestamp : $message"
  fi
}

usage()
{
  # Print documentation until the first empty line
  # @param $1: Exit code (optional)
  local line
  while IFS= read line
  do
    if [ -z "$line" ]
    then
        exit "${1:-0}"
    elif [ "${line:0:2}" == '#!' ]
    then
        # Shebang line
        continue
    fi
    echo "${line:2}" # Remove comment characters
  done < "$0"
}

# main code
if [ "$?" -ne "0" ]
then
    usage "$EX_USAGE"
fi

eval set -- "$params"
unset params

while true
do
    case "$1" in
        -n|hostname)
            hostname="${2-}"
            shift 2
            ;;
        -s|sendnsca)
            sendnscaLocation="${2-}"
            shift 2
            ;;
        -b|bookmark)
            bookmarkfile="${2-}"
            shift 2
            ;;
        -p|nscaport)
            nscaPort="${2-}"
            shift 2
            ;;
        -t|nscato)
            nscaTimeout="${2-}"
            shift 2
            ;;
        -m|nscadelim)
            nscaDelim="${2-}"
            shift 2
            ;;
        -c|nscacfg)
            nscaCfg="${2-}"
            shift 2
            ;;
        -q|quiet)
            quiet=true
            shift
            ;;
        -d|debug)
            debug=true
            shift
            ;;
        -h|--help)
            usage
            exit "$EX_OK"
            ;;
        --)
            shift
            if [ -z "${1:-}" ]
            then
                echo  "You must specify the script to be executed"\
                      "AND the Nagios monitoring server hostname"
                usage
                error "" "$EX_USAGE"
            fi
            if [ -z "${2:-}" ]
            then
                echo  "You must specify the Nagios monitoring"\
                      " server hostname"
                usage
                error "" "$EX_USAGE"
            fi
            if [ -z "${3:-}" ]
            then
                echo  "You must specify the Nagios monitoring"\
                      " passive service description"
                usage
                error "" "$EX_USAGE"
            fi
            if [ -n "${4:-}" ]
            then
                echo  "Too many parameters"
                usage
                error "" "$EX_USAGE"
            fi
            break
            ;;
        *)
            usage
            ;;
    esac
done

outputDebug 'Debug activated' "$debug"

# checking that everything is available and usable
outputDebug "sendnscaLocation -> $sendnscaLocation" "$debug"
if [[ ! -x "$sendnscaLocation" ]]
then
  error "Cannot find/execute send_nsca Nagios plugin" "$EX_CRITICAL"
fi

extScript="${1}"
extScriptBin=$(command -v $extScript | head -n1) || $(echo "")
outputDebug "extScript -> $extScriptBin [ $extScript ]" "$debug"
if [[ ! -x "$extScriptBin" ]]
then
  error "Cannot find/execute specified script" "$EX_CRITICAL"
fi

nagiosHostname="${2}"
nagiosHostnameIP=""
isIP()
{
  local isIPHostname="${1}"
  # isIP="$(echo $isIPHostname | awk '/^\s*[0-2]{0,1}[0-9]{1,2}(\.[0-2]{0,1}[0-9]{1,2}){3}\s*$/ { print $1 }')"
  isIP="$(echo $isIPHostname | awk '/^\s*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\s*$/ { print $1 }')";
  if [[ -n "$isIP" ]]
  then
    echo $isIP
  else
    echo ""
  fi
}
if [[ ! "$(isIP $nagiosHostname)" ]]
then
  nagiosHostnameIP=$(dig +short ${2}) || $(echo "")
  outputDebug "nagiosHostname -> $nagiosHostname : $nagiosHostnameIP" "$debug"
  if [[ ! "$nagiosHostnameIP" ]]
  then
    error "Cannot resolve specified Nagios Hostname" "$EX_CRITICAL"
  fi
else
  outputDebug "nagiosHostname -> $nagiosHostname" "$debug"
fi

svcdesc="${3}"
outputDebug "svcdesc: $svcdesc" "$debug"


sendNscaCMD="$sendnscaLocation -H $nagiosHostname"
if [[ -n "$nscaPort" ]]
then
  outputDebug "nscaPort : $nscaPort" "$debug"
  sendNscaCMD="$sendNscaCMD -p $nscaPort"
fi
if [[ -n "$nscaTimeout" ]]
then
  outputDebug "nscaTimeout : $nscaTimeout" "$debug"
  sendNscaCMD="$sendNscaCMD -t $nscaTimeout"
fi
if [[ -n "$nscaDelim" ]]
then
  outputDebug "nscaDelim : $nscaDelim" "$debug"
  sendNscaCMD="$sendNscaCMD -d \"$nscaDelim\""
fi
if [[ -z "$nscaCfg" ]]
then
  outputDebug "nscaCfg set to default location $nscaCfgDef" "$debug"
  nscaCfg="$nscaCfgDef"
fi

if [[ -r "$nscaCfg" ]]
then
  outputDebug "nscaCfg : $nscaCfg" "$debug"
  sendNscaCMD="$sendNscaCMD -c $nscaCfg"
else
  echo "Cannot find/read specified send_nsca config file $nscaCfg"
  exit "$EX_CRITICAL"
fi

# actual script execution
set +e
  scriptOutput="$($extScript 2>&1)"
  scriptStatus="$(echo ${PIPESTATUS[0]})"
set -e
outputDebug "scriptOutput : $scriptOutput" "$debug"
outputDebug "scriptStatus : $scriptStatus" "$debug"

if [[ -z "$hostname" ]]
then
  hostname=$(hostname -f)
fi
outputDebug "hostname: $hostname" "$debug"

if [[ -z "$nscaDelim" ]]
then
  nscaDelim="\t"
fi
outputDebug "nscaDelim: $nscaDelim" "$debug"

sendNscaMsg=""
sendNscaMsg="$sendNscaMsg""$hostname""$nscaDelim""$svcdesc""$nscaDelim"
sendNscaMsg="$sendNscaMsg""$scriptStatus""$nscaDelim""$scriptOutput"

outputDebug "sendNscaCMD : $sendNscaCMD" "$debug"
outputDebug "sendNscaMsg: $sendNscaMsg" "$debug"

sendEvent=true
if [[ -n "$bookmarkfile" ]]
then
  outputDebug "bookmarkfile is $bookmarkfile" "$debug"
  if [[ ! -f "$bookmarkfile" ]]
  then
    touch "$bookmarkfile"
  fi
  if [[ ! -r "$bookmarkfile" ]]
  then
    error "Cannot read bookmarkfile, check permission" "$EX_CRITICAL"
  fi
  lastStatus="$(cat $bookmarkfile)"
  outputDebug "lastStatus is $lastStatus" "$debug"
  if [[ "$lastStatus" -eq "$scriptStatus" && "$lastStatus" -eq "0" ]]
  then
    sendEvent=false
  else
    sendEvent=true
    set +o noclobber
      echo "$scriptStatus" > "$bookmarkfile"
    set -o noclobber
  fi
else
  outputDebug "no bookmarkfile specified" "$debug"
fi

outputDebug "sendEvent is $sendEvent" "$debug"
if ( "$sendEvent" )
then
  outputDebug "Event sent to $nagiosHostname" "$debug"
  set +e
    sendNscaOutput="$(echo -e $sendNscaMsg | $sendNscaCMD 2>&1)"
    sendNscaStatus="$(echo ${PIPESTATUS[0]})"
  set -e
  outputDebug "sendNscaOutput: $sendNscaOutput" "$debug"
  outputDebug "sendNscaStatus : $sendNscaStatus" "$debug"
  if ( ! "$quiet" )
  then
    echo "$sendNscaOutput"
    exit "$sendNscaStatus"
  fi
else
  outputDebug "Event NOT sent to $nagiosHostname" "$debug"
  if ( ! "$quiet" )
  then
    echo "Event NOT sent as status is not changed"
    exit "$EX_OK"
  fi
fi
