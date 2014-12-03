#main starts at the end of file

RED='\e[0;31m'
BLUE='\e[0;34m'
NC='\e[0m' # No Color

echo_red(){
	echo -e "${RED}$1${NC}"
}

echo_blue(){
	echo -e "${BLUE}$1${NC}"
}

sudo_warning(){
	sudo_commands=$@
	echo_red "You need to be root to execute install.sh"

	echo -e "\tThe only usage of sudo are:"
	print_tabs_on_next_iteration=1
	for command in $sudo_commands
	do
		if [ $print_tabs_on_next_iteration -eq 1 ]; then
			printf "\t\t"
			print_tabs_on_next_iteration=0
		fi
		printf " $command"
		if [[ $command =~ \;$ ]]; then
			printf "\n"
			print_tabs_on_next_iteration=1
		fi
	done

	echo "Do you agree ? [y] to confirm"
	read confirm
	if [ $confirm != 'y' ]; then
		exit 1
	fi
}

exec_with_blue_color(){
	echo -e ${BLUE}
	exec_and_tab_output $1
	echo -e ${NC}
}

exec_and_tab_output_and_color_blue(){
	command=$@
	
	echo -e "${NC}Executing command: ${command}${NC}"
	echo -e "${BLUE}"

	${command} 2>&1 | awk '{print "\t"$0""}'
	command_exit_status=${PIPESTATUS[0]}

	echo -e "${NC}"
	return $((command_exit_status+0)) #converting string to int and returning it
}

main(){
	package=("puppet.noarch")
	command_install_puppet="sudo yum -y install ${package[@]};"

	sudo_warning $command_install_puppet
	exec_and_tab_output_and_color_blue $command_install_puppet

	echo "${package[@]} installed. To know it's location, execute: \$rpm -ql ${package[@]}"
}

main

