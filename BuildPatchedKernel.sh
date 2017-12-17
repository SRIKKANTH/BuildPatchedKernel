#!/bin/bash

#SriMatreNamaha

function check_exit_status ()
{
    exit_status=$?
    message=$1

    if [ $exit_status -ne 0 ]; then
        echo "$message: Failed (exit code: $exit_status)" 
        if [ "$2" == "exit" ]
        then
            exit $exit_status
        fi 
    else
        echo "$message: Success" 
    fi
}

function detect_linux_ditribution_version()
{
    local  distro_version="Unknown"
    if [ -f /etc/centos-release ] ; then
        distro_version=`cat /etc/centos-release | sed s/.*release\ // | sed s/\ .*//`
    elif [ -f /etc/oracle-release ] ; then
        distro_version=`cat /etc/oracle-release | sed s/.*release\ // | sed s/\ .*//`
    elif [ -f /etc/redhat-release ] ; then
        distro_version=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
    elif [ -f /etc/os-release ] ; then
        distro_version=`cat /etc/os-release|sed 's/"//g'|grep "VERSION_ID="| sed 's/VERSION_ID=//'| sed 's/\r//'`
	fi
    echo $distro_version
}

function detect_linux_ditribution()
{
    local  linux_ditribution=`cat /etc/*release*|sed 's/"//g'|grep "^ID="| sed 's/ID=//'`
    local temp_text=`cat /etc/*release*`
    if [ "$linux_ditribution" == "" ]
    then
        if echo "$temp_text" | grep -qi "ol"; then
            linux_ditribution='Oracle'
        elif echo "$temp_text" | grep -qi "Ubuntu"; then
            linux_ditribution='Ubuntu'
        elif echo "$temp_text" | grep -qi "SUSE Linux"; then
            linux_ditribution='SUSE'
        elif echo "$temp_text" | grep -qi "openSUSE"; then
            linux_ditribution='OpenSUSE'
        elif echo "$temp_text" | grep -qi "centos"; then
            linux_ditribution='CentOS'
        elif echo "$temp_text" | grep -qi "Oracle"; then
            linux_ditribution='Oracle'
        elif echo "$temp_text" | grep -qi "Red Hat"; then
            linux_ditribution='RHEL'
        else
            linux_ditribution='unknown'
        fi
    fi
    echo "$(echo "$linux_ditribution" | sed 's/.*/\u&/')"
}

function updaterepos()
{
    ditribution=$(detect_linux_ditribution)
    case "$ditribution" in
        Oracle|RHEL|CentOS)
            yum makecache
            ;;
    
        Ubuntu)
            apt-get update
            ;;
        SUSE|openSUSE|sles)
            zypper refresh
            ;;
         
        *)
            echo "Unknown ditribution"
            return 1
    esac
}

function apt_get_install ()
{
    package_name=$1
    DEBIAN_FRONTEND=noninteractive apt-get install -y  --force-yes $package_name
    check_exit_status "apt_get_install $package_name"
}

function yum_install ()
{
    package_name=$1
    yum install -y $package_name
    check_exit_status "yum_install $package_name"
}

function zypper_install ()
{
    package_name=$1
    zypper --non-interactive in $package_name
    check_exit_status "zypper_install $package_name"
}

function install_package ()
{
    local package_name=$@
    ditribution=$(detect_linux_ditribution)
	for i in "${package_name[@]}"
	do
	    case "$ditribution" in
	        Oracle|RHEL|CentOS)
	            yum_install "$package_name"
	            ;;

	        Ubuntu)
	            apt_get_install "$package_name"
	            ;;

	        SUSE|OpenSUSE|sles)
	            zypper_install "$package_name"
	            ;;

	        *)
	            echo "Unknown ditribution"
	            return 1
		esac
	done
}

#apt-get upda
#apt install kernel-package gcc make git kernel-package libssl-dev -y
