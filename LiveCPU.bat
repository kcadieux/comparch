pushd "%~dp0\CPUS\unpipelined_cpu\quartus"
start "" "modelsim.exe" -do "set topLevelDir \"[pwd]/..\"; source ../scripts/livecpulib.tcl; CompileCPU; InitCPU"
popd