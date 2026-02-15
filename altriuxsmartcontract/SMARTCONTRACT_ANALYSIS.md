# Altriux Smart Contract Analysis

**Generated:** 2026-02-06T23:20:00.000Z  
**Framework:** Sui Move  
**Version:** 0.0.1  
**Address:** 0x0  

## 📋 Overview

Altriux es un juego de estrategia blockchain construido en Sui Move que simula un mundo tribal con recursos, edificios y mecánicas de producción. El contrato implementa un sistema económico completo con múltiples tipos de recursos y edificios culturales.

## 🏗️ Arquitectura del Contrato

### Módulos Principales

| Módulo | Propósito | Elementos Clave |
|---------|-----------|----------------|
| `altriux_resources` | Gestión de inventario y recursos | 214 tipos de recursos, sistema JAX |
| `altriux_buildings` | Sistema de edificios NFT | 6 culturas, 100+ tipos de edificios |
| `altriux_production` | Refinamiento y acuñación | 3 tipos de monedas, sistema de pérdidas |
| `altriux_land` | Gestión de terrenos hexagonales | 12,000 hexágonos, 6 biomas |
| `altriux_mining` | Sistema de minería | Extracción de minerales brutos |
| `altriux_animal` | Gestión de animales | Cría y reproducción |
| `altriux_coin` | Sistema monetario | GDX, SLX, BZC tokens |
| `altriux_utils` | Utilidades compartidas | Tiempo de juego, randomización |
| `atx_coin` | Token adicional | Mecánicas especiales |

## 💰 Sistema Económico

### Monedas (Tokens)

| Token | Propósito | Respaldo | Ratio de Acuñación |
|--------|-----------|------------|-------------------|
| **GDX** | Moneda principal | 20g oro refinado | 1 GDX = 20g oro |
| **SLX** | Moneda plateada | 18.5g plata + 1.5g cobre | 1 SLX = 20g mezcla |
| **BZC** | Moneda de bronce | 1g plata + 19g bronce | 1 BZC = 20g mezcla |

### Recursos JAX (214 tipos)

#### 🌾 Alimentos y Semillas (1-114)
- **Granos básicos:** Trigo, maíz, arroz, cebada, sorgo, mijo, avena, centeno
- **Tubérculos:** Papa, batata, yuca, ñame
- **Legumbres:** Soja, maní, frijol común, garbanzo, lenteja, arveja
- **Semillas oleaginosas:** Girasol, ajonjolí, sésamo, lino, cáñamo
- **Cultivos industriales:** Caña de azúcar, remolacha, algodón
- **Frutas:** Tomate, pimiento, chile, cebolla, ajo, zanahoria
- **Frutales:** Manzana, pera, durazno, plátano, plátano macho
- **Frutas tropicales:** Naranja, mango, papaya, piña, aguacate, coco
- **Frutos secos:** Aceituna, dátil, uva, almendra, nuez
- **Especias:** Cacao, café, vainilla
- **Forrajes:** Trébol, pasto raygrass, festuca, alfalfa

#### ⛏️ Materiales Primas (115-214)
- **Minerales brutos:** Hierro, estaño, cobre, oro, plata, plomo, zinc, níquel, cobalto
- **Metales refinados:** Hierro forjado, bronce, acero, latón
- **Metales preciosos:** Oro refinado, plata refinada, hierro fundido, cobre refinado
- **Maderas:** Primera, segunda, tronco premium, estándar, alto
- **Productos madereros:** Tablón ancho/segundo, viga larga, carbón
- **Maderas procesadas:** Leña seca, astillas, virutas, tablas, vigas
- **Textiles brutos:** Algodón sin hilar, lino sin hilar, cáñamo sin hilar
- **Productos animales:** Lana sin hilar, seda sin hilar, estopas segundas
- **Hilos:** Algodón, lino, cáñamo, lana, seda, varios tipos teñidos
- **Telas:** Lana, lino, cáñamo, algodón, cachemira, seda, alpaca
- **Materiales de construcción:** Caliza, arenisca, granito, mármol, arcilla
- **Materiales industriales:** Ladrillos, cemento crudo, arena, grava
- **Químicos:** Sal mineral, azufre, petróleo crudo
- **Derivados:** Brea de petróleo, brea vegetal, tanino
- **Materiales animales:** Grasas, sebo, cera de abeja

## 🏛️ Sistema de Edificios

### Culturas Disponibles (6 tipos)
1. **Common** - Edificios genéricos
2. **Hindu** - Arquitectura hindú
3. **Islamic** - Arquitectura islámica
4. **Christian** - Arquitectura cristiana
5. **Mesoamerican** - Arquitectura mesoamericana
6. **Tibetan** - Arquitectura tibetana
7. **Scandinavian** - Arquitectura escandinava

### Sistema de Construcción
- **Costos:** Madera primaria + piedra caliza (escalable por tamaño)
- **Tamaños:** Fracciones de hexágono (25=1/4, 50=1/2, 100=1, 200=2)
- **Producción:** Diaria después de 24 horas
- **Niveles:** Sistema de mejoras de edificios

## 🗺️ Sistema de Terrenos

