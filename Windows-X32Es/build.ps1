$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

if (-not (Test-Path -LiteralPath 'build')) {
    New-Item -ItemType Directory -Path 'build' | Out-Null
}

& dlltool -m i386 '--as-flags=--32' -k -d compiler\kernel32.def -l build\libkernel32.a
if ($LASTEXITCODE -ne 0) {
    Write-Output ('dlltool failed (exit ' + $LASTEXITCODE + ')')
    exit 1
}

$sources = @(Get-ChildItem -LiteralPath 'compiler' -Filter '*.asm' -File | Sort-Object Name)
$objs = @()
foreach ($src in $sources) {
    $obj = Join-Path 'build' ($src.BaseName + '.obj')
    & nasm -f win32 -I compiler/inc/ -o $obj ('compiler\' + $src.Name)
    if ($LASTEXITCODE -ne 0) {
        Write-Output ('nasm failed on ' + $src.Name + ' (exit ' + $LASTEXITCODE + ')')
        exit 1
    }
    $objs += $obj
}

& ld -m i386pe -s -e start --subsystem console -o ender.exe @objs build\libkernel32.a
if ($LASTEXITCODE -ne 0) {
    Write-Output ('ld link failed (exit ' + $LASTEXITCODE + ')')
    exit 1
}

Write-Output 'built ender.exe'
exit 0
