# Script d'Export de Projet (Project Export Script)

Ce script Bash permet d'extraire rapidement l'arborescence et le contenu textuel de tous les fichiers d'un répertoire dans un seul fichier Markdown (`.md`). Il est conçu pour faciliter le partage de bases de code avec des modèles de langage (LLM) ou pour archiver une documentation technique.

## 🚀 Fonctionnalités

* **Arborescence automatique** : Génère une vue d'ensemble du projet (style `tree`).
* **Exclusions intelligentes** : Ignore par défaut les dossiers sensibles (`.venv`, `.git`, `__pycache__`) et les fichiers inutiles (`.env`).
* **Filtrage par extension** : Permet de ne scanner que les fichiers pertinents (ex: `.py`, `.sh`, `.json`).
* **Flexibilité** : Accepte les chemins relatifs ou absolus en argument.

## 📋 Prérequis

* Avoir `tree` installé sur votre système.
* *Ubuntu/Debian* : `sudo apt install tree`
* *macOS* : `brew install tree`



## 🛠 Installation

1. Copiez le script dans un fichier nommé `export_project.sh`.
2. Donnez-lui les droits d'exécution :
```bash

```



chmod +x export_project.sh

```

## 💡 Utilisation
Lancez le script en passant le dossier que vous souhaitez analyser en argument :

```bash
./export_project.sh /chemin/vers/votre/projet

```

Le script générera un fichier nommé **`export_contenu.md`** dans le répertoire courant.

## ⚙️ Configuration

Vous pouvez modifier directement les variables au début du script pour l'adapter à vos besoins :

* `EXCLUDE_DIRS` : Liste des répertoires à ignorer.
* `EXCLUDE_FILES` : Liste des noms de fichiers spécifiques à ignorer.
* `INCLUDE_EXTENSIONS` : Liste des extensions de fichiers à inclure (laissez vide pour tout inclure).

## 📝 Exemple de structure du fichier généré

Le fichier `.md` de sortie est formaté comme suit :

1. **En-tête** : Titre du projet et arborescence.
2. **Contenu** : Pour chaque fichier, un titre (chemin relatif) suivi du contenu dans un bloc de code.

---

*Développé pour automatiser la préparation de contexte technique.*

---