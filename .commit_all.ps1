# One commit per file, as requested.
$ErrorActionPreference = 'Continue'
$root = $PWD.Path

$files = @()
git status --porcelain | Where-Object { $_ -notmatch '^\?\?' } | ForEach-Object {
    $code = $_.Substring(0, 2); $p = $_.Substring(3).Trim()
    if ($p -match ' -> ') { $p = ($p -split ' -> ')[-1] }
    $files += [pscustomobject]@{
        Path = ($p -replace '\\', '/')
        Kind = $(if ($code -match 'D') { 'delete' } else { 'update' })
    }
}
git status --porcelain | Where-Object { $_ -match '^\?\?' } | ForEach-Object {
    $p = $_.Substring(3).Trim()
    if (Test-Path $p -PathType Container) {
        Get-ChildItem $p -Recurse -File | ForEach-Object {
            $files += [pscustomobject]@{
                Path = ($_.FullName.Replace("$root\", "").Replace("\", "/"))
                Kind = 'add'
            }
        }
    }
    else {
        $files += [pscustomobject]@{ Path = ($p -replace '\\', '/'); Kind = 'add' }
    }
}

$files = $files | Sort-Object Path -Unique
$log = @()
$i = 0
foreach ($f in $files) {
    $i++
    if (-not (Test-Path $f.Path) -and $f.Kind -ne 'delete') {
        $log += "SKIP(missing) $($f.Path)"; continue
    }
    git add -A -- $f.Path 2>&1 | Out-Null
    $msg = switch ($f.Kind) {
        'add'    { "feat: add $($f.Path)" }
        'delete' { "refactor: remove $($f.Path)" }
        default  { "chore: update $($f.Path)" }
    }
    $out = git commit -m $msg 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Output "[$i/$($files.Count)] OK  $msg"
    }
    else {
        $log += "FAIL $msg :: $($out -join ' ')"
        Write-Output "[$i/$($files.Count)] FAIL $msg"
    }
}
Write-Output "=== DONE: $i processed ==="
if ($log.Count) {
    Write-Output "=== PROBLEMS ==="
    $log | ForEach-Object { Write-Output $_ }
}
