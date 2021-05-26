#!/usr/bin/env bash
# Author: Tay Kratzer tay@cimitra.com
# Modify Date: 5/26/2021
# Upgrade the cimitra_edir.sh Bash script

declare TEMP_FILE_DIRECTORY="/var/tmp"

INSTALL_DIRECTORY="/var/opt/cimitra/scripts/edir"

mkdir -p ${INSTALL_DIRECTORY}

declare -i EXIT_CODE=`echo $?`

if [ $EXIT_CODE -ne 0 ]
then
	echo "Error: Cannot Access Directory: ${INSTALL_DIRECTORY}"
	exit 1
fi

EDIR_SCRIPT="cimitra_edir.sh"

GITHUB_EDIR_SCRIPT="https://raw.githubusercontent.com/cimitrasoftware/edir/main/cimitra_edir.sh"

declare -i CIMITRA_EDIR_SCRIPT_EXISTS=`test -f ${INSTALL_DIRECTORY}/${EDIR_SCRIPT} && echo "0" || echo "1"`

mkdir -p ${TEMP_FILE_DIRECTORY} 1> /dev/null 2> /dev/null 

cd ${TEMP_FILE_DIRECTORY} 1> /dev/null 2> /dev/null 

declare -i EXIT_CODE=`echo $?`

if [ $EXIT_CODE -ne 0 ]
then
	echo "Error: Cannot Access Directory: ${TEMP_FILE_DIRECTORY}"
	exit 1
fi

TEMP_FILE_ONE="${INSTALL_DIRECTORY}.1.$$.tmp"

echo "1" > $TEMP_FILE_ONE 1> /dev/null 2> /dev/null 

declare -i EXIT_CODE=`echo $?`

if [ $EXIT_CODE -ne 0 ]
then
	echo "Error: Insufficient Rights in Directory: ${INSTALL_DIRECTORY}"
	exit 1
fi

rm $TEMP_FILE_ONE 1> /dev/null 2> /dev/null 

declare -i EXIT_CODE=`echo $?`

if [ $EXIT_CODE -ne 0 ]
then
	echo "Error: Insufficient Rights in Directory: ${INSTALL_DIRECTORY}"
	exit 1
fi

# DOWNLOAD THE CIMITRA EDIR SCRIPT
echo ""
echo "Download Begin"
echo "--------------"
curl -LJO ${GITHUB_EDIR_SCRIPT} -o ./cimitra_edir.sh 
declare -i EXIT_CODE=`echo $?` 
echo "--------------"
echo "Download End"




if [ $EXIT_CODE -ne 0 ]
then
	echo "Error: Unable To Download Cimitra eDirectory Script"
	exit 1
fi

cd ${INSTALL_DIRECTORY} 1> /dev/null 2> /dev/null 
declare -i EXIT_CODE=`echo $?`

if [ $EXIT_CODE -ne 0 ]
then
	echo "Error: Insufficient Rights in Directory: ${INSTALL_DIRECTORY}"
	exit 1
fi

mkdir -p ${INSTALL_DIRECTORY}/versions 1> /dev/null 2> /dev/null 
declare -i EXIT_CODE=`echo $?`

if [ $EXIT_CODE -ne 0 ]
then
	echo "Error: Insufficient Rights in Directory: ${INSTALL_DIRECTORY}"
	exit 1
fi

SCRIPT_COPY_FILENAME=`date '+%Y-%m-%d-%H-%M'`-`uuidgen -t | head -c 5`

if [ $CIMITRA_EDIR_SCRIPT_EXISTS -eq 0 ]
then
	cp ${INSTALL_DIRECTORY}/${EDIR_SCRIPT}  ${INSTALL_DIRECTORY}/versions/${SCRIPT_COPY_FILENAME}.sh 1> /dev/null 2> /dev/null 
	declare -i EXIT_CODE=`echo $?`

	if [ $EXIT_CODE -ne 0 ]
	then
		echo ""
		echo "Error: Insufficient Rights in Directory: ${INSTALL_DIRECTORY}/versions"
		echo ""
		exit 1
	fi
fi

echo ""
dos2unix ${TEMP_FILE_DIRECTORY}/${EDIR_SCRIPT}
declare -i EXIT_CODE=`echo $?`
echo ""

if [ $EXIT_CODE -ne 0 ]
then
	echo ""
	echo "Error: Unable to use the dos2unix Command"
	echo ""
	exit 1

fi

cp -v ${TEMP_FILE_DIRECTORY}/${EDIR_SCRIPT}  ${INSTALL_DIRECTORY}/${EDIR_SCRIPT} 
declare -i EXIT_CODE=`echo $?`

	if [ $EXIT_CODE -ne 0 ]
	then
		echo ""
		echo "Error: Insufficient Rights in Directory: ${INSTALL_DIRECTORY}"
		echo ""
		exit 1
	fi

if [ $CIMITRA_EDIR_SCRIPT_EXISTS -ne 0 ]
then
chmod +x ${INSTALL_DIRECTORY}/${EDIR_SCRIPT}
fi

if [ $EXIT_CODE -eq 0 ]
then
	echo ""
	echo "Cimitra eDirectory Script Installed Successfully"
	echo ""
	exit 0
else
	echo ""
	echo "Error: Insufficient Rights in Directory: ${INSTALL_DIRECTORY}"
	echo ""
	exit 1
fi
