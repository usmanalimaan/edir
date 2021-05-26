#!/usr/bin/env bash
# Author: Tay Kratzer tay@cimitra.com
# Modify Date: 5/26/2021
# Modify eDirectory attributes using LDAP Calls

declare TEMP_FILE_DIRECTORY="/var/tmp"

GLOBAL_LDAP_TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.global.tmp.ldif"
GLOBAL_LDAP_TEMP_FILE_TWO="${TEMP_FILE_DIRECTORY}/$$.2.global.tmp.ldif"

declare UserId=""
declare Context=""
declare ListUsersContext=""
declare ManagerId=""
declare ManagerContext=""
declare UserExpirationDate=""
declare theFirstNameUniversal=""
declare theLastNameUniversal=""
declare IgnoreExcludeGroup=""

declare MODIFY_USER_ATTRIBUTE=0

declare -i SHOW_HELP_MESSAGE=0
declare -i EMPTY_STRING_SENT=0
declare -i SleepTime=5
declare -i DisableUserVerify=0
declare -i DisableUserSearch=0
declare -i USER_REPORT_ALREADY_RAN=0
declare -i DISABLE_USER=0
declare -i COMPACT_OUTPUT=0
declare -i MODIFY_GROUP=0
declare -i REPORT_USER=0
declare -i ADD_USER_TO_GROUP=0
declare -i REMOVE_USER_FROM_GROUP=0
declare -i GROUP_MODIFY_COMPLETE=0
declare -i IGNORE_EXCLUDE_GROUP=0
declare -i CREATE_USER=0
declare -i USER_CONTEXT_SET=0
declare -i DEFAULT_USER_CONTEXT_SET=0
declare -i THE_USER_WAS_CREATED=0
declare -i ADD_CREATED_USER_TO_GROUP=0
declare -i LIST_USERS_CONTEXT_SET=0
declare -i ModifiedUserFirstName=0
declare -i ModifiedUserLastName=0
declare -i USER_FULL_NAME_OR_USERID=0
declare -i USER_FULL_NAME_OR_USERID_OR_DN=0
declare -i MANAGER_FULL_NAME_OR_USERID=0
declare -i USER_ACTION=0
declare -i GROUP_ACTION=0
declare -i DisableUserReport=0
declare -i REPLACE_FULL_NAME=0

while [ $# -gt 0 ]; do
  case "$1" in
    --help*|-h*)
    #Show Help Screen
    SHOW_HELP_MESSAGE=1
      ;;
    -IgnoreExcludeGroup)
	# If there is an "EXCLUDE_GROUP" specified in the settings_edir.cfg file, then ignore the Exclude Group.
	IgnoreExcludeGroup="$2"
	IGNORE_EXCLUDE_GROUP=1
	  ;;
    -JustASwitch)
	# Just a switch that at times can be useful with Cimitra
	;;
    -SleepTime)
     # For sleep/pause actions in this script, indicate the amount in seconds default is 5 seconds.
	SleepTime="$2"
	  ;;
    -DisableUserSearch)
     # When modifying a user, if the -UserId and the -Context parameters are not passed, this script will search for the user based on the -FirstName and -LastName parameters.
	DisableUserSearch="1"
	  ;;
    -DisableUserReport)
     # After a user is modified, a user report is run, the -DisablUserReport switch disables this functionality
	DisableUserReport="1"
	  ;;
    -DefaultUserSearchContext)
     # If the -Context parameter is not specified, then if the -DefaultUserSearchContext parameter is specified, it will be used to determine the path to an object
	DefaultUserSearchContext="$2"
	DEFAULT_USER_CONTEXT_SET="1"
	  ;;
    -DefaultManagerSearchContext)
     # If the -ManagerContext parameter is not specified, then if the -DefaultManagerSearchContext parameter is specified, it will be used to determine the path to a user object designated as a manager.
     # The -ManagerContext and -DefaultManagerSearchContext parameters are used when assigning a Manager to a user.
     # -Example: -DefaultManagerSearchContext "ou=users,o=cimitra"
	DefaultManagerSearchContext="$2"
	  ;;
    -UserId)
     # When modifying a user, use the -UserId parameter, along with the -Context or -DefaultUserSearchContext parameter.
     # Example: -UserId "jdoe"
	UserId="$2"
	USER_ACTION=1
	  ;;
    -Context)
     # When modifying a user, use the -UserId parameter, along with the -Context or -DefaultUserSearchContext parameter.
     # Example: -Context "ou=users,o=cimitra"
	Context="$2"
	USER_CONTEXT_SET="1"
	  ;;
    -FullNameOrUserId)
     # When modifying a user, you can either use the person's Userid or their Fullname.
     # Example: -FullNameOrUserId "jdoe" [OR] -FullNameOrUserId "Jane Doe"
     # The script will look for the existence of one user that matches either the Userid or the Full Name specified
	FullNameOrUserId="$2"
	USER_FULL_NAME_OR_USERID=1
	USER_ACTION=1
	  ;;
    -FullNameOrUserIdOrDN)
     # When modifying a user, you can either use the person's Userid or their Fullname or their Distinguished Name
     # Example: -FullNameOrUserIdOrDN "jdoe" [OR] -FullNameOrUserIdOrDN "Jane Doe" [OR] -FullNameOrUserIdOrDN "cn=jdoe,ou=users,o=cimitra"
     # The script will look for the existence of one user that matches either the Userid or the Full Name specified, or if a Distinguished Name is specified, the script knows exactly where to find the user.
	FullNameOrUserIdOrDN="$2"
	USER_FULL_NAME_OR_USERID_OR_DN=1
	USER_ACTION=1
	  ;;
    -ManagerFullNameOrUserId)
     # When adding a manager to a user, you can either use the manager's Userid or their Fullname.
     # Example: -ManagerFullNameOrUserId "asmith" [OR] -ManagerFullNameOrUserId "Ann Smith"
     # The script will look for the existence of one user that matches either the Userid or the Full Name specified.
	ManagerFullNameOrUserId="$2"
	MANAGER_FULL_NAME_OR_USERID=1
	  ;;
    -GroupName)
     # When doing an add/delete of a User from a Group, then use the -GroupName parameter along with the -GroupContext parameter. 
     # Example:  -GroupName "GroupOne" -GroupContext "ou=groups,o=cimitra"
	GroupName="$2"
	  ;;
    -GroupContext)
     # When doing an add/delete of a User from a Group, then use the -GroupName parameter along with the -GroupContext parameter. 
     # Example:  -GroupName "GroupOne" -GroupContext "ou=groups,o=cimitra"
       GroupContext="$2"
	  ;;
    -DefaultGroupContext)
	DefaultGroupContext="$2"
	  ;;
    -GroupDNList)
     # Example: -GroupDNList "cn=GroupOne,ou=users,o=cimitra;cn=GroupTwo,ou=users,o=cimitra"
     # Note: The -GroupContext parameter is not necessary when the -GroupDNList parameter is used
	GroupDNList="$2"
 	  ;;
    -AddUserToGroup)
      MODIFY_GROUP=1
      ADD_USER_TO_GROUP=1
      GROUP_ACTION=1
	  ;;
    -RemoveUserFromGroup)
      MODIFY_GROUP=1
      REMOVE_USER_FROM_GROUP=1
      GROUP_ACTION=1
	  ;;
    -DisableUser)
      DisableUser="$2"
	  ;;
    -EnableUser)
      EnableUser="$2"
	  ;;
    -UserExpirationDate)
     UserExpirationDate="$2"
	  ;;
    -RemoveUserExpiration)
     RemoveUserExpiration="$2"
	  ;;
    -ModifyUser)
      ModifyUser="$2"
	  ;;
    -NewContext)
      NewContext="$2"
	  ;;
    -FirstName)
      FirstName="$2"
      USER_ACTION=1
      ;;
    -LastName)
      LastName="$2"
      USER_ACTION=1
      ;;
    -EmailAddress)
      EmailAddress="$2"
      ;;
    -DefaultPassword)
      DefaultPassword="$2"
	  ;;
    -Password)
      Password="$2"
	  ;;
    -Action)
      Action="$2"
	  ;;
    -Title)
      Title="$2"
	  ;;
    -OfficePhone)
      OfficePhone="$2"
	  ;;
    -MobilePhone)
      MobilePhone="$2"
	  ;;
    -FaxNumber)
      FaxNumber="$2"
	  ;;
    -GenerationQualifier)
      GenerationQualifier="$2"
	  ;;
    -MiddleInitial)
      MiddleInitial="$2"
	  ;;
    -NewFirstName)
      NewFirstName="$2"
	  ;;
    -NewLastName)
      NewLastName="$2"
	  ;;
    -Description)
      Description="$2"
	  ;;
    -ManagerId)
     ManagerId="$2"
	  ;;
    -ManagerContext)
     ManagerContext="$2"
	  ;;
    -ManagerFirstName)
     ManagerFirstName="$2"
	  ;;
    -ManagerLastName)
     ManagerLastName="$2"
	  ;;
    -Department)
      Department="$2"
	  ;;
    -Location)
      Location="$2"
	  ;;
    -ListUsersContext)
     # When using -Action "ListUsers" this is the context that will be used to find the users
     # Example: -ListUsersContext "ou=users,o=cimitra"
	ListUsersContext="$2"
	USER_CONTEXT_SET="1"
	LIST_USERS_CONTEXT_SET="1"
	USER_ACTION="0"
	  ;;
    -LDAPAttributeOne)
      LDAPAttributeOne="$2"
	  ;;
    -LDAPAttributeOneName)
      LDAPAttributeOneName="$2"
	  ;;
    -LDAPAttributeTwo)
      LDAPAttributeTwo="$2"
	  ;;
    -LDAPAttributeTwoName)
      LDAPAttributeTwoName="$2"
	  ;;
    -LDAPAttributeThree)
      LDAPAttributeThree="$2"
	  ;;
    -LDAPAttributeThreeName)
      LDAPAttributeThreeName="$2"
	  ;;
    -LDAPAttributeFour)
      LDAPAttributeFour="$2"
	  ;;
    -LDAPAttributeFourName)
      LDAPAttributeFourName="$2"
	  ;;
    -LDAPAttributeFive)
      LDAPAttributeFive="$2"
	  ;;
    -LDAPAttributeFiveName)
      LDAPAttributeFiveName="$2"
	  ;;
    -LDAPAttributeSix)
      LDAPAttributeSix="$2"
	  ;;
    -LDAPAttributeSixName)
      LDAPAttributeSixName="$2"
	  ;;
    -LDAPAttributeSeven)
      LDAPAttributeSeven="$2"
	  ;;
    -LDAPAttributeSevenName)
      LDAPAttributeSevenName="$2"
	  ;;
    -LDAPAttributeEight)
      LDAPAttributeEight="$2"
	  ;;
    -LDAPAttributeEightName)
      LDAPAttributeEightName="$2"
	  ;;
    -LDAPAttributeNine)
      LDAPAttributeNine="$2"
	  ;;
    -LDAPAttributeNineName)
      LDAPAttributeNineName="$2"
	  ;;
    "")
      EMPTY_STRING_SENT=1
	  ;;
    '')
      EMPTY_STRING_SENT=1
	  ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument *\n"
      printf "***************************\n"
      exit 1
	;;
  esac
  shift
  shift
done

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

if [[ -n "$Action" ]];
then
	if [ $Action == "CreateUser" ]
	then
		CREATE_USER=1
	fi

	if [ $Action == "UserReport" ]
	then
		REPORT_USER=1
	fi


	if [ $Action == "SearchForUser" ]
	then
		USER_ACTION=0
		GROUP_ACTION=0
	fi

	if [ $Action == "ListUsers" ]
	then
		USER_ACTION=0
		GROUP_ACTION=0
	fi
fi

if [ $USER_CONTEXT_SET -eq 0 ]
then
	if [ $DEFAULT_USER_CONTEXT_SET -gt 0 ]
	then
		declare -i DEFAULT_USER_CONTEXT_SET_LENGTH=`echo "${DefaultUserSearchContext}" | wc -c`
			if [ $DEFAULT_USER_CONTEXT_SET_LENGTH -gt 5 ]
			then
			Context="${DefaultUserSearchContext}"
			fi
	fi
fi


function ReportError()
{
echo ""
echo "Error: $1"
echo ""
exit 1
}

function OutputMessage()
{
echo "$1"
}


