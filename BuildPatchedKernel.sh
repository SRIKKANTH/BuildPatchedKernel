#!/bin/bash

#SriMatreNamaha
ditribution="UNKNOWN"
LOGFILE=~/buildLog.log
STATUSFILE=~/Status.log
packages=""

function initialise ()
{
	echo "" > $LOGFILE
	echo "" > $STATUSFILE
	
	ditribution=$(detect_linux_ditribution)
	updaterepos
}

function LogMsg ()
{
	echo $1 >> $LOGFILE
}

function UpdateTestState ()
{
	echo $1 >> STATUSFILE
}

function get_packages ()
{
	case "$ditribution" in
		Oracle|RHEL|CentOS)
			packages="kernel-package gcc make git kernel-package libssl-dev"
			;;

		Ubuntu)
			packages="kernel-package gcc make git kernel-package libssl-dev"
			;;

		SUSE|OpenSUSE|sles)
			packages="kernel-package gcc make git kernel-package libssl-dev"
			;;

		*)
			LogMsg "Unknown ditribution"
			return 1
	esac	
}

function check_exit_status ()
{
    exit_status=$?
    message=$1

    if [ $exit_status -ne 0 ]; then
        LogMsg "$message: Failed (exit code: $exit_status)" 
        if [ "$2" == "exit" ]
        then
			UpdateTestState "ABORTED"
            exit $exit_status
        fi 
    else
        LogMsg "$message: Success" 
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
            LogMsg "Unknown ditribution"
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
	
	LogMsg "Installing package: "$package_name"...."
	
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
				LogMsg "Error (install_package): Unknown ditribution"
				UpdateTestState "ABORTED"
				exit
		esac
	done
	LogMsg "Installing package: "$package_name" done!"
}

function install_package ()
{
	packagelist="kernel-package gcc make git kernel-package libssl-dev"
	for package in $packagelist
	do
		install_package $package
	done
}

function build_kernel ()
{
	cp /boot/config-`uname -r` .config
	CONFIG_FILE=.config
	yes "" | make oldconfig
	sed --in-place=.orig -e s:"# CONFIG_HYPERVISOR_GUEST is not set":"CONFIG_HYPERVISOR_GUEST=y\nCONFIG_HYPERV=y\nCONFIG_HYPERV_UTILS=y\nCONFIG_HYPERV_BALLOON=y\nCONFIG_HYPERV_STORAGE=y\nCONFIG_HYPERV_NET=y\nCONFIG_HYPERV_KEYBOARD=y\nCONFIG_FB_HYPERV=y\nCONFIG_HID_HYPERV_MOUSE=y": ${CONFIG_FILE}
	sed --in-place -e s:"CONFIG_PREEMPT_VOLUNTARY=y":"# CONFIG_PREEMPT_VOLUNTARY is not set": ${CONFIG_FILE}
	sed --in-place -e s:"# CONFIG_EXT4_FS is not set":"CONFIG_EXT4_FS=y\nCONFIG_EXT4_FS_XATTR=y\nCONFIG_EXT4_FS_POSIX_ACL=y\nCONFIG_EXT4_FS_SECURITY=y": ${CONFIG_FILE}
	sed --in-place -e s:"# CONFIG_REISERFS_FS is not set":"CONFIG_REISERFS_FS=y\nCONFIG_REISERFS_PROC_INFO=y\nCONFIG_REISERFS_FS_XATTR=y\nCONFIG_REISERFS_FS_POSIX_ACL=y\nCONFIG_REISERFS_FS_SECURITY=y": ${CONFIG_FILE}
	sed --in-place -e s:"# CONFIG_TULIP is not set":"CONFIG_TULIP=y\nCONFIG_TULIP_MMIO=y": ${CONFIG_FILE}
	sed --in-place -e s:"CONFIG_STAGING=y":"# CONFIG_STAGING is not set": ${CONFIG_FILE}  
	yes "" | make oldconfig
	if [ $? -ne 0 ]; then 
		LogMsg "Error in mkaing .config file"
		UpdateTestState $ICA_TESTFAILED 
		exit 80
	fi
	export CONCURRENCY_LEVEL=`nproc`
	LogMsg "build STARTED.."
	
	make -j$CONCURRENCY_LEVEL
	
	if echo "$ditribution" | grep -qi "Ubuntu"; then
		LogMsg "Building kernel .deb for Ubuntu"
		make-kpkg kernel-image --initrd >>  $LOGFILE
	fi
}

function apply_patches ()
{
	patchelist=`ls *.patch`
	for patch in $patchelist 
	do
		LogMsg "Appling "$patch"...."
		git apply $patch
		check_exit_status "Appling "$patch"...." "exit"
	done
}

initialise
#apt install kernel-package gcc make git kernel-package libssl-dev -y
git clone git://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
cp *.patches linux-next
cd linux-next
apply_patches
build_kernel


