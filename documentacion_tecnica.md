# Documentación Técnica del Proyecto: Sistema BIP Web

Esta documentación detalla la arquitectura, estructura de archivos, base de datos y flujos funcionales del **Módulo de Administración y Seguridad del Sistema BIP Web** (Banco de Iniciativas de Proyectos).

---

## 1. Arquitectura General y Tecnologías

El sistema sigue una arquitectura moderna de aplicación web sin servidor (Serverless) con la siguiente división:

*   **Frontend**: Aplicación multiplataforma (principalmente compilada para Web/Chrome en este entorno) desarrollada en **Flutter (Dart)**.
*   **Backend**: Plataforma **Supabase**, que proporciona:
    *   **Autenticación y Gestión de Usuarios**: Manejo de sesiones y credenciales seguras.
    *   **Base de Datos**: PostgreSQL con seguridad por filas (RLS) habilitada.
    *   **Funcionalidades de Backend (Lógica de Negocio)**: Implementada mediante procedimientos almacenados (funciones RPC) y desencadenadores (triggers) en la base de datos.

---

## 2. Estructura de Directorios (Frontend)

La aplicación sigue una arquitectura organizada en capas horizontales dentro del directorio [`lib/`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/):

```
lib/
├── core/
│   └── security/
│       ├── security.dart (Barrel file)
│       ├── servicio_permisos.dart
│       └── widget_autorizado.dart
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       ├── login_page.dart
│   │       └── presentation.dart (Barrel file)
│   └── security/
│       ├── presentation/
│       │   └── paginas/
│       │       ├── administracion_roles_page.dart
│       │       ├── gestion_usuarios_page.dart
│       │       ├── pagina_prueba_permisos.dart
│       │       └── paginas.dart (Barrel file)
│       └── services/
│           ├── rol_service.dart
│           ├── services.dart (Barrel file)
│           └── usuario_service.dart
├── models/
│   ├── models.dart (Barrel file)
│   └── nodo_recurso.dart
└── main.dart
```

### Descripción de los Componentes Frontend:

*   **[`main.dart`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/main.dart)**: Inicializa Supabase utilizando la URL y Anon Key del proyecto y arranca la aplicación mostrando [`LoginPage`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/features/auth/presentation/login_page.dart).
*   **[`core/security/`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/core/security/)**:
    *   [`servicio_permisos.dart`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/core/security/servicio_permisos.dart): Servicio Singleton (`ServicioPermisos`) que almacena temporalmente en memoria los permisos del usuario activo y proporciona métodos de validación (`tiene`, `tieneAlguno`, `tieneTodos`).
    *   [`widget_autorizado.dart`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/core/security/widget_autorizado.dart): Widget estructural (`WidgetAutorizado`) que encapsula la renderización condicional de la UI en base a la evaluación del servicio de permisos.
*   **[`features/auth/`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/features/auth/)**:
    *   [`login_page.dart`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/features/auth/presentation/login_page.dart): Interfaz y lógica para la autenticación de usuarios contra Supabase Auth. Al iniciar sesión, precarga los permisos del usuario en memoria antes de navegar a la aplicación.
*   **[`features/security/`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/features/security/)**:
    *   [`administracion_roles_page.dart`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/features/security/presentation/paginas/administracion_roles_page.dart): Pantalla para la asignación y visualización del árbol interactivo de permisos por perfil/rol.
    *   [`gestion_usuarios_page.dart`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/features/security/presentation/paginas/gestion_usuarios_page.dart): Interfaz para dar de alta nuevos colaboradores y asignarles uno o más roles.
    *   [`pagina_prueba_permisos.dart`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/features/security/presentation/paginas/pagina_prueba_permisos.dart): Sandbox/Laboratorio que simula tres casos de uso con `WidgetAutorizado`.
    *   [`rol_service.dart`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/features/security/services/rol_service.dart) y [`usuario_service.dart`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/features/security/services/usuario_service.dart): Servicios de comunicación directa con las tablas de la base de datos de Supabase y sus RPCs correspondientes.
*   **[`models/`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/models/)**:
    *   [`nodo_recurso.dart`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/models/nodo_recurso.dart): Define las entidades `ItemPermiso` y `NodoRecurso` (con soporte para cálculo de estados jerárquicos e indeterminados en cascada) y el enumerado `EstadoSeleccion`.

---

## 3. Modelo de Datos y Estructura en Supabase (Backend)

