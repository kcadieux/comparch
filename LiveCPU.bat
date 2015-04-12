setlocal 

SET TEST_NAME=%1%
SET COMMAND=InitCPU

IF NOT "%TEST_NAME%"=="" (
	SET COMMAND=RunTest %1%
)

pushd "%~dp0\CPUS\cpu\quartus"
start "" "modelsim.exe" -do "set topLevelDir \"[pwd]/..\"; source ../scripts/livecpulib.tcl; CompileCPU; %COMMAND%"
popd

endlocal