pushd "%~dp0/quartus"
start "" "modelsim.exe" -do "set topLevelDir \"[pwd]/..\"; source ../scripts/livecpulib.tcl; CompileCPU; InitCPU"
popd