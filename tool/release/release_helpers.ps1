function Get-CompatibleSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath
    )

    $resolvedPath = [IO.Path]::GetFullPath($LiteralPath)
    if (-not [IO.File]::Exists($resolvedPath)) {
        throw "Cannot calculate SHA-256 because the file does not exist: $resolvedPath"
    }
    $getFileHash = Get-Command Get-FileHash -CommandType Cmdlet -ErrorAction SilentlyContinue
    if ($getFileHash -and $getFileHash.ModuleName -eq "Microsoft.PowerShell.Utility") {
        try {
            return (& $getFileHash -Algorithm SHA256 -LiteralPath $resolvedPath).Hash.ToLowerInvariant()
        } catch {
            Write-Verbose "Get-FileHash failed; using the .NET SHA-256 fallback."
        }
    }

    $stream = [IO.File]::Open(
        $resolvedPath,
        [IO.FileMode]::Open,
        [IO.FileAccess]::Read,
        [IO.FileShare]::Read
    )
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $sha256.ComputeHash($stream)
        return ([BitConverter]::ToString($bytes)).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha256.Dispose()
        $stream.Dispose()
    }
}