### Discover or establish a settings_edir.cfg file ###
function ProcessSettingsFile()
{
# See if a EDIR_SCRIPT_SETTINGS_FILE is defined in an environment variable
if [[ -z "${EDIR_SCRIPT_SETTINGS_FILE}" ]] 
then
EDIR_SCRIPT_SETTINGS_FILE="${SCRIPT_PATH}/settings_edir.cfg"
fi

# Test and see if the EDIR_SCRIPT_SETTINGS_FILE file exists
declare -i EDIR_SCRIPT_SETTINGS_FILE_EXISTS=`ls ${EDIR_SCRIPT_SETTINGS_FILE} 2> /dev/null 1> /dev/null && echo "0" || echo "1"`

# If the EDIR_SCRIPT_SETTINGS_FILE does not exist, initialize it with variables
if [ $EDIR_SCRIPT_SETTINGS_FILE_EXISTS -ne 0 ]
then
echo "EDIR_AUTH_STRING=\"SuperS3cr3t\"" >> ${EDIR_SCRIPT_SETTINGS_FILE}
echo "EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE=\"192.168.1.53\"" >> ${EDIR_SCRIPT_SETTINGS_FILE}
echo "EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE=\"389\"" >> ${EDIR_SCRIPT_SETTINGS_FILE}
echo "EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_TWO=\"192.168.1.54\"" >> ${EDIR_SCRIPT_SETTINGS_FILE}
echo "EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_TWO=\"389\"" >> ${EDIR_SCRIPT_SETTINGS_FILE}
echo "EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_THREE=\"192.168.1.54\"" >> ${EDIR_SCRIPT_SETTINGS_FILE}
echo "EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_THREE=\"389\"" >> ${EDIR_SCRIPT_SETTINGS_FILE}
echo "EDIR_USER=\"cn=admin,o=cimitra\"" >> ${EDIR_SCRIPT_SETTINGS_FILE}
echo "EDIR_EXCLUDE_GROUP=\"\"" >> ${EDIR_SCRIPT_SETTINGS_FILE}
OutputMessage ""
OutputMessage "Please configure the eDirectory Script Settings file: ${EDIR_SCRIPT_SETTINGS_FILE}"
OutputMessage ""
exit 1
fi

# Read the EDIR_SCRIPT_SETTINGS_FILE file
EDIR_EXCLUDE_GROUP=""
source ${EDIR_SCRIPT_SETTINGS_FILE}

timeout 1 bash -c "(echo > /dev/tcp/$EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE/$EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE) >/dev/null 2>&1"

PORT_CHECK_EXIT_CODE=`echo $?`

if [ $PORT_CHECK_EXIT_CODE -eq 0 ]
then
EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS="$EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE"
EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT="$EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE"
return
fi


timeout 1 bash -c "(echo > /dev/tcp/$EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_TWO/$EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_TWO) >/dev/null 2>&1"

PORT_CHECK_EXIT_CODE=`echo $?`
if [ $PORT_CHECK_EXIT_CODE -eq 0 ]
then
EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS="$EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_TWO"
EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT="$EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_TWO"
return
fi

timeout 1 bash -c "(echo > /dev/tcp/$EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_THREE/$EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_THREE) >/dev/null 2>&1"

PORT_CHECK_EXIT_CODE=`echo $?`
if [ $PORT_CHECK_EXIT_CODE -eq 0 ]
then
EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS="$EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_THREE"
EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT="$EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_THREE"
return
else
ReportError "Cannot Connect to eDirectory LDAP Server(s)"
fi

}

ProcessSettingsFile

function SHOW_HELP()
{
echo ""
echo "--- Script Help ---"
echo ""
echo "Create or Modify User"
echo ""
echo "Script usage:     $0 [options]"
echo ""
echo "Example:          $0 -Action \"CreateUser\" -UserId \"bsmith\" -FirstName \"Bob\" -LastName \"Smith\" -Context \"users.finance.cimitra\" -Password \"ChangeM3N0W\""
echo ""
echo "Example:          $0 -Action \"ChangePassword\" -UserId \"bsmith\" -Context \"users.finance.cimitra\" -Password \"ChangeM3N0W\""
echo ""
echo "Help:             $0 -h"
echo ""
}

if [ $SHOW_HELP_MESSAGE -gt 0 ]
then
SHOW_HELP
exit 0
fi

function CallSleep()
{
# If the script is running in a terminal, the fact that a sleep/pause is happening will show.
TEST_TTY=`tty | sed -e "s/.*tty\(.*\)/\1/"`

declare -i TEST_HAS_DEV=`echo "$TEST_TTY" | grep -c "/dev"`

if [ $TEST_HAS_DEV -gt 0 ]
then
	if [ $SleepTime -eq 1 ]
	then
	OutputMessage "Pausing for $SleepTime Second"
	else
	OutputMessage "Pausing for $SleepTime Seconds"
	fi
fi
sleep $SleepTime
}

function IdentifyUserFullName()
{
if [ $USER_ACTION -eq 0 ]
then
return
fi


OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"


if [[ -n "$Context" ]];
then
	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} -b ${Context} '(&(objectClass=user)(cn='${UserId}'))' fullName 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null


else

	if [[ -n "$DefaultUserSearchContext" ]];
	then
		{
		ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} -b ${DefaultUserSearchContext} '(&(objectClass=user)(cn='${UserId}'))' fullName 1> ${OUT_FILE_ONE}
		} 1> /dev/null 2> /dev/null
	else
		{
		ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${UserId}'))' fullName 1> ${OUT_FILE_ONE}
		} 1> /dev/null 2> /dev/null
	fi
fi

FULL_NAME_LINE=`grep "fullName:" ${OUT_FILE_ONE}`

FULL_NAME=`cut -d ":" -f2 <<< "${FULL_NAME_LINE}" | xargs`

rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

if [ $COMPACT_OUTPUT -eq 0 ]
then

	if [ $CREATE_USER -eq 0 ]
	then

		if [ $REPORT_USER -eq 0 ]
		then
			OutputMessage "USER OBJECT ACTION: ${FULL_NAME}"
		else
			OutputMessage "USER OBJECT REPORT: ${FULL_NAME}"
		fi

		OutputMessage "cn=${UserId},${Context}"
		OutputMessage "------------------"
	fi
fi

}

function ValidateParameter()
{
Parameter="$1"
ParameterLabel="$2"

[[ -z "$Parameter" ]] && ReportError "Enter a $ParameterLabel"

}

function VerifyUserObjectExistence()
{

UserIdIn="$1"
UserContextIn="$2"

OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"



{
ldapsearch -b ${UserContextIn} uid=${UserIdIn} -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} 1> $OUT_FILE_ONE
} 1> /dev/null 2> /dev/null

declare -i USER_EXISTS=`grep -c "numEntries: 1" ${OUT_FILE_ONE}`

rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

if [ $USER_EXISTS -gt 0 ]
then
	echo "0"
else
	echo "1"
fi

}


