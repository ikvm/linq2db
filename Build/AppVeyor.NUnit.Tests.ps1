$wc = New-Object System.Net.WebClient

$net46Tests = {
	param($dir, $logFileName)
	Set-Location $dir
	$output = nunit3-console Tests\Linq\bin\AppVeyor\net46\linq2db.Tests.dll --result=$logFileName --where "cat != Ignored & cat != SkipCI"
	$result = "" | Select-Object -Property output,status
	$result.output = $output
	$result.status = $LastExitCode
	return $result
}

$netcore2Tests = {
	param($dir, $logFileName)
	Set-Location $dir
	$output = dotnet test Tests\Linq\ -f netcoreapp2.0 --logger "trx;LogFileName=$logFileName" --filter "TestCategory != Ignored & TestCategory != ActiveIssue & TestCategory != SkipCI" -c AppVeyor
	$result = "" | Select-Object -Property output,status
	$result.output = $output
	$result.status = $LastExitCode
	return $result
}

$netcore1Tests = {
	param($dir, $logFileName)
	Set-Location $dir
	$output = dotnet test Tests\Linq\ -f netcoreapp1.0 --logger "trx;LogFileName=$logFileName" --filter "TestCategory != Ignored & TestCategory != ActiveIssue & TestCategory != SkipCI" -c AppVeyor
	$result = "" | Select-Object -Property output,status
	$result.output = $output
	$result.status = $LastExitCode
	return $result
}

$logFileNameNet45 = "$env:APPVEYOR_BUILD_FOLDER\nunit_net46_results.xml"
$logFileNameCore2 = "$env:APPVEYOR_BUILD_FOLDER\nunit_core2_results.xml"
$logFileNameCore1 = "$env:APPVEYOR_BUILD_FOLDER\nunit_core1_results.xml"

$dir = Get-Location
Start-Job $net46Tests  -ArgumentList $dir,$logFileNameNet45
Start-Job $netcore2Tests  -ArgumentList $dir,$logFileNameCore2
Start-Job $netcore1Tests  -ArgumentList $dir,$logFileNameCore1

While (Get-Job -State "Running")
{
  Start-Sleep 1
}

$results = Get-Job | Receive-Job
Write-Host "WRITING TEST OUTPUT:"
$results | Foreach {$_.output} | Write-Host

Write-Host "UPLOADING LOGS:"
$url = "https://ci.appveyor.com/api/testresults/nunit3/$env:APPVEYOR_JOB_ID"
#$wc.UploadFile($url, $logFileNameNet45)
$wc.UploadFile($url, $logFileNameCore2)
$wc.UploadFile($url, $logFileNameCore1)

$exit = ($results | Foreach {$_.status} | Measure-Object -Sum).Sum

$host.SetShouldExit($exit)
