# Godot-4-Optimized-Arena-Demo

# 🏟️ Moral Scarcity
A high-performance, low-poly combat arena game built in **Godot 4**.

## 💡 The Vision
Make a career of gladiator in setting which combines post apocalypse, desert and ancient civillizaztions.
This project focuses on extreme optimization, targeting stable 60+ FPS runtime result on low-end mobile and PC devices.
Absolutely free for everyone and made for educational purposes. 
Also, you are free to use every part of this project as you wish.

**What we are planing to add:**
- Infinite gameplay
- Access to more arenas based on player's progression
- Turn based combat system including ranged and meele weapons of different types
- Random generation

---

## 🛠️ Technical Specifications
- **Engine:** Godot 4.x (Mobile Renderer)
- **Art Style:** Low-Poly, Flat Shaded, Solid Colors
- **Performance Target:** Less than 50 draw calls per frame, very low VRAM usage, 60+ FPS on low-end hardware
- **Optimization Tech:**
  - Mobile renderer instead of Forward+
  - MultiMeshInstance3D for identical objects
  - Solid color materials instead of textures
  - Low poly meshes
  - No real time shadows
  - No real time lighting

---

## 📦 What We Have?
- **Player Controller**
  - Player's movement in space(uncluding jumping and dash) based on keyboard inputs.
  - Player's and camera rotation based on keyboard & mouse inputs.
- **Shaders**
  - Efficient low poly 3D water with illumination immitation and animation controls(height of waves, how many frames in the animation) used on simple plane mesh.
  - 3D animated flag used on simple plane mesh(frequency,speed and color can be adjusted).
  - Very efficient fake lighting shader which gives almost the same effect as real time lighting but runs about 30% faster.
  - Efficient bricks shader for drawing bricks pattern on surfaces(brick/mortar size/color can be adjusted).
  - Very efficient black-transparent gradient shader. We use it to immitate void without the need to physically create empty dark space which leads to better performance.
- **Assets**
  -  Low poly 3D assets(humans, clothing, vehicles, structures, nature, items)
  -  Stylized animations
  -  Textures

---

## 👥 The Team
| Member | Role | GitHub |
| :--- | :--- | :--- |
| **Vlad** | Project Lead / Lead Dev | [@dinazaber](https://github.com/dinazaber) |
| **Yuli** | Dev 2 / Marketing Lead | no github |
| **Konstantin** | Dev 3 / Algorithms Developer  | no github |

---

## 📅 Roadmap For The Next Few Months
- [x] Basic Player Controller
- [x] Art Style
- [x] Light Immitation Shader & A Few More Shaders
- [x] Basic Arena Environment
- [ ] AI Enemy logic & Combat System
- [ ] First Arena Location Design & Realization
