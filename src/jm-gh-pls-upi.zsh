#! /usr/bin/env zsh
# Project LiSt Unfinished Past Iteration
#
SELF="${0##*/}"
. jm_prelude

fmt="%3v %v %11v %10v %5v %v"

header="{{ tablerow (printf "$fmt" "id" "type" "status" "it.start" "it.duration" "title" ) }}\\"
header="" # override

tpl=$(cat << EOF
$header\
{{ range .items }}\
{{ tablerow (printf "$fmt" .content.number .content.type .status .iteration.startDate .iteration.duration .title) }}\
{{ end }}
EOF
)

jq=$(cat << EOF
.items[] | select(.status != "Done")
EOF
)

current=2025-03

gh_args=( \
  --owner @me
  --format json
  # --jq "$jq" # cant combine --jq and --template apparently. The output is
  # just json.
  --template $tpl
  --limit 1000
  $@
)

awk_cond=(
  '$2 == "Issue"'
  '&& $3 != "Done"'
  '&& $4 !~ "'$current'"'
  '&& $4 != "<nil>"'
)

gh project item-list $gh_args | \
  awk "$awk_cond { print }"
