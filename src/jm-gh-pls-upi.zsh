#! /usr/bin/env zsh
# Project LiSt Unfinished Past Iteration
#
SELF="${0##*/}"
. jm_prelude

fmt="%3v %v %10v %5v %v %11v %v"

#                                  1     2      3          4             5    6
header="{{ tablerow (printf "$fmt" "num" "type" "it.start" "it.duration" "id" "status" "title" ) }}\\"
header="" # override

tpl=$(cat << EOF
$header\
{{ range .items }}\
{{ tablerow (printf "$fmt" .content.number .content.type .iteration.startDate .iteration.duration .id .status .title) }}\
{{ end }}
EOF
)

jq=$(cat << EOF
.items[] | select(.status != "Done")
EOF
)

current=$(date +%Y-%m)

gh_args=( \
  --owner @me
  --format json
  # --jq "$jq" # cant combine --jq and --template apparently. The output is
  # just json.
  --template $tpl
  --limit 1000
  $@
)

# Note: fields after .status not addressable because status contains whitespace
awk_cond=(
  '$2 == "Issue"'
  '&& $6 != "Done"'
  '&& $3 !~ "'$current'"'
  '&& $3 != "<nil>"'
)

gh project item-list $gh_args | awk "$awk_cond { print }"
