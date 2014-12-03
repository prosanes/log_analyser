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
    : ${PUPPET_PATH:='/etc/puppet/'}

	pushd $PUPPET_PATH
	echo `pwd`
	puppet_modules="elasticsearch-logstash elasticsearch-elasticsearch puppetlabs-stdlib ispavailability-file_concat"
	for module in $puppet_modules; do
		puppet module install --force $module
	done
	popd
}

main $@
