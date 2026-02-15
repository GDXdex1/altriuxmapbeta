module altriux::altriuxmanufactured {
    
    // --- Refined Metals & Alloys (124-134) ---
    public fun HIERRO_FORJADO(): u64 { 124 }
    public fun BRONCE(): u64 { 125 }
    public fun ACERO(): u64 { 126 }
    public fun COBALTO_REFINADO(): u64 { 127 }
    public fun ORO_REFINADO(): u64 { 128 }
    public fun PLATA_REFINADA(): u64 { 129 }
    public fun HIERRO_FUNDIDO(): u64 { 130 }
    public fun COBRE_REFINADO(): u64 { 131 }
    public fun ESTANO_REFINADO(): u64 { 132 }
    public fun PLOMO_REFINADO(): u64 { 133 }
    public fun NIQUEL_REFINADO(): u64 { 134 }

    // --- Smelting Byproducts (135-139) ---
    public fun PLATA_DESPLAZADA(): u64 { 135 }
    public fun AZUFRE_NATURAL(): u64 { 136 }
    public fun ESCORIA_COBRE(): u64 { 137 }
    public fun ESCORIA_HIERRO(): u64 { 138 }
    public fun ESCORIA_ESTANO(): u64 { 139 }

    // --- Processed Wood (140-151) ---
    public fun TABLON_ANCHO(): u64 { 140 }
    public fun TABLON_SEGUNDA(): u64 { 141 }
    public fun VIGA_LARGA(): u64 { 142 }
    public fun CARBON_MADERA(): u64 { 143 }
    public fun ASTILLAS_MADERA(): u64 { 145 }
    public fun VIRUTAS_MADERA(): u64 { 146 }
    public fun TABLAS_MADERA(): u64 { 147 }
    public fun VIGAS_MADERA(): u64 { 148 }
    public fun MADERA_LAMINADA(): u64 { 149 }
    public fun MADERA_TRATADA(): u64 { 150 }
    public fun RESINA_MADERA(): u64 { 151 }

    // --- Processed Textiles (166-207) ---
    public fun HILO_ALGODON(): u64 { 166 }
    public fun HILO_LINO(): u64 { 167 }
    public fun HILO_CANAMO(): u64 { 168 }
    public fun HILO_LANA(): u64 { 169 }
    public fun HILO_SEDA(): u64 { 170 }
    public fun HILO_YAK_FINO(): u64 { 171 }
    public fun HILO_YAK_GRUESO(): u64 { 172 }
    public fun HILO_CACHMIRA(): u64 { 173 }
    public fun HILO_ALPACA(): u64 { 174 }
    
    public fun TELA_LINO_NATURAL(): u64 { 181 }
    public fun TELA_LANA_NATURAL(): u64 { 182 }
    public fun TELA_ALGODON_NATURAL(): u64 { 183 }
    public fun TELA_CANAMO_NATURAL(): u64 { 184 }
    
    public fun TINTE_OCRE_ROJO(): u64 { 201 }
    public fun MORDIENTE_HIERRO(): u64 { 205 }

    // --- Processed Food & Luxuries (200-209, 230-261) ---
    public fun JAX_MEAT_DRIED(): u64 { 200 }
    public fun JAX_MEAT_PROCESSED(): u64 { 227 }
    public fun JAX_DAIRY_PROCESSED(): u64 { 228 } // Moved from 201 to resolve conflict with SMELLTING_BYPRODUCTS if any, actually 201 was unused smelter but DAIRY was 201. Let's keep 228.
    public fun JAX_WINE(): u64 { 206 }
    public fun JAX_BEER(): u64 { 207 }
    public fun JAX_CIDER(): u64 { 254 } // Grouped with drinks
    public fun JAX_ONION_FLOUR(): u64 { 209 }

    // Flours (230-240)
    public fun JAX_HARINA_TRIGO(): u64 { 230 }
    public fun JAX_HARINA_CENTENO(): u64 { 231 }
    public fun JAX_HARINA_CEBADA(): u64 { 232 }
    public fun JAX_HARINA_MAIZ(): u64 { 225 } // Table ID V2

    // Oils (241-250)
    public fun JAX_ACEITE_MAIZ(): u64 { 241 }
    public fun JAX_ACEITE_LINO(): u64 { 242 }

    // Juices (251-260)
    public fun JAX_JUGO_UVA(): u64 { 251 }
    public fun JAX_JUGO_MANZANA(): u64 { 252 }
    public fun JAX_JUGO_PERA(): u64 { 253 }

    // Sugar & Feed
    public fun JAX_AZUCAR(): u64 { 255 }
    public fun JAX_PIENSO_ANIMAL(): u64 { 256 }

    public fun HARINA(): u64 { 230 } // Default flour is wheat
    public fun PAN(): u64 { 305 } // Building produces this

    // --- Writing Materials & Misc (221-225) ---
    public fun PAPEL(): u64 { 221 }
    public fun TINTA(): u64 { 222 }
    public fun PLUMA_ESCRIBIR(): u64 { 223 }
    public fun ESTOPAS(): u64 { 225 }

    // --- Ship Components (215-220) ---
    public fun JAX_JARCIAS(): u64 { 215 }
    public fun JAX_FOQUE(): u64 { 216 }
    public fun JAX_CONTRAFOQUE(): u64 { 217 }
    public fun JAX_BAUPRES(): u64 { 218 }
    public fun JAX_CLAVOS(): u64 { 219 }
    public fun JAX_VELA_ITEM(): u64 { 220 }
}
