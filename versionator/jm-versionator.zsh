#!/usr/bin/env zsh

set -eu

SELF=${0##*/}

declare -A paargs
declare -a pargs

zparseopts -K -D -a pargs -A paargs v q d x -output-shell: -dch

(( ${pargs[(I)-x]} )) && set -x

(( ${pargs[(I)-v]} )) && {
  verbose() {
    msg=$1; shift
    printf "%s: $msg\n" $SELF $@
  }
} || { verbose() {} }

fatal () {
  msg=$1; shift
  printf "%s: $msg\n" $SELF $@
  exit 1
}

o_out_shell=false
(( ${pargs[(I)--output-shell]} )) && {
  o_out_shell=true
  v_exe=${paargs[--output-shell]}
  rm -f $v_exe
}

# dch date override for deterministic commit sha's in tests.
dch_date=()
[[ ${JMU_VERSIONATOR_DCH_DATE:-} ]] && dch_date+=( --date "${JMU_VERSIONATOR_DCH_DATE}" )

build_counter=${XDG_STATE_HOME:-~/.local/state}/jm-util_build/id
install -d $(dirname $build_counter)
[[ -f $build_counter ]] && build_id=$(cat $build_counter) || build_id=0
(( build_id > 0 )) || build_id=1

(( ${pargs[(I)-d]} )) && {
  version=$(git describe --tags --dirty --match 'v/*') || exit $?
} || {
  version=${1:?Missing <version> argument}
  # FIXME: check given version is base version
  shift
}

# drop the v/ prefix
version=${version#v/}

# read last version form debian/changelog
[[ (( ${pargs[(I)--dch]} )) && -f debian/changelog ]] && {
  dcl_version=$(dpkg-parsechangelog --show-field Version)
  dcl_version=${dcl_version//-*}
} || {
  dcl_version=""
}

[[ ${version##*-} == "dirty" ]] && is_dirty=true || is_dirty=false

$is_dirty || {
  # git-describe --dirty does not trigger on untracked files so make an extra
  # check.
  [[ $(git status --porcelain) ]] && {
    is_dirty=true
    version+="-dirty"
  }
}

(( ${pargs[(I)-d]} )) || { $is_dirty && {
  git status --porcelain; fatal "release is dirty; abort"; }}

[[ ${version} =~ "-[0-9]+-g[0-9a-f]+" ]] && vtype="commit" || vtype="tag"

# version can be either tag or commit but not both.
# version can be dirty or not regardless of if it is tag or commit.

# if dch is enabled, check if new base version is higher than latest in
# debian/changelog.
base_version=${version%%-*}
[[ $dcl_version ]] && dpkg --compare-versions $base_version gt $dcl_version && {
  # The base version has increased. Reset the counter.
  verbose "build_id=1 because detected base of $version > last $dcl_version"
  build_id=1
} || {
  $is_dirty && {
    verbose "build_id++ because detected $version is dirty"
    # always bump build counter if dirty. We have no way of knowing if the
    # contents changed or not in this case.
    build_id=$(( build_id + 1 ))
  } || {
    # tree is clean and base version has not changed.
    [[ $vtype == "commit" ]] && {
      # bump the build id if version is commit
      verbose "build_id++ because detected $version is commit"
      build_id=$(( build_id + 1 ))
    }
  }
}

echo $build_id >$build_counter

if [[ $version =~ '^([^-]*)(-.*)?(-dirty)?$' ]]; then
  reason=""
  $is_dirty && reason+=" dirty"
  [[ $vtype == "commit" ]] && reason+=" commit"

  [[ ${reason} ]] && {
    verbose "build_id inserted because detected version $version is$reason"
    insert="+$build_id"
  } || insert=""

  # insert build id and + separator
  version="${match[1]}${insert}${match[2]}${match[3]}"
else
  fatal "detected version $version is invalid"
fi

# replace all "-" to make the version debian compatible
version=${version//-/.}

$o_out_shell && {
  cat >$v_exe <<EOF
#!/bin/sh

ver=$version

[ "\${1:-}" != "-q" ] && ver="\$0: version=\$ver"
echo "\$ver"
EOF

  (( ${pargs[(I)-q]} )) && args=( $v_exe -q ) || args=( $v_exe )
  sh $args
} || {
  (( ${pargs[(I)-q]} )) && { printf "%s\n" $version } ||
    printf "%s: version=%s\n" $SELF $version
}


(( ${pargs[(I)--dch]} )) && {
  [[ $dcl_version == $version ]] || {
    (( ${pargs[(I)-d]} )) || gbp dch --ignore-branch --git-log --first-parent

    # FIXME: we need to add -1 because we already have been using it. IDK how
    # this should work for general case yet.
    EDITOR=true dch ${dch_date} -v "$version-1" ""

    (( ${pargs[(I)-d]} )) || {
      EDITOR=true dch ${dch_date} -r "unstable" ""

      git commit -qam "version $version"
      git tag -a v/$version -m "$version"
    }
  }
}

exit 0
