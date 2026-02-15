# Análisis de Capacidades Máximas de Recursos (Mina y Fauna)

Este documento detalla las capacidades y reservas máximas programadas en el contrato inteligente para los distintos tipos de minas y recursos naturales del mundo Altriux.

## 1. Minería (Mina de Galena)

Actualmente, el sistema de minería está centrado en la **Galena (PbS)**, que es la fuente principal de Plomo y Plata en el juego.

| Tipo de Mina | Recurso Principal | Reserva Máxima (JAX) | Notas |
| :--- | :--- | :--- | :--- |
| **Mina de Galena** | Galena (Plomo/Plata) | **16,851,851,852** | Única fuente de PbS con 0.3% Ag. |

> [!NOTE]
> Aunque existen otros minerales definidos en el contrato (`altriuxminerals.move`), como Hierro, Cobre y Oro, sus reservas globales y mecanismos de "spawn" específicos no están reflejados como constantes globales en el módulo de minería actual, sugiriendo que su distribución podría ser dinámica o estar en fase de implementación.

## 2. Fauna Silvestre (Poblaciones Máximas)

El contrato de animales salvajes (`altriuxwildanimal.move`) define límites estrictos de población para diversas especies, lo que regula la sostenibilidad de la caza.

| Especie | Población Máxima (Individuos) | Notas |
| :--- | :--- | :--- |
| **Pato Real** | 100,000,000 | Mayor población del sistema. |
| **Conejo Salvaje** | 50,000,000 | |
| **Jabalí** | 20,000,000 | |
| **Caballo Salvaje** | 10,000,000 | |
| **Gallo Bankiva** | 10,000,000 | |
| **Ganso Salvaje** | 10,000,000 | |
| **Cabra Montés** | 6,000,000 | |
| **Muflón** | 4,000,000 | |
| **Gato Montés** | 4,000,000 | |
| **Vicuña** | 3,000,000 | |
| **Búfalo** | 2,000,000 | |
| **Lobo** | 2,000,000 | |
| **Guanaco** | 2,000,000 | |
| **Cebú Salvaje** | 2,000,000 | |
| **Asno Salvaje** | 1,500,000 | |
| **Uro** | 1,000,000 | |
| **Camello Salvaje** | 1,000,000 | |
| **Chacal** | 1,000,000 | |
| **Elefante Salvaje** | 500,000 | |
| **Yak Salvaje** | 400,000 | Menor población del sistema. |

## 3. Bosques (Gestión de Área)

Los bosques no tienen una "reserva" fija de JAX global, sino que se gestionan por unidades de área.

| Tipo de Bosque | Densidad (Árboles/Ha) | Área NFT Estándar |
| :--- | :--- | :--- |
| **Templado** | 600 | 100 Ha |
| **Tropical (Selva)** | 500 | 100 Ha |
| **Boreal (Taiga)** | 1,000 | 100 Ha |

---
**Análisis final:** La Galena es el único mineral con una reserva finita y masiva programada directamente como una constante de contrato para control de escasez. La fauna está altamente diversificada con límites de población que van desde los 400 mil hasta los 100 millones de individuos.
