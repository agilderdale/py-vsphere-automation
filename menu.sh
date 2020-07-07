#!/bin/bash

# Created and maintained by Alicja Gilderdale - https://github.com/agilderdale/pks-env.git
# This script is for setting up PKS Client VM from the scratch.
# Only basic Ubuntu image is required - I personally use Ubuntu Desktop version to have browser:
# https://www.ubuntu.com/download/desktop
# Some commands has been used from from pks-prep bdereims@vmware.com
#Tested on Ubuntu 18.04 LTS
# run this script as sudo
# bash -c "$(wget -O - https://raw.githubusercontent.com/agilderdale/pks-env/master/support-scripts/setup-pks-client.sh)"

BINDIR=/usr/local/bin
BOSHRELEASE=6.2.1
HELMRELEASE=2.14.1
OMRELEASE=4.5.0
PIVNETRELEASE=1.0.0
PKSRELEASE=1.5.2
PIVOTALTOKEN=''
BITSDIR="/DATA/packages"


f_info(){
    today=`date +%H:%M:%S`

    echo "[ $today ] INF  ${FUNCNAME[ 1 ]}: $*"
}

f_error(){
    today=`date +%Y-%m-%d.%H:%M:%S`

    echo "-------------------------------------------------------------------------------------------"
    echo "[ $today ] ERR  ${FUNCNAME[ 1 ]}: $*"
    echo "-------------------------------------------------------------------------------------------"
}

f_verify(){
    rc=`echo $?`
    if [ $rc != 0 ] ; then
        f_error "Last command - FAILED !!!"
        exit 1
    fi
}

f_startup_question() {
    clear
    echo "  ================================================="
    echo "  ================================================="
    echo ""
    echo "  =========== RUN THIS SCRIPT AS SUDO! ============"
    echo ""
    echo "  ================================================="
    echo ""
    echo "  vSphere7 with Kubernetes nested env installation!"
    echo ""
    echo "  ================================================="
    echo ""
    while true; do
        read -p "    Do you wish to start? (y/n): " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) echo "   =============="
                    echo "      GOODBYE!"
                    echo "   =============="
                    exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    echo "    ========================================"

}

f_choice_question() {
    clear
    while true; do
        echo "*******************************************************************************************"
        echo "  What would you like to do today?"
        echo "*******************************************************************************************"
        echo "  Available options:"
        echo "  v - verify pre-reqs env"
        echo "  a - install all (esxi7,vcsa7,nsx-t)"
        echo "  x - esxi7 | c - vcsa7 | n - nsx-t | k - kubectl"
        echo "  e - exit"
        echo "*******************************************************************************************"
        read -p "   Select one of the options? (v|x|c|n|k|e): " vxcnke

        case $vxcnke in
            [Vv]* ) clear;
#                    f_verify_pre_reqs;
                    ;;
            [Aa]* ) f_init;
                    ;;
            [Xx]* ) clear; f_init;
                    f_input_vars PKSRELEASE;
                    f_input_vars_sec PIVOTALTOKEN;
                    f_input_vars PIVNETRELEASE;
                    source /tmp/variables;
                    ;;
            [Cc]* ) clear;
                    f_input_vars BOSHRELEASE;
                    f_init;
                    source /tmp/variables;
                    ;;
            [Nn]* ) clear; f_init;
                    source /tmp/variables;
                    ;;
            [Kk]* ) clear; f_init;
                    source /tmp/variables;
                    ;;
            [Ee]* ) exit;;
            * ) echo "Please answer one of the available options";;
        esac
    done
    echo "*******************************************************************************************"

}


f_input_vars() {
    var=$1
    temp=${!1}
    read -p "Set $1 [ default: ${!1} ]: " $1

    if [[ -z ${!1} ]]
    then
        declare $var=$temp
        echo "export $var=${!var}" >> /tmp/variables
#        cat /tmp/variables
        echo "Set to default: $var="${!var}
    else
#       echo "temp="$temp
        echo "Variable set to: $1 = " ${!1}
        echo "export $1=${!1}" >> /tmp/variables
#       cat /tmp/variables
    fi
    echo "---------------------------"
}

f_input_vars_sec() {

    read -sp "$1: " $1
    echo
    if [[ -z ${!1} ]]
    then
        f_error "The $1 variable has no default value!!! User input is required - EXITING! "
        exit 1
    fi
#    echo $1 = ${!1}
    echo "Set: $1 = **************"
    echo "---------------------------"
}

f_init(){
    f_input_vars BITSDIR

    source /tmp/variables

    if [[ ! -e $BITSDIR ]]
    then
        f_info "Creating $BITSDIR directory:"
        mkdir -p $BITSDIR;
        f_verify
    fi
}

#####################################
# MAIN
#####################################

if [ ! -f /tmp/variables ] ; then
    touch /tmp/variables
else
    >/tmp/variables
fi

f_startup_question
f_choice_question

cat /tmp/pvariables
rm -Rf /tmp/variables

f_info "Task COMPLETED - please check logs for details"
