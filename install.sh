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

intro(){
	echo_red "You need to be root to execute install.sh"
	printf "\tThe only thing usage of sudo is installing puppet.\n"
	echo "Do you agree ? [y] to confirm"
	read confirm
	if [ $confirm != 'y' ]; then
		exit 1
	fi
}

exec_and_tab_output(){
	command=$1
	if [ $2 ]; then
		color=$2
	else
		color=NC
	fi
	echo "Executing command: ${command}"
	echo -e "${color}"
	${command} 2>&1 | awk '{print "\t"$0""}'
	command_exit_status=${PIPESTATUS[0]}
	echo -e "${NC}"
	return $((command_exit_status+0)) #converting string to int and returning it
}

main(){
	intro
	exec_and_tab_output "sudo yum -y install puppet" $BLUE
}

main

