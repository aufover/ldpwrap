# ldpwrap
## Compilation
The packaging folder contains a make_srpm.sh script. Running this script will create a source rpm that can be build and installed in the standard way.

## Running the tool
The tool can be run by the /usr/bin/ldp_run script contained in the package.

## Divine
Currently needs ln -s /usr/lib64/LLVMgold.so /usr/lib/LLVMgold.so to run

## CBMC
Replace ``/bin/csexec-cbmc`` with [this csexec-cbmc](https://raw.githubusercontent.com/aufover/cbmc-utils/master/cbmc_utils/csexec-cbmc.sh) version.

```bash
git clone https://github.com/aufover/ldpwrap; cd ldwrap
cd packaging; ./make_srpm.sh
rpmbuild --rebuild ldpwrap-1.0-1.fc34.src.rpm
sudo dnf localinstall ~/rpmbuild/RPMS/x86_64/ldpwrap-1.0-1.fc34.x86_64.rpm
koji download-build -a src logrotate-3.18.0-3.fc34
# mkdir logs_file
/usr/bin/ldp_run --srpm=/logrotate-3.18.0-3.fc34.src.rpm --tool=cbmc --prp='--unwind 1 --pointer-check' --logdir=<logs_file> --timeout=10
```
