# =============================================================================
#  merge.ps1  –  Merge source files into one UTF-8 file for LLM upload
#
#  USAGE EXAMPLES
#    .\merge.ps1                              # scan current dir, write src.txt
#    .\merge.ps1 -StartDir .\MyProject        # custom root
#    .\merge.ps1 -OutputFile out.md -Format md
#    .\merge.ps1 -IncludeExt .asm,.inc,.ps1   # comma-separated string is fine
#    .\merge.ps1 -NoMeta                      # suppress per-file metadata
# =============================================================================

param(
    # Directory to scan (default: current working directory)
    [string]   $StartDir   = ".",

    # Output file path (relative paths anchored to CWD)
    [string]   $OutputFile = "src.txt",

    # Output format: plain text markers or Markdown fenced blocks
    [ValidateSet("txt", "md")]
    [string]   $Format     = "txt",

    # Suppress per-file Created / Modified / Size metadata lines
    [switch]   $NoMeta,

    # File extensions to include (leading dot, case-insensitive)
    [string[]] $IncludeExt = @(
        # Assembly / low-level
        ".asm", ".inc", ".s", ".nasm",
        # C / C++
        ".c", ".cpp", ".cc", ".cxx", ".h", ".hpp", ".hxx",
        # Pascal / Delphi
        ".pas", ".pp", ".dpr", ".dfm", ".lpr",
        # Web front-end
        ".html", ".htm", ".css", ".scss", ".sass", ".less",
        ".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx",
        # Scripting
        ".ps1", ".psm1", ".psd1", ".bat", ".cmd", ".sh",
        ".py", ".rb", ".pl", ".lua",
        # Data / config / markup
        ".xml", ".json", ".jsonc", ".yaml", ".yml",
        ".toml", ".ini", ".cfg", ".conf", ".env",
        # Windows-specific
        ".rc", ".def", ".manifest", ".lng", ".rgs",
        # Build / project
        ".vcxproj", ".filters", ".props", ".targets", ".sln",
        ".cmake", ".make", ".mk",
        # Docs
        ".md", ".txt", ".rst"
    ),

    # Regex patterns applied to the RELATIVE path (forward-slash-normalised).
    # Any file whose relative path matches at least one pattern is skipped.
    # NOTE: x64 / x86 / arm64 are NOT excluded – they usually hold source files.
    [string[]] $ExcludeDirPattern = @(
        "[/\\]\.git[/\\]",
        "[/\\]bin[/\\]",
        "[/\\]obj[/\\]",
        "[/\\]build[/\\]",
        "[/\\]out[/\\]",
        "[/\\]dist[/\\]",
        "[/\\]\.vs[/\\]",
        "[/\\]node_modules[/\\]",
        "[/\\]__pycache__[/\\]"
    )
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Test-PathExcluded {
    param(
        [string]   $RelativePath,
        [string[]] $Patterns
    )
    # Normalise separators so patterns work on both Windows and Unix
    $normalised = $RelativePath.Replace('\', '/')
    foreach ($pattern in $Patterns) {
        if ($normalised -match $pattern) { return $true }
    }
    return $false
}

# Map extension -> Markdown language identifier for fenced code blocks
function Get-FenceLanguage {
    param([string] $Extension)
    $map = @{
        ".asm"      = "asm"
        ".inc"      = "asm"
        ".s"        = "asm"
        ".nasm"     = "nasm"
        ".c"        = "c"
        ".cpp"      = "cpp"
        ".cc"       = "cpp"
        ".cxx"      = "cpp"
        ".h"        = "c"
        ".hpp"      = "cpp"
        ".hxx"      = "cpp"
        ".pas"      = "pascal"
        ".pp"       = "pascal"
        ".dpr"      = "pascal"
        ".dfm"      = "pascal"
        ".lpr"      = "pascal"
        ".html"     = "html"
        ".htm"      = "html"
        ".css"      = "css"
        ".scss"     = "scss"
        ".sass"     = "sass"
        ".less"     = "less"
        ".js"       = "javascript"
        ".mjs"      = "javascript"
        ".cjs"      = "javascript"
        ".ts"       = "typescript"
        ".tsx"      = "tsx"
        ".jsx"      = "jsx"
        ".ps1"      = "powershell"
        ".psm1"     = "powershell"
        ".psd1"     = "powershell"
        ".bat"      = "batch"
        ".cmd"      = "batch"
        ".sh"       = "bash"
        ".py"       = "python"
        ".rb"       = "ruby"
        ".pl"       = "perl"
        ".lua"      = "lua"
        ".xml"      = "xml"
        ".json"     = "json"
        ".jsonc"    = "jsonc"
        ".yaml"     = "yaml"
        ".yml"      = "yaml"
        ".toml"     = "toml"
        ".ini"      = "ini"
        ".cfg"      = "ini"
        ".conf"     = "ini"
        ".rc"       = "rc"
        ".def"      = "text"
        ".manifest" = "xml"
        ".rgs"      = "text"
        ".lng"      = "text"
        ".vcxproj"  = "xml"
        ".filters"  = "xml"
        ".props"    = "xml"
        ".targets"  = "xml"
        ".sln"      = "text"
        ".cmake"    = "cmake"
        ".make"     = "makefile"
        ".mk"       = "makefile"
        ".md"       = "markdown"
        ".rst"      = "rst"
        ".txt"      = "text"
    }
    $ext = $Extension.ToLowerInvariant()
    if ($map.ContainsKey($ext)) { return $map[$ext] }
    return "text"
}

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------

$baseDirPath = (Resolve-Path $StartDir).Path

$outputPath = if ([System.IO.Path]::IsPathRooted($OutputFile)) {
    $OutputFile
} else {
    Join-Path (Get-Location) $OutputFile
}

# Prevent the output file from being included in the scan
$outputPathNorm = $outputPath.ToLowerInvariant()

# ---------------------------------------------------------------------------
# Collect files
# ---------------------------------------------------------------------------

$normalizedExt = @($IncludeExt | ForEach-Object { $_.ToLowerInvariant() })

$files = Get-ChildItem -Path $baseDirPath -Recurse -File |
    Where-Object {
        # Extension filter
        if (-not ($normalizedExt -contains $_.Extension.ToLowerInvariant())) {
            return $false
        }
        # Skip the output file itself
        if ($_.FullName.ToLowerInvariant() -eq $outputPathNorm) {
            return $false
        }
        # Directory exclusion (relative path only – avoids false positives from
        # absolute path components like "C:\build\...")
        $rel = $_.FullName.Substring($baseDirPath.Length)
        if (Test-PathExcluded -RelativePath $rel -Patterns $ExcludeDirPattern) {
            return $false
        }
        return $true
    } |
    Sort-Object FullName

# ---------------------------------------------------------------------------
# Write output
# ---------------------------------------------------------------------------

$outputDir = Split-Path -Parent $outputPath
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$writer    = [System.IO.StreamWriter]::new($outputPath, $false, $utf8NoBom)

try {
    foreach ($file in $files) {
        $rel = $file.FullName.Substring($baseDirPath.Length).TrimStart('\', '/')
        # Normalise to forward slashes for portability
        $rel = $rel.Replace('\', '/')

        # --- File header ---
        if ($Format -eq "md") {
            $writer.WriteLine("## FILE: $rel")
        } else {
            $writer.WriteLine("<<<FILE: $rel>>>")
        }

        # --- Optional metadata ---
        if (-not $NoMeta) {
            $writer.WriteLine("Created:  $($file.CreationTime.ToString('yyyy-MM-dd HH:mm:ss'))")
            $writer.WriteLine("Modified: $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))")
            $writer.WriteLine("Size:     $([math]::Round($file.Length / 1KB, 2)) KB")
        }

        # --- Open fenced block (md mode) ---
        if ($Format -eq "md") {
            $lang = Get-FenceLanguage -Extension $file.Extension
            $writer.WriteLine("``````$lang")
        }

        # --- File content ---
        $reader = [System.IO.StreamReader]::new($file.FullName, $true)
        try {
            $content = $reader.ReadToEnd()
            $writer.Write($content)
            # Ensure content ends with a newline before the closing fence
            if ($content.Length -gt 0 -and -not ($content[-1] -eq "`n")) {
                $writer.WriteLine()
            }
        } finally {
            $reader.Dispose()
        }

        # --- Close fenced block (md mode) ---
        if ($Format -eq "md") {
            $writer.WriteLine("``````")
        }

        $writer.WriteLine()
    }
} finally {
    $writer.Dispose()
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

$outSize = [math]::Round((Get-Item $outputPath).Length / 1KB, 1)

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " merge.ps1 – done" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Root dir    : $baseDirPath"
Write-Host "  Output file : $outputPath  ($outSize KB)"
Write-Host "  Files merged: $($files.Count)"
Write-Host "  Format      : $Format"
Write-Host "  NoMeta      : $([bool]$NoMeta)"
Write-Host ""

# List extensions that were actually found
$foundExts = $files | ForEach-Object { $_.Extension.ToLowerInvariant() } |
    Sort-Object -Unique
Write-Host "  Extensions present:" -ForegroundColor Gray
foreach ($e in $foundExts) {
    $count = ($files | Where-Object { $_.Extension.ToLowerInvariant() -eq $e }).Count
    Write-Host ("    {0,-12} {1,3} file(s)" -f $e, $count) -ForegroundColor Gray
}
Write-Host ""