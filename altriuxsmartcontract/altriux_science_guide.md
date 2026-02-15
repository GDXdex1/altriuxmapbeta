# Guía del Currículo Académico de Altriux (Semestres)

El sistema de ciencias de Altriux está organizado en un currículo de **6 semestres**, cada uno compuesto por un bloque de **7 materias** (6 científicas/filosóficas y 1 militar).

## Estructura de Progresión
Para avanzar en el currículo, se deben respetar las prelaciones lineales (ej. Matemática 1 -> Matemática 2) y las de bloque.

### Semestre 1: Estudios Básicos
- **Estudios Generales 1**: Base para todas las demás ciencias.
- **Materia Temática**: Agroestudio 1, Matemáticas 1, Astronomía 1, Materiales 1, Teología 1.
- **Militar**: Ciencia Militar 1.

### Semestre 2: Fundamentos
- **Estudios Generales 2**: Requiere EG 1.
- **Materias Temáticas**: Matemática 2, Agroestudio 2, Astronomía 2, Materiales 2.
- **Filosofía 2**: Requiere EG 2 y Teología 1.
- **Militar**: Ciencia Militar 2 (Requiere Mil 1).

### Semestre 3: Ciencias Aplicadas
- **Estudios Generales 3**: Requiere EG 2.
- **Materias**: Matemática 3, Astronomía 3.
- **Física 1**: Requiere Matemática 1.
- **Química 1**: Requiere Materiales 1.
- **Construcción 1**: Requiere Materiales 2.
- **Militar**: Ciencia Militar 3.

### Semestre 4: Ingeniería y Cartografía
- **Estudios Generales 4**: Requiere EG 3.
- **Materias**: Física 2 (Pre: Física 1 y Math 2), Química 2, Construcción 2.
- **Cartografía 1**: Requiere Astronomía 2.
- **Filosofía Aplicada**: Requiere Filosofía 2.
- **Militar**: Ciencia Militar 4.

### Semestre 5: Especialización Superior
- **Física 3**: Requiere Física 2 y Math 3.
- **Ingeniería**: Hidráulica 1, Metalurgia 1.
- **Sociedad**: Medicina 1, Moneda 1.
- **Arquitectura**: Requiere Construcción 2, Física 3 y EG 4.
- **Militar**: Ciencia Militar 5.

### Semestre 6: Maestría y Estrategia
- **Construcción 3**: Requiere Construcción 2, Física 3 y EG 4.
- **Arquitectura de Buques**: Requiere Arquitectura.
- **Especialidades**: Mecánica de Suelos, Medicina 2, Filosofía Política 1.
- **Gran Estrategia**: Requiere Ciencia Militar 5.
- **Militar**: Ciencia Militar 6.

## 4. Unidades de Medida: El JIX
En Altriux, todas las magnitudes físicas se miden en **JIX**. Un JIX es la unidad estándar que unifica peso y volumen:
- **Peso (Masa)**: 1 JIX equivale a **20 Kilogramos**.
- **Volumen**: 1 JIX equivale a **20 Litros**.

Esta unidad se aplica a todos los sistemas: el peso de los libros, la capacidad de los barcos y las reservas de las minas se expresan siempre en **JIX**.

## 5. Sistema Económico y Acuñación (La Ceca)
La economía de Altriux se basa en minerales preciosos y su transformación en moneda circulante.

### Reservas Mineras
- **Plata**: Existen **100 minas** de Plata, cada una con una reserva intrínseca de **22,000,000 JIX**. Generan Plata y Plomo (en ratio galena).
- **Oro**: Existen **30 minas** de Oro, cada una con **330,000 JIX** de reserva.
- **Hierro y Cobre**: Distribuidos según el catastro real en cientos de minas adicionales.

### La Ceca (Meca de Acuñación)
Existen dos niveles de Ceca:
- **Ceca Tribal**: Producción base por trabajador.
- **Ceca Industrial**: Produce el **doble (2x)** que la Ceca Tribal por trabajador.

- **Requisito de Personal**: Mínimo de **5 trabajadores**.
- **Ciclo de Producción**: Una vez cada **6 horas**.
- **Ratio de Producción (Tribal)**: 
    - **100 EST** (Escudos de Plata) por trabajador.
    - **150 LRC** (Líricas de Cobre) por trabajador.
    - **25 Monedas de Oro** por trabajador.
- **Costo de Materiales**: 
    - Requiere lingotes refinados del metal correspondiente según la composición de la moneda:
        - EST: 18.5g Plata / 1.5g Cobre.
        - LRC: 0.5g Plata / 4.5g Cobre.
        - Oro: 20g de Oro (Itef físico).
    - Se aplica un **5% de merma** por procesado.
    - Las wallets administrativas de la Corona (0x554a... y 0xf2a0...) están exentas del requisito de mineral para acuñar, pero sujetas al peso y supply.
- **Combustible**: 1 JIX de Carbón de Madera por trabajador.

## 6. Límites Físicos y Peso
El inventario de cada Héroe está sujeto a las leyes de la física de Altriux:
- **Límite de Peso**: Un jugador no puede cargar más de **2 JIX (40 Kilogramos)** en total.
- **Cálculo de Peso**: Este límite incluye todos los recursos (madera, piedra) y, fundamentalmente, las **monedas**.
    - Una moneda de Oro (Ítem 226) pesa **20g**.
    - Una moneda de Plata (EST) pesa **20g**.
    - Una moneda de Cobre (LRC) pesa **5g**.