### Especificaciones del Mapa
- **Total hexágonos:** 12,000
- **Subterrenos por hexágono:** 2,500 (central reservado)
- **Biomas (6 tipos):**
  1. **Desierto** - Plantación de palmeras datileras, yuca
  2. **Tundra** - Cultivo de centeno, papas
  3. **Llanura** - Trigo, maíz
  4. **Pradera** - Trébol, pasto raygrass
  5. **Montaña** - Alfalfa, cáñamo
  6. **Colina** - Cebada, avenas

### Sistema Agrícola
- **Validación de semillas:** Por bioma específico
- **Rendimiento:** Base + randomización (trigo: 40-65 Jax)
- **Cosecha:** Con expiración de 90 días
- **Plantación:** Consumo de semillas del inventario

## ⚒️ Sistema de Producción

### Refinamiento de Minerales
| Mineral | ID Bruto | ID Refinado | Pérdida |
|---------|------------|---------------|----------|
| Oro | 118 | 128 | 10% |
| Plata | 119 | 129 | 10% |
| Hierro | 115 | 124 | 80% |
| Cobre | 117 | 131 | 70% |

### Proceso de Acuñación
1. **Consumo de recursos refinados** del inventario
2. **Verificación de cantidades** requeridas por tipo de moneda
3. **Acuñación** mediante treasury caps
4. **Transferencia** al jugador solicitante

## 🎮 Mecánicas de Juego

### Sistema de Tiempo
- **Unidad de tiempo:** Segundos del mundo real
- **Producción:** Requiere 24 horas entre ciclos
- **Expiración:** Recursos perecederos con fechas límite

### Sistema de Inventario
- **Estructura:** Bag con type_id → cantidad
- **Capacidad:** Ilimitada por tipo de recurso
- **Expiración:** Table opcional por recurso
- **Propietario:** Address del jugador

### Eventos del Sistema
- **BuildingCreated:** Emisión al construir edificios
- **Producción:** Ciclos diarios registrados
- **Transacciones:** Movimientos de recursos

## 🔧 Características Técnicas

### Optimizaciones Implementadas
- **Bag/Table:** Estructuras eficientes para inventarios
- **Constants:** IDs predefinidos para consistencia
- **Modularidad:** Separación clara de responsabilidades
- **Eventos:** Trazabilidad de acciones importantes

### Seguridad y Validaciones
- **Assertions:** Verificación de condiciones críticas
- **Ownership:** Control estricto de propietarios
- **Expiración:** Prevención de exploits temporales
- **Type Safety:** Sistema de tipos fuerte de Move

## 📈 Análisis de Economía

### Balance de Recursos
- **Total recursos:** 214 tipos diferentes
- **Recursos perecederos:** Sistema de expiración
- **Recursos duraderos:** Materiales de construcción
- **Recursos monetarios:** 3 tipos de tokens

### Flujo Económico
1. **Extracción** → Recursos brutos (minería)
2. **Procesamiento** → Recursos refinados (producción)
3. **Fabricación** → Bienes finales (edificios)
4. **Acuñación** → Moneda (tesorería)
5. **Comercio** → Intercambio entre jugadores

## 🎯 Estrategias de Juego

### Especialización por Bioma
- **Desierto:** Palmeras datileras, cultivos resistentes
- **Tundra:** Cultivos de clima frío, minería
- **Llanura:** Granos básicos, agricultura intensiva
- **Pradera:** Ganadería, forrajes
- **Montaña:** Minería, maderas preciosas
- **Colina:** Cultivos de altura, cantería

### Optimización de Producción
- **Edificios culturales:** Bonificaciones por cultura
- **Tamaño óptimo:** Balance costo/beneficio
- **Ciclos continuos:** Coordinación de producción
- **Almacenamiento:** Gestión de expiración

## 🚀 Recomendaciones de Desarrollo

### Mejoras Inmediatas
1. **Interfaz gráfica** para gestión de inventarios
2. **Mercado descentralizado** para comercio P2P
3. **Sistema de misiones** con recompensas
4. **Integración con mapa** hexagonal existente

### Expansiones Futuras
1. **Sistema de alianzas** entre jugadores
2. **Guerras y conquista** de territorios
3. **Tecnología y investigación** de mejoras
4. **Eventos dinámicos** del mundo

## 📊 Métricas del Contrato

### Complejidad
- **Líneas de código:** ~15,000 líneas totales
- **Módulos:** 9 módulos especializados
- **Recursos:** 214 tipos únicos
- **Edificios:** 100+ tipos con 6 culturas

### Eficiencia
- **Gas optimization:** Uso eficiente de estructuras
- **Storage:** Organización por tipo y uso
- **Updates:** Sistema de modificaciones controlado
- **Events:** Trazabilidad sin sobrecarga

## 🎖️ Conclusión

Altriux implementa un sistema económico tribal completo y sofisticado en blockchain Sui. Con 214 tipos de recursos, 6 culturas arquitectónicas, y un sistema monetario de 3 tokens, ofrece una experiencia de juego estratégico profunda con mecánicas realistas de producción y comercio.

La arquitectura modular permite fácil expansión y el uso de Sui Move asegura seguridad y rendimiento óptimos para un juego de esta escala.
