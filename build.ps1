param(
    [ValidateSet('x64', 'x86', 'arm64')]
    [string]$Arch = 'x64'
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$src = Join-Path 'windows' $Arch
$out = Join-Path 'build' ('windows-' + $Arch)
New-Item -ItemType Directory -Force -Path $out | Out-Null

$imports = @(
    @('GetCommandLineA', 0), @('GetStdHandle', 4), @('WriteFile', 20), @('ReadFile', 20),
    @('CreateFileA', 28), @('GetFileSizeEx', 8), @('CloseHandle', 4), @('ExitProcess', 4),
    @('CreateProcessA', 40), @('WaitForSingleObject', 8), @('GetExitCodeProcess', 8),
    @('CreateDirectoryA', 8), @('VirtualAlloc', 16), @('DeleteFileA', 4)
)

function Stop-Build([string]$What) {
    Write-Output ($What + ' failed (exit ' + $LASTEXITCODE + ')')
    exit 1
}

function Write-Def([bool]$Decorated) {
    $lines = @('LIBRARY kernel32.dll', 'EXPORTS')
    foreach ($i in $imports) {
        if ($Decorated) { $lines += ($i[0] + '@' + $i[1]) } else { $lines += $i[0] }
    }
    $def = Join-Path $out 'kernel32.def'
    Set-Content -LiteralPath $def -Value $lines -Encoding ascii
    return $def
}

$exe = Join-Path $out 'ender.exe'
$lib = Join-Path $out 'libkernel32.a'
$objs = @()

if ($Arch -eq 'arm64') {
    $llvm = 'C:\Program Files\LLVM\bin'
    if (Test-Path -LiteralPath $llvm) { $env:Path = $llvm + ';' + $env:Path }
    $def = Write-Def $false
    & llvm-dlltool -m arm64 -d $def -l $lib
    if ($LASTEXITCODE -ne 0) { Stop-Build 'llvm-dlltool' }
    foreach ($f in Get-ChildItem -LiteralPath $src -Filter '*.S' -File | Sort-Object Name) {
        $obj = Join-Path $out ($f.BaseName + '.o')
        & clang --target=aarch64-w64-mingw32 -DTARGET_WINDOWS -c $f.FullName -o $obj
        if ($LASTEXITCODE -ne 0) { Stop-Build ('clang on ' + $f.Name) }
        $objs += $obj
    }
    & lld-link -nologo -entry:start -subsystem:console -nodefaultlib ('-out:' + $exe) @objs $lib
    if ($LASTEXITCODE -ne 0) { Stop-Build 'lld-link' }
} else {
    $fmt = 'win64'
    if ($Arch -eq 'x86') { $fmt = 'win32' }
    $inc = (Join-Path $src 'inc') + '/'
    foreach ($f in Get-ChildItem -LiteralPath $src -Filter '*.asm' -File | Sort-Object Name) {
        $obj = Join-Path $out ($f.BaseName + '.obj')
        & nasm -f $fmt -I $inc -o $obj $f.FullName
        if ($LASTEXITCODE -ne 0) { Stop-Build ('nasm on ' + $f.Name) }
        $objs += $obj
    }
    if ($Arch -eq 'x86') {
        $def = Write-Def $true
        & dlltool -m i386 '--as-flags=--32' -k -d $def -l $lib
        if ($LASTEXITCODE -ne 0) { Stop-Build 'dlltool' }
        & ld -m i386pe -s -e start --subsystem console -o $exe @objs $lib
        if ($LASTEXITCODE -ne 0) { Stop-Build 'ld' }
    } else {
        & gcc -nostdlib -nostartfiles -s '-Wl,-e,start' '-Wl,--subsystem,console' -o $exe @objs -lkernel32
        if ($LASTEXITCODE -ne 0) { Stop-Build 'gcc' }
    }
}

Write-Output ('built ' + $exe)
exit 0
