#!/bin/bash

BOLD="\e[1m"
RED="\e[91m"
GREEN="\e[92m"
END="\e[0m"

OPTION_CREATE="Create a new project"
OPTION_OPEN="Open an existing project"
OPTION_DELETE="Delete a project"
OPTION_QUIT="Quit"

MSG_CHOOSE="Choose one of the options below"
MSG_CONFIG="Enter some details below"
MSG_CHOICE="Choice: "
MSG_QUIT="Quitting..."
MSG_LIST="Below is a list of your existing projects."
MSG_TO_DELETE="Choose one to delete."
MSG_TO_OPEN="Choose one to open."
MSG_CONFIRM_DELETE="Are you sure you want to delete the project"

INPUT_NAME="Name: "
INPUT_XML_PATH="XML path: "
INPUT_AUTO_BACKUP="Automatic backups (y/n): "

PROJECT_NAME_REGEX='^[a-zA-Z0-9\ ._-]{4,64}$'
NOT_NUMBER='[^0-9]'

# $1 bool at least one available project
display_menu () {
	clear
	echo -e "$MSG_CHOOSE\n"
	OPTIONS="$OPTION_CREATE"
	if [ $1 -eq 1 ]; then
		OPTIONS="$OPTIONS,$OPTION_OPEN,$OPTION_DELETE"
	fi
	OPTIONS="$OPTIONS,$OPTION_QUIT"
	
	IFS=',' read -r -a array <<< "$OPTIONS"
	
	len=-1
	for index in "${!array[@]}"; do
		echo "[$index] ${array[index]}"
		len=$(expr $len + 1)
	done

	echo ""
	while
		valid=1
		echo -e "$MSG_CHOICE\c"
		read c
		if [ -z $c ] || [[ "$c" =~ $NOT_NUMBER ]]; then
			valid=0
			printf "${BOLD}${RED}Please enter a number${END}\n\n"
		elif [ "$c" -gt $len ]; then
			valid=0
			printf "${BOLD}${RED}No option found with the ID ${c}${END}\n\n"
		fi	
		[ $valid -eq 0 ]
	do true; done
	
	run_command "${array[$c]}"
}

run_command()
{
	clear
	if [[ "$1" == "$OPTION_QUIT" ]]; then
		echo -e "$MSG_QUIT"
		exit 0
	elif [[ "$1" == "$OPTION_CREATE" ]]; then
		echo -e "$MSG_CONFIG"
		LC_ALL=POSIX
		while
			valid=1
			echo -e "\n$INPUT_NAME\c"
			read name
			if ! [[ "$name" =~ $PROJECT_NAME_REGEX ]]; then
				valid=0
				printf "${BOLD}${RED}Invalid name${END}\n"
			elif [ -d "$PROJECTS/$name" ]; then
				valid=0
				printf "${BOLD}${RED}A project with this name already exists${END}\n"
			fi
			[ $valid -eq 0 ]
		do true; done

		while
			valid=1
			echo -e "\n$INPUT_XML_PATH\c"
			read xml_path
			
			if [ ! -e $xml_path ]; then
				valid=0
				printf "${BOLD}${RED}The path "$xml_path" does not exist\n${END}"
			elif [ ! -f $xml_path ]; then
				valid=0
				printf "${BOLD}${RED}The path "$xml_path" is not a file\n${END}"
			elif [[ "$xml_path" != *.xml ]]; then
				valid=0
				printf "${BOLD}${RED}The file "$xml_path" is not an XML\n${END}"
			fi
			[ $valid -eq 0 ]
		do true; done
		
		while
			echo -e "\n$INPUT_AUTO_BACKUP\c"
			read auto_backup
			[[ $auto_backup != "y" && $auto_backup != "n" ]]
		do
			printf "${BOLD}${RED}Invalid option: ${auto_backup}\n${END}"
		done

		PROJECT_DIR="$PROJECTS/$name"
		mkdir -p "$PROJECT_DIR" 
		cd "$PROJECT_DIR"
		touch .config
		echo "$xml_path" > .config
		echo $auto_backup >> .config
		printf "${BOLD}${GREEN}\nProject ${name} created successfully\n${END}"
	elif [[ "$1" == "$OPTION_DELETE" ]]; then
		echo -e "$MSG_LIST $MSG_TO_DELETE\n"
		ls -A -1 "$PROJECTS"
		
		while
			echo -e "\n$MSG_CHOICE\c"
			read name
			[ ! -d "$PROJECTS/$name" ]
		do
			printf "${BOLD}${RED}No project named ${name} found.\n${END}"
		done

		while
			echo -e "\n$MSG_CONFIRM_DELETE $name (y/n): \c"
			read confirm
			[[ $confirm != "y" && $confirm != "n" ]]
		do
			printf "${BOLD}${RED}Invalid option: ${confirm}\n${END}"
		done
		if [ $confirm == "y" ]; then
			rm -rf "$PROJECTS/$name"
			printf "${BOLD}${GREEN}\nProject ${name} deleted successfully\n${END}"
		fi
	elif [[ "$1" == "$OPTION_OPEN" ]]; then
		echo -e "$MSG_LIST $MSG_TO_OPEN\n"
		ls -A -1 "$PROJECTS"

		while
			echo -e "\n$MSG_CHOICE\c"
			read name
			[ ! -d "$PROJECTS/$name" ]
		do
			printf "${BOLD}${RED}No project named ${name} found.\n${END}"
		done

		clear
		PROJECT_DIR="$PROJECTS/$name"
		cd "$PROJECT_DIR"
		xml=$(head -n1 .config)
		echo "XML to open: "$xml""
		if [ ! -f "$xml" ]; then
			printf "${BOLD}${RED}\nThe XML ${xml} does not exist. Edit the project config.\n${END}"
		fi
	fi
}


if [ -z "$TERMUX_VERSION" ]; then
	INTERNAL_STORAGE="$HOME"
else
	INTERNAL_STORAGE="$HOME/storage/shared"
fi

WORKDIR="$INTERNAL_STORAGE/XmlColorManager"
PROJECTS="$WORKDIR/projects"

if [ ! -d "$PROJECTS" ] || [ -z $(ls -A "$PROJECTS") ]; then
	display_menu 0
else
	display_menu 1
fi
