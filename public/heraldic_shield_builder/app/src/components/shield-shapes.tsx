// Componentes SVG para las 12 formas de escudo heráldico

import React from 'react';

interface ShieldPathProps {
  className?: string;
  fill?: string;
  stroke?: string;
  strokeWidth?: string | number;
}

// 1. Escudo Medieval (Heater) - La forma clásica
export const HeaterShield: React.FC<ShieldPathProps> = ({ className, fill, stroke, strokeWidth }) => (
  <path
    d="M 100 10 
       L 190 10 
       Q 200 10 200 20
       L 200 120
       Q 200 180 100 190
       Q 0 180 0 120
       L 0 20
       Q 0 10 10 10
       Z"
    className={className}
    fill={fill}
    stroke={stroke}
    strokeWidth={strokeWidth}
  />
);

// 2. Escudo Francés
export const FrenchShield: React.FC<ShieldPathProps> = ({ className, fill, stroke, strokeWidth }) => (
  <path
    d="M 100 5
       L 195 5
       Q 200 5 200 10
       L 200 130
       Q 200 175 100 195
       Q 0 175 0 130
       L 0 10
       Q 0 5 5 5
       Z"
    className={className}
    fill={fill}
    stroke={stroke}
    strokeWidth={strokeWidth}
  />
);

// 3. Escudo Español
export const SpanishShield: React.FC<ShieldPathProps> = ({ className, fill, stroke, strokeWidth }) => (
  <path
    d="M 100 5
       L 190 5
       Q 195 5 195 10
       L 195 100
       Q 195 160 100 195
       Q 5 160 5 100
       L 5 10
       Q 5 5 10 5
       Z"
    className={className}
    fill={fill}
    stroke={stroke}
    strokeWidth={strokeWidth}
  />
);

// 4. Escudo Inglés
export const EnglishShield: React.FC<ShieldPathProps> = ({ className, fill, stroke, strokeWidth }) => (
  <path
    d="M 100 5
       L 185 5
       Q 190 5 190 10
       L 190 140
       Q 190 185 100 195
       Q 10 185 10 140
       L 10 10
       Q 10 5 15 5
       Z"
    className={className}
    fill={fill}
    stroke={stroke}
    strokeWidth={strokeWidth}
  />
);

// 5. Escudo Alemán
export const GermanShield: React.FC<ShieldPathProps> = ({ className, fill, stroke, strokeWidth }) => (
  <path
    d="M 100 5
       L 180 5
       Q 185 5 185 10
       L 185 110
       Q 185 165 100 195
       Q 15 165 15 110
       L 15 10
       Q 15 5 20 5
       Z"
    className={className}
    fill={fill}
    stroke={stroke}
    strokeWidth={strokeWidth}
  />
);

// 6. Escudo Italiano
export const ItalianShield: React.FC<ShieldPathProps> = ({ className, fill, stroke, strokeWidth }) => (
  <path
    d="M 100 5
       L 175 5
       Q 180 5 180 10
       L 180 120
       Q 180 170 100 195
       Q 20 170 20 120
       L 20 10
       Q 20 5 25 5
       Z"
    className={className}
    fill={fill}
    stroke={stroke}
    strokeWidth={strokeWidth}
  />
);

// 7. Escudo Suizo
export const SwissShield: React.FC<ShieldPathProps> = ({ className, fill, stroke, strokeWidth }) => (
  <path
    d="M 100 5
       L 170 5
       Q 175 5 175 10
       L 175 130
       Q 175 175 100 195
       Q 25 175 25 130
       L 25 10
       Q 25 5 30 5
       Z"
    className={className}
    fill={fill}
    stroke={stroke}
    strokeWidth={strokeWidth}
  />
);

// 8. Escudo Polaco
export const PolishShield: React.FC<ShieldPathProps> = ({ className, fill, stroke, strokeWidth }) => (
  <path
    d="M 100 5
       L 165 5
       Q 170 5 170 10
       L 170 140
       Q 170 180 100 195
       Q 30 180 30 140
       L 30 10
       Q 30 5 35 5
       Z"
    className={className}
    fill={fill}
    stroke={stroke}
    strokeWidth={strokeWidth}
  />
);

// 9. Escudo Otomano
export const OttomanShield: React.FC<ShieldPathProps> = ({ className, fill, stroke, strokeWidth }) => (
  <path
    d="M 100 5
       L 160 5
       Q 165 5 165 10
       L 165 150
       Q 165 185 100 195
       Q 35 185 35 150
       L 35 10
       Q 35 5 40 5
       Z"
    className={className}
    fill={fill}
    stroke={stroke}
    strokeWidth={strokeWidth}
  />
);

// 10. Escudo Renacentista
export const RenaissanceShield: React.FC<ShieldPathProps> = ({ className, fill, stroke, strokeWidth }) => (
  <path
    d="M 100 5
       L 155 5
       Q 160 5 160 10
       L 160 160
       Q 160 190 100 195
       Q 40 190 40 160
       L 40 10
       Q 40 5 45 5
       Z"
    className={className}
    fill={fill}
    stroke={stroke}
    strokeWidth={strokeWidth}
  />
);

// 11. Escudo Barroco
export const BaroqueShield: React.FC<ShieldPathProps> = ({ className, fill, stroke, strokeWidth }) => (
  <path
    d="M 100 5
       C 140 5 170 15 180 40
       C 190 65 185 100 170 130
       C 155 160 130 185 100 195
       C 70 185 45 160 30 130
       C 15 100 10 65 20 40
       C 30 15 60 5 100 5
       Z"
    className={className}
    fill={fill}
    stroke={stroke}
    strokeWidth={strokeWidth}
  />
);

// 12. Escudo Moderno
export const ModernShield: React.FC<ShieldPathProps> = ({ className, fill, stroke, strokeWidth }) => (
  <path
    d="M 100 5
       L 150 5
       Q 160 5 160 15
       L 160 170
       Q 160 190 100 195
       Q 40 190 40 170
       L 40 15
       Q 40 5 50 5
       Z"
    className={className}
    fill={fill}
    stroke={stroke}
    strokeWidth={strokeWidth}
  />
);

// Mapa de componentes de escudo
export const SHIELD_COMPONENTS = {
  heater: HeaterShield,
  french: FrenchShield,
  spanish: SpanishShield,
  english: EnglishShield,
  german: GermanShield,
  italian: ItalianShield,
  swiss: SwissShield,
  polish: PolishShield,
  ottoman: OttomanShield,
  renaissance: RenaissanceShield,
  baroque: BaroqueShield,
  modern: ModernShield,
};

// Función para obtener el componente de escudo por tipo
export const getShieldComponent = (shape: keyof typeof SHIELD_COMPONENTS) => {
  return SHIELD_COMPONENTS[shape] || HeaterShield;
};
