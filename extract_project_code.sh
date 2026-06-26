#!/usr/bin/env bash

# ===================================================================
# CONFIGURATION ET ARGUMENTS
# ===================================================================

# Vérifier si un argument a été fourni
if [[ -z "$1" ]]; then
  echo -e "\x1b[31mERREUR: Aucun dossier spécifié.\x1b[0m"
  echo "Usage: $0 <chemin_du_projet>"
  exit 1
fi

# Définition dynamique du projet (conversion en chemin absolu)
TargetDir="$1"
ProjectRoot=$(realpath "$TargetDir" 2>/dev/null || echo "$TargetDir")

# Nom du projet pour le fichier de sortie
ProjectName=$(basename "$ProjectRoot")

# Définissez le dossier où stocker les fichiers texte générés
OutputFolder="$HOME/projects"
OutputFile="$OutputFolder/${ProjectName}_codebase.txt"

# Vérification de l'existence du dossier source
if [[ ! -d "$ProjectRoot" ]]; then
  echo -e "\x1b[31mERREUR: Le dossier $ProjectRoot n'existe pas !\x1b[0m" >&2
  exit 1
fi

# Création du dossier de sortie s'il n'existe pas
mkdir -p "$OutputFolder"

# Création du fichier de sortie vide
: > "$OutputFile"

# --- LISTES D'EXCLUSION/INCLUSION ---

ExcludedFilesRelativePath=(
  "package-lock.json"
  ".env"
  "*.excalidraw.json"
  "uv.lock"
  "dump_*"
)

ExcludedDirectoryNames=(
  ".git" "bin" "obj" "docs" "compiled" "node_modules" "target" "package" "__pycache__" ".venv" "venv" "dist" "fixtures"
)

IncludedExtensions=(
  ".py" ".json" ".yaml" ".yml" ".md" ".html" ".css" ".tex" ".txt" ".sql" ".tf"
)

# ===================================================================
# FONCTION D'ARCHITECTURE
# ===================================================================

GetProjectArchitecture() {
  local RootPath="$1"
  local TreeExcludes=("${ExcludedDirectoryNames[@]}" "${ExcludedFilesRelativePath[@]}")

  {
    echo "==================================================="
    echo " ARCHITECTURE DU PROJET : $ProjectName"
    echo "==================================================="
    echo "$ProjectName/"
    echo "---------------------------------------------------"

    tree \
      -I "$(IFS='|'; echo "${TreeExcludes[*]}")" \
      --charset utf-8 \
      "$RootPath"

    echo "==================================================="
    echo
  } >> "$OutputFile"
}

# --- FONCTION DE VÉRIFICATION ---

ShouldProcessFile() {
  local File="$1"
  local RelPath="$2"
  local Ext

  Ext="${File##*.}"
  Ext=".${Ext,,}"

  for pattern in "${ExcludedFilesRelativePath[@]}"; do
    if [[ "$RelPath" == $pattern || "$RelPath" == */$pattern ]]; then
      echo "  Exclusion: $RelPath" >&2
      return 1
    fi
  done

  if [[ " ${IncludedExtensions[*]} " == *" $Ext "* ]]; then
    return 0
  fi

  return 1
}

# ===================================================================
# PROCESSUS PRINCIPAL
# ===================================================================

echo -e "\n=== ANALYSE DU PROJET : $ProjectName ===" \
  | sed -e 's/.*/\x1b[36m&\x1b[0m/'

echo -e "Cible: $ProjectRoot"
echo -e "Dossiers exclus: $(IFS=', '; echo "${ExcludedDirectoryNames[*]}")" \
  | sed -e 's/.*/\x1b[33m&\x1b[0m/'

# Étape 1 : Générer l'architecture
GetProjectArchitecture "$ProjectRoot"

echo -e "\n=== EXTRACTION DU CODE ===" \
  | sed -e 's/.*/\x1b[36m&\x1b[0m/'

FileCount=0

# Étape 2 : Parcourir et extraire les fichiers
while IFS= read -r -d '' File; do
  RelPath="${File#$ProjectRoot/}"

  if echo "$RelPath" | grep -qE "(^|/)($(IFS='|'; echo "${ExcludedDirectoryNames[*]}"))(/|$)"; then
    continue
  fi

  if ShouldProcessFile "$File" "$RelPath"; then
    ((FileCount++))
    echo -e "  Traitement: $RelPath" | sed -e 's/.*/\x1b[32m&\x1b[0m/'

    {
      echo -e "\n═══════════════════════════════════════════════════"
      echo "FICHIER: $RelPath"
      echo "═══════════════════════════════════════════════════"
      cat "$File" 2>/dev/null || echo "[ERREUR: Impossible de lire le fichier]"
      echo -e "═══════════════════════════════════════════════════\n"
    } >> "$OutputFile"
  fi
done < <(find "$ProjectRoot" -type f -not -path "*/\.*" -print0 | sort -z -V)

echo -e "\n=== TERMINÉ ===" \
  | sed -e 's/.*/\x1b[32m&\x1b[0m/'

echo -e "Fichiers traités : $FileCount"
echo -e "Fichier généré   : \x1b[36m$OutputFile\x1b[0m"
