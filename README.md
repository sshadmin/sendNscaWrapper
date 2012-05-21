sendNscaWrapper
===============

Custom script to send NSCA events to Nagios passive monitoring checks

Simple bash wrapper around Nagios send_nsca

## NAME ##
    sendNscaWrapper.sh - simple bash wrapper around Nagios send_nsca

## SYNOPSIS ##
    sendNscaWrapper.sh <script> <nagiosHostname> [<options>]

## DESCRIPTION ##
    -c, --nscacfg   <send_nsca config file>
           Specify send_nsca config file
           (default /etc/nagios/send_nsca.cfg)
    -m, --nscadelim <send_nsca field delimiter>
           Specify send_nsca field delimiter
           (default "\t")
    -t, --nscato    <send_nsca timeout>
           Specify send_nsca timeout
           (default 10 seconds)
    -p, --nscaport  <send_nsca nagios target port>
           Specify send_nsca target port
           (default 5667)

    -s, --sendnsca  <send_nsca bin location>
           Specify send_nsca bin location
           By default send_nsca is searched in /usr/bin/send_nsca and then
           in the $PATH structure
    -n, --hostname  <send_nsca sender hostname>
           Specify send_nsca sender hostname
           By default send_nsca will use the result of `hostname -f`
    -b, --bookmark  <bookmark file>
           Specify a file to use as a bookmark, to contain last status
           and send events ONLY on status change or status != (OK/0)
           (if you want to send first event, empty the bookmark file)
    -h, --help
           Output this help text
    -d, --debug
           Enable debug statements

## EXAMPLES ##
     [.. to be filled soon ..]
