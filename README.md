The `create_users.sh` script automates reading a text file named userlists.txt with usernames and group names, creating users and groups, setting up home directories, generating random passwords, and logging all actions for auditing purposes.

### Key Features

**Reading Input File**:
The script processes each line of the input file, formatted as `user;groups`.

**Creating Users and Groups**:
Each user is assigned a personal group and the group is named after the user name, and additional groups are added as specified. 

The script ensures no conflicts by checking for existing users and groups.

**Setting Up Home Directories**:
Home directories are created with the appropriate permissions and ownership to ensure security and privacy.

**Generating Secure Passwords**:
Random passwords are generated and assigned to each user. These passwords are securely stored in a file with restricted access.

**Logging Actions**:
All actions are logged to `/var/log/user_management.log`, providing a detailed audit trail.

**Secure Password Storage**:
User passwords are stored in `/var/secure/user_passwords.csv`, with permissions set to restrict access to the file owner only.

### Usage

To run the script, provide the name of the text file containing usernames and groups as the first argument:
sudo bash create_users.sh userlist.txt
