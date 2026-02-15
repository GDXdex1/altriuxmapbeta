# Distribución de Tierras (Land Logistics)

Análisis técnico de la geografía del mundo Altriux Tribal, basada en un mapa hexagonal de escala planetaria (~70,350 hexágonos de 100km²).

## 1. Estadísticas Globales de Terreno

Basado en la generación determinista (Seed 42), la distribución de los hexágonos "Large" (100km²) es la siguiente:

| Terreno | Cantidad (Hex) | Descripción |
| :--- | :--- | :--- |
| **Océano** | 48,788 | Masa de agua principal, inhabitable. |
| **Tundra** | 7,070 | Zonas polares y subpolares. |
| **Hielo** | 1,062 | Casquetes polares extremos (>88° Lat). |
| **Desierto** | 2,614 | Zonas áridas (Drantium y Brontium). |
| **Pradera (Meadow)** | 2,713 | Terreno fértil base para agricultura. |
| **Llanura (Plains)** | 2,084 | Áreas abiertas, ideales para expansión. |
| **Costa** | 3,174 | Transición tierra-mar, recursos pesqueros. |
| **Cordillera (Mountain Range)** | 1,535 | Cadenas montañosas en forma de C. |
| **Colinas (Hills)** | 1,310 | Terreno elevado, base para bosques/selvas. |

**Total de Tierras Emergidas**: ~21,500 hexágonos.

---

## 2. Características del Terreno (Features)

Las características son modificadores que existen **sobre** el terreno base, no definen el bioma por sí mismas.

| Característica | Cantidad | Terreno Base Permitido |
| :--- | :--- | :--- |
| **Bosque Boreal** | 1,418 | Tundra |
| **Selva (Jungle)** | 360 | Colinas (Solo Drantium) |
| **Bosque (Forest)** | 364 | Colinas (Solo Brontium) |
| **Oasis** | 251 | Desierto |
| **Volcán** | 190 | Cordillera |
| **Picos (Mountain)** | 16 | Tundra, Desierto, Hielo |

---

## 3. Logística de SubLands

Cada hexágono "Large" se divide de forma jerárquica:
- **Relación**: 1 Hex (100km²) = 10,000 SubLands (1km²).
- **Generación**: Los SubLands se generan bajo demanda (Lazy Minting).
- **ID del Sistema**: q, r relativos al centro del hexágono padre.

## 4. Biomas Agrícolas Reales
Para el sistema de agricultura (`altriuxland.move`), los biomas se consolidan en:
1. **Hielo** (Incultivable)
2. **Tundra** (Frío extremo, bonos a Avena/Centeno)
3. **Desierto** (Cultivable solo con Oasis/Riego)
4. **Llanura** (Base para Cereales)
5. **Colina** (Hills)
6. **Pradera** (Meadow)
7. **Cordillera** (Si pendiente < 25°)
8. **Costa**
9. **Océano**
