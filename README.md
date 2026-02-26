# Godot-4-Optimized-Arena-Demo

# 🏟️ Moral Scarcity
A high-performance, low-poly combat arena game built in **Godot 4**.

![Moral Scarcity Demo](media/aiopl7.gif)

## 💡 The Vision
Our project is inspired by classic shooters(especially Doom and Duke Nukem 3D).
The game is devided into unique levels that represent unique locations.
Like in classic shooters, you will encounter enemies(melee and ranged) on each level.
Each level will contain secret locations inside that the player can try to discover(it may be supply stashes or easter eggs).
We want to combine the retro style of classic shooters with the abilities of modern hardware by adding features that those games were lack of.
This project focuses on extreme optimization, targeting very high frame rate on low-end mobile and PC devices.
Absolutely free for everyone and made for educational purposes. 
Also, you are free to use every part of this project as you wish as it is under **MIT LICENSE**.

**What we are planning to add:**
- Interesting Locations that the player would like to discover
- Advanced AI relatively to the one in classic shooters
- Differnt playable weapons, from cold to launchers
- Modern technologies(physical simulation and more)

---

## 🛠️ Technical Specifications
- **Engine:** Godot 4.x (Mobile Renderer)
- **Art Style:** Low-Poly, Flat-Shaded, Pixelated Textures
- **Performance Target:** Less than 50 draw calls per frame, very low VRAM usage, 60+ FPS on low-end hardware
- **Optimization Tech:**
  - Mobile renderer instead of Forward+
  - MultiMeshInstance3D for identical objects
  - Low Resolution Textures
  - Low-poly meshes
  - No real-time shadows
  - No real-time lighting
  - Optimized Algorithms

---

## 👥 The Team
| Member | Role | GitHub |
| :--- | :--- | :--- |
| **Vlad** | Project Lead / Lead Dev / Assets Creator | [@dinazaber](https://github.com/dinazaber) |
| **Yuli** | Dev 2 / Marketing Lead | N/A |
| **Konstantin** | Dev 3 / Algorithms Developer / Assets Creator  | N/A |
| **Shimon** | Dev 4 / Algorithms Developer  | N/A |

---

## 📅 Roadmap For The Next Few Months
- [x] Basic Player Controller
- [x] Art Style
- [x] Main Shaders
- [x] AI Enemy Path Finding
- [ ] Full AI Enemy logic
- [ ] First Level Design & Implementation
- [ ] Basic Interface & Main Menu

---

## 🧱 Used In This Project
- **MultiMesh Scatter**
  - GitHub Link: https://github.com/arcaneenergy/godot-multimesh-scatter
- **MetaMultimeshInstance3D**
  - Godot Asset Library Link: https://godotengine.org/asset-library/asset/2043
