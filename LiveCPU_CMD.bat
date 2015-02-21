pushd "%~dp0\CPUS\unpipelined_cpu\quartus"
start "" "vsim.exe" -c -do "set topLevelDir \"[pwd]/..\"; source ../scripts/livecpulib.tcl; CompileCPU; InitCPU"
popd