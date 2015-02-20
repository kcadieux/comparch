pushd "%~dp0\quartus"
start "" "vsim.exe" -c -do "set topLevelDir \"[pwd]/..\"; source ../scripts/modelsim_integration.tcl;"
popd