La base de datos cuenta con tablas transaccionales, catálogos geográficos y económicos. A continuación se listan las tablas identificadas en la base de datos PostgreSQL:

```mermaid
erDiagram
    instituciones ||--o{ perfiles : "pertenece"
    instituciones ||--o{ roles : "registrado_en"
    instituciones ||--o{ bitacora_auditoria : "audita"
    
    auth_users ||--|| perfiles : "perfil_id"
    auth_users ||--o{ usuarios_roles : "roles_asignados"
    auth_users ||--o{ excepciones_permisos_usuario : "excepcion"
    
    perfiles ||--o{ usuarios_roles : "roles_usuario"
    roles ||--o{ usuarios_roles : "asignado_a"
    roles ||--o{ roles_permisos : "tiene"
    
    recursos_sistema ||--o{ permisos : "contiene"
    recursos_sistema ||--o{ recursos_sistema : "padre"
    permisos ||--o{ roles_permisos : "concedido_en"
    permisos ||--o{ excepciones_permisos_usuario : "exceptuado_en"
    
    departamentos ||--o{ municipios : "contiene"
    sectores ||--o{ sectores : "subsector_padre"
```

### Detalle de las Tablas y Columnas:

#### 1. `public.instituciones` (Catálogo de Entidades / UPEGs)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `codigo` (VARCHAR, Unique)
*   `nombre` (VARCHAR)
*   `estado` (VARCHAR, Default: `'ACTIVO'`, Check: `'ACTIVO'`, `'INACTIVO'`)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)
*   `fecha_actualizacion` (TIMESTAMPTZ, Default: `now()`)

#### 2. `public.perfiles` (Extensión del Perfil de Usuario de Supabase Auth)
*   `id` (UUID, PK, Referencia: `auth.users(id)`)
*   `institucion_id` (UUID, FK, Referencia: `public.instituciones(id)`)
*   `nombres` (VARCHAR, Max-Length: 100)
*   `apellidos` (VARCHAR, Max-Length: 100)
*   `identidad` (VARCHAR, Max-Length: 30)
*   `celular` (VARCHAR, Max-Length: 30)
*   `cargo` (VARCHAR, Max-Length: 100)
*   `estado` (VARCHAR, Default: `'ACTIVO'`, Check: `'ACTIVO'`, `'INACTIVO'`, `'BLOQUEADO'`)
*   `debe_cambiar_clave` (BOOLEAN, Default: `false`)
*   `ultimo_inicio_sesion` (TIMESTAMPTZ, Nullable)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)
*   `fecha_actualizacion` (TIMESTAMPTZ, Default: `now()`)

#### 3. `public.roles` (Roles de Usuario)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `institucion_id` (UUID, FK, Referencia: `public.instituciones(id)`)
*   `codigo` (VARCHAR, Unique)
*   `nombre` (VARCHAR)
*   `descripcion` (TEXT, Nullable)
*   `es_sistema` (BOOLEAN, Default: `false`)
*   `esta_activo` (BOOLEAN, Default: `true`)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)
*   `fecha_actualizacion` (TIMESTAMPTZ, Default: `now()`)

#### 4. `public.usuarios_roles` (Asociación de Roles a Usuarios)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `usuario_id` (UUID, FK, Referencia: `public.perfiles(id)`)
*   `rol_id` (UUID, FK, Referencia: `public.roles(id)`)
*   `vigente_desde` (TIMESTAMPTZ, Default: `now()`)
*   `vigente_hasta` (TIMESTAMPTZ, Nullable)
*   `asignado_por` (UUID, FK, Referencia: `auth.users(id)`)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)

#### 5. `public.recursos_sistema` (Módulos, Menús y Pantallas del Sistema)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `recurso_padre_id` (UUID, FK, Referencia: `public.recursos_sistema(id)`, Nullable)
*   `codigo` (VARCHAR, Unique)
*   `nombre` (VARCHAR)
*   `descripcion` (TEXT, Nullable)
*   `tipo_recurso` (USER-DEFINED Enum: `tipo_recurso_enum` [`MODULO`, `MENU`, `PANTALLA`, `PESTAÑA`, `SECCION`, `BOTON`, `ACCION`, `API`, `REPORTE`])
*   `ruta` (VARCHAR, Nullable)
*   `icono` (VARCHAR, Nullable)
*   `orden_visual` (INTEGER, Default: 0)
*   `es_visible` (BOOLEAN, Default: `true`)
*   `esta_activo` (BOOLEAN, Default: `true`)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)
*   `fecha_actualizacion` (TIMESTAMPTZ, Default: `now()`)

