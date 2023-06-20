#!/bin/bash


# This file is part of sscg.
#
# sscg is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# sscg is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with sscg.  If not, see <http://www.gnu.org/licenses/>.
#
# In addition, as a special exception, the copyright holders give
# permission to link the code of portions of this program with the
# OpenSSL library under certain conditions as described in each
# individual source file, and distribute linked combinations
# including the two.
# You must obey the GNU General Public License in all respects
# for all of the code used other than OpenSSL.  If you modify
# file(s) with this exception, you may extend this exception to your
# version of the file(s), but you are not obligated to do so.  If you
# do not wish to do so, delete this exception statement from your
# version.  If you delete this exception statement from all source
# files in the program, then also delete it here.
#
# Copyright 2016-2023 by Stephen Gallagher <sgallagh@redhat.com>


# Created by argbash-init v2.10.0
# ARG_OPTIONAL_SINGLE([commitish],[c],[The commit to be tagged for release.],[HEAD])
# ARG_OPTIONAL_BOOLEAN([debug],[],[Print debugging output])
# ARG_POSITIONAL_SINGLE([version],[The version of SSCG to release])
# ARG_DEFAULTS_POS([])
# ARG_HELP([Tags a new upstream release and submits])
# ARGBASH_GO()
# needed because of Argbash --> m4_ignore([
### START OF CODE GENERATED BY Argbash v2.10.0 one line above ###
# Argbash is a bash code generator used to get arguments parsing right.
# Argbash is FREE SOFTWARE, see https://argbash.io for more info


die()
{
	local _ret="${2:-1}"
	test "${_PRINT_HELP:-no}" = yes && print_help >&2
	echo "$1" >&2
	exit "${_ret}"
}


begins_with_short_option()
{
	local first_option all_short_options='ch'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - POSITIONALS
_positionals=()
_arg_version=
# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_commitish="HEAD"
_arg_debug="off"


print_help()
{
	printf '%s\n' "Tags a new upstream release and submits"
	printf 'Usage: %s [-c|--commitish <arg>] [--(no-)debug] [-h|--help] <version>\n' "$0"
	printf '\t%s\n' "<version>: The version of SSCG to release"
	printf '\t%s\n' "-c, --commitish: The commit to be tagged for release. (default: 'HEAD')"
	printf '\t%s\n' "--debug, --no-debug: Print debugging output (off by default)"
	printf '\t%s\n' "-h, --help: Prints help"
}


parse_commandline()
{
	_positionals_count=0
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			-c|--commitish)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_commitish="$2"
				shift
				;;
			--commitish=*)
				_arg_commitish="${_key##--commitish=}"
				;;
			-c*)
				_arg_commitish="${_key##-c}"
				;;
			--no-debug|--debug)
				_arg_debug="on"
				test "${1:0:5}" = "--no-" && _arg_debug="off"
				;;
			-h|--help)
				print_help
				exit 0
				;;
			-h*)
				print_help
				exit 0
				;;
			*)
				_last_positional="$1"
				_positionals+=("$_last_positional")
				_positionals_count=$((_positionals_count + 1))
				;;
		esac
		shift
	done
}


handle_passed_args_count()
{
	local _required_args_string="'version'"
	test "${_positionals_count}" -ge 1 || _PRINT_HELP=yes die "FATAL ERROR: Not enough positional arguments - we require exactly 1 (namely: $_required_args_string), but got only ${_positionals_count}." 1
	test "${_positionals_count}" -le 1 || _PRINT_HELP=yes die "FATAL ERROR: There were spurious positional arguments --- we expect exactly 1 (namely: $_required_args_string), but got ${_positionals_count} (the last one was: '${_last_positional}')." 1
}


assign_positional_args()
{
	local _positional_name _shift_for=$1
	_positional_names="_arg_version "

	shift "$_shift_for"
	for _positional_name in ${_positional_names}
	do
		test $# -gt 0 || break
		eval "$_positional_name=\${1}" || die "Error during argument parsing, possibly an Argbash bug." 1
		shift
	done
}

parse_commandline "$@"
handle_passed_args_count
assign_positional_args 1 "${_positionals[@]}"

# OTHER STUFF GENERATED BY Argbash

### END OF CODE GENERATED BY Argbash (sortof) ### ])
# [ <-- needed because of Argbash
# vvv  PLACE YOUR CODE HERE  vvv

set -e
tagname=sscg-${_arg_version}

# Make sure the working directory is clean
git diff --quiet HEAD --exit-code || ( echo "Working directory is dirty" && exit 2 )

# Make sure we are on the release branch
git checkout main || ( echo "Unable to switch to main branch" && exit 2 )

# Fetch tags and make sure that the provided version is not already among them
git fetch --tags
git tag -v ${tagname} > /dev/null 2>&1 && ( echo "Tag '${tagname}' is already in use!" && exit 1 )

# Update the version in meson.build
meson rewrite kwargs set project / version ${_arg_version}
git diff --quiet HEAD --exit-code || git commit -sam "Updating version to ${_arg_version}"

# Tag the new release
git tag -sm "Releasing SSCG ${_arg_version}" ${tagname} ${_arg_commitish}

# Push the tag to Github
git push origin main
git push origin tag ${tagname}

# Create the release
gh release create --generate-notes ${tagname}


# ^^^  TERMINATE YOUR CODE BEFORE THE BOTTOM ARGBASH MARKER  ^^^
# ] <-- needed because of Argbash
