@echo off

SET TEST_NAME=%1%

IF "%TEST_NAME%"=="" (
	ECHO FAILURE: No test name was specified
	GOTO EXIT
)

pushd "%~dp0\..\quartus"
vsim.exe -c -do "set topLevelDir \"[pwd]/..\"; source ../scripts/livecpulib.tcl; RunTest %TEST_NAME%; quit"
popd


:EXIT