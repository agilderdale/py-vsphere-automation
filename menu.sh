#!/bin/bash

# Created and maintained by Alicja Gilderdale - https://github.com/agilderdale/py-vsphere-automation.git
# This script is to install and configure nested env for vSphere7 with K8s.
# Only basic Ubuntu image is required - I personally use Ubuntu Desktop version to have browser:
# https://www.ubuntu.com/download/desktop
# Majority of the repo is a fork from the https://github.com/nvpnathan/py-vsphere-automation.git
# This script is a wrapper interface to make it easier to execute #Tested on Ubuntu 18.04 LTS
# run this script as sudo
# bash -c "$(wget -O - https://raw.githubusercontent.com/agilderdale/py-vsphere-automation/blob/master/menu.sh)"

BINDIR='/usr/local/bin'
DOMAIN='mylab.com'
NTP_SERVER='dns-ntp-61-23.mylab.com'
PARENT_VC='p-vcsa67u3-61-26.mylab.com'
VC_ESX_HOST='10.172.210.52'
VC_ESXI_DATASTORE='61-22-SD3-890GB'
MASTER_PASSWORD='VMware1!'
BITSDIR='/DATA'
VC_ISO_PATH='/DATA/packages'
VC_IP='192.168.41.22'
VC_DNS_SERVERS='dns-ntp-61-23.mylab.com'
VC_GATEWAY='192.168.41.1'
VC_PORTGROUP='vDS-61-PG-Trunk'
ESX_IP_1='192.168.41.27'
ESX_IP_2='192.168.41.28'
ESX_IP_3='192.168.41.29'


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
        read -p "   Select one of the options? (v|a|x|e): " vaxcnke

        case $vaxcnke in
            [Vv]* ) clear;
#                    f_verify_pre_reqs;
                    ;;
            [Aa]* ) f_init;
                    f_download_git_repo;
                    f_update_config_file;
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

    if [[ ! -e $BITSDIR ]] ; then
        f_info "Creating $BITSDIR directory:"
        mkdir -p $BITSDIR;
        f_verify
    fi

    f_input_vars DOMAIN
    f_input_vars NTP_SERVER
    f_input_vars VC_DNS_SERVERS
    f_input_vars PARENT_VC
    f_input_vars VC_ESX_HOST
    f_input_vars VC_ESXI_DATASTORE
    f_input_vars MASTER_PASSWORD
    f_input_vars VC_GATEWAY
    f_input_vars VC_PORTGROUP
    f_input_vars ESX_IP_1
    f_input_vars ESX_IP_2
    f_input_vars ESX_IP_3
}

f_download_git_repo() {
    source /tmp/variables
    echo "-------------------------------------------------------------------------------------------"
    f_info "Downloading  github repo from https://github.com/agilderdale/py-vsphere-automation.git"
    if [[ -e ${BITSDIR}/GIT/py-vsphere-automation/ ]]
    then
        f_info "${BITSDIR}/GIT/py-vsphere-automation - cleaning up"
        rm -Rf ${BITSDIR}/GIT/py-vsphere-automation
    else [[ ! -e ${BITSDIR}/GIT/ ]]
        f_info "Creating ${BITSDIR}/GIT/py-vsphere-automation"
        mkdir -p ${BITSDIR}/GIT/
    fi
    cd ${BITSDIR}/GIT/
    git clone https://github.com/agilderdale/py-vsphere-automation.git
    cd py-vsphere-automation/
    git submodule init
    git submodule update
    f_info "Git repo download - COMPLETED"
}

f_update_config_file() {
    source /tmp/variables

    cp ${BITSDIR}/GIT/py-vsphere-automation/vsphere_config_template.yaml ${BITSDIR}/GIT/py-vsphere-automation/vsphere_config.yaml

    while read line; do
    case "$line" in \#*) continue ;; esac
      var1=`echo $line |awk '{print $1}' | sed 's/;//g'`
      echo $var1
      if [[ ! -z "$var1" ]] ; then
         sed -i -e "s/<${var1}>/${!var1}/g" ${BITSDIR}/GIT/py-vsphere-automation/vsphere_config.yaml
      fi
    done < ${BITSDIR}/GIT/py-vsphere-automation/vsphere_config.yaml

#    while read -r line
#    do
#      var1=`echo $line |awk '{print $1}'`
#      echo $var1
#        if [[  $var1 != \#* ]] || [[ ! -z "$var1" ]] ; then
#          echo "test"
#          sed -i -e "s/<${var1}>/${!var1}/g" ${BITSDIR}/GIT/py-vsphere-automation/vsphere_config.yaml
#        else
#          echo "Line with comment"
#        fi
#    done < ${BITSDIR}/GIT/py-vsphere-automation/vsphere_config.yaml
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

cat /tmp/variables
rm -Rf /tmp/variables

f_info "Task COMPLETED - please check logs for details"
