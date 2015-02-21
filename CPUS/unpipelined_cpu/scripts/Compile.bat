@echo off

pushd "%~dp0\..\quartus"
vsim.exe -c -do "set topLevelDir \"[pwd]/..\"; source ../scripts/livecpulib.tcl; CompileCPU; quit"
popd


:EXIT