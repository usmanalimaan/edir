#!/usr/bin/env bash
# Author: Tay Kratzer tay@cimitra.com
# Modify Date: 5/26/2021
# Upgrade the cimitra_edir.sh Bash script

# STATIC VARIABLES
declare TEMP_FILE_DIRECTORY="/var/tmp"

GITHUB_EDIR_SCRIPT="https://raw.githubusercontent.com/cimitrasoftware/edir/main/cimitra_edir.sh"

EDIR_SCRIPT="cimitra_edir.sh"

# NON_STATIC VARIABLE
CURRENT_DIRECTORY=`pwd`

# DOES THE EDIR SCRIPT EXIST?
declare -i CIMITRA_EDIR_SCRIPT_EXISTS=`test -f ${CURRENT_DIRECTORY}/${EDIR_SCRIPT} && echo "0" || echo "1"`

# MAKE THE TEMP DIRECTORY IF IT DOES NOT EXIST
mkdir -p ${TEMP_FILE_DIRECTORY} 1> /dev/null 2> /dev/null 

# GET INTO THE TEMP DIRECTORY
cd ${TEMP_FILE_DIRECTORY} 1> /dev/null 2> /dev/null 
declare -i EXIT_CODE=`echo $?`

if [ $EXIT_CODE -ne 0 ]
then
	echo "Error: Cannot Access Directory: ${TEMP_FILE_DIRECTORY}"
	exit 1
fi

# TEST RIGHTS TO THE TEMP DIRECTORY
TEMP_FILE_ONE="${CURRENT_DIRECTORY}.1.$$.tmp"

echo "1" > $TEMP_FILE_ONE 1> /dev/null 2> /dev/null 
declare -i EXIT_CODE=`echo $?`

if [ $EXIT_CODE -ne 0 ]
then
	echo "Error: Insufficient Rights in Directory: ${CURRENT_DIRECTORY}"
	exit 1
fi

rm $TEMP_FILE_ONE 1> /dev/null 2> /dev/null 
declare -i EXIT_CODE=`echo $?`

if [ $EXIT_CODE -ne 0 ]
then
	echo "Error: Insufficient Rights in Directory: ${CURRENT_DIRECTORY}"
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

declare -i EXIT_CODE=`echo $?`

if [ $EXIT_CODE -ne 0 ]
then
	echo "Error: Unable To Download Cimitra eDirectory Script"
	exit 1
fi

cd ${CURRENT_DIRECTORY} 1> /dev/null 2> /dev/null 
declare -i EXIT_CODE=`echo $?`

if [ $EXIT_CODE -ne 0 ]
then
	echo "Error: Insufficient Rights in Directory: ${CURRENT_DIRECTORY}"
	exit 1
fi

# STORE THE OLD CODE
mkdir -p ${CURRENT_DIRECTORY}/versions 1> /dev/null 2> /dev/null 
declare -i EXIT_CODE=`echo $?`

if [ $EXIT_CODE -ne 0 ]
then
	echo "Error: Insufficient Rights in Directory: ${CURRENT_DIRECTORY}"
	exit 1
fi

SCRIPT_COPY_FILENAME=`date '+%Y-%m-%d-%H-%M'`-`uuidgen -t | head -c 5`


if [ $CIMITRA_EDIR_SCRIPT_EXISTS -eq 0 ]
then
	cp ${CURRENT_DIRECTORY}/${EDIR_SCRIPT}  ${CURRENT_DIRECTORY}/versions/${SCRIPT_COPY_FILENAME}.sh 1> /dev/null 2> /dev/null 
	declare -i EXIT_CODE=`echo $?`

	if [ $EXIT_CODE -ne 0 ]
	then
		echo ""
		echo "Error: Insufficient Rights in Directory: ${CURRENT_DIRECTORY}/versions"
		echo ""
		exit 1
	fi
fi

# MAKE SURE THE DOWNLOADED FILE IS IN LINUX FORMAT
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

# COPY THE NEWLY DOWNLOADED EDIR SCRIPT TO IT'S DESIGNATED LOCATION
cp -v ${TEMP_FILE_DIRECTORY}/${EDIR_SCRIPT}  ${CURRENT_DIRECTORY}/${EDIR_SCRIPT} 
declare -i EXIT_CODE=`echo $?`
echo ""

rm ${TEMP_FILE_DIRECTORY}/${EDIR_SCRIPT} 1> /dev/null 2> /dev/null 

	if [ $EXIT_CODE -ne 0 ]
	then
		echo ""
		echo "Error: Insufficient Rights in Directory: ${CURRENT_DIRECTORY}"
		echo ""
		exit 1
	fi

# IF THE SCRIPT DID NOT EXIST BEFORE, MAKE IT EXECUTABLE
if [ $CIMITRA_EDIR_SCRIPT_EXISTS -ne 0 ]
then
chmod +x ${CURRENT_DIRECTORY}/${EDIR_SCRIPT}
fi

if [ $EXIT_CODE -eq 0 ]
then
	echo ""
	echo "Cimitra eDirectory Script Installed Successfully"
	echo ""
	exit 0
else
	echo ""
	echo "Error: Insufficient Rights in Directory: ${CURRENT_DIRECTORY}"
	echo ""
	exit 1
fi