#### 6. `public.permisos` (Privilegios individuales del Sistema)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `recurso_id` (UUID, FK, Referencia: `public.recursos_sistema(id)`)
*   `codigo` (VARCHAR, Unique)
*   `nombre` (VARCHAR)
*   `descripcion` (TEXT, Nullable)
*   `accion` (VARCHAR)
*   `esta_activo` (BOOLEAN, Default: `true`)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)
*   `fecha_actualizacion` (TIMESTAMPTZ, Default: `now()`)

#### 7. `public.roles_permisos` (Asociación de Roles con Permisos)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `rol_id` (UUID, FK, Referencia: `public.roles(id)`)
*   `permiso_id` (UUID, FK, Referencia: `public.permisos(id)`)
*   `otorgado_por` (UUID, FK, Referencia: `auth.users(id)`)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)

#### 8. `public.excepciones_permisos_usuario` (Excepciones de Permiso específicas por Usuario)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `usuario_id` (UUID, FK, Referencia: `auth.users(id)`)
*   `permiso_id` (UUID, FK, Referencia: `public.permisos(id)`)
*   `efecto` (VARCHAR, Check: `'PERMITIR'`, `'DENEGAR'`)
*   `motivo` (TEXT, Nullable)
*   `vigente_desde` (TIMESTAMPTZ, Default: `now()`)
*   `vigente_hasta` (TIMESTAMPTZ, Nullable)
*   `asignado_por` (UUID, FK, Referencia: `auth.users(id)`)
*   `fecha_creacion` (TIMESTAMPTZ)

#### 9. `public.bitacora_auditoria` (Registro de Auditoría de Acciones Críticas)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `institucion_id` (UUID, FK, Referencia: `public.instituciones(id)`, Nullable)
*   `usuario_id` (UUID, FK, Referencia: `auth.users(id)`, Nullable)
*   `accion` (VARCHAR)
*   `tipo_entidad` (VARCHAR)
*   `entidad_id` (TEXT, Nullable)
*   `valores_anteriores` (JSONB, Nullable)
*   `valores_nuevos` (JSONB, Nullable)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)

#### 10. `public.sectores` (Catálogo Jerárquico Económico)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `sector_padre_id` (UUID, FK, Referencia: `public.sectores(id)`, Nullable)
*   `codigo` (VARCHAR, Unique)
*   `nombre` (VARCHAR)
*   `estado` (VARCHAR, Default: `'ACTIVO'`, Check: `'ACTIVO'`, `'INACTIVO'`)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)

#### 11. `public.niveles_preinversion` (Catálogo de Preinversión)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `codigo` (VARCHAR, Unique)
*   `nombre` (VARCHAR)
*   `orden` (INTEGER)
*   `descripcion` (TEXT, Nullable)
*   `estado` (VARCHAR, Default: `'ACTIVO'`, Check: `'ACTIVO'`, `'INACTIVO'`)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)

#### 12. `public.metodologias_evaluacion` (Catálogo de Metodologías Socioeconómicas)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `codigo` (VARCHAR, Unique)
*   `nombre` (VARCHAR)
*   `sigla` (VARCHAR)
*   `descripcion` (TEXT, Nullable)
*   `estado` (VARCHAR, Default: `'ACTIVO'`, Check: `'ACTIVO'`, `'INACTIVO'`)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)

#### 13. `public.fuentes_financiamiento` (Catálogo de Fuentes de Financiamiento)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `codigo` (VARCHAR, Unique)
*   `nombre` (VARCHAR)
*   `tipo` (VARCHAR, Check: `'FONDOS_NACIONALES'`, `'COOPERACION_EXTERNA'`, `'APP'`)
*   `estado` (VARCHAR, Default: `'ACTIVO'`, Check: `'ACTIVO'`, `'INACTIVO'`)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)

#### 14. `public.departamentos` (Catálogo Geográfico - Departamentos de Honduras)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `codigo` (VARCHAR, Unique)
*   `nombre` (VARCHAR)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)

#### 15. `public.municipios` (Catálogo Geográfico - Municipios)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `departamento_id` (UUID, FK, Referencia: `public.departamentos(id)`)
*   `codigo` (VARCHAR, Unique)
*   `nombre` (VARCHAR)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)

