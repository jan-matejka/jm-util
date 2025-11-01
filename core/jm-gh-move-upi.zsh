#! /usr/bin/env zsh
# Move issues in Unfinished Past Iterations to @current

SELF="${0##*/}"
. jm_prelude

set -e

declare -a pargs
declare -A paargs
zparseopts -K -D -a pargs -Apaargs n

dry=""
(( ${pargs[(I)-n]} )) && { dry=echo }
gh-project-id p_id p_no _argv $@
set -- $_argv

current=$(date +%Y-%m)

pfl_args=(
  --owner @me
  --format json
  --jq '.fields[] | select(.name == "Iteration") | .id'
  $p_no
)
iteration_field_id=$(gh project field-list $pfl_args)

gql=$(cat <<EOF
query{
  node(id: "$p_id") {
    ... on ProjectV2 {
      field(name: "Iteration") {
        ... on ProjectV2IterationField {
          id
          name
          configuration {
            # Not sure, but looks like the iterations are ordered, therefore
            # first one should be current. Technically its also possible for the
            # first one to be future or for getting no iterations at all (TBD).
            iterations {
              startDate
              id
              duration
              title
              titleHTML
            }
          }
        }
      }
    }
  }
}'
EOF
)
cur_iter_args=(
  -f query=$gql
  --jq '.data.node.field.configuration.iterations[0].id'
)

iteration_current_id=$(gh api graphql $cur_iter_args)

set_current_args=(
  --field-id $iteration_field_id
  --iteration-id $iteration_current_id
  --project-id $p_id
  --id %
)

jm gh pls-upi -p $p_no |
  awk '{ print $5 }' |
  xargs -r -I% $dry gh project item-edit $set_current_args
