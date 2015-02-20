pushd "%~dp0/quartus"
start "" "modelsim.exe" -do "set topLevelDir \"[pwd]/..\"; source ../scripts/modelsim_integration.tcl;"
popd