#### 16. `public.tipologias_inversion` (Catálogo de Tipologías de Inversión)
*   `id` (UUID, PK, Default: `gen_random_uuid()`)
*   `codigo` (VARCHAR, Unique)
*   `nombre` (VARCHAR)
*   `descripcion` (TEXT, Nullable)
*   `estado` (VARCHAR, Default: `'ACTIVO'`, Check: `'ACTIVO'`, `'INACTIVO'`)
*   `fecha_creacion` (TIMESTAMPTZ, Default: `now()`)

---

## 4. Lógica del Lado del Servidor (Procedimientos y Triggers en Postgres)

El backend de Supabase utiliza las siguientes funciones PL/pgSQL personalizadas para realizar operaciones transaccionales complejas:

### 1. `public.tiene_permiso(permiso_solicitado TEXT, id_usuario UUID) RETURNS BOOLEAN`
*   **Propósito**: Evalúa si un usuario posee un permiso de manera efectiva siguiendo una jerarquía de prioridades:
    1.  **DENEGAR explícito**: Si existe una excepción tipo `'DENEGAR'` para ese permiso y usuario, retorna `false` inmediatamente.
    2.  **PERMITIR explícito**: Si existe una excepción tipo `'PERMITIR'` activa, retorna `true`.
    3.  **Permiso asignado por Rol**: Verifica si el usuario cuenta con un rol asignado vigente que a su vez tenga asignado el permiso correspondiente en `roles_permisos`.
*   **Security Context**: `SECURITY DEFINER` (Se ejecuta con los privilegios de administrador para poder consultar las tablas del sistema de seguridad).

### 2. `public.obtener_mis_permisos() RETURNS TABLE(codigo TEXT)`
*   **Propósito**: Retorna la lista de códigos de permisos activos para el usuario autenticado que realiza la llamada (`auth.uid()`).
*   **Security Context**: `SECURITY DEFINER`.

### 3. `public.guardar_roles_usuario(id_usuario UUID, ids_roles UUID[]) RETURNS VOID`
*   **Propósito**: Ejecuta de manera transaccional:
    1.  Elimina todas las asignaciones de roles previas del usuario especificado de `usuarios_roles`.
    2.  Inserta los nuevos roles asignados, definiendo a `auth.uid()` (usuario administrador actual) en el campo `asignado_por`.
    3.  Registra la acción en la tabla `bitacora_auditoria` para fines de seguimiento.
*   **Security Context**: `SECURITY DEFINER`.

### 4. `public.crear_perfil_nuevo_usuario() TRIGGER`
*   **Propósito**: Trigger asignado para ejecutarse después de una inserción en la tabla interna `auth.users`. Toma la metadata del usuario (`raw_user_meta_data`) que se envía al registrarse desde el frontend de Flutter (como `nombres`, `apellidos`, `cargo`, `celular`, `identidad` e `institucion_id`) e inserta de forma automática la fila correspondiente en la tabla pública `public.perfiles`.
*   **Security Context**: `SECURITY DEFINER`.

### 5. `public.obtener_arbol_permisos_rol(id_rol UUID) RETURNS TABLE`
*   **Propósito**: Devuelve la estructura jerárquica de recursos del sistema vinculada con los permisos asignados o no al rol indicado, facilitando la construcción del árbol interactivo de la UI.
*   **Security Context**: No identificado detalladamente en el código fuente (invocado mediante RPC).

### 6. `public.guardar_permisos_rol(id_rol UUID, ids_permisos UUID[]) RETURNS VOID`
*   **Propósito**: Actualiza de forma atómica los permisos asociados a un rol específico.
*   **Security Context**: Invocado mediante RPC.

---

## 5. Módulo de Autenticación, Seguridad y Autorización

