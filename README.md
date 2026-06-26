# Extract Project Code

Ce script Bash permet d'extraire de manière robuste l'arborescence et le contenu textuel des fichiers d'un projet dans un unique fichier texte bien structuré. Il est idéal pour préparer du contexte technique de qualité à destination des modèles de langage (LLMs).

## 🚀 Fonctionnalités

* **Arborescence claire** : Intègre une vue globale du projet générée avec `tree`.
* **Centralisation des exports** : Génère automatiquement les fichiers de sortie dans un dossier centralisé (`$HOME/projects/`).
* **Tri naturel** : Les fichiers sont listés et concaténés par ordre alphabétique logique (grâce à `sort -V`).
* **Exclusions et inclusions robustes** :
  * Ignore intelligemment les dossiers lourds ou inutiles (`node_modules`, `.venv`, `.git`, `dist`, etc.).
  * Filtre strictement par extensions (`.py`, `.json`, `.tf`, `.md`, etc.) de manière insensible à la casse.
* **Sécurité & Espaces** : Gère parfaitement les fichiers contenant des espaces ou des caractères spéciaux dans leur nom (via `-print0`).
* **UX Terminal** : Interface en ligne de commande colorée et claire pour suivre l'avancement de l'extraction.

## 📋 Prérequis

* Avoir `tree` installé sur votre système.
  * *Ubuntu/Debian* : `sudo apt install tree`
  * *macOS* : `brew install tree`

## 🛠 Installation

1. Enregistrez le script sous le nom **`extract_project_code.sh`**.
2. Rendez-le exécutable :
```bash
chmod +x extract_project_code.sh

```

## 💡 Utilisation

Lancez le script en passant le chemin du dossier que vous souhaitez analyser en argument (chemin relatif ou absolu) :

```bash
./extract_project_code.sh /chemin/vers/votre/projet

```

### Emplacement de sortie

Le script va automatiquement créer un fichier nommé **`[NomDuProjet]_codebase.txt`** dans le dossier **`~/projects/`**.

## ⚙️ Configuration

Vous pouvez personnaliser le comportement directement dans le script en modifiant les listes d'exclusion et d'inclusion :

* `OutputFolder` : Le dossier où seront centralisés vos exports (par défaut `$HOME/projects`).
* `ExcludedDirectoryNames` : Les dossiers à ignorer complètement lors du parcours.
* `ExcludedFilesRelativePath` : Fichiers spécifiques ou patterns globbing à exclure (ex: `package-lock.json`, `dump_*`).
* `IncludedExtensions` : Seules les extensions présentes dans cette liste seront extraites.

## 📝 Structure du fichier généré

Le fichier texte de sortie est structuré de la manière suivante :

1. **Architecture du Projet** : Une section délimitée affichant le rendu de la commande `tree`.
2. **Contenu des Fichiers** : Pour chaque fichier valide trouvé, un bloc visuel clair contenant le chemin relatif suivi de son contenu textuel brut.

---

*Développé pour optimiser et automatiser l'injection de contexte technique.*

