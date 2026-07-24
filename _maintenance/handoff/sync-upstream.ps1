# Run the portable maintenance workflow from PowerShell.
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& node (Join-Path $scriptDir "sync-upstream.mjs") @args
exit $LASTEXITCODE
