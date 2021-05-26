# edir
Cimitra's eDirectory Practice

[ INSTALL ]

1. In a terminal on a Linux server, most likely a SUSE Server with eDirectory installed

2. Install the Cimitra's eDirectory Script with the command below

curl -fsSL https://raw.githubusercontent.com/cimitrasoftware/edir/main/install.sh | sh

3. Go to the directory /var/opt/cimitra/scritps/edir

cd /var/opt/cimitra/scritps/edir

4. Run: ./cimitra_edir.sh

5. Edit the settings_edir.cfg file with variables needed to authenticate to your eDirectory tree via LDAP

6. Run: ./cimitra_edir.sh -Action "[some action]"
  
EXAMPLE: ./cimitra_edir.sh -Action "UserReport" -UserId "jdoe" -Context "ou=users,o=cimitra"
  
-OR- 
 
EXAMPLE: ./cimitra_edir.sh -Action "ListAllUsersInTree"
 
