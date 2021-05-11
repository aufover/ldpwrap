Name:    ldpwrap
Version: 1.0
Release: 1%{?dist}
Summary: Tool for running source code analyzers


License: BSD
Source0: %{name}.tar.gz

BuildRequires: gcc
Requires: csexec gllvm
Recommends: symbiotic divine

%description
ldpwrap contains a library and script that overrides the standard rpm build process and runs code analyzers during the check section of the build

%prep
pwd
rm -rf ldpwrap
mkdir ldpwrap
cp ../SOURCES/%name.tar.gz ./ldpwrap
cd ldpwrap
tar -xf %name.tar.gz
rm %name.tar.gz
cp ./* ../../BUILD

%build
#Possible macros are -DDEBUG and -DCSEXEC_PATH=/USR/BIN/CSEXEC
#If DEBUG is defined, debug messages are printed during the execution
#CSEXEC_PATH overrides the path to csexec
gcc $(MACROS) -shared -fPIC ./ldpreload_wrap.c -o ldpwrap.so -ldl


%install
mkdir -p $RPM_BUILD_ROOT/usr/lib64
mkdir -p $RPM_BUILD_ROOT/usr/bin
install -m 755 ldpwrap.so $RPM_BUILD_ROOT/usr/lib64/ldpwrap.so
install -m 755 ldp_run.sh $RPM_BUILD_ROOT/usr/bin/ldp_run

%files
/usr/lib64/*
/usr/bin/*
%doc



%changelog
* Wed May 12 2021 Jakub Martisko <jamartis@redhat.com> - 1.0-1
- Initial Release
