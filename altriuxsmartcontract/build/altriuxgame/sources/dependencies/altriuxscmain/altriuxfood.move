module altriux::altriuxfood {
    
    // --- Food ID Constants (Seeds are Odd, Foods are Seed+1 = Even) ---
    // Cereals
    public fun JAX_WHEAT(): u64 { 2 }
    public fun JAX_MAIZE(): u64 { 4 }
    public fun JAX_RICE(): u64 { 6 }
    public fun JAX_BARLEY(): u64 { 8 }
    public fun JAX_SORGHUM(): u64 { 10 }
    public fun JAX_MILLET(): u64 { 12 }
    public fun JAX_OATS(): u64 { 14 }
    public fun JAX_RYE(): u64 { 16 }
    
    // Tubers
    public fun JAX_POTATO(): u64 { 18 }
    public fun JAX_SWEET_POTATO(): u64 { 20 }
    public fun JAX_CASSAVA(): u64 { 22 }
    public fun JAX_YAM(): u64 { 24 }
    public fun JAX_SUGAR_BEET(): u64 { 48 } // Moved here for grouping logic, ID from user list order implies seed 47

    // Legumes
    public fun JAX_SOYBEAN(): u64 { 26 }
    public fun JAX_PEANUT(): u64 { 28 }
    public fun JAX_COMMON_BEAN(): u64 { 30 }
    public fun JAX_CHICKPEA(): u64 { 32 }
    public fun JAX_LENTIL(): u64 { 34 }
    public fun JAX_PEA(): u64 { 36 }

    // Oilseeds / Textiles / Industrial
    public fun JAX_SUNFLOWER(): u64 { 38 }
    public fun JAX_SESAME(): u64 { 40 }
    public fun JAX_FLAX(): u64 { 42 }
    public fun JAX_HEMP(): u64 { 44 }
    public fun JAX_SUGAR_CANE(): u64 { 46 }
    public fun JAX_COTTON(): u64 { 106 }

    // Vegetables
    public fun JAX_TOMATO(): u64 { 50 }
    public fun JAX_PEPPER(): u64 { 52 }
    public fun JAX_CHILI_PEPPER(): u64 { 54 }
    public fun JAX_ONION(): u64 { 56 }
    public fun JAX_GARLIC(): u64 { 58 }
    public fun JAX_CARROT(): u64 { 60 }
    public fun JAX_CABBAGE(): u64 { 62 }
    public fun JAX_SQUASH(): u64 { 64 }

    // Fruits
    public fun JAX_APPLE(): u64 { 66 }
    public fun JAX_PEAR(): u64 { 68 }
    public fun JAX_PEACH(): u64 { 70 }
    public fun JAX_BANANA(): u64 { 72 }
    public fun JAX_PLANTAIN(): u64 { 74 }
    public fun JAX_ORANGE(): u64 { 76 }
    public fun JAX_MANGO(): u64 { 78 }
    public fun JAX_PAPAYA(): u64 { 80 }
    public fun JAX_PINEAPPLE(): u64 { 82 }
    public fun JAX_AVOCADO(): u64 { 84 }
    public fun JAX_COCONUT(): u64 { 86 }
    public fun JAX_OLIVE(): u64 { 88 }
    public fun JAX_DATE_PALM(): u64 { 90 }
    public fun JAX_GRAPE(): u64 { 92 }
    public fun JAX_STRAWBERRY(): u64 { 94 }
    
    // Nuts / Spices / Luxuries
    public fun JAX_ALMOND(): u64 { 100 }
    public fun JAX_WALNUT(): u64 { 102 }
    public fun JAX_COCOA(): u64 { 104 }
    public fun JAX_COFFEE(): u64 { 110 } // Seed 109
    public fun JAX_TABACO(): u64 { 162 }
    public fun JAX_TABACO_BULTOS(): u64 { 163 }
    public fun JAX_VANILLA(): u64 { 112 } // Seed 111
    public fun JAXSEED_LINO_ACEITE(): u64 { 119 }
    public fun JAX_LINO_ACEITE(): u64 { 120 }

    // Forage
    public fun JAX_CLOVER(): u64 { 108 }
    public fun JAX_RYEGRASS(): u64 { 114 } // Seed 113
    public fun JAX_FESCUE(): u64 { 116 } // Seed 115
    public fun JAX_ALFALFA(): u64 { 118 } // Seed 117

    // Processed / Extra (No seed correspondence directly in this list, but user asked for constants)
    public fun JAX_MEAT_DRIED(): u64 { 200 }
    public fun JAX_DAIRY_EGGS(): u64 { 201 }
    public fun JAX_SALT(): u64 { 202 }
    public fun JAX_SUGAR(): u64 { 203 } // From Cane/Beet
    public fun JAX_SPICES(): u64 { 204 }
    public fun JAX_OIL(): u64 { 205 }
    public fun JAX_WINE(): u64 { 206 }
    public fun JAX_BEER(): u64 { 207 }
    public fun JAX_CIDER(): u64 { 208 }
    public fun JAX_ONION_FLOUR(): u64 { 209 }

    // Byproducts
    public fun JAX_HENO(): u64 { 215 }
    public fun JAX_RASTROJO_FERTILIZANTE(): u64 { 216 }

    // --- Processed Products (from Table) ---
    // Cereals -> Flours/Processed (221-227)
    public fun JAX_HARINA_BLANCA(): u64 { 221 }
    public fun JAX_HARINA_INTEGRAL(): u64 { 222 }
    public fun JAX_MALTA(): u64 { 223 }
    public fun JAX_AVENA_HOJUELAS(): u64 { 224 }
    public fun JAX_HARINA_MAIZ_V2(): u64 { 225 }
    public fun JAX_ARROZ_DESCASCARILLADO(): u64 { 226 }
    public fun JAX_HARINA_CENTENO_V2(): u64 { 227 }

    // Cereals -> Drinks (207, 301-302)
    public fun JAX_SAKE(): u64 { 301 }
    public fun JAX_CHICHA(): u64 { 302 }

    // Legumes -> Food (303-308)
    public fun JAX_TOFU(): u64 { 303 }
    public fun JAX_ACEITE_SOYA(): u64 { 304 }
    public fun JAX_MANTEQUILLA_MANI(): u64 { 305 }
    public fun JAX_HUMMUS(): u64 { 306 }
    public fun JAX_LENTEJAS_SECAS(): u64 { 307 }
    public fun JAX_FRIJOLES_SECOS(): u64 { 308 }

    // Oilseeds -> Oils (309-313)
    public fun JAX_ACEITE_GIRASOL(): u64 { 309 }
    public fun JAX_ACEITE_SESAMO(): u64 { 310 }
    public fun JAX_ACEITE_LINO_V2(): u64 { 311 }
    public fun JAX_ACEITE_OLIVA_V2(): u64 { 312 }
    public fun JAX_ACEITE_COCO_V2(): u64 { 313 }
    public fun JAX_TAPIOCA(): u64 { 314 }
    public fun JAX_COFFEE_SECADO(): u64 { 315 }
    public fun JAX_COFFEE_MOLIDO(): u64 { 316 }

    // Textiles (167-171)
    public fun JAX_LINO_HILADO(): u64 { 167 }
    public fun JAX_CANAMO_HILADO(): u64 { 168 }
    public fun JAX_HILO_ALGODON_V2(): u64 { 169 }
    public fun JAX_TELA(): u64 { 170 }
    public fun JAX_ROPA(): u64 { 171 }
    
    public fun is_textile(id: u64): bool {
        id >= 167 && id <= 171
    }

    public fun is_textile_yarn(id: u64): bool {
        id == 167 || id == 168 || id == 169
    }

    // --- Agricultural Byproducts (Forage/Feed) ---
    public fun BYPRO_SALVADO_C(): u64 { 350 }
    public fun BYPRO_SALVADO_B(): u64 { 351 }
    public fun BYPRO_SALVADO_A(): u64 { 352 }
    public fun BYPRO_TOTOMOXTLE(): u64 { 353 }
    public fun BYPRO_CASCARILLA(): u64 { 354 }
    public fun BYPRO_LEVADURA_RESIDUIAL(): u64 { 355 }
    public fun BYPRO_ORUJO_B(): u64 { 356 }
    public fun BYPRO_BAGAZO_B(): u64 { 357 }
    public fun BYPRO_OKARA_A_PLUS(): u64 { 358 }
    public fun BYPRO_HARINA_SOYA_A_PLUS(): u64 { 359 }
    public fun BYPRO_TORTA_MANI_A(): u64 { 360 }
    public fun BYPRO_PIEL_RESIDUAL(): u64 { 361 }
    public fun BYPRO_HOJARASCA_B(): u64 { 362 }
    public fun BYPRO_VAINAS_A(): u64 { 363 }
    public fun BYPRO_TORTA_A(): u64 { 364 }
    public fun BYPRO_TORTA_B(): u64 { 365 }
    public fun BYPRO_ORUJO_C(): u64 { 366 }
    public fun BYPRO_LINAZA_C(): u64 { 367 }
    public fun BYPRO_TALLOS_RESIDUALES_B(): u64 { 368 }
    public fun BYPRO_SEMILLAS_ALGODON_B(): u64 { 369 }

    // --- Animal Products (Meat) ---
    public fun JAX_MEAT_FRESH_LUXURY(): u64 { 370 }
    public fun JAX_MEAT_FRESH_BASIC(): u64 { 371 }
    public fun JAX_MEAT_FRESH_THIRD(): u64 { 372 }
    public fun JAX_MEAT_SALTED_LUXURY(): u64 { 373 }
    public fun JAX_MEAT_SALTED_BASIC(): u64 { 374 }
    public fun JAX_MEAT_SALTED_THIRD(): u64 { 375 }

    // --- Categories ---
    const CAT_NONE: u8 = 0;
    const CAT_CEREAL: u8 = 1;
    const CAT_TUBER: u8 = 2;
    const CAT_LEGUME: u8 = 3;
    const CAT_VEGETABLE: u8 = 4;
    const CAT_FRUIT: u8 = 5;
    const CAT_NUT: u8 = 6;
    const CAT_OILSEED: u8 = 7;
    const CAT_FIBER: u8 = 8; // Cotton, Flax, Hemp
    const CAT_LUXURY: u8 = 9; // Coffee, Cocoa, Vanilla, Spices, Sugar
    const CAT_FORAGE: u8 = 10;
    const CAT_PROTEIN: u8 = 11; // Meat, Eggs
    const CAT_DAIRY: u8 = 12; 
    const CAT_MINERAL: u8 = 13; // Salt
    const CAT_DRINK: u8 = 14; // Wine, Beeer

    public fun get_category(food_id: u64): u8 {
        if (food_id >= 2 && food_id <= 16) CAT_CEREAL
        else if (food_id >= 18 && food_id <= 24) CAT_TUBER
        else if (food_id == 314) CAT_TUBER // Tapioca
        else if (food_id == 48) CAT_TUBER // Sugar Beet
        else if (food_id >= 26 && food_id <= 36) CAT_LEGUME
        else if (food_id >= 38 && food_id <= 40) CAT_OILSEED // Sunflower, Sesame
        else if (food_id >= 42 && food_id <= 44) CAT_FIBER // Flax, Hemp (can be oil too)
        else if (food_id == 46) CAT_LUXURY // Sugar Cane
        else if (food_id == 106) CAT_FIBER // Cotton
        else if (food_id >= 50 && food_id <= 64) CAT_VEGETABLE
        else if (food_id >= 66 && food_id <= 94) CAT_FRUIT
        else if (food_id >= 100 && food_id <= 102) CAT_NUT
        else if (food_id == 104 || food_id == 110 || food_id == 112 || food_id == 162 || food_id == 163 || food_id == 315 || food_id == 316) CAT_LUXURY
        else if (food_id == 108 || (food_id >= 114 && food_id <= 118)) CAT_FORAGE
        else if (food_id == 200) CAT_PROTEIN
        else if (food_id == 201) CAT_DAIRY
        else if (food_id == 202) CAT_MINERAL
        else if (food_id == 203 || food_id == 204 || food_id == 209) CAT_LUXURY
        else if (food_id == 205) CAT_OILSEED // Processed Oil
        else if (food_id >= 206 && food_id <= 208) CAT_DRINK
        else if (food_id >= 221 && food_id <= 227) CAT_CEREAL // Flours
        else if (food_id >= 301 && food_id <= 302) CAT_DRINK
        else if (food_id >= 303 && food_id <= 308) CAT_LEGUME // Processed Legumes
        else if (food_id >= 309 && food_id <= 313) CAT_OILSEED // Processed Oils
        else if (food_id >= 350 && food_id <= 369) CAT_FORAGE // Byproducts
        else if (food_id >= 370 && food_id <= 375) CAT_PROTEIN // Meat
        else CAT_NONE
    }

    public fun is_cereal(food_id: u64): bool { get_category(food_id) == CAT_CEREAL }
    public fun is_fruit(food_id: u64): bool { get_category(food_id) == CAT_FRUIT }
    public fun is_drink(food_id: u64): bool { get_category(food_id) == CAT_DRINK }
}
