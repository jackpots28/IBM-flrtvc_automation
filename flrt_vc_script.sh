#!/bin/bash

# July 2023 - Updated Aug 2023
# Script for quickly retreiving lslpp/emgr data from AIX host(s)
# format is to run script with 1 arg "host" - you can run this in a loop as well:
# e.g. for i in $(cat server.list); do ./flrt_vc_script.sh $i; done
# make sure the dest dir's are correct for you system

# Dependencies required to run: sshpass
# Change these directories to what you want

/usr/bin/which sshpass;
if [[ $? -ne 0 ]]
then    
        echo "---            Dependency Error            ---";
        echo "--- Is SSHPASS installed on your machined? ---";
        echo "---             Exiting Script             ---";
        exit 1;
else
        echo "---     Dependencies Resolved Correctly    ---";
fi

remote_save_path="/home/<USERID>/"
local_save_path="/home/<USERID>/<DIR>"

host="$1";
ping -c1 -W1 $host;

if [[ $? -ne 0 ]]
then
        echo "--- Error ---";
        echo "--- Is the host name provided correct and up? ---";
        exit 1;
else
        echo "--- Ping success. Continuing. ---";
fi

if [[ $host =~ .*"vio".* ]]
then
        echo "--- $host is a VIO ---";
        echo "---  Using PADMIN  ---";
        read -sp 'Please enter PADMIN Password: ' passvar;
        temp_arch=$(sshpass -p $passvar ssh padmin@$host \
        "echo "uname -a" | oem_setup_env" | awk '{print $1}');
        echo $temp_arch;
        if [[ $temp_arch == "AIX" ]]
        then
                echo "--- Arch is AIX. Continuing. ---";
                sshpass -p $passvar ssh padmin@$host "echo "lslpp -Lcq" | oem_setup_env" > "$local_save_path"/"$host"_lslpp.txt;
                sshpass -p $passvar ssh padmin@$host "echo "emgr -lv3" | oem_setup_env" > "$local_save_path"/"$host"_emgr.txt;
                exit 0;
        else
                echo "--- ERROR Detecting OS ---";
        exit 1;
        fi
else
        echo "--- $host is NOT a VIO ---";
fi

host_arch=$(ssh $host "uname -a" | awk '{print $1}');
echo $host_arch;

if [[ $host_arch == "AIX" ]]
then
        echo "--- Arch is AIX. Continuing. ---";
        ssh $host "sudo lslpp -Lcq > "$remote_save_path$host"_lslpp.txt; sudo emgr -lv3 > "$remote_save_path$host"_emgr.txt;";
else
        echo "--- Arch is not AIX. Exitting. ---";
        exit 1;
fi

if [[ $? -ne 0 ]]
then
        echo "--- Prior block failed in lslpp/emgr commands. ---";
        exit 1;
else
        echo "--- Copying Files to ~/move_me ---"
        scp $host:"$remote_save_path$host"_lslpp.txt $local_save_path;
        scp $host:"$remote_save_path$host"_emgr.txt $local_save_path;
fi

echo "Script Complete.";
echo "Upload results to https://esupport.ibm.com/customercare/flrt/vc"
exit 0;