- **Profesiones y Rango**:
    - **Soldado**: Progresa de Nivel 1 a 6, vinculado a Ciencia Militar 1 a 6.
    - **Oficios Civiles**: Progresan de Nivel 1 a 4, vinculados a materias temáticas de los Semestres 1 a 4.
- **Jerarquía Espacial**:
    - El mundo se divide en **Lands** (Grandes), cada una con 7 **SubLands** (Medianas), y cada una con 7 **SmallTiles** (Pequeñas).
    - El Héroe tiene una posición exacta (`current_tile`) que determina su interacción con el entorno.
- **Logística Avanzada**:
    - Los recursos y monedas no se transfieren directamente entre jugadores.
    - Deben transferirse a un objeto de almacenamiento (Barco, Edificio, Carreta) que posea su propio `Inventory`.
    - La captura de animales salvajes requiere que el Héroe esté en la misma **SmallTile** que la manada.
- **Consecuencia**: Si un jugador alcanza el peso máximo, no podrá añadir más recursos ni acuñar nuevas monedas hasta que libere espacio en su inventario.

## 7. Reproducción de Libros y Cadena de Suministros
Los libros son NFTs de suministro ilimitado. Para "copiar" un libro existente, un jugador debe poseer los materiales necesarios y las herramientas adecuadas:

### Requisitos de Copia
- **Papel**: Proporcional al peso del libro (**JIX**). Se requiere 1 unidad de papel por cada 100 JIX de peso.
- **Tinta**: Proporcional al peso. Se requiere 1 unidad de tinta por cada 200 JIX de peso.
- **Pluma de Escribir**: Se consume 1 unidad de pluma por cada copia realizada.
- **Original**: Se debe tener acceso al libro original para realizar la copia.

### Cadena de Producción de Materiales (Resources)
1.  **Papel**: Se produce en el **Molino de Papel** a partir de **Estopas** (provenientes del Lino/Flax).
2.  **Tinta**: Se fabrica a partir de **Tanino** (extraído de astillas de madera) y **Conchas Vegetales** (materia prima medieval).
3.  **Estopas**: Subproducto del procesamiento del **Lino (Flax)**.
4.  **Tanino**: Se extrae procesando grandes cantidades de **Astillas de Madera**.

## 5. Requisitos de Maestría (Puntos)

## Catálogo de Libros (40 Ejemplares)
Estos libros son la base del conocimiento en Altriux. Los primeros 20 (Ciencias y técnicas) pertenecen a la wallet `CREATOR_1` y los últimos 20 (Filosofía, Medicina y Estrategia) a `CREATOR_2`.

### Ciencias Exactas e Ingeniería (CREATOR_1)
1.  **Fundamentos de la Razón**: Estudios Generales 1.
2.  **El Surco y la Semilla**: Agroestudio 1, 2.
3.  **Cálculo Primordial**: Matemáticas 1.
4.  **Esferas Celestes**: Astronomía 1, 2.
5.  **La Esencia del Mundo**: Materiales 1, Química 1.
6.  **Principios de Inercia**: Física 1, 2.
7.  **Geometría del Espacio**: Matemáticas 2, 3.
8.  **Tratado de Forja y Aleación**: Materiales 2, Metalurgia 1.
9.  **El Arte de la Piedra**: Construcción 1, 2.
10. **Mecánica Automata**: Física 2, 3.
11. **Alquimia de los Elementos**: Química 1, 2.
12. **Cimientos de lo Eterno**: Construcción 2, 3.
13. **Hidrodinámica Civil**: Hidráulica 1.
14. **El Latis del Horizonte**: Astronomía 3, Cartografía 1.
15. **Sinfonía de los Números**: Matemáticas 3.
16. **Navegación de las Estrellas**: Astronomía 2, 3.
17. **Estudios de la Materia**: Química 2, Metalurgia 1.
18. **Arquitectura del Relieve**: Mecánica de Suelos.
19. **El Peso de la Tierra**: Geometría, Física 1.
20. **Ingeniería de la Civitas**: Arquitectura, Construcción 3.

### Humanidades, Estrategia y Medicina (CREATOR_2)
21. **La Chispa de la Herencia**: Estudios Generales 2.
22. **Senderos del Espíritu**: Teología 1, Filosofía 2.
23. **El Juramento de Vida**: Medicina 1, 2.
24. **Cuna de Civilizaciones**: Estudios Generales 3, 4.
25. **El Valor del Intercambio**: Moneda.
26. **Tratado de las Virtudes**: Filosofía 2, Filosofía Aplicada.
27. **Arte de la Guerra de Altriux**: Ciencia Militar 1, 2.
28. **Anatomía de lo Oculto**: Medicina 1.
29. **Leyes del Pensamiento**: Filosofía Aplicada, Filosofía Política.
30. **El Orden de los Dioses**: Teología 1.
31. **Estrategia de las Falanges**: Ciencia Militar 3, 4.
32. **El Corazón del Hombre**: Medicina 2.
33. **Crónicas del Nuevo Mundo**: Estudios Generales 4.
34. **Ingeniería Naval Imperial**: Arquitectura de Buques.
35. **Tácticas de Asedio**: Ciencia Militar 4, 5.
36. **El Destino de las Naciones**: Filosofía Política, Ciencia Militar 6.
37. **La Mente del General**: Ciencia Militar 5, Gran Estrategia.
38. **Sabiduría de los Ancianos**: Estudios Generales 2, Filosofía 2.
39. **El Código de la Espada**: Ciencia Militar 6, Gran Estrategia.
40. **Compendio de la Alianza**: Estudios Generales 3, Filosofía Política.
