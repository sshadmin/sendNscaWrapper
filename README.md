sendNscaWrapper
===============

Simple bash wrapper around Nagios send_nsca

## NAME ##
    LiberoSendNSCA.sh - Libero custom script to send NSCA events to Nagios monitoring

## SYNOPSIS ##
    LiberoSendNSCA.sh <script> <nagiosHostname> [<options>]

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
     -h, --help
            Output this help text
     -d, --debug
            Enable debug statements
 
## EXAMPLES ##
     [.. to be filled soon ..]
 

