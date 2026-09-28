#Requires -Version 5.1

# ===================================================================
# CONFIGURATION ET ARGUMENTS
# ===================================================================

# Vérifier si un argument a été fourni
param(
    [Parameter(Position = 0)]
    [string]$TargetDir
)

if ([string]::IsNullOrWhiteSpace($TargetDir)) {
    Write-Host "ERREUR: Aucun dossier spécifié." -ForegroundColor Red
    Write-Host "Usage: .\export-codebase.ps1 <chemin_du_projet>"
    exit 1
}

# Définition dynamique du projet (conversion en chemin absolu)
try {
    $ProjectRoot = (Resolve-Path -LiteralPath $TargetDir -ErrorAction Stop).Path
}
catch {
    # On conserve le chemin fourni afin de pouvoir afficher une erreur
    $ProjectRoot = $TargetDir
}

# Nom du projet pour le fichier de sortie
$ProjectName = Split-Path -Leaf $ProjectRoot.TrimEnd('\', '/')

# Définissez le dossier où stocker les fichiers texte générés
$OutputFolder = Join-Path $HOME "projects"
$OutputFile = Join-Path $OutputFolder "${ProjectName}_codebase.txt"

# Vérification de l'existence du dossier source
if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    Write-Host "ERREUR: Le dossier $ProjectRoot n'existe pas !" -ForegroundColor Red
    exit 1
}

# Création du dossier de sortie s'il n'existe pas
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

# Création du fichier de sortie vide
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

    # Recherche de la commande tree Windows
    $TreeCommand = Get-Command tree.exe -ErrorAction SilentlyContinue

    if ($null -ne $TreeCommand) {

        # La commande tree.exe Windows ne possède pas l'équivalent
        # direct de l'option -I de la version Unix.
        #
        # On génère donc nous-mêmes l'arborescence filtrée.

        function Write-Tree {
            param(
                [string]$Path,
                [string]$Prefix = ""
            )

            $Items = Get-ChildItem -LiteralPath $Path -Force |
                Where-Object {
                    $ExcludedDirectoryNames -notcontains $_.Name -and
                    -not ($_.PSIsContainer -and $_.Name.StartsWith("."))
                } |
                Where-Object {
                    $ShouldExclude = $false

                    foreach ($Pattern in $ExcludedFilesRelativePath) {
                        if ($_.Name -like $Pattern) {
                            $ShouldExclude = $true
                            break
                        }
                    }

                    -not $ShouldExclude
                } |
                Sort-Object @{ Expression = { -not $_.PSIsContainer } }, Name

            for ($i = 0; $i -lt $Items.Count; $i++) {

                $Item = $Items[$i]
                $IsLast = ($i -eq $Items.Count - 1)

                if ($IsLast) {
                    $Branch = "\-- "
                    $NextPrefix = "$Prefix    "
                }
                else {
                    $Branch = "|-- "
                    $NextPrefix = "$Prefix|   "
                }

                Add-Content -LiteralPath $OutputFile `
                    -Value "$Prefix$Branch$($Item.Name)" `
                    -Encoding UTF8

                if ($Item.PSIsContainer) {
                    Write-Tree -Path $Item.FullName -Prefix $NextPrefix
                }
            }
        }

        Write-Tree -Path $RootPath
    }
    else {
        Add-Content -LiteralPath $OutputFile `
            -Value "[ERREUR: Impossible de générer l'arborescence]" `
            -Encoding UTF8
    }

    Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value @"
===================================================

"@
}


# ===================================================================
# FONCTION DE VÉRIFICATION
# ===================================================================

function Should-ProcessFile {
    param(
        [string]$File,
        [string]$RelPath
    )

    # Vérification des fichiers exclus
    foreach ($Pattern in $ExcludedFilesRelativePath) {

        $FileName = Split-Path -Leaf $RelPath

        if ($FileName -like $Pattern) {
            Write-Host "  Exclusion: $RelPath" -ForegroundColor DarkGray
            return $false
        }
    }

    # Vérification de l'extension
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


# ===================================================================
# ÉTAPE 1 : GÉNÉRER L'ARCHITECTURE
# ===================================================================

Get-ProjectArchitecture -RootPath $ProjectRoot


# ===================================================================
# ÉTAPE 2 : EXTRACTION DU CODE
# ===================================================================

Write-Host ""
Write-Host "=== EXTRACTION DU CODE ===" -ForegroundColor Cyan

$FileCount = 0

# Récupération récursive des fichiers
$Files = Get-ChildItem `
    -LiteralPath $ProjectRoot `
    -File `
    -Recurse `
    -Force `
    -ErrorAction SilentlyContinue |
    Sort-Object FullName

foreach ($File in $Files) {

    # Chemin relatif par rapport à la racine du projet
    $RelPath = $File.FullName.Substring(
        $ProjectRoot.TrimEnd('\').Length
    ).TrimStart('\', '/')

    # ---------------------------------------------------------------
    # Exclusion des dossiers
    # ---------------------------------------------------------------

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

    # Exclusion des fichiers/dossiers cachés commençant par "."
    if ($PathParts | Where-Object { $_ -like ".*" }) {
        continue
    }

    # ---------------------------------------------------------------
    # Vérification du fichier
    # ---------------------------------------------------------------

    if (Should-ProcessFile -File $File.FullName -RelPath $RelPath) {

        $FileCount++

        Write-Host "  Traitement: $RelPath" -ForegroundColor Green

        # -----------------------------------------------------------
        # Ajout du contenu au fichier de sortie
        # -----------------------------------------------------------

        Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value ""

        Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value `
            "═══════════════════════════════════════════════════"

        Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value `
            "FICHIER: $RelPath"

        Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value `
            "═══════════════════════════════════════════════════"

        try {

            # Lecture du fichier avec UTF-8
            $Content = Get-Content `
                -LiteralPath $File.FullName `
                -Raw `
                -Encoding UTF8 `
                -ErrorAction Stop

            Add-Content `
                -LiteralPath $OutputFile `
                -Value $Content `
                -Encoding UTF8

        }
        catch {

            Add-Content `
                -LiteralPath $OutputFile `
                -Value "[ERREUR: Impossible de lire le fichier]" `
                -Encoding UTF8
        }

        Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value `
            "═══════════════════════════════════════════════════"

        Add-Content -LiteralPath $OutputFile -Encoding UTF8 -Value ""
    }
}


# ===================================================================
# FIN
# ===================================================================

Write-Host ""
Write-Host "=== TERMINÉ ===" -ForegroundColor Green

Write-Host "Fichiers traités : $FileCount"

Write-Host "Fichier généré   : " -NoNewline
Write-Host $OutputFile -ForegroundColor Cyan