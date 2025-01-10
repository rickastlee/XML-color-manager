#!/bin/bash

BOLD="\e[1m"
RED="\e[91m"
GREEN="\e[92m"
END="\e[0m"

OPTION_CREATE="Create a new project"
OPTION_OPEN="Open an existing project"
OPTION_QUIT="Quit"

MSG_CHOOSE="Choose one of the options below"
MSG_CONFIG="Enter some details below"
MSG_CHOICE="Choice: "

INPUT_NAME="Name: "
INPUT_XML_PATH="XML path: "
INPUT_AUTO_BACKUP="Automatic backups (y/n): "

PROJECT_NAME_REGEX='^[a-zA-Z0-9\ ._-]{4,64}$'
NOT_NUMBER='[^0-9]'

# $1 bool at least one available project
display_menu () {
	echo -e "\n$MSG_CHOOSE\n"
	OPTIONS="$OPTION_CREATE"
	if [ $1 -eq 1 ]; then
		OPTIONS="$OPTIONS,$OPTION_OPEN"
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
    
    echo "${array[$c]}"
    #run_command "${array[$c]}"
}

run_command()
{
	if [[ "$1" == "$OPTION_QUIT" ]]; then
	    exit 0
	elif [[ "$1" == "$OPTION_CREATE" ]]; then
	    echo -e "\n$MSG_CONFIG\n"
	    
		while
			echo -e "$INPUT_NAME\c"
			read name
		! [[ "$name" =~ $PROJECT_NAME_REGEX ]]
		do
			echo -e "Invalid name\n"
		done
	    
	    while
	   	 valid=1
	    	echo -e "$INPUT_XML_PATH\c"
	        read xml_path
	        
	        if [ ! -e $xml_path ]; then
	        	valid=0
	        	printf "${BOLD}${RED}The path "$xml_path" does not exist\n\n${END}"
	        elif [ ! -f $xml_path ]; then
	        	valid=0
	        	printf "${BOLD}${RED}The path "$xml_path" is not a file\n\n${END}"
	        elif [[ "$xml_path" != *.xml ]]; then
	        	valid=0
				printf "${BOLD}${RED}The file "$xml_path" is not an XML\n\n${END}"
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
	fi
}


if [ -z "$TERMUX_VERSION" ]; then
	INTERNAL_STORAGE="$HOME"
else
	INTERNAL_STORAGE="$HOME/storage/shared"
fi

WORKDIR="$INTERNAL_STORAGE/XmlColorManager"
PROJECTS="$WORKDIR/projects"

if [ -d $PROJECTS ]; then
	display_menu 1
else
    display_menu 0
fi
