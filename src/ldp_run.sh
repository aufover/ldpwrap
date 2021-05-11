#!/bin/bash
COMPILERS="CC=gclang CXX=gclang++  CFLAGS='-g -Wno-unused-parameter -Wno-unknown-attributes -Wno-unused-label -Wno-unknown-pragmas -Wno-unused-command-line-argument -O0 -Xclang -disable-llvm-passes -D__inline=
'"
RPMBUILD_DEFINES="--define \"__cc gclang\" --define \"__cxx gclang++\" --define \"toolchain clang\" --define \"__spec_check_pre export LD_PRELOAD=/usr/lib64/ldpwrap.so %{___build_pre}\""



# Symbiotic
# bash -c "CC=$(CC) CXX=$(C++) CFLAGS='$(CFLAGS)' CSEXEC_WRAP_CMD=$$'--skip-ld-linux\acsexec-symbiotic\a-s\a--prp=memsafety --timeout=30' rpmbuild --define \"__cc gclang\" --define \"__cxx gclang++\" --define \"toolchain clang\" --define \"__spec_check_pre export LD_PRELOAD=/tmp/ldpreload_wrap.so %{___build_pre}\" -ri $(PATH_TO_SRPM)"


TOOL=
PRP=
TIMEOUT=30
LOGDIR="/tmp"
SRPM=


for i in "$@"
do
case $i in
    -s=*|--srpm=*)
    SRPM="${i#*=}"
    shift # past argument=value
    ;;
    -t=*|--tool=*)
    TOOL="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--prp=*)
    PRP="${i#*=}"
    shift # past argument=value
    ;;
    -w=*|--watchdog=*)
    TIMEOUT="${i#*=}"
    shift # past argument=value
    ;;
    -l=*|--logdir=*)
    LOGDIR="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

function help (){
cat <<EOF
Usage: ldp_run OPTS

where OPTS can be following:
      -s=ARG|--srpm=ARG                                            ARG specifies the path to the tested source rpm
      -t={symbiotic,divine,cbmc}|--tool={symbiotic,divine,cbmc}    Specifies which tool shall be used, the initial version supports only symbiotic.
      -p=ARG|--prp=ARG                                             ARG specifies which property shall be tested, the possible values are the same as the one accepted by the tool (e.g. --prp OPT for symbiotic)
      -w=NUM|--watchdog=NUN                                        Sets the tool timeout to NUM seconds, default value is 30
      -l=DIR|--logdir=DIR                                          Specifies the directory, where the test results will be stored, default value is /tmp

The -s -t and -p options must be specified
EOF
}

if [ -z "$TOOL" ] || [ -z "$PRP"] || [ -z "$SRPM" ]
then
    help
    exit 1
fi



case $TOOL in
    symbiotic)
        set -o xtrace
        WRAP_CMD=$'--skip-ld-linux\acsexec-symbiotic\a-l\a'"$LOGDIR"$'\a-s\a--prp='"$PRP\ --timeout=$TIMEOUT"
        bash -c "$COMPILERS CSEXEC_WRAP_CMD=$WRAP_CMD rpmbuild $RPMBUILD_DEFINES -ri $SRPM"
        ;;
    *)
        help
        exit 1
        ;;
esac

