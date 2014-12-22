#main is called at the end of this file

parse_arguments() {
	ARGS=$(getopt -o p: -l "puppet-path:" -n "getopt.sh" -- "$@");

	#Bad arguments
	if [ $? -ne 0 ]; then
		exit 1
	fi

	eval set -- "$ARGS";

	while true; do
		echo $1
		case "$1" in
			-p|--puppet-path)
            shift;
            if [ -n "$1" ]; then
                PUPPET_PATH=$1
                shift;
            fi
			;;
			--)
			shift;
			break;
			;;
		esac
	done

	if [ ${#@} -lt 0 ] ; then
		echo "Wrong number of arguments"
	fi

	REMAINING_ARGS="$@"
}

main() {
    parse_arguments "$@" # Pass 1: this first time it is used to retrieve simple values
    : ${PUPPET_PATH:='/etc/puppet'}
    : ${PUPPET_FILE:='Puppetfile'}

	#install_puppet_modules $PUPPET_PATH "./puppet_modules.txt"
	pushd $PUPPET_PATH
		rm -f ./Puppetfile
		librarian-puppet init
	popd
	cp $PUPPET_FILE $PUPPET_PATH/Puppetfile
	pushd $PUPPET_PATH
		librarian-puppet install --verbose
	popd
	#move_files_to_module_dir $PUPPET_PATH
	rsync -r files/ $PUPPET_PATH/modules/
}

main $@
