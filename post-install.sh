#!/bin/sh

# Set up required variables
# If any of the required variables is not set the installation will not start
username=
hostname=
continet=
city=
lang=
esp=


# The function checks if a variable is set.
# If the variable is not set, the function will exit.
#
#   :param $1: string of the variable which needs to be set
#   :param $1: variable to be checked
is_set() {
    [[ -z "$2" ]] && { echo "Error: $1 is not set"; exit 1; } || echo "$1: $2"
}

check() {
    is_set "username"   $username
    is_set "hostname"   $hostname
    is_set "continet"   $continet
    is_set "city"       $city
    is_set "lang"       $lang
    is_set "esp"        $esp
}

case $1 in
    "check")
        check
        ;;
    *)
        echo "Unknown option: ${1}"
esac