### Flujo de Autenticación
1.  El usuario ingresa su correo y contraseña en la vista [`LoginPage`](file:///Users/hugozuniga/development/Proyecto Programacion Movil/proyecto_programacion_movil_grupo_4/lib/features/auth/presentation/login_page.dart).
2.  El frontend realiza la llamada a `Supabase.instance.client.auth.signInWithPassword`.
3.  Si las credenciales son válidas, Supabase devuelve la sesión del usuario.
4.  **Antes de redirigir**, la aplicación ejecuta `await ServicioPermisos().cargarPermisosUsuario()`.
5.  Esta llamada invoca la función RPC de Postgres `obtener_mis_permisos` y almacena los códigos de permisos en un `Set<String>` local en memoria.
6.  Una vez cargados, se hace la transición a [`AdministracionRolesPage`](file:///Users/hugozuniga/development/Proyecto Programacion Movil/proyecto_programacion_movil_grupo_4/lib/features/security/presentation/paginas/administracion_roles_page.dart).

### Flujo de Autorización Reactivo (`WidgetAutorizado`)
El frontend provee el widget `WidgetAutorizado` para envolver secciones de la UI de forma declarativa. Puede evaluar:
*   Un permiso simple: `WidgetAutorizado(permiso: 'seguridad.roles.crear', child: BotonCrear())`.
*   Una lista de permisos bajo dos condiciones:
    *   **Cualquiera (Default)**: Muestra el widget si el usuario tiene al menos un código de permiso en la lista (`ServicioPermisos().tieneAlguno`).
    *   **Todos** (`requiereTodos: true`): Muestra el widget si el usuario cuenta con la totalidad de los permisos requeridos (`ServicioPermisos().tieneTodos`).
*   **Fallback**: Si el usuario no tiene permisos, se renderiza opcionalmente un widget alternativo (por defecto un `SizedBox.shrink()` invisible).

---

## 6. Flujos Funcionales de la Aplicación

### A. Gestión de Roles y Permisos (Árbol Jerárquico)
1.  **Carga**: Se listan los roles desde la tabla `roles` en el panel izquierdo. Al seleccionar uno, se ejecuta `obtenerArbolPermisos(idRol)`.
2.  **Renderizado**: La UI dibuja de forma recursiva los `NodoRecurso` mediante widgets `_WidgetNodoArbol`.
3.  **Evaluación de Estados**: Cada nodo calcula dinámicamente su estado de selección (`EstadoSeleccion`):
    *   `marcado`: Si todos los permisos de sus hojas están otorgados.
    *   `indeterminado`: Si sólo algunos permisos están otorgados.
    *   `desmarcado`: Si ningún permiso está otorgado.
4.  **Selección en Cascada**: Marcar o desmarcar un nodo padre ejecuta `seleccionarEnCascada(valor)`, mutando de forma recursiva los permisos del nodo y de todos sus descendientes.
5.  **Guardado**: Al presionar **Guardar Permisos**, se extraen todos los IDs de los permisos activos y se envían a la función RPC `guardar_permisos_rol`.

### B. Registro y Gestión de Colaboradores
1.  **Carga**: Se listan los perfiles junto con la información unida de su institución (`instituciones`) y roles asignados (`usuarios_roles`).
2.  **Creación**: 
    *   Se extraen las instituciones activas (`obtenerInstituciones`).
    *   El administrador ingresa los datos y selecciona una institución del dropdown (`isExpanded: true` previene el desbordamiento de pantalla).
    *   Al enviar, se invoca `signUp` en Supabase Auth, transmitiendo los datos del colaborador en el parámetro `data`.
    *   El trigger de base de datos intercepta el registro e inserta los datos complementarios del colaborador en `perfiles`.
3.  **Asignación de Roles**: Al pulsar **Asignar Roles**, se presenta un listado con checkboxes y al pulsar **Guardar Asignación** se invoca a la función RPC `guardar_roles_usuario`.

---

## 7. Configuración de Dependencias y Variables

### Dependencias Principales ([`pubspec.yaml`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/pubspec.yaml))
*   `flutter`: SDK de Flutter.
*   `cupertino_icons: ^1.0.8`: Iconografía estilo Cupertino (iOS).
*   `supabase_flutter: ^2.17.2`: SDK oficial de Flutter para la comunicación con Supabase.

### Variables de Entorno / Conexión ([`main.dart`](file:///Users/hugozuniga/development/Proyecto%20Programacion%20Movil/proyecto_programacion_movil_grupo_4/lib/main.dart))
El proyecto cuenta con las siguientes credenciales embebidas directamente en el código de inicialización:
*   **Supabase URL**: `https://lxxzuqpogmuayfefiuiy.supabase.co`
*   **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4eHp1cXBvZ211YXlmZWZpdWl5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1OTc4NzYsImV4cCI6MjEwMzE3Mzg3Nn0.Qr2vM2Bi_ylycYXbP9voIQhHHoRyIQq3r6cfeLt0p0w`