function UserReport()
{

if [ $USER_REPORT_ALREADY_RAN -gt 0 ]
then
	# Don't run this function more than once when a script runs
	return 1
fi


theGivenName=""
theSurname=""
theMobilePhone="[NONE]"
theTitle="[NONE]"
theDepartment="[NONE]"
theDescription="[NONE]"
theLocation="[NONE]"
theOfficePhone="[NONE]"
theMobilePhone="[NONE]"
theExpirationDate="[NONE]"
theFaxNumber="[NONE]"
theAccountStatus=""
theDnName=""
theUserDnName=""
theManager="[NONE]"
theFullName=""
theMiddleName=""
theGeneration=""


OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"
OUT_FILE_TWO="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.2.tmp.out"

OutputMessage "Context: $Context"
OutputMessage "UserId: $UserId"
if [[ -n "$Context" ]];
then
	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${UserId}'))' -b ${Context} 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null

declare -i NUMBER_OF_USER_RECORDS=`grep -c "numEntries" ${OUT_FILE_ONE}`

	if [ $NUMBER_OF_USER_RECORDS -lt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "(1) No User Exists With The UserId Of: ${UserId}"
	fi

declare -i RECORD_COUNT=`grep "numEntries" ${OUT_FILE_ONE} | sed 's/^[^:]*: //'`

	if [ $RECORD_COUNT -gt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "(2) More Than One User Exists With the Userid: ${UserId}"	
	fi
fi



if [[ -n "$Context" ]];
then
	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${UserId}'))' -b ${Context} 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null
else

	if [[ -n "$DefaultUserSearchContext" ]];
	then
		{
		ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${UserId}'))' -b ${DefaultUserSearchContext} 1> ${OUT_FILE_ONE}
		} 1> /dev/null 2> /dev/null

	else
		{
		ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${UserId}'))' 1> ${OUT_FILE_ONE}
		} 1> /dev/null 2> /dev/null
	fi
		{
		ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${UserId}'))' 1> ${OUT_FILE_ONE}
		} 1> /dev/null 2> /dev/null
fi



	declare -i NUMBER_OF_USER_RECORDS=`grep -c "numEntries" ${OUT_FILE_ONE}`

	if [ $NUMBER_OF_USER_RECORDS -lt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "A User Does Not Exist With The Userid: ${UserId}"
	fi

declare -i RECORD_COUNT=`grep "numEntries" ${OUT_FILE_ONE} | sed 's/^[^:]*: //'`

	if [ $RECORD_COUNT -gt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "(3) More Than One User Exists With The Userid: ${UserId}"	
	fi


USER_NAME=`grep "fullName:" ${OUT_FILE_ONE}`
theFullName=${USER_NAME#fullName: }

FIRST_NAME=`grep "givenName:" ${OUT_FILE_ONE}`
theFirstName=${FIRST_NAME#givenName: }

LAST_NAME=`grep "sn:" ${OUT_FILE_ONE}`
theLastName=${LAST_NAME#sn: }

MIDDLE_NAME=`grep "initials:" ${OUT_FILE_ONE}`
theMiddleName=${MIDDLE_NAME#initials: }

GENERATION_QUALIFIER=`grep "generationQualifier:" ${OUT_FILE_ONE}`
theGeneration=${GENERATION_QUALIFIER#generationQualifier: }

DN=`grep "dn:" ${OUT_FILE_ONE}`
theUserDnName=${DN#dn: }

TITLE=`grep "title:" ${OUT_FILE_ONE}`
declare -i TITLE_LENGTH=`echo "${TITLE}" | wc -c`
if [ $TITLE_LENGTH -gt 2 ]
then
	theTitle=${TITLE#title: }
fi

LOCATION=`grep "siteLocation:" ${OUT_FILE_ONE}`

declare -i LOCATION_LENGTH=`echo "${LOCATION}" | wc -c`
if [ $LOCATION_LENGTH -gt 2 ]
then
	theLocation=${LOCATION#siteLocation: }
fi

DESCRIPTION=`grep "description:" ${OUT_FILE_ONE}`
declare -i DESCRIPTION_LENGTH=`echo "${DESCRIPTION}" | wc -c`
if [ $DESCRIPTION_LENGTH -gt 2 ]
then
	theDescription=${DESCRIPTION#description: }
fi

DEPARTMENT=`grep "ou:" ${OUT_FILE_ONE}`
declare -i DEPARTMENT_LENGTH=`echo "${DEPARTMENT}" | wc -c`
if [ $DEPARTMENT_LENGTH -gt 2 ]
then
	theDepartment=${DEPARTMENT#ou: }
fi

OFFICE_PHONE=`grep "telephoneNumber:" ${OUT_FILE_ONE}`
declare -i OFFICE_PHONE_LENGTH=`echo "${OFFICE_PHONE}" | wc -c`
if [ $OFFICE_PHONE_LENGTH -gt 2 ]
then
	theOfficePhone=${OFFICE_PHONE#telephoneNumber: }
fi

MOBILE_PHONE=`grep "mobile:" ${OUT_FILE_ONE}`
declare -i MOBILE_PHONE_LENGTH=`echo "${MOBILE_PHONE}" | wc -c`
if [ $MOBILE_PHONE_LENGTH -gt 2 ]
then
	theMobilePhone=${MOBILE_PHONE#mobile: }
fi

FAX_NUMBER=`grep "facsimileTelephoneNumber:" ${OUT_FILE_ONE}`
declare -i FAX_NUMBER_LENGTH=`echo "${FAX_NUMBER}" | wc -c`
if [ $FAX_NUMBER_LENGTH -gt 2 ]
then
	theFaxNumber=${FAX_NUMBER#facsimileTelephoneNumber: }
fi

    OutputMessage "USER INFORMATION REPORT"
    OutputMessage "-----------------------"
    OutputMessage "NAME:  ${theFirstName} ${theLastName}"
    OutputMessage "FULL NAME:  ${theFirstName} ${theMiddleName} ${theLastName} ${theGeneration}"
    OutputMessage "FIRST NAME: ${theFirstName}"
    OutputMessage "LAST  NAME: ${theLastName}"
    OutputMessage "DISTINGUISHED NAME: ${theUserDnName}"
    MANAGER_DN=`grep "manager:" ${OUT_FILE_ONE}`
    declare -i MANAGER_DN_LENGTH=`echo "${MANAGER_DN}" | wc -c`
		if [ $MANAGER_DN_LENGTH -gt 5 ]
		then
			theManager=${MANAGER_DN#manager: }
			ManagerId_1=${theManager#cn=} # remove cn= 
			TheManagerId=${ManagerId_1%%,*}   # remove portion after the comma
			TheManagerContext=${theManager#*,}

			{
			ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${TheManagerId}'))' -b ${TheManagerContext} 1> ${OUT_FILE_TWO}
			} 1> /dev/null 2> /dev/null

			MANAGER_USER_NAME=`grep "fullName:" ${OUT_FILE_TWO}`
			ManagerFullName=${MANAGER_USER_NAME#fullName: }

			MANAGER_FIRST_NAME=`grep "givenName:" ${OUT_FILE_TWO}`
			ManagerFirstName=${MANAGER_FIRST_NAME#givenName: }

			MANAGER_LAST_NAME=`grep "sn:" ${OUT_FILE_TWO}`
			ManagerLastName=${MANAGER_LAST_NAME#sn: }

			MANAGER_MIDDLE_NAME=`grep "initials:" ${OUT_FILE_TWO}`
			ManagerMiddleName=${MANAGER_MIDDLE_NAME#initials: }

			MANAGER_GENERATION_QUALIFIER=`grep "generationQualifier:" ${OUT_FILE_TWO}`
			ManagerGeneration=${MANAGER_GENERATION_QUALIFIER#generationQualifier: }
	

    			OutputMessage "MANAGER NAME:  ${ManagerFirstName} ${ManagerLastName}"
    			OutputMessage "MANAGER FULL NAME:  ${ManagerFirstName} ${ManagerMiddleName} ${ManagerLastName} ${ManagerGeneration}"
    			OutputMessage "MANAGER DISTINGUISHED NAME: ${theManager}"
    			rm ${OUT_FILE_TWO} 1> /dev/null 2> /dev/null

fi
    OutputMessage "TITLE: ${theTitle}"
    OutputMessage "DESCRIPTION: ${theDescription}"
    OutputMessage "DEPARTMENT: ${theDepartment}"

    if [ $LOCATION_LENGTH -gt 2 ]
    then
    OutputMessage "LOCATION: ${theLocation}"
    fi

    OutputMessage "OFFICE PHONE: ${theOfficePhone}"
    OutputMessage "MOBILE PHONE: ${theMobilePhone}"


    if [ $FAX_NUMBER_LENGTH -gt 2 ]
    then
    	OutputMessage "FAX NUMBER: ${theFaxNumber}"
    fi

grep "groupMembership:" ${OUT_FILE_ONE} 1> ${OUT_FILE_TWO}

declare -i GROUP_MEMBERSHIP_EXISTS=`grep -c "groupMembership:" ${OUT_FILE_TWO}`

if [ $GROUP_MEMBERSHIP_EXISTS -gt 0 ]
then
    OutputMessage "GROUP MEMBERSHIPS"
    OutputMessage "-----------------"
	while IFS= read -r GROUP_LINE; do
	TheGroupNameIn=${GROUP_LINE#groupMembership: }
	OutputMessage "${TheGroupNameIn}"
	done < ${OUT_FILE_TWO}
    OutputMessage "-----------------"
fi

rm ${OUT_FILE_TWO} 1> /dev/null 2> /dev/null


declare -i LOGIN_DISABLED=`grep "loginDisabled:" ${OUT_FILE_ONE} | grep -c "TRUE"`

if [ $LOGIN_DISABLED -eq 0 ]
then
	OutputMessage "ACCOUNT ENABLED: YES"
else
	OutputMessage "ACCOUNT ENABLED: NO"
fi

declare -i ACCOUNT_LOCKED=`grep "lockedByIntruder:" ${OUT_FILE_ONE} | grep -c "TRUE"`

if [ $ACCOUNT_LOCKED -eq 0 ]
then
	OutputMessage "ACCOUNT LOCKED: NO"
else
	OutputMessage "ACCOUNT LOCKED: YES"
fi

declare -i LOGIN_EXPIRATION_EXISTS=`grep -c "loginExpirationTime:" ${OUT_FILE_ONE}`

if [ $LOGIN_EXPIRATION_EXISTS -gt 0 ]
then
	EXPIRATION_TIME=`grep "loginExpirationTime:" ${OUT_FILE_ONE}`
	theAccountExpirationTime=${EXPIRATION_TIME#loginExpirationTime:}

	YEAR="${theAccountExpirationTime:0:5}"
	YEAR=`echo "${YEAR}" | sed 's/^[[:space:]]*//g'`

	MONTH="${theAccountExpirationTime:5:2}"
	MONTH=$(echo "$MONTH" | sed 's/^0*//')

	DAY="${theAccountExpirationTime:7:2}"
	DAY=$(echo "$DAY" | sed 's/^0*//')

	OutputMessage "ACCOUNT EXPIRATION TIME: ${MONTH}/${DAY}/${YEAR}"
else
	OutputMessage "ACCOUNT EXPIRATION TIME: [NONE]"
fi

declare -i LOGIN_TIME_EXISTS=`grep -c "loginTime:" ${OUT_FILE_ONE}`

if [ $LOGIN_TIME_EXISTS -gt 0 ]
then
	LOGIN_TIME=`grep "loginTime:" ${OUT_FILE_ONE}`
	theAccountLoginTime=${LOGIN_TIME#loginTime:}

	YEAR="${theAccountLoginTime:0:5}"
	YEAR=`echo "${YEAR}" | sed 's/^[[:space:]]*//g'`

	MONTH="${theAccountLoginTime:5:2}"
	MONTH=$(echo "$MONTH" | sed 's/^0*//')

	DAY="${theAccountLoginTime:7:2}"
	DAY=$(echo "$DAY" | sed 's/^0*//')

	OutputMessage "LAST LOGIN TIME: ${MONTH}/${DAY}/${YEAR}"
else
	OutputMessage "LAST LOGIN TIME: [NONE]"
fi

USER_REPORT_ALREADY_RAN="1"

}

function VerifyUserExistsInGroup()
{

GroupNameIn="$1"
GroupContextIn="$2"
UserIdIn="$3"
UserContextIn="$4"

OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"

{
ldapsearch -b ${GroupContextIn} -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=group)(cn='${GroupNameIn}'))' member 1> $OUT_FILE_ONE
} 1> /dev/null 2> /dev/null

declare -i GROUP_EXISTS=`grep -ic "cn=${GroupNameIn},${GroupContextIn}" ${OUT_FILE_ONE}`

if [ $GROUP_EXISTS -eq 0 ]
then
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	echo "2"
	return
fi

declare -i USER_EXISTS=`grep -ic "cn=${UserIdIn},${UserContextIn}" ${OUT_FILE_ONE}`

if [ $USER_EXISTS -eq 0 ]
then
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	echo "1"
	return
else
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	echo "0"
	return
fi
}


function DetermineExcludeGroupConflict()
{

GroupNameIn="$1"
GroupContextIn="$2"

if [ $IGNORE_EXCLUDE_GROUP -gt 0 ]
then
	return
fi

declare -i EDIR_EXCLUDE_GROUP_LENGTH=`echo "${EDIR_EXCLUDE_GROUP}" | wc -c`

if [ $EDIR_EXCLUDE_GROUP_LENGTH -lt 8 ]
then 
	return
fi

GroupName_1=${EDIR_EXCLUDE_GROUP#cn=} # remove cn= 
ExcludeGroupName=${GroupName_1%%,*}  # remove portion after the comma
ExcludeGroupContext=${EDIR_EXCLUDE_GROUP#*,} # Get the Group Context

ExcludeGroupDN="cn=${ExcludeGroupName},${ExcludeGroupContext}"

str1="cn=${GroupNameIn},${GroupContextIn}"
str2="${ExcludeGroupDN}"

shopt -s nocasematch
case "$str1" in
	$str2 )
		OutputMessage ""
		OutputMessage "--------------------------------------------------------------------------------"
		OutputMessage "Insufficent Rights to Administer Group: ${ExcludeGroupDN}"
		OutputMessage  "-------------------------------------------------------------------------------"
		ReportError "The Administrator Does Not Allow Changes to This Group"
	;;

esac


}

function VerifyGroupObjectExistence()
{

GroupNameIn="$1"
GroupContextIn="$2"

OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"

{
ldapsearch -b ${GroupContextIn} -s one -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=group)(cn='${GroupNameIn}'))' member 1> $OUT_FILE_ONE
} 1> /dev/null 2> /dev/null

declare -i THIS_GROUP_EXISTS=`grep -ic "cn=${GroupNameIn},${GroupContextIn}" ${OUT_FILE_ONE}`

rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

if [ $THIS_GROUP_EXISTS -gt 0 ]
then
	echo "0"
else
	echo "1"
fi
}

function SimpleUserReport()
{

theUserIdIn="$1"
theUserContextIn="$2"

theGivenName=""
theSurname=""
theDnName=""
theUserDnName=""
theFullName=""
theMiddleName=""
theGeneration=""


OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"
OUT_FILE_TWO="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.2.tmp.out"
 

{
ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${theUserIdIn}'))' -b ${theUserContextIn} 1> ${OUT_FILE_ONE}
} 1> /dev/null 2> /dev/null

declare -i NUMBER_OF_USER_RECORDS=`grep -c "numEntries" ${OUT_FILE_ONE}`

	if [ $NUMBER_OF_USER_RECORDS -lt 1 ]
	then 
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	ReportError "(4) More Than One User Exists With the Userid: ${UserId}"
	fi

declare -i RECORD_COUNT=`grep "numEntries" ${OUT_FILE_ONE} | sed 's/^[^:]*: //'`

	if [ $RECORD_COUNT -gt 1 ]
	then 
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	ReportError "(5) More Than One User Exists With the Userid: ${UserId}"	
	fi


declare -i NUMBER_OF_USER_RECORDS=`grep -c "numEntries" ${OUT_FILE_ONE}`

if [ $NUMBER_OF_USER_RECORDS -lt 1 ]
then 

	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	ReportError "A User Does Not Exist With The Userid: ${UserId}"
fi

declare -i RECORD_COUNT=`grep "numEntries" ${OUT_FILE_ONE} | sed 's/^[^:]*: //'`

if [ $RECORD_COUNT -gt 1 ]
then 
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	ReportError "(6) More Than One User Exists With The Userid: ${UserId}"	
fi


USER_NAME=`grep "fullName:" ${OUT_FILE_ONE}`
theFullName=${USER_NAME#fullName: }

FIRST_NAME=`grep "givenName:" ${OUT_FILE_ONE}`
theFirstName=${FIRST_NAME#givenName: }

LAST_NAME=`grep "sn:" ${OUT_FILE_ONE}`
theLastName=${LAST_NAME#sn: }

MIDDLE_NAME=`grep "initials:" ${OUT_FILE_ONE}`
theMiddleName=${MIDDLE_NAME#initials: }

GENERATION_QUALIFIER=`grep "generationQualifier:" ${OUT_FILE_ONE}`
theGeneration=${GENERATION_QUALIFIER#generationQualifier: }

DN=`grep "dn:" ${OUT_FILE_ONE}`
theUserDnName=${DN#dn: }

    OutputMessage "MEMBER INFORMATION REPORT"
    OutputMessage "-------------------------"
    OutputMessage "FULL NAME:  ${theFirstName} ${theMiddleName} ${theLastName} ${theGeneration}"
    OutputMessage "DISTINGUISHED NAME: ${theUserDnName}"
    OutputMessage "-------------------------"




}

function ListAllUsersInTree()
{
	# LDAP Search from base of tree

OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"

{
ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn=*))' | grep -vE "fullName:" | grep -e "dn:" | sed 's/.*dn: //' 1> ${OUT_FILE_ONE}
} 1> /dev/null 2> /dev/null

declare -i EXIT_CODE=`echo $?`

cat ${OUT_FILE_ONE}

rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

exit ${EXIT_CODE}
}

function ListUsers()
{
declare -i CONTEXT_SPECIFIED=0
declare theContext=""


if [ $LIST_USERS_CONTEXT_SET -eq 0 ]
then

	if [[ -n "$Context" ]];
	then
		CONTEXT_SPECIFIED=1
		theContext="${Context}"
	fi

	if [ $CONTEXT_SPECIFIED -eq 0 ]
	then
		if [[ -n "$DefaultUserSearchContext" ]];
		then
			CONTEXT_SPECIFIED=1
			theContext="${DefaultUserSearchContext}"
		fi
	fi
else
	theContext="${ListUsersContext}"
	CONTEXT_SPECIFIED=1
fi

OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"

if [ $CONTEXT_SPECIFIED -gt 0 ]
then
	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} -b ${theContext} '(&(objectClass=user)(cn=*))' | grep -e "fullName:" -e "dn:" | sed 's/fullName://' 1> ${OUT_FILE_ONE} 
	} 1> /dev/null 2> /dev/null
else
	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn=*))' | grep -e "fullName:" -e "dn:" | sed 's/fullName://'| sed 's/fullName://' | sed 's/dn://' 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null
fi

declare -i OUT_FILE_SIZE=`cat ${OUT_FILE_ONE} | wc -l`

if [ $OUT_FILE_SIZE -gt 1 ]
then
    OutputMessage "USERS IN ORGANIZATION REPORT"
    OutputMessage "----------------------------"
    cat ${OUT_FILE_ONE} 2> /dev/null
    OutputMessage "----------------------------"
else
    OutputMessage "USERS IN ORGANIZATION REPORT"
    OutputMessage "------------------------------"
    OutputMessage "Users In Organization [ NONE ]"
    OutputMessage "------------------------------"

fi

rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

}


function GroupReport()
{


if [[ -n "$GroupName" ]];
then

declare -i GroupContextLength=`echo "${GroupContext}" | wc -c`

	if [ ${GroupContextLength} -lt 5 ]
	then
		return 1
	fi


fi


local GROUP_EXISTS=$(VerifyGroupObjectExistence "$GroupName" "$GroupContext")

if [ $GROUP_EXISTS -eq 1 ]
then
	OutputMessage "Error Group Does Not Exist: cn=${GroupName},${GroupContext}"
	return 1
fi

DetermineExcludeGroupConflict "${GroupName}" "${GroupContext}"


OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"

	{
	ldapsearch -b "${GroupContext}" cn=${GroupName} -Filter:objectclass=group -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} 1> $OUT_FILE_ONE
	} 1> /dev/null 2> /dev/null


declare -i GROUP_EXISTS=`grep -c "numEntries: 1" ${OUT_FILE_ONE}`

if [ $GROUP_EXISTS -eq 0 ]
then
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	ReportError "Group Does Not Exist"
fi

OUT_FILE_TWO="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.2.tmp.out"

grep "member:" ${OUT_FILE_ONE} 1> ${OUT_FILE_TWO}

declare -i GROUP_MEMBERSHIP_EXISTS=`grep -c "member:" ${OUT_FILE_TWO}`

if [ $GROUP_MEMBERSHIP_EXISTS -gt 0 ]
then
    OutputMessage "GROUP MEMBERS REPORT"
    OutputMessage "--------------------"
    OutputMessage ""
	while IFS= read -r MEMBER_LINE; do
	THE_MEMBER=${MEMBER_LINE#member: }
	UserId_1=${THE_MEMBER#cn=} # remove cn= 
	theUserId=${UserId_1%%,*}   # remove portion after the comma
	theContext=${MEMBER_LINE#*,}
	SimpleUserReport "${theUserId}" "${theContext}"
	done < ${OUT_FILE_TWO}
	OutputMessage ""
fi

rm ${OUT_FILE_TWO} 1> /dev/null 2> /dev/null


rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

}


function AddUserToGroups()
{

GROUP_MODIFY_COMPLETE=1

# Semicolons should be the delimeters in the array
IFS=";" read -a GROUP_ARRAY <<< $GroupDNList

for GROUP in "${GROUP_ARRAY[@]}"
do
	GroupName_1=${GROUP#cn=} # remove cn= 
     	GroupName=${GroupName_1%%,*}  # remove portion after the comma
	GroupContext=${GROUP#*,} # get the Group Context

	DetermineExcludeGroupConflict "${GroupName}" "${GroupContext}"

		local GROUP_EXISTS=$(VerifyGroupObjectExistence "$GroupName" "$GroupContext")

	if [ $GROUP_EXISTS -eq 1 ]
	then
		OutputMessage "Error Group Does Not Exist: cn=${GroupName},${GroupContext}"
		continue
	fi

	local GROUP_EXISTS=$(VerifyGroupObjectExistence "$GroupName" "$GroupContext")


	if [ $GROUP_EXISTS -eq 1 ]
	then
		OutputMessage "Error Group Does Not Exist: cn=${GroupName},${GroupContext}"
		continue
	fi

	local USER_EXISTS=$(VerifyUserObjectExistence "$UserId" "$Context")

	if [ $USER_EXISTS -eq 1 ]
	then
		ReportError "User Does Not Exist: cn=${UserId},${Context}"
		return 1
	fi

	local USER_EXISTS_IN_GROUP_ALREADY=$(VerifyUserExistsInGroup "$GroupName" "$GroupContext" "${UserId}" "${Context}")

	if [ $USER_EXISTS_IN_GROUP_ALREADY -eq 0 ]
	then
		OutputMessage ""
		OutputMessage "User Already Exists In Group"
		OutputMessage "User: cn=${UserId},${Context}"
		OutputMessage "Group: cn=${GroupName},${GroupContext}"
		OutputMessage ""
		continue
	fi


	TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.tmp.ldif"

	echo "dn: cn=${GroupName},${GroupContext}" 1> ${TEMP_FILE_ONE}
	echo "changetype: modify" 1>> ${TEMP_FILE_ONE}
	echo "add: equivalentToMe" 1>> ${TEMP_FILE_ONE}
	echo "equivalentToMe: cn=${UserId},${Context}" 1>> ${TEMP_FILE_ONE}
	echo "-" 1>> ${TEMP_FILE_ONE}
	echo "add: member" 1>> ${TEMP_FILE_ONE}
	echo "member: cn=${UserId},${Context}" 1>> ${TEMP_FILE_ONE}
	echo "" 1>> ${TEMP_FILE_ONE}
	echo "dn: cn=${UserId},${Context}" 1>> ${TEMP_FILE_ONE}
	echo "changetype: modify" 1>> ${TEMP_FILE_ONE}
	echo "add: groupMembership" 1>> ${TEMP_FILE_ONE}
	echo "groupMembership: cn=${GroupName},${GroupContext}" 1>> ${TEMP_FILE_ONE}

	OutputMessage "Adding User To Group: cn=${GroupName},${GroupContext}"

	{
	ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE}
	} 1> /dev/null 2> /dev/null

	declare -i EXIT_STATUS=`echo $?`

	rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

	if [ $EXIT_STATUS -ne 0 ]
	then
	
		OutputMessage ""
		OutputMessage "User NOT Added to Group"
		OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"
		{
		ldapsearch -b "$GroupContext" cn=${GroupName} -Filter:objectclass=group -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} 1> $OUT_FILE_ONE
		} 1> /dev/null 2> /dev/null


		declare -i GROUP_EXISTS=`grep -c "numEntries: 1" ${OUT_FILE_ONE}`

		if [ $GROUP_EXISTS -eq 0 ]
		then
			OutputMessage "Group Does Not Exist"
			rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	
		fi

	declare -i USER_EXISTS=`grep -c "cn=${UserId},${Context}" ${OUT_FILE_ONE}`

		if [ $USER_EXISTS -eq 0 ]
		then
			OutputMessage "User Already Exists In This Group"
			OutputMessage ""
			rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		fi

	fi

done


}

function CreateGroup()
{

local GROUP_EXISTS=$(VerifyGroupObjectExistence "$GroupName" "$GroupContext")

if [ $GROUP_EXISTS -eq 0 ]
then
	OutputMessage "Error Group Already Exists: cn=${GroupName},${GroupContext}"
	return 1
fi


TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.tmp.ldif"
TheGroupContext=""

if [[ -n "$GroupContext" ]];
then
	TheGroupContext=${GroupContext}
else
	if [[ -n "$DefaultGroupContext" ]];
	then
		TheGroupContext=${DefaultGroupContext}
	else
		ReportError "The Group Context Is Not Specified: cn=${GroupName}"
	fi

fi



echo "dn: cn=${GroupName},${TheGroupContext}" 1> ${TEMP_FILE_ONE}
echo "changetype: add" 1>> ${TEMP_FILE_ONE}
echo "cn: ${GroupName}" 1>> ${TEMP_FILE_ONE}
echo "objectclass: Group" 1>> ${TEMP_FILE_ONE}

OutputMessage "Creating The Group: cn=${GroupName},${TheGroupContext}"

	{
	ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE}
	} 1> /dev/null 2> /dev/null

declare -i EXIT_STATUS=`echo $?`

rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

if [ $EXIT_STATUS -eq 0 ]
then
	OutputMessage "Group Created"
else
	OutputMessage ""
	OutputMessage "Group NOT Created"
	OutputMessage ""
return 1
fi

OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"

	{
	ldapsearch -b "$TheGroupContext" cn=${GroupName} -Filter:objectclass=group -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} 1> $OUT_FILE_ONE
	} 1> /dev/null 2> /dev/null


declare -i GROUP_EXISTS=`grep -c "numEntries: 1" ${OUT_FILE_ONE}`

	if [ $GROUP_EXISTS -eq 0 ]
	then
		ErrorMessage "Group Does Not Exist"
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		return 1
	else
	OutputMessage "Group Created"
	fi

rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

}



function AddUserToGroup()
{

GROUP_MODIFY_COMPLETE=1
if [[ -n "$GroupDNList" ]];
then
	AddUserToGroups
	return 0
else
local GROUP_EXISTS=$(VerifyGroupObjectExistence "$GroupName" "$GroupContext")
fi


if [ $GROUP_EXISTS -eq 1 ]
then
	OutputMessage "Error Group Does Not Exist: cn=${GroupName},${GroupContext}"
	return 1
fi



DetermineExcludeGroupConflict "${GroupName}" "${GroupContext}"

local USER_EXISTS=$(VerifyUserObjectExistence "$UserId" "$Context")

if [ $USER_EXISTS -eq 1 ]
then
	ReportError "User Does Not Exist: cn=${UserId},${Context}"
fi

local USER_EXISTS_IN_GROUP_ALREADY=$(VerifyUserExistsInGroup "$GroupName" "$GroupContext" "${UserId}" "${Context}")

if [ $USER_EXISTS_IN_GROUP_ALREADY -eq 0 ]
then
	OutputMessage ""
	OutputMessage "User Already Exists In Group"
	OutputMessage "User: cn=${UserId},${Context}"
	OutputMessage "Group: cn=${GroupName},${GroupContext}"
	OutputMessage ""
	return 0
fi

TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.tmp.ldif"

echo "dn: cn=${GroupName},${GroupContext}" 1> ${TEMP_FILE_ONE}
echo "changetype: modify" 1>> ${TEMP_FILE_ONE}
echo "add: equivalentToMe" 1>> ${TEMP_FILE_ONE}
echo "equivalentToMe: cn=${UserId},${Context}" 1>> ${TEMP_FILE_ONE}
echo "-" 1>> ${TEMP_FILE_ONE}
echo "add: member" 1>> ${TEMP_FILE_ONE}
echo "member: cn=${UserId},${Context}" 1>> ${TEMP_FILE_ONE}
echo "" 1>> ${TEMP_FILE_ONE}
echo "dn: cn=${UserId},${Context}" 1>> ${TEMP_FILE_ONE}
echo "changetype: modify" 1>> ${TEMP_FILE_ONE}
echo "add: groupMembership" 1>> ${TEMP_FILE_ONE}
echo "groupMembership: cn=${GroupName},${GroupContext}" 1>> ${TEMP_FILE_ONE}



OutputMessage "Adding User To Group: cn=${GroupName},${GroupContext}"


{
ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE}
} 1> /dev/null 2> /dev/null

declare -i EXIT_STATUS=`echo $?`

rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null


if [ $EXIT_STATUS -eq 0 ]
then
	OutputMessage "User Added To Group"
else
	OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"
	{
	ldapsearch -b "$GroupContext" cn=${GroupName} -Filter:objectclass=group -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} 1> $OUT_FILE_ONE
	} 1> /dev/null 2> /dev/null


declare -i GROUP_EXISTS=`grep -c "numEntries: 1" ${OUT_FILE_ONE}`

	if [ $GROUP_EXISTS -eq 0 ]
	then
	OutputMessage "Group Does Not Exist"
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	return 1
	fi


declare -i USER_EXISTS=`grep -c "cn=${UserId},${Context}" ${OUT_FILE_ONE}`

	if [ $USER_EXISTS -gt 0 ]
	then
		OutputMessage "User Added To Group"
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

	else
		OutputMessage ""
		OutputMessage "User NOT Added to Group"
	       return 1
	fi

fi


}

function RemoveUserFromGroups()
{


GROUP_MODIFY_COMPLETE=1
IFS=";" read -a GROUP_ARRAY <<< $GroupDNList

for GROUP in "${GROUP_ARRAY[@]}"
do
	GroupName_1=${GROUP#cn=} # remove cn= 
     	GroupName=${GroupName_1%%,*}  # remove portion after the comma
	GroupContext=${GROUP#*,} # Get the Group Context

		local GROUP_EXISTS=$(VerifyGroupObjectExistence "$GroupName" "$GroupContext")

		if [ $GROUP_EXISTS -eq 1 ]
			then
			OutputMessage "Error Group Does Not Exist: cn=${GroupName},${GroupContext}"
			continue
		fi

	DetermineExcludeGroupConflict "${GroupName}" "${GroupContext}"

	local USER_EXISTS=$(VerifyUserObjectExistence "$UserId" "$Context")

	if [ $USER_EXISTS -eq 1 ]
	then
		ReportError "User Does Not Exist: cn=${UserId},${Context}"
	fi

	local USER_EXISTS_IN_GROUP_ALREADY=$(VerifyUserExistsInGroup "$GroupName" "$GroupContext" "${UserId}" "${Context}")

	if [ $USER_EXISTS_IN_GROUP_ALREADY -eq 1 ]
	then
		OutputMessage "User Does NOT Exist In Group"
		OutputMessage "User: cn=${UserId},${Context}"
		OutputMessage "Group: cn=${GroupName},${GroupContext}"
		continue
	fi

	TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.tmp.ldif"


	echo "dn: cn=${GroupName},${GroupContext}" 1> ${TEMP_FILE_ONE}
	echo "changetype: modify" 1>> ${TEMP_FILE_ONE}
	echo "delete: equivalentToMe" 1>> ${TEMP_FILE_ONE}
	echo "equivalentToMe: cn=${UserId},${Context}" 1>> ${TEMP_FILE_ONE}
	echo "-" 1>> ${TEMP_FILE_ONE}
	echo "delete: member" 1>> ${TEMP_FILE_ONE}
	echo "member: cn=${UserId},${Context}" 1>> ${TEMP_FILE_ONE}
	
	OutputMessage ""
	OutputMessage "Removing  User: cn=${UserId},${Context}"
	OutputMessage "From The Group: cn=${GroupName},${GroupContext}"


	{
	ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE}
	} 1> /dev/null 2> /dev/null

	declare -i EXIT_STATUS=`echo $?`

	rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

	if [ $EXIT_STATUS -ne 0 ]
	then
		OutputMessage ""
		OutputMessage "User NOT Removed From Group"
		continue
	fi

	echo "dn: cn=${UserId},${Context}" 1>> ${TEMP_FILE_ONE}
	echo "delete: groupMembership" 1>> ${TEMP_FILE_ONE}
	echo "groupMembership: cn=${GroupName},${GroupContext}" 1>> ${TEMP_FILE_ONE}

	{
	ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE}
	} 1> /dev/null 2> /dev/null


	declare -i EXIT_STATUS=`echo $?`

	if [ $EXIT_STATUS -eq 0 ]
	then
	OutputMessage "User Membership From Group Removed"
	else
	OutputMessage ""
	OutputMessage "User Membership From Group NOT Removed"
	continue
	fi



	OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"
	{
	ldapsearch -b "$GroupContext" cn=${GroupName} -Filter:objectclass=group -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} 1> $OUT_FILE_ONE
	} 1> /dev/null 2> /dev/null


	declare -i GROUP_EXISTS=`grep -c "numEntries: 1" ${OUT_FILE_ONE}`

		if [ $GROUP_EXISTS -eq 0 ]
		then
			OutputMessage "Group Does Not Exist"
			rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
			continue
		fi

	declare -i USER_EXISTS=`grep -c "cn=${UserId},${Context}" ${OUT_FILE_ONE}`
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

		if [ $USER_EXISTS -eq 0 ]
		then
			OutputMessage "Confirmed User Removed From Group"
			OutputMessage ""
		fi


done

}


function RemoveUserFromGroup()
{

GROUP_MODIFY_COMPLETE=1
if [[ -n "$GroupDNList" ]];
then
RemoveUserFromGroups
return 0
else

local GROUP_EXISTS=$(VerifyGroupObjectExistence "$GroupName" "$GroupContext")

fi
if [ $GROUP_EXISTS -eq 1 ]
then
	OutputMessage "Error Group Does Not Exist: cn=${GroupName},${GroupContext}"
	return 1
fi

DetermineExcludeGroupConflict "${GroupName}" "${GroupContext}"

local USER_EXISTS=$(VerifyUserObjectExistence "$UserId" "$Context")

if [ $USER_EXISTS -eq 1 ]
then
	ReportError "User Does Not Exist: cn=${UserId},${Context}"
fi

local USER_EXISTS_IN_GROUP_ALREADY=$(VerifyUserExistsInGroup "$GroupName" "$GroupContext" "${UserId}" "${Context}")

if [ $USER_EXISTS_IN_GROUP_ALREADY -eq 2 ]
then
	OutputMessage "Cannot Locate Group"
	OutputMessage "Group: cn=${GroupName},${GroupContext}"
	return 1
fi

if [ $USER_EXISTS_IN_GROUP_ALREADY -eq 1 ]
then
	OutputMessage "User Does Not Exist In Group"
	OutputMessage "User: cn=${UserId},${Context}"
	OutputMessage "Group: cn=${GroupName},${GroupContext}"
	return 1
fi


TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.tmp.ldif"

echo "dn: cn=${GroupName},${GroupContext}" 1> ${TEMP_FILE_ONE}
echo "changetype: modify" 1>> ${TEMP_FILE_ONE}
echo "delete: equivalentToMe" 1>> ${TEMP_FILE_ONE}
echo "equivalentToMe: cn=${UserId},${Context}" 1>> ${TEMP_FILE_ONE}
echo "-" 1>> ${TEMP_FILE_ONE}
echo "delete: member" 1>> ${TEMP_FILE_ONE}
echo "member: cn=${UserId},${Context}" 1>> ${TEMP_FILE_ONE}

OutputMessage ""
OutputMessage "Removing  User: cn=${UserId},${Context}"
OutputMessage "From The Group: cn=${GroupName},${GroupContext}"

{
ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE}
} 1> /dev/null 2> /dev/null

declare -i EXIT_STATUS=`echo $?`

if [ $EXIT_STATUS -ne 0 ]
then
OutputMessage ""
OutputMessage "User NOT Removed From Group"
return 1
fi

rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null
echo "dn: cn=${UserId},${Context}" 1>> ${TEMP_FILE_ONE}
echo "delete: groupMembership" 1>> ${TEMP_FILE_ONE}
echo "groupMembership: cn=${GroupName},${GroupContext}" 1>> ${TEMP_FILE_ONE}

{
ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE}
} 1> /dev/null 2> /dev/null


if [ $EXIT_STATUS -eq 0 ]
then
OutputMessage "User Membership From Group Removed"
else
OutputMessage ""
OutputMessage "User Membership From Group NOT Removed"
return 1
fi

rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"

{
ldapsearch -b "$GroupContext" cn=${GroupName} -Filter:objectclass=group -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} 1> $OUT_FILE_ONE
} 1> /dev/null 2> /dev/null


declare -i GROUP_EXISTS=`grep -c "numEntries: 1" ${OUT_FILE_ONE}`

	if [ $GROUP_EXISTS -eq 0 ]
	then
	OutputMessage "Group Does Not Exist"
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	return 1
	fi

declare -i USER_EXISTS=`grep -c "cn=${UserId},${Context}" ${OUT_FILE_ONE}`
rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

	if [ $USER_EXISTS -gt 0 ]
	then
	OutputMessage "Confirmed User Exists In Group"
	OutputMessage ""
	return 0
	fi



}


function LDAP_ATTRIBUTE_MODIFY_LIST()
{
LDAP_ATTRIBUTE="$1"
LDAP_VALUE="$2"
FRIENDLY_NAME=$3

declare -i ATTRIBUTE_LENGTH=`echo ${LDAP_VALUE} | wc -m`

if [ $ATTRIBUTE_LENGTH -lt 2 ]
then
	return 1
fi


GLOBAL_LDAP_TEMP_FILE_ONE_EXISTS=`test -f ${GLOBAL_LDAP_TEMP_FILE_ONE} && echo "0" || echo "1"`

if [ $GLOBAL_LDAP_TEMP_FILE_ONE_EXISTS -ne 0 ]
then
	MODIFY_USER_ATTRIBUTE=1
	echo "dn: cn=${UserId},${Context}" 1> ${GLOBAL_LDAP_TEMP_FILE_ONE}
	echo "changetype: Modify" 1>> ${GLOBAL_LDAP_TEMP_FILE_ONE}
else

	GLOBAL_LDAP_TEMP_FILE_REPLACE_VALUE=`grep -c "replace:" ${GLOBAL_LDAP_TEMP_FILE_ONE}`

	if [ $GLOBAL_LDAP_TEMP_FILE_REPLACE_VALUE -gt 0 ]
	then
		echo "-" 1>> ${GLOBAL_LDAP_TEMP_FILE_ONE}
	fi

fi


echo "replace: ${LDAP_ATTRIBUTE}" 1>> ${GLOBAL_LDAP_TEMP_FILE_ONE}
echo "${LDAP_ATTRIBUTE}: ${LDAP_VALUE}" 1>> ${GLOBAL_LDAP_TEMP_FILE_ONE}

OutputMessage "Change ${FRIENDLY_NAME} To: ${LDAP_VALUE}"

}


function MoveUser()
{

ValidateParameter "$Context" "Context | Example: -Context \"users.finance.cimitra\""
ValidateParameter "$UserId" "Context | Example: -UserId \"bsmith\""
ValidateParameter "$NewContext" "New Context | Example: -NewContext \"users.support.cimitra\""

OutputMessage ""
OutputMessage "Moving User"
OutputMessage "cn=${UserId},${Context}"


TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.ldif"

echo "dn: cn=${UserId},${Context}" 1> ${TEMP_FILE_ONE}
echo "changetype: moddn" 1>> ${TEMP_FILE_ONE}
echo "newrdn: cn=${UserId}"  1>> ${TEMP_FILE_ONE}
echo "deleteoldrdn: 1"  1>> ${TEMP_FILE_ONE}
echo "newsuperior: ${NewContext}"  1>> ${TEMP_FILE_ONE}

{
ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE}
} 1> /dev/null 2> /dev/null

declare -i EXIT_STATUS=`echo $?`

rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

if [ $EXIT_STATUS -eq 0 ]
then
	OutputMessage "NEW DISTINGUISHED NAME: cn=${UserId},${NewContext}"
	OutputMessage "Move User Complete"
	Context="${NewContext}"
	return 0
else
	OutputMessage ""
	OutputMessage "Account cn=${UserId},${Context} NOT Moved"
	OutputMessage ""
	return 1
fi

}

function CreateUserGroupActionTest()
{

if [[ -n "$GroupName" ]];
then

	if [[ -n "$GroupContext" ]];
	then
		ADD_CREATED_USER_TO_GROUP="1"
		return
	fi
fi


if [[ -n "$GroupDNList" ]];
then
	ADD_CREATED_USER_TO_GROUP="1"
fi

}

function DetermineUserToGroupAction()
{


if [ $MODIFY_GROUP -eq 0 ]
then
	return
fi

if [ $GROUP_MODIFY_COMPLETE -eq 1 ]
then
	return
fi

if [[ -n "$GroupName" ]];
then

	if [[ -n "$GroupContext" ]];
	then
	
		if [ $REMOVE_USER_FROM_GROUP -gt 0 ]
		then
			RemoveUserFromGroup
		fi

	
		if [ $ADD_USER_TO_GROUP -gt 0 ]
		then
			AddUserToGroup
		fi
		
	fi
fi


if [[ -n "$GroupDNList" ]];
then
	
	if [ $REMOVE_USER_FROM_GROUP -gt 0 ]
	then
		RemoveUserFromGroups
	fi

	

	if [ $ADD_USER_TO_GROUP -gt 0 ]
	then
		AddUserToGroups
	fi
		
fi

}

function SearchForManagerByFirstAndLastName()
{


OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"

if [[ -n "$ManagerContext" ]];
then
	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(fullName='${ManagerFirstName}' '${ManagerLastName}'))' -b ${ManagerContext} 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null

declare -i NUMBER_OF_USER_RECORDS=`grep -c "numEntries" ${OUT_FILE_ONE}`

	if [ $NUMBER_OF_USER_RECORDS -lt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "A User Does Not Exist With the Name: ${ManagerFirstName} ${ManagerLastName}"
	fi

	declare -i RECORD_COUNT=`grep "numEntries" ${OUT_FILE_ONE} | sed 's/^[^:]*: //'`

	if [ $RECORD_COUNT -gt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "$FUNCNAME: More Than One User Exists With The Name: ${ManagerFirstName} ${ManagerLastName}"
	fi


	USER_DN=`grep "dn:" ${OUT_FILE_ONE}`

	UserId_1=${USER_DN#dn: } # remove dn: 
	UserId_2=${UserId_1#cn=} # remove cn= 
	ManagerId=${UserId_2%%,*}  # remove portion after the comma
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	return 0

fi

if [[ -n "$DefaultManagerSearchContext" ]];
then
	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(fullName='${ManagerFirstName}' '${ManagerLastName}'))' -b ${DefaultManagerSearchContext} 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null
else

	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(fullName='${ManagerFirstName}' '${ManagerLastName}'))' 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null
fi


declare -i NUMBER_OF_USER_RECORDS=`grep -c "numEntries" ${OUT_FILE_ONE}`

	if [ $NUMBER_OF_USER_RECORDS -lt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "A User Does Not Exist With the Name: ${ManagerFirstName} ${ManagerLastName}"
	fi

	declare -i RECORD_COUNT=`grep "numEntries" ${OUT_FILE_ONE} | sed 's/^[^:]*: //'`

	if [ $RECORD_COUNT -gt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "$FUNCNAME: More Than One User Exists With The Name: ${ManagerFirstName} ${ManagerLastName}"
	fi

	


	MANAGER_DN=`grep "dn:" ${OUT_FILE_ONE}`
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

	ManagerId_1=${MANAGER_DN#dn: } # remove dn: 
	ManagerId_2=${ManagerId_1#cn=} # remove cn= 
	ManagerId=${ManagerId_2%%,*}   # remove portion after the comma
	ManagerContext=${MANAGER_DN#*,}




return 0

}

function SearchForManagerByUserId()
{

declare -i MANAGER_ID_LENGTH=`echo "${ManagerId}" | wc -c`

if [ $MANAGER_ID_LENGTH -lt 2 ]
then
	return 1
fi

OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"
 
if [[ -n "$ManagerContext" ]];
then
	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${ManagerId}'))' -b ${ManagerContext} 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null

declare -i NUMBER_OF_USER_RECORDS=`grep -c "numEntries" ${OUT_FILE_ONE}`

	if [ $NUMBER_OF_USER_RECORDS -lt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "(7) More Than One User Exists With the Userid: ${UserId}"
	fi

declare -i RECORD_COUNT=`grep "numEntries" ${OUT_FILE_ONE} | sed 's/^[^:]*: //'`

	if [ $RECORD_COUNT -gt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "(8) More Than One User Exists With the Userid: ${UserId}"	
	fi


	USER_DN=`grep "dn:" ${OUT_FILE_ONE}`

	UserId_1=${USER_DN#dn: } # remove dn: 
	UserId_2=${UserId_1#cn=} # remove cn= 
	ManagerId=${UserId_2%%,*}  # remove portion after the comma
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	return 0

fi



if [[ -n "$ManagerContext" ]];
then
	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${ManagerId}'))' -b ${ManagerContext} 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null
else

	if [[ -n "$DefaultUserSearchContext" ]];
	then

		{
		ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} -b ${DefaultUserSearchContext} '(&(objectClass=user)(cn='${ManagerId}'))' 1> ${OUT_FILE_ONE}
		} 1> /dev/null 2> /dev/null

	else
		{
		ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${ManagerId}'))' 1> ${OUT_FILE_ONE}
		} 1> /dev/null 2> /dev/null
	fi
fi



	declare -i NUMBER_OF_USER_RECORDS=`grep -c "numEntries" ${OUT_FILE_ONE}`

	if [ $NUMBER_OF_USER_RECORDS -lt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "A User Does Not Exist With The Userid: ${ManagerId}"
	fi

	declare -i RECORD_COUNT=`grep "numEntries" ${OUT_FILE_ONE} | sed 's/^[^:]*: //'`

	if [ $RECORD_COUNT -gt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "(9) More Than One User Exists With The Userid: ${ManagerId}"	
	fi

	USER_DN=`grep "dn:" ${OUT_FILE_ONE}`


	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

	UserId_1=${USER_DN#dn: } # remove dn: 
	UserId_2=${UserId_1#cn=} # remove cn= 

	ManagerId=${UserId_2%%,*}   # remove portion after the comma

	ManagerContext=${USER_DN#*,}



return 0

}



function FindManagerDN()
{

if [ $DisableUserSearch -gt 0 ]
then
return
fi

if [[ -z "$ManagerId" ]];then

	if [[ -n "$ManagerFirstName" ]];
	then


		if [[ -n "$ManagerLastName" ]];
		then
			SearchForManagerByFirstAndLastName
		fi

	fi

fi

if [ $MANAGER_FULL_NAME_OR_USERID -gt 0 ]
then
	SearchForManagerByUserId
fi


}

function SearchForUserByUserId()
{

USERID_LENGTH=`echo "${UserID}" | wc -c`

if [ ${USERID_LENGTH} -lt 2 ]
then
	return 1
fi

OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"
 
if [[ -n "$Context" ]];
then
	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${UserId}'))' -b ${Context} 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null

declare -i NUMBER_OF_USER_RECORDS=`grep -c "numEntries" ${OUT_FILE_ONE}`

	if [ $NUMBER_OF_USER_RECORDS -lt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "(10) More Than One User Exists With the Userid: ${UserId}"
	fi

declare -i RECORD_COUNT=`grep "numEntries" ${OUT_FILE_ONE} | sed 's/^[^:]*: //'`

	if [ $RECORD_COUNT -gt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "(11) More Than One User Exists With the Userid: ${UserId}"	
	fi


	USER_DN=`grep "dn:" ${OUT_FILE_ONE}`

	UserId_1=${USER_DN#dn: } # remove dn: 
	UserId_2=${UserId_1#cn=} # remove cn= 
	UserId=${UserId_2%%,*}  # remove portion after the comma
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	return 0

fi



if [[ -n "$Context" ]];
then
	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${UserId}'))' -b ${Context} 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null
else

	if [[ -n "$DefaultUserSearchContext" ]];
	then
		{
		ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${UserId}'))' -b ${DefaultUserSearchContext} 1> ${OUT_FILE_ONE}
		} 1> /dev/null 2> /dev/null

	else
		{
		ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${UserId}'))' 1> ${OUT_FILE_ONE}
		} 1> /dev/null 2> /dev/null


	fi


	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(cn='${UserId}'))' 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null
fi



	declare -i NUMBER_OF_USER_RECORDS=`grep -c "numEntries" ${OUT_FILE_ONE}`

	if [ $NUMBER_OF_USER_RECORDS -lt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "A User Does Not Exist With The Userid: ${UserId}"
	fi

	declare -i RECORD_COUNT=`grep "numEntries" ${OUT_FILE_ONE} | sed 's/^[^:]*: //'`

	if [ $RECORD_COUNT -gt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "(12) More Than One User Exists With The Userid: ${UserId}"	
	fi

	USER_DN=`grep "dn:" ${OUT_FILE_ONE}`


	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

	UserId_1=${USER_DN#dn: } # remove dn: 
	UserId_2=${UserId_1#cn=} # remove cn= 

	UserId=${UserId_2%%,*}   # remove portion after the comma

	Context=${USER_DN#*,}



return 0

}





function SearchForUserByFirstAndLastName()
{

OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"

if [[ -n "$Context" ]];
then

	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(fullName='${FirstName}' '${LastName}'))' -b ${Context} 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null

	declare -i NUMBER_OF_USER_RECORDS=`grep -c "numEntries" ${OUT_FILE_ONE}`

	if [ $NUMBER_OF_USER_RECORDS -lt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "A User Does Not Exist With the Name: ${FirstName} ${LastName}"
	fi

	declare -i RECORD_COUNT=`grep "numEntries" ${OUT_FILE_ONE} | sed 's/^[^:]*: //'`

	if [ $RECORD_COUNT -gt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "More Than One User Exists With The Name: ${FirstName} ${LastName}"
	fi


	USER_DN=`grep "dn:" ${OUT_FILE_ONE}`

	UserId_1=${USER_DN#dn: } # remove dn: 
	UserId_2=${UserId_1#cn=} # remove cn= 
	UserId=${UserId_2%%,*}  # remove portion after the comma
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
	return 0

fi

if [[ -n "$Context" ]];
then
	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(fullName='${FirstName}' '${LastName}'))' -b ${Context} 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null

else

	if [[ -n "$DefaultUserSearchContext" ]];
	then
		{
		ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(fullName='${FirstName}' '${LastName}'))' -b ${DefaultUserSearchContext} 1> ${OUT_FILE_ONE}
		} 1> /dev/null 2> /dev/null
	else
		{
		ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)(fullName='${FirstName}' '${LastName}'))' 1> ${OUT_FILE_ONE}
		} 1> /dev/null 2> /dev/null
	fi


fi
	



declare -i NUMBER_OF_USER_RECORDS=`grep -c "numEntries" ${OUT_FILE_ONE}`

	if [ $NUMBER_OF_USER_RECORDS -lt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "A User Does Not Exist With the Name: ${FirstName} ${LastName}"
	fi

declare -i RECORD_COUNT=`grep "numEntries" ${OUT_FILE_ONE} | sed 's/^[^:]*: //'`

	if [ $RECORD_COUNT -gt 1 ]
	then 
		rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null
		ReportError "$FUNCNAME: More Than One User Exists With The Name: ${FirstName} ${LastName}"
	fi

	USER_DN=`grep "dn:" ${OUT_FILE_ONE}`
	rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

	UserId_1=${USER_DN#dn: } # remove dn: 
	UserId_2=${UserId_1#cn=} # remove cn= 

	UserId=${UserId_2%%,*}   # remove portion after the comma

	Context=${USER_DN#*,}


return 0

}

function FindUserDN()
{

if [ $DisableUserSearch -gt 0 ]
then
return
fi

if [[ -z "$UserId" ]];then


	if [[ -n "$FirstName" ]];
	then


		if [[ -n "$LastName" ]];
		then
			SearchForUserByFirstAndLastName
		fi

	fi

	if [[ -z "$Context" ]];then
		SearchForUserByUserId
	fi



return 0
fi



if [[ -z "$Context" ]];then
	SearchForUserByUserId
fi

}

function LockUser()
{

TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.ldif"

echo "dn: cn=${UserId},${Context}" 1> ${TEMP_FILE_ONE}
echo "changetype: modify" 1>> ${TEMP_FILE_ONE}
echo "replace: lockedByIntruder"  1>> ${TEMP_FILE_ONE}
echo "lockedByIntruder: TRUE"  1>> ${TEMP_FILE_ONE}

OutputMessage "Locking User Account"

{
ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE}
} 1> /dev/null 2> /dev/null


declare -i EXIT_STATUS=`echo $?`

rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

if [ $EXIT_STATUS -eq 0 ]
then
	OutputMessage "User Account Locked"
	return 0
else
	OutputMessage ""
	OutputMessage "User Account NOT Locked"
	OutputMessage ""
	return 1
fi

}

function UnlockUser()
{

TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.ldif"

echo "dn: cn=${UserId},${Context}" 1> ${TEMP_FILE_ONE}
echo "changetype: modify" 1>> ${TEMP_FILE_ONE}
echo "replace: lockedByIntruder"  1>> ${TEMP_FILE_ONE}
echo "lockedByIntruder: FALSE"  1>> ${TEMP_FILE_ONE}

OutputMessage "Unlocking User Account"

{
ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE}
} 1> /dev/null 2> /dev/null


declare -i EXIT_STATUS=`echo $?`

rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

if [ $EXIT_STATUS -eq 0 ]
then
	OutputMessage "User Account Unlocked"
	return 0
else
	OutputMessage ""
	OutputMessage "User Account NOT Unlocked"
	OutputMessage ""
	return 1
fi

}


function DisableUser()
{

TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.ldif"

echo "dn: cn=${UserId},${Context}" 1> ${TEMP_FILE_ONE}
echo "changetype: modify" 1>> ${TEMP_FILE_ONE}
echo "replace: loginDisabled"  1>> ${TEMP_FILE_ONE}
echo "loginDisabled: TRUE"  1>> ${TEMP_FILE_ONE}


OutputMessage ""
OutputMessage "Disabling User Account"
OutputMessage "cn=${UserId},${Context}"

{
ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE}
} 1> /dev/null 2> /dev/null


declare -i EXIT_STATUS=`echo $?`

rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

if [ $EXIT_STATUS -eq 0 ]
then
	OutputMessage "User Account Disabled: cn=${UserId},${Context}"
	return 0
else
	OutputMessage ""
	OutputMessage "User Account NOT Disabled: cn=${UserId},${Context}"
	OutputMessage ""
	return 1
fi

}

function EnableUser()
{

TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.ldif"

echo "dn: cn=${UserId},${Context}" 1> ${TEMP_FILE_ONE}
echo "changetype: modify" 1>> ${TEMP_FILE_ONE}
echo "replace: loginDisabled"  1>> ${TEMP_FILE_ONE}
echo "loginDisabled: FALSE"  1>> ${TEMP_FILE_ONE}

OutputMessage ""
OutputMessage "Enabling User Account"
OutputMessage "cn=${UserId},${Context}"

{
ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE}
} 1> /dev/null 2> /dev/null


declare -i EXIT_STATUS=`echo $?`

rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

if [ $EXIT_STATUS -eq 0 ]
then
	OutputMessage "User Account Enabled: cn=${UserId},${Context}"
	return 0
else
	OutputMessage ""
	OutputMessage "User Account NOT Enabled: cn=${UserId},${Context}"
	OutputMessage ""
	return 1
fi

}

function ParseUserIdentityOrDN()
{

if [[ -n "$UserId" ]];then
	return 1
fi

IDENTITY_INPUT_STRING="${FullNameOrUserIdOrDN}"

CURRENT_IDENTITY=$(echo "${IDENTITY_INPUT_STRING}" | tr -s " ")
CURRENT_IDENTITY=${CURRENT_IDENTITY%% }
CURRENT_IDENTITY=${CURRENT_IDENTITY## }
CURRENT_IDENTITY_LENGTH=`echo "${CURRENT_IDENTITY}" | wc -w`

if [ $CURRENT_IDENTITY_LENGTH -lt 1 ]
then
	USER_ACTION="0"
	return 1
fi

if  [ $CURRENT_IDENTITY_LENGTH -eq 1 ]
then
	declare -i CN_EXISTS=`echo "${CURRENT_IDENTITY}" | grep -ic "cn="`

	if [ $CN_EXISTS -eq 0 ]
	then
		UserId="${CURRENT_IDENTITY}"
	else

		TheUserId_1=${CURRENT_IDENTITY#cn=} # remove cn= 
		UserId=${TheUserId_1%%,*}   # remove portion after the comma
		Context=${CURRENT_IDENTITY#*,}

	fi
fi


if  [ $CURRENT_IDENTITY_LENGTH -gt 1 ]
then
	FirstName=`echo "${CURRENT_IDENTITY}"  | head -n1 | cut -d " " -f1`
	LastName=`echo "${CURRENT_IDENTITY}"  | head -n1 | cut -d " " -f2`
fi


}

function ParseUserIdentity()
{

if [[ -n "$UserId" ]];then
	return 1
fi

IDENTITY_INPUT_STRING="${FullNameOrUserId}"

CURRENT_IDENTITY=$(echo "${IDENTITY_INPUT_STRING}" | tr -s " ")
CURRENT_IDENTITY=${CURRENT_IDENTITY%% }
CURRENT_IDENTITY=${CURRENT_IDENTITY## }
CURRENT_IDENTITY_LENGTH=`echo "${CURRENT_IDENTITY}" | wc -w`

if [ $CURRENT_IDENTITY_LENGTH -lt 2 ]
then
	USER_ACTION=0
	return 1
fi

if  [ $CURRENT_IDENTITY_LENGTH -eq 1 ]
then
	UserId="${CURRENT_IDENTITY}"
fi


if  [ $CURRENT_IDENTITY_LENGTH -gt 1 ]
then
	FirstName=`echo "${CURRENT_IDENTITY}"  | head -n1 | cut -d " " -f1`
	LastName=`echo "${CURRENT_IDENTITY}"  | head -n1 | cut -d " " -f2`
fi


}


function ParseManagerIdentity()
{

if [[ -n "$ManagerId" ]];then
	return 1
fi

IDENTITY_INPUT_STRING="${ManagerFullNameOrUserId}"

CURRENT_IDENTITY=$(echo "${IDENTITY_INPUT_STRING}" | tr -s " ")
CURRENT_IDENTITY=${CURRENT_IDENTITY%% }
CURRENT_IDENTITY=${CURRENT_IDENTITY## }
CURRENT_IDENTITY_LENGTH=`echo "${CURRENT_IDENTITY}" | wc -w`

if [ $CURRENT_IDENTITY_LENGTH -lt 1 ]
then
	return 1
fi

if  [ $CURRENT_IDENTITY_LENGTH -eq 1 ]
then
	ManagerId="${CURRENT_IDENTITY}"
fi


if  [ $CURRENT_IDENTITY_LENGTH -gt 1 ]
then
	ManagerFirstName=`echo "${CURRENT_IDENTITY}"  | head -n1 | cut -d " " -f1`
	ManagerLastName=`echo "${CURRENT_IDENTITY}"  | head -n1 | cut -d " " -f2`
fi


}

function SetUserExpiration()
{

SLASH_CHAR="/"
declare -i NUMBER_OF_SLASHES=`awk -F"${SLASH_CHAR}" '{print NF-1}' <<< "${UserExpirationDate}"`

if [ $NUMBER_OF_SLASHES -ne 2 ]
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

if [ $NUMBER_OF_SLASHES -ne 2 ]
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

THE_MONTH_VALUE=`echo "${UserExpirationDate}" | awk -F\/ '{print $1}'`

re='^[0-9]+$'
if ! [[ $THE_MONTH_VALUE =~ $re ]] ; 
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

THE_MONTH_VALUE_LENGTH=`echo ${THE_MONTH_VALUE} | wc -c`

if [ $THE_MONTH_VALUE_LENGTH -lt 2 ]
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

if [ $THE_MONTH_VALUE_LENGTH -gt 3 ]
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

if [ $THE_MONTH_VALUE -gt 12 ]
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

if [ $THE_MONTH_VALUE -lt 1 ]
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

if [ $THE_MONTH_VALUE_LENGTH -lt 3 ]
then
	THE_MONTH_VALUE="0${THE_MONTH_VALUE}"
fi


THE_DAY_VALUE=`echo "${UserExpirationDate}" | awk -F\/ '{print $2}'`

re='^[0-9]+$'
if ! [[ $THE_DAY_VALUE =~ $re ]] ; 
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

THE_DAY_VALUE_LENGTH=`echo "${THE_DAY_VALUE}" | wc -c`

if [ $THE_DAY_VALUE_LENGTH -gt 4 ]
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

if [ $THE_DAY_VALUE -gt 31 ]
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

if [ $THE_DAY_VALUE -lt 1 ]
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

if [ $THE_DAY_VALUE_LENGTH -lt 3 ]
then
	THE_DAY_VALUE="0${THE_DAY_VALUE}"
fi

THE_YEAR_VALUE=`echo "${UserExpirationDate}" | awk -F\/ '{print $3}'`

re='^[0-9]+$'
if ! [[ $THE_YEAR_VALUE =~ $re ]] ; 
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

THE_YEAR_VALUE_LENGTH=`echo ${THE_YEAR_VALUE} | wc -c`

if [ $THE_YEAR_VALUE_LENGTH -lt 5 ]
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

if [ $THE_YEAR_VALUE_LENGTH -gt 5 ]
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	return 1
fi

if [ $THE_YEAR_VALUE -lt 2020 ]
then
	OutputMessage "Incorrect Date Format: ${UserExpirationDate}"
	OutputMessage "Use an Expiration Date in the Future"
	return 1
fi

EXPIRATION_DATE="${THE_YEAR_VALUE}${THE_MONTH_VALUE}${THE_DAY_VALUE}050000Z"

TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.tmp.ldif"

echo "dn: cn=${UserId},${Context}" 1> ${TEMP_FILE_ONE}
echo "changetype: modify" 1>> ${TEMP_FILE_ONE}
echo "replace: loginExpirationTime" 1>> ${TEMP_FILE_ONE}
echo "loginExpirationTime: ${EXPIRATION_DATE}" 1>> ${TEMP_FILE_ONE}


OutputMessage "Enabling User Account Expiration: ${UserExpirationDate}"

{
ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE}
} 1> /dev/null 2> /dev/null


declare -i EXIT_STATUS=`echo $?`

rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

if [ $EXIT_STATUS -eq 0 ]
then
	OutputMessage "User Account Expiration Date Set"
	return 0
else
	OutputMessage ""
	OutputMessage "User Account Expiration Date NOT Set"
	OutputMessage ""
	return 1
fi


}

function RemoveUserExpiration()
{

TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.tmp.ldif"

echo "dn: cn=${UserId},${Context}" 1> ${TEMP_FILE_ONE}
echo "delete: loginExpirationTime" 1>> ${TEMP_FILE_ONE}

OutputMessage "Disabling User Account Expiration"

OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"

{
ldapmodify -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -f ${TEMP_FILE_ONE} 2> ${OUT_FILE_ONE}
} 1> /dev/null 2> /dev/null

declare -i EXIT_STATUS=`echo $?`

rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

declare -i NO_SUCH_ATTRIBUTE=`grep -ic "no such attribute" ${OUT_FILE_ONE}`

rm ${OUT_FILE_ONE} 1> /dev/null 2> /dev/null

if [ $EXIT_STATUS -eq 0 ]
then
OutputMessage "User Account Expiration Removed"
return 0
else


	if [ $NO_SUCH_ATTRIBUTE -gt 0 ]
	then
	OutputMessage ""
	OutputMessage "User Account Expiration Date NOT Removed"
	OutputMessage "There Was No Expiration Date For This User Account"
	OutputMessage ""
	else
	OutputMessage ""
	OutputMessage "User Account Expiration Date NOT Removed"
	OutputMessage ""
	fi
return 1
fi


}


function ModifyUser()
{

ValidateParameter "$UserId" "Userid | Example: -UserId \"bsmith\""
ValidateParameter "$Context" "Context | Example: -Context \"ou=users,o=cimitra\""

theFirstNameUniversal="${FirstName}"
theLastNameUniversal="${LastName}"

if [[ -n "$OfficePhone" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "telephoneNumber" "${OfficePhone}" "Office Phone"
fi

if [[ -n "$MobilePhone" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "mobile" "${MobilePhone}" "Mobile Phone"
fi

if [[ -n "$FaxNumber" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "facsimileTelephoneNumber" "${FaxNumber}" "Fax Number"
fi

if [[ -n "$GenerationQualifier" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "generationQualifier" "${GenerationQualifier}" "Generation Qualifier"
fi

if [[ -n "$MiddleInitial" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "initials" "${MiddleInitial}" "Middle Initial"
fi

if [[ -n "$Title" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "title" "${Title}" "Title"
fi

if [[ -n "$Department" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "ou" "${Department}" "Department"
fi

if [[ -n "$Description" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "description" "${Description}" "Description"
fi

if [[ -n "$Location" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "l" "${Location}" "Location"
fi

if [[ -n "$NewFirstName" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "givenName" "${NewFirstName}" "First Name"
theFirstNameUniversal="${NewFirstName}"
ModifiedUserFirstName="1"
REPLACE_FULL_NAME=1
fi

if [[ -n "$NewLastName" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "sn" "${NewLastName}" "Last Name"
theLastNameUniversal="${NewLastName}"
ModifiedUserLastName="1"
REPLACE_FULL_NAME=1
fi



if [[ -n "$EmailAddress" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "mail" "${EmailAddress}" "Email Address"
fi

if [[ -n "$ManagerId" ]];
then
ValidateParameter "$ManagerContext" "ManagerContext | Example: -ManagerContext \"ou=users,o=cimitra\""
LDAP_ATTRIBUTE_MODIFY_LIST "manager" "cn=${ManagerId},${ManagerContext}" "Manager"
fi

if [[ -n "$LDAPAttributeOne" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "${LDAPAttributeOne}" "${LDAPAttributeOneName}" "${LDAPAttributeOneName}"
fi

if [[ -n "$LDAPAttributeTwo" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "${LDAPAttributeTwo}" "${LDAPAttributeTwoName}" "${LDAPAttributeTwoName}"
fi

if [[ -n "$LDAPAttributeThree" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "${LDAPAttributeThree}" "${LDAPAttributeThreeName}" "${LDAPAttributeThreeName}"
fi

if [[ -n "$LDAPAttributeFour" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "${LDAPAttributeFour}" "${LDAPAttributeFourName}" "${LDAPAttributeFourName}"
fi

if [[ -n "$LDAPAttributeFive" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "${LDAPAttributeFive}" "${LDAPAttributeFiveName}" "${LDAPAttributeFiveName}"
fi

if [[ -n "$LDAPAttributeSix" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "${LDAPAttributeSix}" "${LDAPAttributeSixName}" "${LDAPAttributeSixName}"
fi

if [[ -n "$LDAPAttributeSeven" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "${LDAPAttributeSeven}" "${LDAPAttributeSevenName}" "${LDAPAttributeSevenName}"
fi

if [[ -n "$LDAPAttributeEight" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "${LDAPAttributeEight}" "${LDAPAttributeEightName}" "${LDAPAttributeEightName}"
fi

if [[ -n "$LDAPAttributeNine" ]];
then
LDAP_ATTRIBUTE_MODIFY_LIST "${LDAPAttributeNine}" "${LDAPAttributeNineName}" "${LDAPAttributeNineName}"
fi

MODIFY_GROUP=1

if [ $MODIFY_USER_ATTRIBUTE -eq 0 ]
then
rm ${GLOBAL_LDAP_TEMP_FILE_ONE} 1> /dev/null 2> /dev/null
return
fi

{
ldapmodify -v -x -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -w $EDIR_AUTH_STRING  -D $EDIR_USER -f ${GLOBAL_LDAP_TEMP_FILE_ONE}
} 1> /dev/null 2> /dev/null

declare -i EXIT_STATUS=`echo $?`

cp ${GLOBAL_LDAP_TEMP_FILE_ONE} /var/opt/cimitra/scripts/edir/tmp.ldif

rm ${GLOBAL_LDAP_TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

if [ $EXIT_STATUS -eq 0 ]
then
	OutputMessage "All Modifications Made"
	OutputMessage "-----------------------"
else
	OutputMessage ""
	OutputMessage "All Modifications NOT Made"
	OutputMessage "-----------------------"
	OutputMessage ""
fi



if [ $REPLACE_FULL_NAME -eq 0 ]
then
	return
fi


OutputMessage "Renaming Full Name From: ${FirstName} ${LastName}"
OutputMessage "To a New User Full Name: ${theFirstNameUniversal} ${theLastNameUniversal}"
OutputMessage "-----------------------"

TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.$FUNCNAME.1.tmp.ldif"


echo "dn: cn=${UserId},${Context}" 1> $TEMP_FILE_ONE
echo "changetype: modify" 1>> $TEMP_FILE_ONE
echo "replace: fullName" 1>> $TEMP_FILE_ONE
echo "fullName: ${theFirstNameUniversal} ${theLastNameUniversal}" 1>> $TEMP_FILE_ONE

{
ldapmodify -v -x -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -w $EDIR_AUTH_STRING  -D $EDIR_USER -f $TEMP_FILE_ONE
} 1> /dev/null 2> /dev/null

declare -i EXIT_CODE=`echo $?`

rm $TEMP_FILE_ONE 1>> /dev/null 2>> /dev/null

if [ $EXIT_CODE -eq 0 ]
then
	FirstName="${theFirstNameUniversal}"
	LastName="${theLastNameUniversal}"
	OutputMessage "-----------------------"
else
	ReportError "Unable to Rename User's Full Name"
fi

}

function ChangePassword()
{
[[ -z "$Context" ]] && ReportError "Enter a Context"
[[ -z "$UserId" ]] && ReportError "Enter a UserId"

if [[ -z "$Password" ]];then

	if [[ -z "$DefaultPassword" ]];then
		ValidateParameter "$Password" "Password | Example: -Password \"changeM3N0W\""
		Password="${DefaultPassword}"
	else
		ReportError "Please specify a password with the -Password parameter"
	fi
fi

if [ $COMPACT_OUTPUT -eq 0 ]
then
	OutputMessage "Resetting User Password"
	OutputMessage "cn=${UserId},${Context}"
fi


TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.tmp.ldif"

echo "dn: cn=${UserId},${Context}" 1> ${TEMP_FILE_ONE}
echo "changetype: modify" 1>> ${TEMP_FILE_ONE}
echo "replace: userPassword" 1>> ${TEMP_FILE_ONE}
echo "userPassword: ${Password}" 1>> ${TEMP_FILE_ONE}

{
ldapmodify -v -x -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -D ${EDIR_USER} -w ${EDIR_AUTH_STRING} -f ${TEMP_FILE_ONE}
} 1> /dev/null 2> /dev/null

declare -i EXIT_STATUS=`echo $?`

rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

if [ $EXIT_STATUS -eq 0 ]
then
	OutputMessage "Password Changed"
else
	OutputMessage ""
	OutputMessage "Password NOT Changed"
	OutputMessage ""
fi
}



function CreateUser()
{
if [ $THE_USER_WAS_CREATED -eq 1 ]
then
	return 1
fi



COMPACT_OUTPUT="1"
MODIFY_GROUP="1"
CREATE_USER="1"
ADD_USER_TO_GROUP="1"
REMOVE_USER_FROM_GROUP="0"
ValidateParameter "$FirstName" "First Name | Example: -FirstName \"Bob\""
ValidateParameter "$LastName" "Last Name | Example: -LastName \"Smith\""
ValidateParameter "$Context" "Context | Example: -Context \"users.finance.cimitra\""
ValidateParameter "$UserId" "Userid | Example: -UserId \"bsmith\""



if [[ -z "$Password" ]];then

	if [[ -z "$DefaultPassword" ]];then
		ValidateParameter "$Password" "Password | Example: -Password \"changeM3N0W\""
	else
	Password="${DefaultPassword}"
	fi

fi

ValidateParameter "$Password" "Password | Example: -Password \"changeM3N0W\""


OutputMessage "Creating User: $FirstName $LastName"
OutputMessage "cn=${UserId},${Context}"


local USER_EXISTS=$(VerifyUserObjectExistence "$UserId" "$Context")

if [ $USER_EXISTS -eq 0 ]
then
	ReportError "User Already Exists: cn=${UserId},${Context}"
fi

TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.tmp.ldif"

echo "dn: cn=${UserId},${Context}" 1> ${TEMP_FILE_ONE}
echo "changetype: add" 1>> ${TEMP_FILE_ONE}
echo "objectClass: user" 1>> ${TEMP_FILE_ONE}
echo "uniqueID: ${UserId}" 1>> ${TEMP_FILE_ONE}
echo "givenName: ${FirstName}" 1>> ${TEMP_FILE_ONE}
echo "sn: ${LastName}" 1>> ${TEMP_FILE_ONE}
echo "fullName: ${FirstName} ${LastName}" 1>> ${TEMP_FILE_ONE}


{
ldapadd -x -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT} -w $EDIR_AUTH_STRING  -D $EDIR_USER -f ${TEMP_FILE_ONE}
} 1> /dev/null 2> /dev/null

local DOES_USER_EXIST=$(VerifyUserObjectExistence "$UserId" "$Context")

if [ $DOES_USER_EXIST -ne 0 ]
then
	ReportError "User Account: cn=${UserId},${Context} NOT Created"
fi

rm ${TEMP_FILE_ONE} 1> /dev/null 2> /dev/null

THE_USER_WAS_CREATED=1

OutputMessage "User Account Created"

CallSleep

ChangePassword

ModifyUser

MODIFY_USER_ATTRIBUTE=0
}


if [[ -z "$Action" ]];then
OutputMessage "Use The -Action Parameter"
OutputMessage ""
OutputMessage "Reports"
OutputMessage ""
OutputMessage "Example: $0 -Action \"ListAllUsersInTree\""
OutputMessage "Example: $0 -Action \"ListUsers\""
OutputMessage ""
OutputMessage "User Object Reports/Actions"
OutputMessage ""
OutputMessage "Example: $0 -Action \"SearchForUser\""
OutputMessage "Example: $0 -Action \"UserReport\""
OutputMessage "Example: $0 -Action \"CreateUser\""
OutputMessage "Example: $0 -Action \"ModifyUser\""
OutputMessage "Example: $0 -Action \"MoveUser\""
OutputMessage ""
OutputMessage "User Object Account Access"
OutputMessage ""
OutputMessage "Example: $0 -Action \"DisableUser\""
OutputMessage "Example: $0 -Action \"EnableUser\""
OutputMessage "Example: $0 -Action \"LockUser\""
OutputMessage "Example: $0 -Action \"UnlockUser\""
OutputMessage "Example: $0 -Action \"SetUserExpiration\""
OutputMessage "Example: $0 -Action \"RemoveUserExpiration\""
OutputMessage ""
OutputMessage "User and Group Object Changes"
OutputMessage ""
OutputMessage "Example: $0 -Action \"GroupReport\""
OutputMessage "Example: $0 -Action \"CreateGroup\""
OutputMessage "Example: $0 -Action \"AddUserToGroup\""
OutputMessage "Example: $0 -Action \"RemoveUserFromGroup\""

OutputMessage ""
ReportError "An -Action is required"
fi


if [ $USER_FULL_NAME_OR_USERID -gt 0 ]
then
	ParseUserIdentity
fi

if [ $USER_FULL_NAME_OR_USERID_OR_DN -gt 0 ]
then
	ParseUserIdentityOrDN
fi

if [ $MANAGER_FULL_NAME_OR_USERID -gt 0 ]
then
	ParseManagerIdentity
fi

function CheckForExcludeGroup()
{
declare -i RETURN_FROM_FUNCTION=$1


if [ $USER_ACTION -eq 0 ]
then
	return 0
fi


if [ $IGNORE_EXCLUDE_GROUP -gt 0 ]
then
	return 0
fi

declare -i EDIR_EXCLUDE_GROUP_LENGTH=`echo "${EDIR_EXCLUDE_GROUP}" | wc -c`

if [ $EDIR_EXCLUDE_GROUP_LENGTH -lt 8 ]
then 
	return 0
fi

declare -i EXCLUDE_GROUP_PROPERLY_NAMED=`echo "${EDIR_EXCLUDE_GROUP}" | grep -c "cn="`


if [ $EXCLUDE_GROUP_PROPERLY_NAMED -eq 0 ]
then
OutputMessage ""
OutputMessage "--------------------------------------------------------------------------------"
OutputMessage "Insufficent Rights to Administer Objects"
OutputMessage "Exclude Group Improperly Named: \"${EDIR_EXCLUDE_GROUP}\" "
OutputMessage  "--------------------------------------------------------------------------------"
ReportError "Use a Proper GroupName User Distinguished Name Format - Example: cn=cimitra_exlcude,ou=groups,o=cimitra"
fi


GroupName_1=${EDIR_EXCLUDE_GROUP#cn=} # remove cn= 
ExcludeGroupName=${GroupName_1%%,*}  # remove portion after the comma
ExcludeGroupContext=${EDIR_EXCLUDE_GROUP#*,} # Get the Group Context

local THIS_GROUP_EXISTS=$(VerifyGroupObjectExistence "$ExcludeGroupName" "$ExcludeGroupContext")


if [ $THIS_GROUP_EXISTS -eq 1 ]
then
	ReportError "Error Group Does Not Exist: cn=${ExcludeGroupName},${ExcludeGroupContext}"
fi

local GROUP_EXISTS=$(VerifyUserExistsInGroup "${ExcludeGroupName}" "${ExcludeGroupContext}" "${UserId}" "${Context}")

local USER_EXISTS_IN_GROUP_ALREADY=$(VerifyUserExistsInGroup "${ExcludeGroupName}" "${ExcludeGroupContext}" "${UserId}" "${Context}")

# echo "USER_EXISTS_IN_GROUP_ALREADY = $USER_EXISTS_IN_GROUP_ALREADY"

if [ $USER_EXISTS_IN_GROUP_ALREADY -eq 0 ]
then	
	if [ $RETURN_FROM_FUNCTION -eq 1 ]
	then
	echo "1"
	return 1
	fi


	if [ -n $FirstName ]
	then
		if [ $LastName ]
		then
		ReportError "Insufficent Rights to Administer User: $FirstName $LastName"
		fi
	else
		if [ -n $UserId ]
		then
		ReportError "Insufficent Rights to Administer User: $UserId"
		fi
	fi

ReportError "Insufficent Rights to Administer User"

fi

}

function ShowUserReport
{
if [ $DisableUserReport -eq 1 ]
then
	return 0
fi

if [ $USER_ACTION -eq 0 ]
then
	if [ $GROUP_ACTION -eq 0 ]
	then
		return 0
	fi
fi

UserReport
}


function SearchForUser()
{

OUT_FILE_ZERO="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.0.string.tmp.out"
OutputMessage "Search For Users With These Attributes"
# sed 's/^[[:space:]]*//' <<< "$mystring"


if [[ -n "$UserId" ]];
then
	OutputMessage "Userid: $UserId"
	theUserId="(cn=${UserId})"
else
	theUserId=""
fi

if [[ -n "$FirstName" ]];
then
	OutputMessage "First Name: $FirstName"
       FirstName_1=`echo "${FirstName}" | xargs`
	FirstName_2=`echo "${FirstName_1}" | sed -e 's/\s\+/*/g'`
	theFirstName="(givenName=${FirstName_2})"
else
	theFirstName=""
fi

if [[ -n "$LastName" ]];
then
	OutputMessage "Last Name: $LastName"
       LastName_1=`echo "${LastName}" | xargs`
	LastName_2=`echo "${LastName_1}" | sed -e 's/\s\+/*/g'`
	theLastName="(sn=${LastName_2})"
else
	theLastName=""
fi

if [[ -n "$OfficePhone" ]];
then
	OutputMessage "Office Phone: $OfficePhone"
       OfficePhone_1=`echo "${OfficePhone}" | xargs`
	OfficePhone_2=`echo "${OfficePhone_1}" | sed -e 's/\s\+/*/g'`
	theOfficePhone="(telephoneNumber=${OfficePhone_2})"
else
	theOfficePhone=""
fi

if [[ -n "$MobilePhone" ]];
then
	OutputMessage "Mobile Phone: $MobilePhone"
       MobilePhone_1=`echo "${MobilePhone}" | xargs`
	MobilePhone_2=`echo "${MobilePhone_1}" | sed -e 's/\s\+/*/g'`
	theMobilePhone="(mobile=${MobilePhone_2})"
else
	theMobilePhone=""
fi


if [[ -n "$FaxNumber" ]];
then
	OutputMessage "Fax Number: $FaxNumber"
       FaxNumber_1=`echo "${FaxNumber}" | xargs`
	FaxNumber_2=`echo "${FaxNumber_1}" | sed -e 's/\s\+/*/g'`
	theFaxNumber="(facsimiletelephonenumber=${FaxNumber_2})"
else
	theFaxNumber=""
fi

if [[ -n "$GenerationQualifier" ]];
then
	OutputMessage "Generational Qualifier: $GenerationQualifier"
       GQ_1=`echo "${GenerationQualifier}" | xargs`
	GQ_2=`echo "${GQ_1}" | sed -e 's/\s\+/*/g'`
	theGenerationQualifier="(generationQualifier=${GQ_2})"
else
	theGenerationQualifier=""
fi

if [[ -n "$MiddleInitial" ]];
then
	OutputMessage "Middle Initials: ${MiddleInitial}"
       MiddleInitial_1=`echo "${MiddleInitial}" | xargs`
	MiddleInitial_2=`echo "${MiddleInitial_1}" | sed -e 's/\s\+/*/g'`
	theMiddleInitial="(initials=${MiddleInitial_2})"
else
	theMiddleInitial=""
fi

if [[ -n "$Title" ]];
then
	OutputMessage "Title: $Title"
       Title_1=`echo "${Title}" | xargs`
	Title_2=`echo "${Title_1}" | sed -e 's/\s\+/*/g'`
	theTitle="(title=${Title_2})"
else
	theTitle=""
fi

if [[ -n "$Department" ]];
then
	OutputMessage "Department: $Department"
       Department_1=`echo "${Department}" | xargs`
	Department_2=`echo "${Department_1}" | sed -e 's/\s\+/*/g'`
	theDepartment="(ou=${Department_2})"
else
	theDepartment=""
fi

if [[ -n "$Location" ]];
then
       Location_1=`echo "${Location}" | xargs`
	Location_2=`echo "${Location_1}" | sed -e 's/\s\+/*/g'`
	theLocation="(l=${Location_2})"
else
	theLocation=""
fi

if [[ -n "$EmailAddress" ]];
then
	OutputMessage "Email Address: $EmailAddress"
	theEmailAddress="(mail=${EmailAddress})"
else
	theEmailAddress=""
fi


if [[ -n "$Description" ]];
then
       Description_1=`echo "${Description}" | xargs`
	Description_2=`echo "${Description_1}" | sed -e 's/\s\+/*/g'`
	theDescription="(description=${Description_2})"
else
	theDescription=""
fi

declare -i CONTEXT_SET=0

if [[ -n "$Context" ]];
then
	theContext="${Context}"
	CONTEXT_SET=1
fi

if [[ -n "$DefaultUserSearchContext" ]];
then
	theContext="${DefaultUserSearchContext}"
	CONTEXT_SET=1
fi

OUT_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.1.tmp.out"
OUT_FILE_TWO="${TEMP_FILE_DIRECTORY}/$$.${FUNCNAME}.2.tmp.out"


if [ $CONTEXT_SET -gt 0 ]
then

	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user) '${theUserId}' '${theFirstName}' '${theLastName}' '${theOfficePhone}' '${theMobilePhone}' '${theFaxNumber}' '${theGenerationQualifier}' '${theMiddleInitial}' '${theDepartment}' '${theDescription}' '${theTitle}' '${theLocation}' '${theEmailAddress}')' -b ${theContext} cn 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null
else
	{
	ldapsearch -v -x -w $EDIR_AUTH_STRING  -D $EDIR_USER -h ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_ADDRESS_ONE} -p ${EDIR_LDAP_SERVICE_SIMPLE_AUTHENTICATION_PORT_ONE} '(&(objectClass=user)'${theUserId}''${theFirstName}''${theLastName}''${theOfficePhone}''${theMobilePhone}''${theFaxNumber}''${theGenerationQualifier}''${theMiddleInitial}''${theDepartment}''${theDescription}''${theTitle}''${theLocation}''${theEmailAddress}')' cn 1> ${OUT_FILE_ONE}
	} 1> /dev/null 2> /dev/null
fi

grep "dn: cn=" ${OUT_FILE_ONE} 1>> ${OUT_FILE_TWO}

rm ${OUT_FILE_ONE} 1>> /dev/null 2>> /dev/null

declare -i USER_EXISTS=`grep -c "dn:" ${OUT_FILE_TWO}`
declare -i COUNTER=0
if [ $USER_EXISTS -gt 0 ]
then
 
	if [ $USER_EXISTS -eq 1 ]
	then
    		OutputMessage "$USER_EXISTS USER MATCHES THE SEARCH"
	else
    		OutputMessage "$USER_EXISTS USERS MATCH THE SEARCH"
	fi
    	
	OutputMessage "--------------------------"
	while IFS= read -r USER_LINE; do
	let COUNTER=COUNTER+1
	TheUserDNIn=${USER_LINE#dn: }
	UserId_1=${TheUserDNIn#cn=} # remove cn= 
	UserId=${UserId_1%%,*}   # remove portion after the comma
	Context=${TheUserDNIn#*,}


	USER_ACTION="1"
	local EXCLUDE_GROUP_MEMBER_CHECK=$(CheckForExcludeGroup "1")
	declare -i EXCLUDE_GROUP_MEMBER=`echo ${EXCLUDE_GROUP_MEMBER_CHECK}`
	USER_ACTION="0"

		if [ $EXCLUDE_GROUP_MEMBER -eq 1 ]
		then
		OutputMessage "USER #${COUNTER} DETAILS UNAVAILABLE"
		continue
		fi

	USER_REPORT_ALREADY_RAN="0"
       OutputMessage "---------------------"
	OutputMessage "USER #${COUNTER} INFO START" 
       OutputMessage "---------------------"
	UserReport
       OutputMessage "----------------------"
	OutputMessage "USER #${COUNTER} INFO FINISH" 
       OutputMessage "---------------------"

	done < ${OUT_FILE_TWO}
    OutputMessage "--------------------------"
else
OutputMessage "NO USERS MATCH THE SEARCH"
fi

rm ${OUT_FILE_TWO} 1> /dev/null 2> /dev/null

}


if [ $Action == "SearchForUser" ]
then
	USER_ACTION=0
	GROUP_ACTION=0
	SearchForUser
	exit 0
fi


FindUserDN

IdentifyUserFullName


if [[ -z "$UserId" ]];
then
	if [ $USER_ACTION -eq 1 ]
	then
		ReportError "No User Action Possible Without User Identity"
	fi

	if [ $Action == "MoveUser" ]
	then
		ReportError "No User Action Possible Without User Identity"
	fi

	if [ $Action == "ModifyUser" ]
	then
		ReportError "No User Action Possible Without User Identity"
	fi

	if [ $Action == "UserReport" ]
	then
		ReportError "No User Action Possible Without User Identity"
	fi

	if [ $Action == "DisableUser" ]
	then
		ReportError "No User Action Possible Without User Identity"
	fi

	if [ $Action == "EnableUser" ]
	then
		ReportError "No User Action Possible Without User Identity"
	fi
fi

CheckForExcludeGroup "0"

FindManagerDN

CreateUserGroupActionTest

$Action

if [ $ADD_CREATED_USER_TO_GROUP -eq 0 ]
then
	ShowUserReport
fi

DetermineUserToGroupAction

if [ $ADD_CREATED_USER_TO_GROUP -gt 0 ]
then
	ShowUserReport
fi

