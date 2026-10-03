#Requires -Version 5.1

# ===================================================================
# CONFIGURATION ET ARGUMENTS
# ===================================================================

param(
    [Parameter(Position = 0)]
    [string]$TargetDir
)

if ([string]::IsNullOrWhiteSpace($TargetDir)) {
    Write-Host "ERREUR: Aucun dossier spécifié." -ForegroundColor Red
    Write-Host "Usage: scan-project <chemin_du_projet>"
    exit 1
}

try {
    $ProjectRoot = (Resolve-Path -LiteralPath $TargetDir -ErrorAction Stop).Path
}
catch {
    $ProjectRoot = $TargetDir
}

$ProjectName = Split-Path -Leaf $ProjectRoot.TrimEnd('\', '/')
$OutputFolder = Join-Path $HOME "projects"
$OutputFile = Join-Path $OutputFolder "${ProjectName}_codebase.txt"

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    Write-Host "ERREUR: Le dossier $ProjectRoot n'existe pas !" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
Set-Content -LiteralPath $OutputFile -Value "" -Encoding UTF8


# ===================================================================
# LISTES D'EXCLUSION/INCLUSION
# ===================================================================

$ExcludedFilesRelativePath = @(
    "package-lock.json"
    ".env"
    "*.excalidraw.json"
    "uv.lock"
    "dump_*"
)

$ExcludedDirectoryNames = @(
    ".git"
    "bin"
    "obj"
    "docs"
    "compiled"
    "node_modules"
    "coverage"
    "target"
    "package"
    "__pycache__"
    ".venv"
    "venv"
    "dist"
    "fixtures"
)

$IncludedExtensions = @(
    ".py"
    ".ipynb"
    ".ts"
    ".tsx"
    ".json"
    ".yaml"
    ".yml"
    ".md"
    ".html"
    ".css"
    ".tex"
    ".txt"
    ".sql"
    ".tf"
)


# ===================================================================
# FONCTION D'ARCHITECTURE
# ===================================================================

function Get-ProjectArchitecture {
    param(
        [string]$RootPath
    )

    Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value @"
===================================================
 ARCHITECTURE DU PROJET : $ProjectName
===================================================
$ProjectName/
---------------------------------------------------
"@

    function Write-Tree {
        param(
            [string]$Path,
            [string]$Prefix = ""
        )

        $RawItems = Get-ChildItem -LiteralPath $Path -Force
        $Filtered1 = $RawItems | Where-Object { $ExcludedDirectoryNames -notcontains $_.Name -and -not ($_.PSIsContainer -and $_.Name.StartsWith(".")) }
        
        $Filtered2 = foreach ($item in $Filtered1) {
            $ShouldExclude = $false
            foreach ($Pattern in $ExcludedFilesRelativePath) {
                if ($item.Name -like $Pattern) {
                    $ShouldExclude = $true
                    break
                }
            }
            if (-not $ShouldExclude) { $item }
        }

        if ($null -ne $Filtered2) {
            $Items = $Filtered2 | Sort-Object @{ Expression = { -not $_.PSIsContainer } }, Name
        } else {
            $Items = @()
        }

        for ($i = 0; $i -lt $Items.Count; $i++) {

            $Item = $Items[$i]
            $IsLast = ($i -eq ($Items.Count - 1))

            if ($IsLast) {
                $Branch = "\-- "
                $NextPrefix = "$Prefix    "
            }
            else {
                $Branch = "|-- "
                $NextPrefix = "$Prefix|   "
            }

            Add-Content -LiteralPath $OutputFile -Value "$Prefix$Branch$($Item.Name)" -Encoding UTF8

            if ($Item.PSIsContainer) {
                Write-Tree -Path $Item.FullName -Prefix $NextPrefix
            }
        }
    }

    Write-Tree -Path $RootPath

    Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value @"
===================================================

"@
}


# ===================================================================
# FONCTION DE VÉRIFICATION
# ===================================================================

function Test-ProcessFile {
    param(
        [string]$File,
        [string]$RelPath
    )

    foreach ($Pattern in $ExcludedFilesRelativePath) {
        $FileName = Split-Path -Leaf $RelPath
        if ($FileName -like $Pattern) {
            Write-Host "  Exclusion: $RelPath" -ForegroundColor DarkGray
            return $false
        }
    }

    $Extension = [System.IO.Path]::GetExtension($File).ToLowerInvariant()

    if ($IncludedExtensions -contains $Extension) {
        return $true
    }

    return $false
}


# ===================================================================
# PROCESSUS PRINCIPAL
# ===================================================================

Write-Host ""
Write-Host "=== ANALYSE DU PROJET : $ProjectName ===" -ForegroundColor Cyan
Write-Host "Cible: $ProjectRoot"
Write-Host "Dossiers exclus: $($ExcludedDirectoryNames -join ', ')" -ForegroundColor Yellow

Get-ProjectArchitecture -RootPath $ProjectRoot

Write-Host ""
Write-Host "=== EXTRACTION DU CODE ===" -ForegroundColor Cyan

$FileCount = 0

$RawFiles = Get-ChildItem -LiteralPath $ProjectRoot -File -Recurse -Force -ErrorAction SilentlyContinue
if ($null -ne $RawFiles) {
    $Files = $RawFiles | Sort-Object FullName
} else {
    $Files = @()
}

foreach ($File in $Files) {

    $RelPath = $File.FullName.Substring($ProjectRoot.TrimEnd('\').Length).TrimStart('\', '/')

    $PathParts = $RelPath -split '[\\/]'
    $ExcludedDirectory = $false

    foreach ($DirectoryName in $ExcludedDirectoryNames) {
        if ($PathParts -contains $DirectoryName) {
            $ExcludedDirectory = $true
            break
        }
    }

    if ($ExcludedDirectory) {
        continue
    }

    $HasHidden = $false
    foreach ($part in $PathParts) {
        if ($part -like ".*") {
            $HasHidden = $true
            break
        }
    }
    if ($HasHidden) {
        continue
    }

    if (Test-ProcessFile -File $File.FullName -RelPath $RelPath) {

        $FileCount++
        Write-Host "  Traitement: $RelPath" -ForegroundColor Green

        Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value ""
        Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value "═══════════════════════════════════════════════════"
        Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value "FICHIER: $RelPath"
        Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value "═══════════════════════════════════════════════════"

        try {
            $Content = Get-Content -LiteralPath $File.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            Add-Content -LiteralPath $OutputFile -Value $Content -Encoding UTF8
        }
        catch {
            Add-Content -LiteralPath $OutputFile -Value "[ERREUR: Impossible de lire le fichier]" -Encoding UTF8
        }

        Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value "═══════════════════════════════════════════════════"
        Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value ""
    }
}

Write-Host ""
Write-Host "=== TERMINÉ ===" -ForegroundColor Green
Write-Host "Fichiers traités : $FileCount"
Write-Host "Fichier généré   : " -NoNewline
Write-Host $OutputFile -ForegroundColor Cyan