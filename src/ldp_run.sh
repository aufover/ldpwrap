#!/bin/bash

#Copyright (c) 2020, Red Hat, Inc.
#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are met:
#
#1. Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#2. Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#3. Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.




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
      -m=NUM|--max-time=NUN                                        Sets the tool timeout to NUM seconds, default value is 30
      -l=DIR|--logdir=DIR                                          Specifies the directory, where the test results will be stored, default value is /tmp

The -s -t and and for symbiotic -p options must be specified
EOF
}

if [ -z "$TOOL" ] || [ -z "$SRPM" ]
then
    help
    exit 1
fi



case $TOOL in
    symbiotic)
        set -o xtrace
	if [ -z "$PRP" ]
	then
   		help
   		exit 1
	fi
	COMPILERS="CC=gclang CXX=gclang++  CFLAGS='-g -Wno-unused-parameter -Wno-unknown-attributes -Wno-unused-label -Wno-unknown-pragmas -Wno-unused-command-line-argument -O0 -Xclang -disable-llvm-passes -D__inline='"
	RPMBUILD_DEFINES="--define \"__cc gclang\" --define \"__cxx gclang++\" --define \"toolchain clang\" --define \"__spec_check_pre export LD_PRELOAD=/usr/lib64/ldpwrap.so %{___build_pre}\""
        
	WRAP_CMD=$'--skip-ld-linux\acsexec-symbiotic\a-l\a'"$LOGDIR"$'\a-s\a--prp='"$PRP\ --timeout=$TIMEOUT"
        bash -c "$COMPILERS CSEXEC_WRAP_CMD=$WRAP_CMD rpmbuild $RPMBUILD_DEFINES -ri $SRPM"
        ;;
    divine)
	COMPILERS="CC=dioscc CXX=diosc++  CFLAGS='-g -Wno-unused-parameter -Wno-unknown-attributes -Wno-unused-label -Wno-unknown-pragmas -Wno-unused-command-line-argument -O0"
	RPMBUILD_DEFINES="--define \"__cc dioscc\" --define \"__cxx diosc++\" --define \"__spec_check_pre export LD_PRELOAD=/usr/lib64/ldpwrap.so %{___build_pre}\""
        
	WRAP_CMD=$'--skip-ld-linux\acsexec-divine\a-l\a'"$LOGDIR"$'\a-d\acheck\a\ --max-time\ $TIMEOUT"'
        bash -c "$COMPILERS CSEXEC_WRAP_CMD=$WRAP_CMD rpmbuild $RPMBUILD_DEFINES -ri $SRPM"
        ;;
    *)
        help
        exit 1
        ;;
esac

