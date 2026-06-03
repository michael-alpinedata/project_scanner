#!/bin/bash

# --- CONFIGURATION ---
OUTPUT_FILE="export_contenu.md"
EXCLUDE_DIRS=(".venv" ".git" "node_modules" "__pycache__"  )
EXCLUDE_FILES=(".env" "$OUTPUT_FILE" "export_project.sh" "__init__" )
INCLUDE_EXTENSIONS=("py" "sh" "md" "txt" "json" "js")

# --- VÉRIFICATION DE TREE ---
if ! command -v tree &> /dev/null; then
    echo "--------------------------------------------------------"
    echo "Erreur : 'tree' n'est pas installé."
    echo "Pour l'installer, utilisez l'une des commandes suivantes :"
    echo "  - Debian/Ubuntu : sudo apt update && sudo apt install tree"
    echo "  - Fedora/CentOS : sudo dnf install tree"
    echo "  - Arch Linux    : sudo pacman -S tree"
    echo "  - macOS         : brew install tree"
    echo "--------------------------------------------------------"
    exit 1
fi

# --- GESTION DES ARGUMENTS ---
if [ -z "$1" ]; then
    echo "Usage: $0 <chemin_du_dossier>"
    exit 1
fi

TARGET_DIR=$(realpath "$1")

if [ ! -d "$TARGET_DIR" ]; then
    echo "Erreur : Le dossier '$TARGET_DIR' n'existe pas."
    exit 1
fi

# --- GÉNÉRATION DU FICHIER ---
echo "Extraction du dossier : $TARGET_DIR"
echo "# Architecture du projet : $TARGET_DIR" > "$OUTPUT_FILE"
echo '```text' >> "$OUTPUT_FILE"
tree -I "$(IFS='|'; echo "${EXCLUDE_DIRS[*]}")" "$TARGET_DIR" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo -e "\n---\n" >> "$OUTPUT_FILE"

# --- CONSTRUCTION DE LA COMMANDE FIND ---
find_args=("$TARGET_DIR")

# 1. On ignore les dossiers spécifiés dans EXCLUDE_DIRS
for dir in "${EXCLUDE_DIRS[@]}"; do
    find_args+=("-path" "*/$dir" "-prune" "-o")
done

# 2. On ignore TOUS les fichiers/dossiers commençant par un "."
find_args+=("-name" ".*" "-prune" "-o")

# 3. On ne garde que les fichiers (-type f)
find_args+=("-type" "f" "-print")

# --- PARCOURS ET EXTRACTION ---
find "${find_args[@]}" -print | while read -r filepath; do
    filename=$(basename "$filepath")
    
    # Vérification des fichiers exclus
    skip=false
    for ex in "${EXCLUDE_FILES[@]}"; do
        [[ "$filename" == "$ex" ]] && skip=true && break
    done
    [[ "$skip" == true ]] && continue

    # Vérification des extensions
    if [ ${#INCLUDE_EXTENSIONS[@]} -gt 0 ]; then
        ext="${filepath##*.}"
        [[ ! " ${INCLUDE_EXTENSIONS[*]} " =~ " $ext " ]] && continue
    fi

echo "## Fichier : ${filepath#$TARGET_DIR/}" >> "$OUTPUT_FILE"
    echo '```text' >> "$OUTPUT_FILE"
    cat "$filepath" >> "$OUTPUT_FILE"
    # Échappe bien les backticks ici avec un antislash devant chacun
    echo -e "\n\`\`\`\n" >> "$OUTPUT_FILE"
done