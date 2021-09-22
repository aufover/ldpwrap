# ldpwrap
## Compilation
The packaging folder contains a make_srpm.sh script. Running this script will create a source rpm that can be build and installed in the standard way.
```bash
git clone https://github.com/aufover/ldpwrap; cd ldwrap # get ldpwrap
cd packaging; ./make_srpm.sh # make source rpm package
rpmbuild --rebuild ldpwrap*.src.rpm # make rpm package
sudo dnf localinstall ~/rpmbuild/RPMS/x86_64/ldpwrap*.rpm # install it
```

## Running the tool
The tool can be run by the /usr/bin/ldp_run script contained in the package.

## Divine
Currently needs ln -s /usr/lib64/LLVMgold.so /usr/lib/LLVMgold.so to run

## CBMC
An example of usage of [cbmc](https://github.com/diffblue/cbmc) and ldpwrapper:
```bash
koji download-build -a src logrotate-3.18.0-3.fc34 # get package which you want to analyze, in this example the logrotate package is used
# run cbmc analysis on choosed package:
/usr/bin/ldp_run --srpm=/logrotate-3.18.0-3.fc34.src.rpm --tool=cbmc --prp='--unwind 1 --pointer-check' --logdir=<logs_file> --max-time=10
```
