pushd "%~dp0\quartus"
start "" "vsim.exe" -c -do "set topLevelDir \"[pwd]/..\"; source ../scripts/livecpulib.tcl; CompileCPU; InitCPU"
popd