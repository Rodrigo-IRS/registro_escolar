module registro_escolar::registro_escolar {
    // ===================================================================================
    // Módulo: Registro Escolar Descentralizado
    // Autor: Rodrigo IRS (con ayuda de Gemini)
    //
    // -- DESCRIPCIÓN DEL PROYECTO --
    // Este módulo implementa un sistema básico para la gestión de registros estudiantiles
    // en la blockchain de Sui. Permite a las escuelas crear un registro digital y a los
    // padres/tutores inscribir a los alumnos, creando un "ExpedienteDigital" único
    // que es propiedad del tutor. Esto crea un sistema portable, seguro y transparente
    // para manejar la información de los alumnos.
    //
    // -- ¿CÓMO USARLO? (FLUJO DE INTERACCIÓN) --
    // 1. Un director de escuela llama a la función `crear_escuela()` para generar el
    //    objeto `RegistroEscolar` compartido para su institución.
    // 2. Un padre/tutor llama a `inscribir_alumno()`, pasándole el `RegistroEscolar`
    //    y los datos de su hijo. Esta acción crea un `ExpedienteDigital` y le transfiere
    //    la propiedad al padre/tutor.
    // 3. El director puede entonces llamar a `asignar_grado_y_grupo()` para actualizar
    //    la información académica del alumno.
    // 4. El padre/tutor puede llamar a `actualizar_contacto()` en cualquier momento para
    //    modificar su propia información de contacto en el expediente.
    // 5. Cualquiera con acceso al objeto `ExpedienteDigital` puede usar la función
    //    de solo lectura `consultar_datos()` para ver la información básica.
    // ===================================================================================


    // --- Importaciones (Finales y 100% Limpias) ---
    use std::string::{Self, String};
    use sui::table::{Self, Table};

    // --- Definiciones de Objetos (Structs) ---

    /// Representa a una escuela. Contiene una tabla que funciona como índice
    /// para encontrar los expedientes de los alumnos inscritos.
    public struct RegistroEscolar has key {
        id: sui::object::UID,
        expedientes: Table<u64, sui::object::ID>
    }

    /// Representa el expediente de un alumno. Es un objeto propiedad del tutor
    /// que contiene toda la información relevante.
    public struct ExpedienteDigital has key, store {
        id: sui::object::UID,
        nia: u64,
        nombre_completo: String,
        curp: String,
        telefono_tutor: u64,
        email_tutor: String,
        grado: u64,
        grupo: String,
    }

    // --- Funciones ---

    /// FUNCIÓN 1: Crea el objeto `RegistroEscolar` para una nueva escuela.
    /// Lo comparte en la red para que sea accesible públicamente.
    public entry fun crear_escuela(ctx: &mut sui::tx_context::TxContext) {
        let registro = RegistroEscolar {
            id: sui::object::new(ctx),
            expedientes: table::new(ctx),
        };
        sui::transfer::share_object(registro);
    }

    /// FUNCIÓN 2: Inscribe a un nuevo alumno en una escuela.
    /// Crea el `ExpedienteDigital`, lo transfiere al tutor y lo registra en la escuela.
    public entry fun inscribir_alumno(
        registro: &mut RegistroEscolar,
        nia: u64,
        nombre_completo: String,
        curp: String,
        telefono_inicial: u64,
        email_inicial: String,
        ctx: &mut sui::tx_context::TxContext
    ) {
        let expediente = ExpedienteDigital {
            id: sui::object::new(ctx),
            nia: nia,
            nombre_completo: nombre_completo,
            curp: curp,
            telefono_tutor: telefono_inicial,
            email_tutor: email_inicial,
            grado: 0,
            grupo: string::utf8(b"Sin asignar"),
        };
        table::add(&mut registro.expedientes, nia, sui::object::id(&expediente));
        sui::transfer::transfer(expediente, sui::tx_context::sender(ctx));
    }

    /// FUNCIÓN 3: Consulta los datos básicos de un expediente.
    /// Es una función de solo lectura que no modifica el estado.
    public fun consultar_datos(expediente: &ExpedienteDigital): (u64, String, String) {
        (expediente.nia, expediente.nombre_completo, expediente.curp)
    }

    /// FUNCIÓN 4: Permite al tutor (dueño del expediente) actualizar su contacto.
    public entry fun actualizar_contacto(
        expediente: &mut ExpedienteDigital,
        nuevo_telefono: u64,
        nuevo_email: String
    ) {
        expediente.telefono_tutor = nuevo_telefono;
        expediente.email_tutor = nuevo_email;
    }

    /// FUNCIÓN 5: Permite a la escuela asignar grado y grupo a un alumno inscrito.
    public entry fun asignar_grado_y_grupo(
        registro: &RegistroEscolar,
        expediente: &mut ExpedienteDigital,
        nuevo_grado: u64,
        nuevo_grupo: String
    ) {
        assert!(table::contains(&registro.expedientes, expediente.nia), 0);
        expediente.grado = nuevo_grado;
        expediente.grupo = nuevo_grupo;
    }

    // --- Pruebas ---
    #[test]
    fun prueba_flujo_completo() {
        let mut ctx = sui::tx_context::dummy();

        let registro = RegistroEscolar {
            id: sui::object::new(&mut ctx),
            expedientes: table::new(&mut ctx),
        };
        let expediente = ExpedienteDigital {
            id: sui::object::new(&mut ctx),
            nia: 12345,
            nombre_completo: string::utf8(b"Rodrigo IRS"),
            curp: string::utf8(b"ABCD123456..."),
            telefono_tutor: 5551112222,
            email_tutor: string::utf8(b"tutor@email.com"),
            grado: 0,
            grupo: string::utf8(b"Sin asignar"),
        };
        
        // Limpieza final de los objetos.
        let RegistroEscolar { id: id_registro, expedientes } = registro;
        table::destroy_empty(expedientes);
        sui::object::delete(id_registro);

        let ExpedienteDigital { id: id_expediente, .. } = expediente;
        sui::object::delete(id_expediente);
    }
}
