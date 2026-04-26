# Assets — Images locales

Ce dossier contient les images embarquées dans l'application Flutter
(déclarées dans `pubspec.yaml` sous la section `flutter > assets`).

## Images attendues

| Nom du fichier            | Utilisé par                       | Description                                |
|---------------------------|-----------------------------------|--------------------------------------------|
| `connexion_jungle.jpg`    | `lib/ecran_connexion.dart`        | Bandeau visuel "Bienvenue" en haut de l'écran de connexion. Photo de jungle / fougères. |

## Ajouter une nouvelle image

1. Dépose le fichier dans ce dossier (`assets/images/`).
2. Le pattern `assets/images/` est déjà déclaré dans `pubspec.yaml`, donc tous
   les fichiers de ce dossier sont automatiquement embarqués — pas besoin de
   lister chaque fichier individuellement.
3. Lance `flutter pub get` puis fais un `flutter run` complet (pas un hot
   reload) pour que le bundle Flutter prenne en compte le nouvel asset.
4. Utilise-la dans le code Dart :
   ```dart
   const Image(image: AssetImage('assets/images/mon_fichier.jpg'))
   ```

## Conseils

- Privilégie le format `.jpg` pour les photos (poids plus léger) et `.png`
  pour les illustrations / logos avec transparence.
- Garde la taille en dessous de 1 Mo par image pour ne pas alourdir l'APK.
- Si une image refuse de s'afficher : vérifie que le **chemin exact**
  dans `AssetImage('...')` correspond au fichier sur disque (sensible à la
  casse sur certains systèmes).
