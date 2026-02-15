module altriux::altriuxbooks {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::table;
    use std::option::{Self, Option};
    use altriux::altriuxhero::{Self, Hero};
    use altriux::altriuxscience;
    use altriux::altriuxresources::{Self, Inventory};
    use altriux::altriuxmanufactured;

    const CREATOR_1: address = @0x554a2392980b0c3e4111c9a0e8897e632d41847d04cbd41f9e081e49ba2eb04a;
    const CREATOR_2: address = @0xf2a0919d5a077df0fe4317f008729072fd9e39076b8b087ef8f48bacf00ded0c;

    const STUDY_DURATION_MS: u64 = 6 * 60 * 60 * 1000; // 6 hours

    const E_HERO_LOCKED: u64 = 1;
    const E_NOT_AUTHORIZED: u64 = 2;
    const E_PREREQUISITE_NOT_MET: u64 = 3;
    const E_INVALID_BRANCH: u64 = 4;

    public struct Book has key, store {
        id: UID,
        title: vector<u8>,
        branches: vector<u8>,
        weight_jax: u64,
        content_highlight: vector<u8>,
        image_url: Option<vector<u8>>,
    }

    public struct MasterLibrary has key {
        id: UID,
        jhoux_claimed: bool,
        elliot_claimed: bool,
    }

    public entry fun init_library(ctx: &mut TxContext) {
        // This is a one-time setup for the shared library state
        sui::transfer::share_object(MasterLibrary {
            id: object::new(ctx),
            jhoux_claimed: false,
            elliot_claimed: false,
        });
    }

    public entry fun claim_jhoux_library(lib: &mut MasterLibrary, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == CREATOR_1, E_NOT_AUTHORIZED);
        assert!(!lib.jhoux_claimed, E_NOT_AUTHORIZED);
        
        // Jhoux I: Maestro de Ciencias Cósmicas y Terrenales
        mint_book_bundle(b"Ciencia de nuestro planeta", vector[60, 30, 10, 20], 1850, b"Obra magna integradora: Describe la Tierra como esfera en movimiento...", CREATOR_1, ctx);
        mint_book_bundle(b"Tratado de mecanica celeste", vector[62, 31, 22], 1420, b"Movimiento planetario como engranajes cosmicos...", CREATOR_1, ctx);
        mint_book_bundle(b"Fundamentos del calculo infinitesimal", vector[22, 30, 40], 1150, b"Concepto de 'fluxiones' (derivadas) para medir cambio continuo...", CREATOR_1, ctx);
        mint_book_bundle(b"Arquitectura de catedrales goticas", vector[43, 80, 31, 45], 2200, b"Ingenieria revolucionaria: Arcos apuntados auto-soportantes...", CREATOR_1, ctx);
        mint_book_bundle(b"Hidraulica y riego avanzado", vector[45, 11, 31], 980, b"Norias de engranajes compuestos, acueductos con pendiente calculada (0.1%)...", CREATOR_1, ctx);
        mint_book_bundle(b"Metales y aleaciones sagradas", vector[51, 52, 41], 1350, b"Purificacion de hierro con carbon vegetal controlado...", CREATOR_1, ctx);
        mint_book_bundle(b"Navegacion astronomica oceanica", vector[63, 61, 30], 870, b"Astrolabio de latitud precisa; cartas estelares para oceanos desconocidos...", CREATOR_1, ctx);
        mint_book_bundle(b"Fisica de los cuatro elementos", vector[30, 31, 70], 1050, b"Teoria del impetus (precursor del momentum); hidrodinamica de fluidos...", CREATOR_1, ctx);
        mint_book_bundle(b"Agricultura racional de los valles", vector[11, 10, 85], 760, b"Rotacion trienal optimizada; analisis de suelos por textura/color...", CREATOR_1, ctx);
        mint_book_bundle(b"Geometria aplicada a fortificaciones", vector[42, 90, 21], 1580, b"Dise\xf1o de murallas con taludes calculados para desviar catapultas...", CREATOR_1, ctx);

        lib.jhoux_claimed = true;
    }

    public entry fun claim_elliot_library(lib: &mut MasterLibrary, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == CREATOR_2, E_NOT_AUTHORIZED);
        assert!(!lib.elliot_claimed, E_NOT_AUTHORIZED);
        
        // Elliotrixer I: Maestro de Artes Medicas y Filosofia Vital
        mint_book_bundle(b"Teoria de la vida", vector[82, 71, 50], 1680, b"Obra fundacional de biologia: Propone que toda vida surge de 'semillas invisibles'...", CREATOR_2, ctx);
        mint_book_bundle(b"Ciencia humana descriptiva", vector[82, 84], 1420, b"Primer atlas con disecciones reales (no galenicas); sistema circulatorio...", CREATOR_2, ctx);
        mint_book_bundle(b"Alquimia practica de medicamentos", vector[50, 51, 82], 1120, b"Destilacion de alcohol etilico (70%); preparacion de eter como anestesico...", CREATOR_2, ctx);
        mint_book_bundle(b"Etica medica hipocratica", vector[71, 82], 580, b"Juramento modificado: 'No danaras aunque el paciente sea enemigo'...", CREATOR_2, ctx);
        mint_book_bundle(b"Herbario de plantas curativas", vector[10, 82, 33], 940, b"120 especies con dosis exactas: digitalis para corazon, quinina, opio...", CREATOR_2, ctx);
        mint_book_bundle(b"Tratado avanzado de cirugia", vector[84, 82, 91], 1350, b"Suturas con seda esterilizada; amputaciones con torniquete regulable...", CREATOR_2, ctx);
        mint_book_bundle(b"Filosofia natural de los cuerpos", vector[71, 30, 50], 820, b"Materia como combinacion de tierra/agua/aire/fuego; teoria corpuscular...", CREATOR_2, ctx);
        mint_book_bundle(b"Quimica de la anatomia humana", vector[51, 82, 10], 1050, b"Analisys de sangre/orina mediante reactivos vegetales...", CREATOR_2, ctx);
        mint_book_bundle(b"El planeta como un todo ", vector[74, 83, 72], 720, b"Analogia cuerpo-estado: rey=cabeza, nobles=brazos, campesinos=piernas...", CREATOR_2, ctx);
        mint_book_bundle(b"La creacion como milagro cientificamente exacto", vector[11, 82, 50], 890, b"Cultivo intensivo de plantas medicinales: amapola, mandragora...", CREATOR_2, ctx);

        lib.elliot_claimed = true;
    }

    fun mint_book_bundle(
        title: vector<u8>,
        branches: vector<u8>,
        weight_jax: u64,
        content_highlight: vector<u8>,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let mut i = 0;
        while (i < 5) {
            sui::transfer::public_transfer(Book { 
                id: object::new(ctx), 
                title, 
                branches, 
                weight_jax, 
                content_highlight, 
                image_url: option::none() 
            }, recipient);
            i = i + 1;
        };
    }

    public entry fun mint_science_book(title: vector<u8>, branches: vector<u8>, weight_jax: u64, content_highlight: vector<u8>, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == CREATOR_1, E_NOT_AUTHORIZED);
        sui::transfer::public_transfer(Book { 
            id: object::new(ctx), 
            title, 
            branches, 
            weight_jax, 
            content_highlight, 
            image_url: option::none() 
        }, CREATOR_1);
    }

    public entry fun mint_phil_book(title: vector<u8>, branches: vector<u8>, weight_jax: u64, content_highlight: vector<u8>, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == CREATOR_2, E_NOT_AUTHORIZED);
        sui::transfer::public_transfer(Book { 
            id: object::new(ctx), 
            title, 
            branches, 
            weight_jax, 
            content_highlight, 
            image_url: option::none() 
        }, CREATOR_2);
    }

    /// Transcribes a book. Requires a worker (Hero) with mastery in "Estudios Básicos 2" (ID 2).
    public fun transcribe_book(
        original: &Book, 
        worker: &mut Hero,
        inv: &mut Inventory, 
        clock: &Clock, 
        ctx: &mut TxContext
    ): Book {
        let now = clock::timestamp_ms(clock);
        assert!(!altriuxhero::is_locked(worker, now), E_HERO_LOCKED);
        
        // Requirement: "Estudios Básicos 2" (ID 2)
        let masteries = altriuxhero::get_masteries(worker);
        assert!(sui::table::contains(masteries, 2), E_PREREQUISITE_NOT_MET);

        // Requirements: Quill + Paper/Ink based on weight
        let paper_req = (original.weight_jax + 99) / 100;
        let ink_req = (original.weight_jax + 199) / 200;

        altriuxresources::consume_jax(inv, altriuxmanufactured::PAPEL(), paper_req, clock);
        altriuxresources::consume_jax(inv, altriuxmanufactured::TINTA(), ink_req, clock);
        altriuxresources::consume_jax(inv, altriuxmanufactured::PLUMA_ESCRIBIR(), 1, clock);

        // Lock hero for transcription
        altriuxhero::set_study_lock(worker, now + STUDY_DURATION_MS);

        Book {
            id: object::new(ctx),
            title: original.title,
            branches: original.branches,
            weight_jax: original.weight_jax,
            content_highlight: original.content_highlight,
            image_url: original.image_url,
        }
    }

    public fun read_and_study(hero: &mut Hero, book: &Book, branch_choice: u8, clock: &Clock) {
        let now = clock::timestamp_ms(clock);
        assert!(!altriuxhero::is_locked(hero, now), E_HERO_LOCKED);
        
        // Check if branch is in book
        let mut i = 0;
        let mut found = false;
        let len = std::vector::length(&book.branches);
        while (i < len) {
            if (*std::vector::borrow(&book.branches, i) == branch_choice) {
                found = true;
                break
            };
            i = i + 1;
        };
        assert!(found, E_INVALID_BRANCH);
        
        // Check prerequisite
        let masteries = altriuxhero::get_masteries(hero);
        assert!(altriuxscience::check_prerequisite(branch_choice, masteries), E_PREREQUISITE_NOT_MET);

        // Add point
        let science_points = altriuxhero::get_science_points_mut(hero);
        if (!table::contains(science_points, branch_choice)) {
            table::add(science_points, branch_choice, 0);
        };
        let p = table::borrow_mut(science_points, branch_choice);
        *p = *p + 1;

        // Check for mastery
        let threshold = altriuxscience::get_points_req(branch_choice);
        if (*p >= threshold) {
            let m = altriuxhero::get_masteries_mut(hero);
            if (!table::contains(m, branch_choice)) {
                table::add(m, branch_choice, true);
            }
        };

        // Lock hero
        altriuxhero::set_study_lock(hero, now + STUDY_DURATION_MS);
    }

    #[test_only]
    public fun destroy_book_for_testing(b: Book) {
        let Book { id, title: _, branches: _, weight_jax: _, content_highlight: _, image_url: _ } = b;
        sui::object::delete(id);
    }
}
