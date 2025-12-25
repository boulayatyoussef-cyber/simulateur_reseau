# 🌐 OCaml Network Simulator (Projet Gamifié)

Un simulateur de réseau performant et robuste développé en **OCaml**. Ce projet modélise des topologies complexes, calcule des routes optimales via l'algorithme de **Dijkstra**, et simule la propagation de paquets avec gestion de la **latence**, du **TTL** et des **pannes aléatoires**.

---

## 🚀 Fonctionnalités Clés

- **Topologie Réaliste** : Nœuds et liens bidirectionnels avec latence (ticks) et fiabilité (%).
- **Intelligence de Routage** : Implémentation de **Dijkstra** pour trouver le chemin le plus court en temps réel.
- **Simulation à Temps Discret** : Système de `ticks` pour suivre le mouvement des paquets.
- **Gestion des Imprévus** : Simulation de coupures de câbles (Link Failure) et pertes de données.
- **Système de Jeu** : Score, budget de transmission et bonus de livraison.
- **Interface CLI Colorée** : Feedback visuel immédiat dans le terminal (Vert/Rouge/Bleu).

---

## 🛠️ Architecture du Code (Mon Empreinte)

Le projet est structuré de manière modulaire :
* **Modélisation** : Utilisation de `Records` pour les paquets, nœuds et liens.
* **Stockage** : Utilisation de `Hashtbl` pour un accès en $O(1)$ aux tables de routage.
* **Algorithmie** : Dijkstra avec récursion pour reconstruire les chemins optimaux.
* **Moteur** : Boucle de simulation gérant l'état du réseau à chaque unité de temps.

---

## 📥 Installation & Compilation (Ubuntu)

### 1. Prérequis
Assurez-vous d'avoir OCaml installé :
```bash
sudo apt update && sudo apt install ocaml
