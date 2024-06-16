#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

declare -a pargs
declare -A paargs
zparseopts -K -D -a pargs -A paargs h: p:

declare -A ports=(
  www      443
  imap     143
  imaps    993
  smtp     25
  smtps    465
  smtp-msa 587
  file     0
)

# protocol
check-arg "protocol" ${1:-}
protocol=$1
(( ${${(k)ports}[(I)$protocol]} )) || fatal "Unknown protocol: %s" $protocol

# host
check-arg "host" ${2:-}
host=$2

# hostname
(( ${${(k)paargs}[(I)-h]} )) && hostname=${paargs[-h]} || hostname=$host

# port
(( ${${(k)paargs}[(I)-p]} )) && port=${paargs[-p]} || port=${ports[$protocol]}

# argv
client_argv=( -showcerts -servername $host -connect $hostname:$port )
[[ $protocol == "smtp" ]] && client_argv+=( -starttls smtp )

formatter=(openssl x509 -inform pem -noout -text)

case $protocol in
"file")
  cat $host | $formatter
  ;;
*)
  # connect
  echo | openssl s_client $client_argv 2>/dev/null | $formatter
  ;;
esac
