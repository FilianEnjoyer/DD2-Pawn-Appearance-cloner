-- ============================================================
-- ============================================================
-- PASO 73: CLONADO DE CARACTERISTICAS DEL CUERPO SIN TOCAR VISUALES DEL EQUIPO
--
-- Se parte del Paso 69, pero ahora los campos visuales del equipo quedan
-- fuera del clonado: tops, pants, mantle, helm, backpack, underwear y
-- facewear, incluyendo sus variaciones, NO se leen ni se escriben.
--
-- Gender y Species tampoco se modifican.
--
-- Para los colores y otros datos que pueden vivir como propiedades en
-- HumanPartSwapper o MetaData, Paso 70 busca getters/setters REALES por
-- reflexion. Solo guarda propiedades corporales que tengan un getter sin
-- parametros, un setter compatible y un valor Lua simple.
--
-- No se inventan nombres de getters/setters. Si un dato complejo aparece,
-- queda registrado en el log con su tipo real para poder estudiarlo aparte.
-- ============================================================

-- PASO 59: bloqueo de doble ejecucion de la misma version.
-- Las copias de versiones antiguas con otros nombres siguen requiriendo eliminacion manual.
if rawget(_G, "__PawnResearch_Paso59_Loaded") == true then
    return
end
_G.__PawnResearch_Paso59_Loaded = true

-- ============================================================
-- PASO 76: despues de que Paso 74 dejo el cuerpo invisible y el equipo flotando,
-- esta version hace rollback del experimento peligroso. No escribe campos de
-- escala del Human, no llama setupScale/updateScale, no refresca PartSwapper y
-- no escribe colores. En su lugar, inspecciona _BodyEditContext._EditValues
-- para descubrir las claves reales de los sliders corporales.
-- ============================================================

-- pawn_research_paso50.lua
--
-- PASO 43: diagnostico de por que HumanSkillContext:setSkill() devuelve FALSE,
-- usando exactamente el patron de TWINWV (get_SkillContext + EnabledCustomSkills)
-- sin asumir que un skill no aprendido pueda equiparse por fuerza.
-- El Paso 42 ya demostro que la lectura devuelve IDs reales, pero los intentos
-- de escritura de Momo devolvieron FALSE repetidamente. Este paso corta el
-- reintento cada 30 frames y agrega diagnostico SOLO LECTURA antes de tocar
-- EnabledCustomSkills/SkillAvailability.
-- externa de IDs/nombres y usa ese catalogo para mostrar/validar las skills
-- por vocacion en el editor de peones. No se incorpora la funcion de cambio
-- de vocacion/hotkeys de TWINWV: solo sus datos de skills.
--
-- Log 41 confirmado: HumanSkillContext:getSkillID/setSkill ya leen los IDs
-- reales de 6 slots en el peon Mage (28,34,33,25,29,35).
--
--
-- PASO 38: sobre el Paso 37 (que encontro QUE objetos mirar), este paso
-- mira ADENTRO de los 2-3 candidatos reales sin filtrar nada, para sacar la
-- lista completa de campos (con su valor actual) y metodos:
--   - Human.<SkillContext>k__BackingField (app.HumanSkillContext) -- el
--     candidato mas fuerte para el loadout de skills EQUIPADAS ahora.
--   - Human.<Job0XActionCtrl>k__BackingField de la VOCACION ACTUAL del
--     peon (se arma el nombre del campo dinamicamente segun CurrentJob,
--     no hay que elegirlo a mano) -- candidato al loadout que el juego
--     recuerda por vocacion.
--   - Human.<AbilityContext>k__BackingField, opcional via casilla (sistema
--     aparte, Abilities pasivas).
-- Sigue siendo SOLO LECTURA -- no escribe nada todavia. El proximo paso
-- (39) recien implementa lectura/escritura real de slots concretos, una
-- vez que confirmes en un log real como esta armado esto (nombres de campo
-- tipo _Skill01.._Skill04/_CoreSkill, y sus setters reales).
-- ============================================================
--
-- pawn_research_paso37.lua
--
-- PASO 37: primer paso hacia SKILLS (habilidades equipadas), a pedido tuyo.
-- Todavia no sabemos donde vive esto en la memoria del juego -- ni el campo/
-- metodo correcto, ni el enum de IDs de skill, ni si hay algo parecido al
-- bit de vocacion de itemData.json. En vez de inventar nombres de campo a
-- ciegas (que es exactamente lo que nos salio mal con los "9 parametros" de
-- getItem en el mod original), este paso es SOLO un diagnostico de lectura:
-- busca, sobre los objetos que ya sabemos que existen (app.Character, Human,
-- JobContext, PartSwapper y _PawnDataContext -- este ultimo ya sabiamos que
-- tiene _SubSkill/Personalidad/Voz, buen candidato a tener hermanos de
-- skills), todo campo o metodo cuyo nombre contenga "skill", "action" o
-- "ability". Es de solo lectura, no escribe nada.
--
-- Como usarlo: abre "Diagnostico de Skills (Paso 37)", elegi el peon,
-- pulsa el boton, y pasame el bloque del log que arranca en "PASO 37
-- DIAGNOSTICO DE SKILLS". Con eso identificamos el campo/metodo real y en
-- el proximo paso armamos la lectura/escritura de verdad (filtrada por
-- vocacion, si el juego lo permite de alguna forma parecida al equipo).
-- ============================================================
--
-- pawn_research_paso35.lua
--
-- PASO 35: se agrega VOCACION y NIVEL al panel de override (equipo/
-- personalidad/voz), como dos campos mas por peon, con el mismo mecanismo
-- confirmado en el Paso 15/16 (escribir CurrentJob/_Level via set_field()
-- sobre un personaje YA EXISTENTE, y reescribir el backing field del
-- contenedor por si el juego guarda una copia). A diferencia del Paso
-- 15/16 -- que solo forzaba esto en el peon que se CONTRATABA a
-- continuacion, via un hook de hirePawn -- esto se aplica en caliente
-- sobre cualquier peon del roster actual, igual que ya hacia el resto del
-- override (misma funcion hpo_apply_if_needed, mismo re.on_frame).
--
-- Tambien se corrigio como se muestran las vocaciones en TODA la interfaz
-- (la casilla de "solo mostrar equipo de la vocacion actual" y el nuevo
-- combo de Vocacion): antes se mostraba el nombre crudo del campo del
-- enum de app.Character.JobEnum ("Job01", "Job02", ...), que es literal-
-- mente como esta escrito en el juego -- lo confirmamos en el Paso 16
-- (dump_job_enum_names). Ahora hay una tabla nueva, HPO_JobRealNames, que
-- traduce cada Job01..Job10 a su nombre real (Fighter, Archer, Mage,
-- Thief, Warrior, Sorcerer, Mystic Spearhand, Trickster, Magick Archer,
-- Warfarer), deducida cruzando itemData.json: para Job01 a Job06 la
-- evidencia es solida (cada uno tiene un tipo de arma/armadura exclusivo y
-- reconocible: espadas, arcos, bastones, dagas, armas a dos manos,
-- arquibastones grandes). Para las 3 vocaciones hibridas (Job07-09) la
-- evidencia es mas circunstancial -- confirmalo la primera vez que las
-- uses viendo el menu del peon en el juego, y si algun numero no calza,
-- HPO_JobRealNames es la UNICA tabla que hay que corregir.
-- ============================================================
--
-- pawn_research_paso34-6.lua
--
-- PASO 34-6: ningun elemento de la interfaz muestra un CharacterID "pelado"
-- (solo numeros) sin el nombre del peon al lado. Se agrego una funcion
-- unica, describe_character_id(roster, character_id), que busca el ID en
-- el roster actual y devuelve "Nombre "Apodo" (CID=...)"; si el peon dueno
-- de ese ID ya no esta en la partida (por ejemplo lo despediste), devuelve
-- "Peon no presente en el roster actual (CID=...)" en vez de fallar o
-- mostrar solo el numero. Se aplico en:
--   - El candado de seguridad (CharacterID protegido): ahora muestra a
--     quien corresponde ese ID, o avisa si no esta presente.
--   - "Origen" / "Destino" del clonado de plantillas (antes decian solo
--     "CID origen: 123456").
--   - La lista de "Asignaciones actuales" (antes solo listaba
--     "CID=123456 -> plantilla"; ahora tambien dice el nombre del peon).
--   - Los mensajes de estado al asignar/quitar una asignacion persistente,
--     y al reaplicar el equipo/personalidad/voz de un peon (antes decian
--     "CID 123456" a secas).
--   - Los logs de restauracion automatica de plantillas (PASO 33), que
--     ahora incluyen el nombre ademas del CID.
-- El equipo (Main/Sub/Head/etc.), la personalidad, la especializacion y la
-- voz YA mostraban el nombre real (no solo el ID) desde antes de este
-- paso, asi que no se toco esa parte.
-- ============================================================
--
-- pawn_research_paso34-4.lua
--
-- PASO 34-4: dos arreglos sobre paso34-3, a partir de logpaso34v2.txt.
--
-- 1) EQUIPO NUNCA SE APLICABA: hpo_find_getitem_method() buscaba una
--    sobrecarga de getItem con 9 parametros (firma del mod original, escrito
--    para otra version del juego). Tu log confirmo que esa sobrecarga NO
--    EXISTE en tu version -- las reales son de 2 a 4 parametros. Ahora se
--    usa getItem(Int32 itemId, Int32 cantidad, Character/CharacterID), que
--    es la que de verdad calza con lo que ya teniamos a mano, encontrada por
--    la misma reflexion que ya hacia el codigo (nada de adivinar strings).
--
-- 2) HIPOTESIS DEL CONFLICTO CON EL CLONADO (la que vos mismo sospechaste):
--    la plantilla de PASO 33 incluye los mismos campos de _Meta que la ropa
--    (_TopsStyle, _PantsStyle, _HelmStyle, _MantleStyle, _BackpackStyle,
--    _FacewearStyle, _UnderwearStyle). Si el equipo real ya estaba aplicado
--    y despues cambia el roster (contratas/despides a CUALQUIERA), el
--    restauro automatico de PASO 33 reescribe esos mismos campos con los
--    valores clonados, pisando visualmente el equipo. Se agrego: (a) que el
--    restauro de PASO 33 invalide el cache de HiredPawnOverride para que se
--    reaplique el equipo justo despues, y (b) que un equipo exitoso llame a
--    apply_refresh() (la misma funcion que ya usa el clonado) por si
--    setEquip por si solo no repinta el modelo, igual que nos paso con
--    _HairStyle en el Paso 19-22.
--
-- Todo lo demas (plantillas persistentes, personalidad/especializacion/voz,
-- candado de seguridad, roster) sigue exactamente igual que en paso34-3.
-- ============================================================
--
-- pawn_research_paso34.lua (texto original de paso34, sin tocar mas abajo)
--
-- PASO 34: SE INCORPORA "Hired Pawn Override" (mod de terceros de Evo,
-- v1.5.3) a nuestro propio script.
--
-- Contexto: nos pasaste el mod original (HiredPawnOverride.lua +
-- itemData.json) diciendo que dejo de funcionar en la version actual de
-- DD2/REFramework. Al revisarlo, todo el bloque de equipo/personalidad/
-- especializacion/voz (ItemManager, _PawnDataContext) esta escrito de forma
-- razonable y puede seguir siendo valido -- el problema casi seguro esta
-- MAS ARRIBA: para encontrar al peon contratado, el mod original usaba
--   PawnManager:get_PartyPawnList() + PawnManager:getPartyPawnID(pawn)
-- Esos dos metodos no son los que confirmamos en nuestros propios pasos
-- (1-33): nosotros siempre usamos PawnManager:get_PawnCharacterList(),
-- que ya sabemos que funciona en tu version actual. Si get_PartyPawnList
-- ya no existe o cambio de forma, get_hired_pawn() del mod original
-- devuelve nil SIEMPRE, y por eso NADA se aplicaba nunca -- ni equipo, ni
-- personalidad, ni voz -- sin importar si el resto del codigo era correcto.
--
-- Por eso, en vez de parchear el mod original por separado, lo integramos
-- ACA usando nuestra propia infraestructura ya probada:
--   - get_roster() / find_roster_by_id() en vez de get_hired_pawn()
--   - get_part_swapper(character) en vez de character['<HumanPartSwapper>k__BackingField']
--     directo (misma idea, ya la teniamos con fallback a get_HumanPartSwapper())
--   - El resto (ItemManager para equipo, partSwapper._PawnDataContext para
--     personalidad/especializacion/voz) se porto casi tal cual, pero con
--     pcall + mensaje de error capturado en cada paso (el mod original a
--     veces descartaba el mensaje de error del pcall). Esta parte NO la
--     probamos nosotros todavia -- si algo de eso tambien cambio, el log
--     te va a decir EXACTAMENTE en que llamada fallo.
--
-- Ademas, en vez del esquema original de "Hired Pawn Slot 1 / Slot 2"
-- (una tabla fija de 2 casilleros), lo generalizamos a CUALQUIER peon del
-- roster actual, identificado por CharacterID -- igual que el resto de
-- este script. La configuracion de cada peon (equipo/personalidad/voz)
-- se guarda en reframework/data/PawnResearch/HiredPawnOverride/config.json
-- indexada por CharacterID, asi que no hay limite de 2 peones y sobrevive
-- a que cambies de peones contratados.
--
-- PASO 33 (plantillas de apariencia persistentes) sigue exactamente igual
-- mas abajo, sin tocar.
-- ============================================================

-- ------------------------------------------------------------
-- PASO 33: PLANTILLAS PERSISTENTES PARA PEONES EXISTENTES
--
-- Objetivo:
--   Tomar un peon que ya existe en la partida, copiarle una "plantilla"
--   (nivel, vocacion, nombre/apodo y _Meta de apariencia) y asociar esa
--   plantilla a su CharacterID.
--
-- La persistencia NO depende de modificar los bytes del save de DD2:
--   reframework/data/PawnResearch/PersistentTemplates/*.json
-- contiene las plantillas y una tabla de asignaciones CharacterID -> plantilla.
--
-- Al arrancar una partida, el script detecta el roster y, si encuentra un
-- CharacterID asignado, reaplica su plantilla una vez cuando cambia el
-- roster. Tambien hay un boton de restauracion manual.
--
-- IMPORTANTE:
--   - NO sustituimos app.Character.
--   - Conservamos el CharacterID y el objeto Pawn original.
--   - Por seguridad, gender/species se comprueban y no se modifican.
--   - NO hay hooks de alto trafico.
--   - El polling es muy ligero: una comprobacion cada 60 frames.
--
-- Basado en los metodos ya confirmados durante los pasos anteriores:
--   Human.StatusContext._Level
--   Human.JobContext.CurrentJob
--   PawnContext:setName / setNickName
--   HumanPartSwapper._Meta
-- ------------------------------------------------------------

-- PASO 34-4: reintegramos el log independiente que teniamos hasta el Paso
-- 22 (pawn_research_log.txt) y que se habia perdido en el camino hasta
-- paso34-3 -- desde entonces todo iba solo a logp(), que termina
-- mezclado con miles de lineas de ruido del propio REFramework en
-- re2_framework_log.txt (por eso costaba encontrar algo). logp() hace las
-- dos cosas: manda el mensaje a logp() (para verlo en vivo en la
-- consola/overlay) Y lo agrega a reframework/data/pawn_research_log.txt,
-- un archivo chico y propio con SOLO nuestros mensajes.
local PAWN_LOG_FILE = "pawn_research_log.txt"
local pawn_log_content = (function()
    local ok, content = pcall(function() return fs.read(PAWN_LOG_FILE) end)
    if ok and content ~= nil then return content end
    return ""
end)()

local function logp(msg)
    log.info(msg)
    pawn_log_content = pawn_log_content .. tostring(msg) .. "\n"
    pcall(function() fs.write(PAWN_LOG_FILE, pawn_log_content) end)
end

local TEMPLATE_DIR = "PawnResearch/PersistentTemplates"
local ASSIGNMENTS_FILE = TEMPLATE_DIR .. "/assignments.json"

local function safe(fn)
    local ok, a, b, c = pcall(fn)
    if ok then return a, b, c end
    return nil, a, nil
end

local function safe_call(obj, method_name, ...)
    if obj == nil then return nil end
    local ok, result = pcall(function(...) return obj:call(method_name, ...) end, ...)
    if ok then return result end
    return nil
end

local function value_to_string(v)
    if v == nil then return "nil" end
    if type(v) == "userdata" then
        local addr = safe(function() return v:get_address() end)
        if addr ~= nil then
            local td = safe(function() return v:get_type_definition() end)
            local tn = td and (safe(function() return td:get_full_name() end) or "<?>") or "<?>"
            return string.format("userdata(%s) 0x%X", tn, addr)
        end
    end
    return tostring(v)
end

local function get_pawn_manager()
    return sdk.get_managed_singleton("app.PawnManager")
end

local function find_field_in_hierarchy(td, exact_name)
    local seen = {}
    while td ~= nil do
        local tn = safe(function() return td:get_full_name() end) or "<?>"
        if seen[tn] then break end
        seen[tn] = true

        local fields = safe(function() return td:get_fields() end) or {}
        for _, f in ipairs(fields) do
            local fn = safe(function() return f:get_name() end)
            if fn == exact_name then
                return f
            end
        end

        td = safe(function() return td:get_parent_type() end)
    end
    return nil
end

local function get_field_value_by_name(obj, exact_name)
    if obj == nil then return nil end
    local td = safe(function() return obj:get_type_definition() end)
    if td == nil then return nil end
    local f = find_field_in_hierarchy(td, exact_name)
    if f == nil then return nil end
    return safe(function() return f:get_data(obj) end)
end

local function set_field_value_by_name(obj, exact_name, value)
    if obj == nil then return false, "objeto nil" end
    local ok, err = pcall(function() obj:set_field(exact_name, value) end)
    if ok then return true, nil end
    return false, tostring(err)
end

-- ============================================================
-- Candado de seguridad por CharacterID (el mismo mecanismo de los pasos
-- anteriores). Mientras este puesto, ningun peon con ese CharacterID puede
-- ser modificado por este script -- ni a mano, ni por la restauracion
-- automatica del polling de abajo.
-- ============================================================
local post_update_audit_only = true -- se desactiva en un paso posterior tras validar el TDB post-TU4
local protected_id_value = { "2283028347" } -- Emilia por defecto. Vacio para desactivar.

local function is_character_protected(character_id)
    if protected_id_value[1] == nil or protected_id_value[1] == "" then return false end
    if character_id == nil then return false end
    return tostring(character_id) == protected_id_value[1]
end

local function get_pawn_context_for_character(character)
    if character == nil then return nil end

    local pm = get_pawn_manager()
    if pm == nil then return nil end
    local list = safe_call(pm, "get_PawnCharacterList")
    if list == nil then return nil end

    local target_id = get_field_value_by_name(character, "CharacterID")
    local count = safe_call(list, "get_Count") or 0

    for i = 0, count - 1 do
        local c = safe_call(list, "get_Item", i)
        local cid = get_field_value_by_name(c, "CharacterID")
        if c ~= nil and tostring(cid) == tostring(target_id) then
            local pawn = safe_call(pm, "getPartyPawn(app.Character, System.Boolean)", c, true)
            if pawn == nil then return nil end

            local gp = safe_call(pawn, "get_CachedAIGoalPlanning")
            if gp == nil then return nil end

            return safe_call(gp, "get_CachedPawnContext")
        end
    end

    return nil
end

local function get_human(character)
    return get_field_value_by_name(character, "<Human>k__BackingField")
end

local function get_status(character)
    local human = get_human(character)
    return get_field_value_by_name(human, "<StatusContext>k__BackingField")
end

local function get_job_context(character)
    local human = get_human(character)
    return get_field_value_by_name(human, "<JobContext>k__BackingField")
end

-- ============================================================
-- PASO 34-5: casilla de "solo mostrar equipo de la vocacion actual"
--
-- Confirmado cruzando 4 contrataciones reales contra itemData.json:
-- el bit que usa el campo "job" de cada item es 2^CurrentJob (NO
-- 2^(CurrentJob-1); ese otro exponente es el que usa ChangedJobBits,
-- un campo distinto). Los 4 casos observados calzaron exacto:
--   CurrentJob=1 -> bit=2  (Valiant Armor, job=2)
--   CurrentJob=2 -> bit=4  (Stoutdraw Armor, job=4)
--   CurrentJob=4 -> bit=16 (Battahli Jacket, job=16)
--   CurrentJob=6 -> bit=64 (Animistic Robe, job=64)
-- Jewelry/Mantle/Visual usan job=1022 (bits de las 9 vocaciones base
-- combinados), por eso quedan disponibles para cualquiera de esas 9.
--
-- Nota: si mas adelante usas un peon Warfarer (o cualquier vocacion
-- fuera de las 9 bases) y la casilla le oculta TODO el equipo de una
-- categoria, es porque esa vocacion no tiene bit propio en itemData.json
-- -- asi es como el juego original restringe ese equipo, no es un bug
-- de este filtro.
local function is_job_bit_set(mask, job_index)
    if mask == nil or job_index == nil then return true end
    local bit_value = 2 ^ job_index
    local shifted = math.floor(mask / bit_value)
    return shifted % 2 == 1
end

-- Traduce app.Character.JobEnum a nombres reales. IMPORTANTE: el juego NO
-- guarda "Fighter", "Archer", etc. como nombre del campo del enum -- eso
-- ya lo confirmamos en el Paso 16 (dump_job_enum_names): los campos se
-- llaman literalmente Job01, Job02 ... Job10 (None=0). Por eso, aunque la
-- reflexion funcione perfecto, mostrar el nombre del campo tal cual da
-- "Job01 (1)" en vez de "Fighter (1)".
--
-- HPO_JobRealNames de abajo es la traduccion manual Job01..Job10 -> nombre
-- real de vocacion. Se dedujo cruzando, para cada valor de CurrentJob, que
-- tipo de arma/armadura de itemData.json tiene EXACTAMENTE ese bit (ver los
-- comentarios de mas arriba, "PASO 34-5: casilla de..."): p.ej. el bit de
-- CurrentJob=1 solo lo tienen espadas (Trusty Sword, Iron Sword, Broadsword)
-- -> Fighter; el de CurrentJob=2 solo arcos (Fluted Bow, Hunter's Bow) ->
-- Archer; el de CurrentJob=4 solo dagas (Stilettos, Throatcutters) -> Thief;
-- el de CurrentJob=6 solo arquibastones grandes (Grievous Horns) -> Sorcerer.
-- Del 1 al 6 esta cruzado asi con evidencia solida. Del 7 al 9 (las 3
-- vocaciones hibridas) la evidencia es mas circunstancial (nombres de arma
-- con temática de lanza/filo, de baston/ceptro, y de flechas magicas/onirico
-- respectivamente) -- confirmalo tu mismo la primera vez que uses cada una
-- (la vocacion real que aparece en el menu del peon en el juego) y si algun
-- numero no calza, corrigelo aca abajo, es la UNICA tabla que hay que tocar.
local HPO_JobRealNames = {
    [0] = "Sin vocacion",
    [1] = "Fighter",
    [2] = "Archer",
    [3] = "Mage",
    [4] = "Thief",
    [5] = "Warrior",
    [6] = "Sorcerer",
    [7] = "Mystic Spearhand",
    [8] = "Magick Archer",
    [9] = "Trickster",
    [10] = "Warfarer",
}

-- Traduce app.Character.JobEnum a nombres reales, leyendo los valores
-- estaticos del enum (mismo truco que ya usamos en el Paso 13). Se hace
-- una sola vez al cargar el script. Ya no se usa para mostrar el nombre
-- (para eso esta HPO_JobRealNames de arriba) -- se conserva solo como
-- respaldo por si algun dia aparece una vocacion nueva (DLC) que todavia
-- no este en esa tabla, para no mostrar un simple "<numero desconocido>".
local hpo_job_enum_names = {}
local function hpo_load_job_enum_names()
    local td = sdk.find_type_definition("app.Character.JobEnum")
    if td == nil then return end
    local fields = safe(function() return td:get_fields() end) or {}
    for _, field in ipairs(fields) do
        local is_static = safe(function() return field:is_static() end)
        if is_static then
            local fname = safe(function() return field:get_name() end)
            local value = safe(function() return field:get_data(nil) end)
            if fname ~= nil and value ~= nil then
                hpo_job_enum_names[tostring(value)] = fname
            end
        end
    end
end
hpo_load_job_enum_names()

local function hpo_job_name(current_job)
    if current_job == nil then return "<sin vocacion>" end
    local key = tonumber(current_job)
    local real = key ~= nil and HPO_JobRealNames[key] or nil
    if real ~= nil then
        return real .. " (" .. tostring(current_job) .. ")"
    end
    -- Vocacion fuera de la tabla de arriba (no deberia pasar con el juego
    -- base): usamos el nombre crudo del enum en vez de fallar en silencio.
    return (hpo_job_enum_names[tostring(current_job)] or "Vocacion desconocida") .. " (" .. tostring(current_job) .. ")"
end

local function get_part_swapper(character)
    if character == nil then return nil end

    local direct = get_field_value_by_name(character, "<HumanPartSwapper>k__BackingField")
    if direct ~= nil then return direct end

    return safe_call(character, "get_HumanPartSwapper")
end

local function get_meta(character)
    local ps = get_part_swapper(character)
    if ps == nil then return nil, nil end
    return get_field_value_by_name(ps, "_Meta"), ps
end

local function meta_get(meta, field_name)
    if meta == nil then return nil end
    if type(meta) == "table" then return meta[field_name] end
    return get_field_value_by_name(meta, field_name)
end

local function meta_set(meta, field_name, value)
    if meta == nil then return false, "meta nil" end
    if type(meta) == "table" then
        meta[field_name] = value
        return true, nil
    end
    return set_field_value_by_name(meta, field_name, value)
end

-- Lista historica mantenida para compatibilidad con plantillas antiguas.
-- Las plantillas nuevas NO se limitan a esta lista: snapshot_meta completo
-- descubre los campos actuales directamente desde app.CharacterEditDefine.MetaData.

-- Estos campos no forman parte del cuerpo que queremos clonar.
-- Tambien quedan protegidos aunque aparezcan en una plantilla antigua.
local META_FIELDS_NEVER_COPY = {
    _Gender = true,
    _Species = true,

    -- Visuales del equipo.
    _TopsStyle = true,
    _TopsVariationStyle = true,
    _PantsStyle = true,
    _PantsVariationStyle = true,
    _MantleStyle = true,
    _MantleVariationStyle = true,
    _HelmStyle = true,
    _HelmVariationStyle = true,
    _UnderwearStyle = true,
    _UnderwearVariationStyle = true,
    _BackpackStyle = true,
    _FacewearStyle = true,
    _FacewearVariationStyle = true,

    -- Estado interno, no es una caracteristica corporal.
    _Locked = true,
}

local function is_simple_lua_value(value)
    local t = type(value)
    return t == "number" or t == "string" or t == "boolean"
end

local BODY_PROPERTY_KEYWORDS = {
    "hair",
    "skin",
    "fur",
    "tattoo",
    "scar",
    "face",
    "eye",
    "eyebrow",
    "eyelash",
    "eyeliner",
    "eyeshadow",
    "freckle",
    "cheek",
    "lip",
    "nose",
    "muscle",
    "body",
    "height",
    "stature",
    "scale",
    "proportion",
}

local paso71_hair_diag_done = {}

local BODY_PROPERTY_EXCLUDES = {
    "tops",
    "pants",
    "mantle",
    "helm",
    "helmet",
    "backpack",
    "underwear",
    "facewear",
    "weapon",
    "armor",
    "equip",
    "equipment",
    "gear",
    "cloth",
}

local function text_contains_any(text, words)
    local lower = string.lower(tostring(text or ""))
    for _, word in ipairs(words) do
        if string.find(lower, word, 1, true) then
            return true
        end
    end
    return false
end

local function is_body_property_name(property_name)
    if property_name == nil then return false end
    if not text_contains_any(property_name, BODY_PROPERTY_KEYWORDS) then
        return false
    end
    if text_contains_any(property_name, BODY_PROPERTY_EXCLUDES) then
        return false
    end
    return true
end

local resolve_property_setter
local resolve_property_getter

local function split_property_accessor(method_name)
    local name = tostring(method_name or "")

    if string.sub(name, 1, 4) == "get_" and #name > 4 then
        return "get", string.sub(name, 5)
    end
    if string.sub(name, 1, 3) == "get" and #name > 3 then
        return "get", string.sub(name, 4)
    end
    if string.sub(name, 1, 4) == "set_" and #name > 4 then
        return "set", string.sub(name, 5)
    end
    if string.sub(name, 1, 3) == "set" and #name > 3 then
        return "set", string.sub(name, 4)
    end

    return nil, nil
end

local function get_body_property_pairs(obj)
    local getters = {}
    local setters = {}
    local td = safe(function() return obj and obj:get_type_definition() end)
    local seen_types = {}

    while td ~= nil do
        local type_name = safe(function() return td:get_full_name() end) or "<?>"
        if seen_types[type_name] then break end
        seen_types[type_name] = true

        local methods = safe(function() return td:get_methods() end) or {}
        for _, method in ipairs(methods) do
            local is_static = safe(function() return method:is_static() end)
            local method_name = safe(function() return method:get_name() end)
            if is_static ~= true and method_name ~= nil then
                local kind, property_name = split_property_accessor(method_name)
                if kind ~= nil and property_name ~= nil
                    and is_body_property_name(property_name)
                then
                    local param_types = safe(function() return method:get_param_types() end) or {}
                    local return_type = safe(function() return method:get_return_type() end)
                    local return_name = return_type and safe(function() return return_type:get_full_name() end) or "<?>"

                    if kind == "get" and #param_types == 0 then
                        getters[property_name] = getters[property_name] or {}
                        getters[property_name][#getters[property_name] + 1] = {
                            method_name = method_name,
                            return_type = return_name,
                        }
                    elseif kind == "set" and #param_types == 1 then
                        local param_name = safe(function() return param_types[1]:get_full_name() end) or "<?>"
                        setters[property_name] = setters[property_name] or {}
                        setters[property_name][#setters[property_name] + 1] = {
                            method_name = method_name,
                            param_type = param_name,
                        }
                    end
                end
            end
        end

        td = safe(function() return td:get_parent_type() end)
    end

    local property_pairs = {}
    for property_name, get_list in pairs(getters) do
        for _, getter in ipairs(get_list) do
            for _, setter in ipairs(setters[property_name] or {}) do
                if getter.return_type == setter.param_type then
                    property_pairs[#property_pairs + 1] = {
                        property_name = property_name,
                        getter = getter.method_name,
                        setter = setter.method_name,
                        type_name = getter.return_type,
                    }
                end
            end
        end
    end

    return property_pairs
end

local function snapshot_body_properties(obj, label, owner)
    local result = {}
    local skipped = {}
    if obj == nil then return result, skipped end

    for _, pair in ipairs(get_body_property_pairs(obj)) do
        local ok, value = pcall(function()
            return obj:call(pair.getter)
        end)

        if ok and is_simple_lua_value(value) then
            result[#result + 1] = {
                name = pair.property_name,
                getter = pair.getter,
                setter = pair.setter,
                type_name = pair.type_name,
                owner = tostring(label),
                value = value,
            }
            logp(
                "[PawnResearch] PASO 72 BODY PROP CAPTURADA "
                .. tostring(label)
                .. " :: " .. tostring(pair.property_name)
                .. " getter=" .. tostring(pair.getter)
                .. " setter=" .. tostring(pair.setter)
                .. " tipo=" .. tostring(pair.type_name)
                .. " valor=" .. tostring(value)
            )
        else
            skipped[#skipped + 1] = {
                name = pair.property_name,
                getter = pair.getter,
                setter = pair.setter,
                type_name = pair.type_name,
                lua = type(value),
                reason = ok and "valor_no_primitivo" or "getter_exception",
            }
        end
    end

    if #result == 0 and #skipped == 0 then
        logp(
            "[PawnResearch] PASO 72 BODY PROP: sin getters/setters corporales simples en "
            .. tostring(label)
        )
    end

    return result, skipped
end

local function paso72_log_type_instance(obj, label, keywords, max_depth, visited)
    if obj == nil then return end
    if max_depth == nil then max_depth = 1 end
    if visited == nil then visited = {} end

    local addr = safe(function() return obj:get_address() end)
    local visit_key = tostring(addr or value_to_string(obj))
    if visited[visit_key] then return end
    visited[visit_key] = true

    local td = safe(function() return obj:get_type_definition() end)
    if td == nil then return end
    local type_name = safe(function() return td:get_full_name() end) or "<?>"

    logp("[PawnResearch] PASO 72 DEEP TIPO " .. label .. " :: " .. type_name)

    local fields = safe(function() return td:get_fields() end) or {}
    for _, field in ipairs(fields) do
        local fname = safe(function() return field:get_name() end)
        local is_static = safe(function() return field:is_static() end)
        if fname ~= nil and is_static ~= true
            and (keywords == nil or text_contains_any(fname, keywords))
        then
            local ftype = safe(function()
                local ft = field:get_type()
                return ft and ft:get_full_name() or "<?>"
            end) or "<?>"
            local value = safe(function() return field:get_data(obj) end)
            logp(
                "[PawnResearch] PASO 72 DEEP CAMPO "
                .. label .. " :: " .. fname
                .. " tipo=" .. ftype
                .. " valor=" .. value_to_string(value)
            )

            if max_depth > 0 and value ~= nil and type(value) == "userdata" then
                local child_type = safe(function()
                    local ctd = value:get_type_definition()
                    return ctd and ctd:get_full_name() or "<?>"
                end) or "<?>"
                if child_type ~= type_name
                    and not string.find(child_type, "via.GameObject", 1, true)
                    and not string.find(child_type, "via.Component", 1, true)
                then
                    local child_keywords = keywords
                    local child_lower = string.lower(child_type)
                    if string.find(child_lower, "color", 1, true)
                        or string.find(child_lower, "colour", 1, true)
                        or string.find(child_lower, "hair", 1, true)
                        or string.find(child_lower, "vector", 1, true)
                        or string.find(child_lower, "float4", 1, true)
                    then
                        child_keywords = nil
                    end
                    paso72_log_type_instance(
                        value,
                        label .. "." .. fname,
                        child_keywords,
                        max_depth - 1,
                        visited
                    )
                end
            end
        end
    end

    local methods = safe(function() return td:get_methods() end) or {}
    for _, method in ipairs(methods) do
        local mname = safe(function() return method:get_name() end)
        local is_static = safe(function() return method:is_static() end)
        if mname ~= nil and is_static ~= true
            and (keywords == nil or text_contains_any(mname, keywords))
        then
            local params = safe(function() return method:get_param_types() end) or {}
            local ret = safe(function() return method:get_return_type() end)
            local ret_name = ret and safe(function() return ret:get_full_name() end) or "<?>"
            local pnames = {}
            for _, p in ipairs(params) do
                pnames[#pnames + 1] = safe(function() return p:get_full_name() end) or "<?>"
            end
            logp(
                "[PawnResearch] PASO 72 DEEP METODO "
                .. label .. " :: " .. mname
                .. " params=" .. table.concat(pnames, ",")
                .. " return=" .. ret_name
            )
        end
    end
end

local function paso72_dump_deep_body_candidates(ps, character)
    local keywords = {
        "hair", "color", "colour", "tint", "dye", "palette",
        "material", "param", "body", "height", "scale", "stature",
        "proportion", "joint", "transform", "bone", "size", "length"
    }

    local candidates = {
        { label = "BodyDetailEditor", obj = safe_call(ps, "get_BodyDetailEditor") },
        { label = "BodyDetailEditor.Hair", obj = nil },
        { label = "BodyDetailEditor.BodyHair", obj = nil },
        { label = "BodyDetailEditor.MaterialBakerController", obj = nil },
        { label = "Human", obj = get_human(character) },
    }

    local bde = candidates[1].obj
    if bde ~= nil then
        candidates[2].obj = safe_call(bde, "get_Hair")
        candidates[3].obj = safe_call(bde, "get_BodyHair")
        candidates[4].obj = get_field_value_by_name(bde, "_MaterialBakerController")
    end

    for _, c in ipairs(candidates) do
        if c.obj ~= nil then
            paso72_log_type_instance(c.obj, c.label, keywords, 2)
        else
            logp("[PawnResearch] PASO 72 DEEP " .. c.label .. " = nil")
        end
    end
end

local function paso71_dump_hair_color_candidates(ps)
    if ps == nil then return end

    local candidates = {
        { name = "BodyDetailEditor", getter = "get_BodyDetailEditor" },
        { name = "HairObj", getter = "get_HairObj" },
        { name = "HairSwapObj", getter = "get_HairSwapObj" },
    }

    for _, candidate in ipairs(candidates) do
        local obj = safe_call(ps, candidate.getter)
        if obj ~= nil then
            logp(
                "[PawnResearch] PASO 72 HAIR DIAG "
                .. candidate.name
                .. " tipo=" .. (safe(function()
                    local td_obj = obj:get_type_definition()
                    return td_obj and td_obj:get_full_name() or "<?>"
                end) or "<?>")
            )

            local td = safe(function() return obj:get_type_definition() end)
            local seen_types = {}
            while td ~= nil do
                local type_name = safe(function() return td:get_full_name() end) or "<?>"
                if seen_types[type_name] then break end
                seen_types[type_name] = true

                logp(
                    "[PawnResearch] PASO 72 HAIR DIAG TIPO="
                    .. type_name
                )

                local fields = safe(function() return td:get_fields() end) or {}
                for _, field in ipairs(fields) do
                    local fname = safe(function() return field:get_name() end)
                    if fname ~= nil
                        and text_contains_any(
                            fname,
                            { "hair", "color", "colour", "tint", "material", "param", "palette", "dye" }
                        )
                    then
                        local ftype = safe(function()
                            local ft = field:get_type()
                            return ft and ft:get_full_name() or "<?>"
                        end) or "<?>"
                        local is_static = safe(function() return field:is_static() end)
                        local value = nil
                        if is_static ~= true then
                            value = safe(function() return field:get_data(obj) end)
                        end
                        logp(
                            "[PawnResearch] PASO 72 HAIR DIAG CAMPO "
                            .. type_name
                            .. "::" .. fname
                            .. " tipo=" .. ftype
                            .. " static=" .. tostring(is_static)
                            .. " valor=" .. value_to_string(value)
                        )
                    end
                end

                local methods = safe(function() return td:get_methods() end) or {}
                for _, method in ipairs(methods) do
                    local mname = safe(function() return method:get_name() end)
                    if mname ~= nil
                        and text_contains_any(
                            mname,
                            { "hair", "color", "colour", "tint", "material", "param", "palette", "dye" }
                        )
                    then
                        local is_static = safe(function() return method:is_static() end)
                        local params = safe(function() return method:get_param_types() end) or {}
                        local ret = safe(function() return method:get_return_type() end)
                        local ret_name = ret and safe(function() return ret:get_full_name() end) or "<?>"
                        local pnames = {}
                        for i, p in ipairs(params) do
                            pnames[#pnames + 1] =
                                safe(function() return p:get_full_name() end) or "<?>"
                        end
                        logp(
                            "[PawnResearch] PASO 72 HAIR DIAG METODO "
                            .. type_name
                            .. "::" .. mname
                            .. " static=" .. tostring(is_static)
                            .. " params=" .. table.concat(pnames, ",")
                            .. " return=" .. ret_name
                        )
                    end
                end

                td = safe(function() return td:get_parent_type() end)
            end
        else
            logp(
                "[PawnResearch] PASO 72 HAIR DIAG "
                .. candidate.name
                .. " = nil"
            )
        end
    end
end


-- ============================================================
-- PASO 82: DIAGNOSTICO EDITVALUES POR get_element, SIN ESCRITURAS
--
-- El diagnostico del Paso 72 confirmo estructuras reales:
--   BodyDetailEditor._Hair -> app.charaedit.ch000.Hair
--   Hair._RootColor / _TipColor / _CapRootColor -> via.Color
--   via.Color.rgba -> System.UInt32
--   Hair get/set RootColor, TipColor, AutoCapColor, CapRootColor,
--       TipBlend, Sheen, Gloss
--   BodyDetailEditor._BodyHair -> app.charaedit.ch000.BodyHair
--   BodyHair._Color -> via.Color
--   BodyHair get/set Color, Density
--   Human get_BodyScale() -> System.Single
--   Human get/set Scale() -> app.Character.ScaleEnum
--
-- No usamos nombres inventados: todos estos miembros vienen del log de
-- reflexion del juego real. El color se serializa como rgba (UInt32),
-- y al aplicar se modifica el rgba del via.Color EXISTENTE y se vuelve a
-- asignar mediante el setter confirmado, para cubrir copia de valor.
-- ============================================================

local function paso73_get_color_rgba(color_obj)
    if color_obj == nil then return nil, "color_nil" end

    local td = safe(function() return color_obj:get_type_definition() end)
    if td == nil then return nil, "color_type_nil" end

    local type_name = safe(function() return td:get_full_name() end) or "<?>"
    if type_name ~= "via.Color" then
        return nil, "tipo_no_es_via.Color:" .. tostring(type_name)
    end

    local field = find_field_in_hierarchy(td, "rgba")
    if field == nil then
        return nil, "campo_rgba_no_encontrado"
    end

    local field_type = safe(function()
        local ft = field:get_type()
        return ft and ft:get_full_name() or "<?>"
    end) or "<?>"

    if field_type ~= "System.UInt32" then
        return nil, "tipo_rgba_inesperado:" .. tostring(field_type)
    end

    local rgba = safe(function() return field:get_data(color_obj) end)
    return rgba, nil
end

local function paso73_snapshot_hair_data(ps)
    local result = {}
    if ps == nil then return result end

    local bde = safe_call(ps, "get_BodyDetailEditor")
    if bde == nil then return result end

    local hair = safe_call(bde, "get_Hair")
    if hair ~= nil then
        local hair_data = {}

        local root = safe_call(hair, "get_RootColor")
        local tip = safe_call(hair, "get_TipColor")
        local cap_root = safe_call(hair, "get_CapRootColor")

        hair_data.root_rgba = select(1, paso73_get_color_rgba(root))
        hair_data.tip_rgba = select(1, paso73_get_color_rgba(tip))
        hair_data.cap_root_rgba = select(1, paso73_get_color_rgba(cap_root))
        hair_data.auto_cap_color = safe_call(hair, "get_AutoCapColor")
        hair_data.tip_blend = safe_call(hair, "get_TipBlend")
        hair_data.sheen = safe_call(hair, "get_Sheen")
        hair_data.gloss = safe_call(hair, "get_Gloss")

        result.hair = hair_data

        logp(
            "[PawnResearch] PASO 73 HAIR CAPTURADO"
            .. " root=" .. tostring(hair_data.root_rgba)
            .. " tip=" .. tostring(hair_data.tip_rgba)
            .. " caproot=" .. tostring(hair_data.cap_root_rgba)
            .. " autoCap=" .. tostring(hair_data.auto_cap_color)
            .. " tipBlend=" .. tostring(hair_data.tip_blend)
            .. " sheen=" .. tostring(hair_data.sheen)
            .. " gloss=" .. tostring(hair_data.gloss)
        )
    end

    local body_hair = safe_call(bde, "get_BodyHair")
    if body_hair ~= nil then
        local body_hair_data = {}
        local color = safe_call(body_hair, "get_Color")
        body_hair_data.color_rgba = select(1, paso73_get_color_rgba(color))
        body_hair_data.density = safe_call(body_hair, "get_Density")
        result.body_hair = body_hair_data

        logp(
            "[PawnResearch] PASO 73 BODYHAIR CAPTURADO"
            .. " color=" .. tostring(body_hair_data.color_rgba)
            .. " density=" .. tostring(body_hair_data.density)
        )
    end

    return result
end


local function paso73_verify_hair_color_data(character, payload, results)
    if character == nil or type(payload) ~= "table" then return end
    if type(payload.hair_detail) ~= "table" then return end

    local ps = get_part_swapper(character)
    if ps == nil then return end
    local bde = safe_call(ps, "get_BodyDetailEditor")
    if bde == nil then return end

    local verify_ok = 0
    local verify_fail = 0

    local hair = safe_call(bde, "get_Hair")
    local src = payload.hair_detail.hair
    if hair ~= nil and type(src) == "table" then
        local checks = {
            { key = "root_rgba", getter = "get_RootColor" },
            { key = "tip_rgba", getter = "get_TipColor" },
            { key = "cap_root_rgba", getter = "get_CapRootColor" },
        }
        for _, p in ipairs(checks) do
            if type(src[p.key]) == "number" then
                local color = safe_call(hair, p.getter)
                local actual = select(1, paso73_get_color_rgba(color))
                if tostring(actual) == tostring(src[p.key]) then
                    verify_ok = verify_ok + 1
                else
                    verify_fail = verify_fail + 1
                    logp(
                        "[PawnResearch] PASO 74 HAIR VERIFY FAIL "
                        .. p.key
                        .. " esperado=" .. tostring(src[p.key])
                        .. " actual=" .. tostring(actual)
                    )
                end
            end
        end

        local scalar_checks = {
            { key = "auto_cap_color", getter = "get_AutoCapColor" },
            { key = "tip_blend", getter = "get_TipBlend" },
            { key = "sheen", getter = "get_Sheen" },
            { key = "gloss", getter = "get_Gloss" },
        }
        for _, p in ipairs(scalar_checks) do
            if src[p.key] ~= nil then
                local actual = safe_call(hair, p.getter)
                if tostring(actual) == tostring(src[p.key]) then
                    verify_ok = verify_ok + 1
                else
                    verify_fail = verify_fail + 1
                    logp(
                        "[PawnResearch] PASO 74 HAIR VERIFY FAIL "
                        .. p.key
                        .. " esperado=" .. tostring(src[p.key])
                        .. " actual=" .. tostring(actual)
                    )
                end
            end
        end
    end

    local body_hair = safe_call(bde, "get_BodyHair")
    local body_src = payload.hair_detail.body_hair
    if body_hair ~= nil and type(body_src) == "table" then
        if type(body_src.color_rgba) == "number" then
            local color = safe_call(body_hair, "get_Color")
            local actual = select(1, paso73_get_color_rgba(color))
            if tostring(actual) == tostring(body_src.color_rgba) then
                verify_ok = verify_ok + 1
            else
                verify_fail = verify_fail + 1
                logp(
                    "[PawnResearch] PASO 74 BODYHAIR VERIFY FAIL color"
                    .. " esperado=" .. tostring(body_src.color_rgba)
                    .. " actual=" .. tostring(actual)
                )
            end
        end
        if body_src.density ~= nil then
            local actual = safe_call(body_hair, "get_Density")
            if tostring(actual) == tostring(body_src.density) then
                verify_ok = verify_ok + 1
            else
                verify_fail = verify_fail + 1
                logp(
                    "[PawnResearch] PASO 74 BODYHAIR VERIFY FAIL density"
                    .. " esperado=" .. tostring(body_src.density)
                    .. " actual=" .. tostring(actual)
                )
            end
        end
    end

    results.hair_verify_ok = verify_ok
    results.hair_verify_fail = verify_fail

    logp(
        "[PawnResearch] PASO 74 HAIR VERIFY resumen ok="
        .. tostring(verify_ok) .. " fail=" .. tostring(verify_fail)
    )
end

local function paso82_snapshot_body_edit_values(ps)
    if ps == nil then
        logp("[PawnResearch] PASO 82 EDITVALUES: PartSwapper nil")
        return nil
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 82 EDITVALUES: BodyEditor nil")
        return nil
    end

    local body_edit_context = get_field_value_by_name(body_editor, "_BodyEditContext")
    if body_edit_context == nil then
        logp("[PawnResearch] PASO 82 EDITVALUES: BodyEditContext nil")
        return nil
    end

    local ctx_type = object_type_name(body_edit_context)
    logp("[PawnResearch] PASO 82 EDITVALUES CONTEXTO tipo=" .. tostring(ctx_type))

    local ctx_td = safe(function() return body_edit_context:get_type_definition() end)
    if ctx_td == nil then
        logp("[PawnResearch] PASO 82 EDITVALUES: TypeDefinition nil")
        return nil
    end

    local edit_values_field = find_field_in_hierarchy(ctx_td, "_EditValues")
    if edit_values_field == nil then
        logp("[PawnResearch] PASO 82 EDITVALUES: campo _EditValues no encontrado por reflexion")
    else
        local ft = safe(function()
            local t = edit_values_field:get_type()
            return t and t:get_full_name() or "<?>"
        end) or "<?>"
        logp("[PawnResearch] PASO 82 EDITVALUES CAMPO _EditValues tipo=" .. tostring(ft))
    end

    local values = safe(function()
        return body_edit_context:get_field("_EditValues")
    end)

    if values == nil and edit_values_field ~= nil then
        values = safe(function()
            return edit_values_field:get_data(body_edit_context)
        end)
    end

    if values == nil then
        logp("[PawnResearch] PASO 82 EDITVALUES OBJETO ARRAY nil")
        return nil
    end

    local array_type = safe(function() return values:get_type_definition() end)
    local array_type_name = array_type and safe(function() return array_type:get_full_name() end)
        or object_type_name(values)
    logp("[PawnResearch] PASO 82 EDITVALUES ARRAY tipo=" .. tostring(array_type_name))

    local saw_get_element = false
    local saw_get_size = false
    local saw_get_elements = false
    if array_type ~= nil then
        local methods = safe(function() return array_type:get_methods() end) or {}
        for _, method in ipairs(methods) do
            local mn = safe(function() return method:get_name() end)
            if mn == "get_element" or mn == "get_size" or mn == "get_elements" then
                local params = safe(function() return method:get_param_types() end) or {}
                local names = {}
                for _, ptype in ipairs(params) do
                    names[#names + 1] = safe(function() return ptype:get_full_name() end) or "<?>"
                end
                local ret = safe(function()
                    local rt = method:get_return_type()
                    return rt and rt:get_full_name() or "<?>"
                end) or "<?>"
                logp("[PawnResearch] PASO 82 EDITVALUES ARRAY METODO " .. tostring(mn)
                    .. " params=" .. table.concat(names, ",") .. " return=" .. tostring(ret))
                if mn == "get_element" then saw_get_element = true end
                if mn == "get_size" then saw_get_size = true end
                if mn == "get_elements" then saw_get_elements = true end
            end
        end
    end

    logp("[PawnResearch] PASO 82 EDITVALUES ARRAY CAPACIDADES get_size="
        .. tostring(saw_get_size) .. " get_element=" .. tostring(saw_get_element)
        .. " get_elements=" .. tostring(saw_get_elements))

    local size = safe(function() return values:get_size() end)
    if size == nil then
        logp("[PawnResearch] PASO 82 EDITVALUES ARRAY get_size fallo")
        return { type_name = array_type_name, count = nil, enumerated = false, values = {} }
    end

    logp("[PawnResearch] PASO 82 EDITVALUES ARRAY size=" .. tostring(size))

    local count = tonumber(size) or 0
    if count < 0 then count = 0 end
    if count > 256 then count = 256 end

    local found = 0
    local snapshot_values = {}
    local unique_hashes = {}
    local unique_order = {}
    local duplicate_hashes = {}

    for i = 0, count - 1 do
        local element = safe(function()
            return values:get_element(i)
        end)

        if element == nil then
            logp("[PawnResearch] PASO 82 EDITVALUE index=" .. tostring(i) .. " elemento=nil")
        else
            found = found + 1
            local element_td = safe(function() return element:get_type_definition() end)
            local element_type = element_td and safe(function() return element_td:get_full_name() end)
                or object_type_name(element)
            logp("[PawnResearch] PASO 82 EDITVALUE index=" .. tostring(i)
                .. " tipo=" .. tostring(element_type))

            local edit_key_hash = nil
            local edit_value = nil

            if element_td ~= nil then
                local fields = safe(function() return element_td:get_fields() end) or {}
                local entries = {}
                for _, f in ipairs(fields) do
                    local name = safe(function() return f:get_name() end)
                    local type_name = safe(function()
                        local t = f:get_type()
                        return t and t:get_full_name() or "<?>"
                    end) or "<?>"
                    local val = safe(function() return f:get_data(element) end)
                    local repr = value_to_string(val)
                    logp("[PawnResearch] PASO 82 EDITVALUE CAMPO index=" .. tostring(i)
                        .. " :: " .. tostring(name)
                        .. " tipo=" .. tostring(type_name)
                        .. " valor=" .. tostring(repr))

                    if name == "_EditKeyHash" and type_name == "System.UInt32"
                        and type(val) == "number"
                    then
                        edit_key_hash = val
                    elseif name == "_Value" and type_name == "System.Single"
                        and type(val) == "number"
                    then
                        edit_value = val
                    end

                    if name ~= nil and is_simple_lua_value(val) then
                        entries[#entries + 1] = tostring(name) .. "=" .. repr
                    end
                end

                if #entries > 0 then
                    logp("[PawnResearch] PASO 82 EDITVALUE SIMPLE index=" .. tostring(i)
                        .. " :: " .. table.concat(entries, " | "))
                end
            end

            if edit_key_hash ~= nil and edit_value ~= nil then
                snapshot_values[#snapshot_values + 1] = {
                    index = i,
                    edit_key_hash = edit_key_hash,
                    value = edit_value,
                }

                local key = tostring(edit_key_hash)
                if unique_hashes[key] == nil then
                    unique_hashes[key] = true
                    unique_order[#unique_order + 1] = edit_key_hash
                else
                    duplicate_hashes[key] = (duplicate_hashes[key] or 1) + 1
                end
            end
        end
    end

    logp("[PawnResearch] PASO 82 EDITVALUES RESUMEN size=" .. tostring(size)
        .. " encontrados=" .. tostring(found)
        .. " valores_guardables=" .. tostring(#snapshot_values)
        .. " hashes_unicos=" .. tostring(#unique_order))

    -- Lectura cruzada: confirma como BodyEditContext resuelve cada hash cuando
    -- existen entradas repetidas en _EditValues. Esto sigue siendo SOLO LECTURA.
    local get_edit_value_ok = 0
    local get_edit_value_fail = 0
    local get_edit_value_rows = {}

    if #unique_order > 0 then
        for _, hash in ipairs(unique_order) do
            local direct = safe(function()
                return body_edit_context:call("getEditValue", hash)
            end)

            if direct ~= nil then
                get_edit_value_ok = get_edit_value_ok + 1
                get_edit_value_rows[#get_edit_value_rows + 1] = {
                    edit_key_hash = hash,
                    value = direct,
                }
                logp(
                    "[PawnResearch] PASO 82 GETEDITVALUE hash="
                    .. tostring(hash)
                    .. " -> " .. tostring(direct)
                )
            else
                get_edit_value_fail = get_edit_value_fail + 1
                logp(
                    "[PawnResearch] PASO 82 GETEDITVALUE FAIL hash="
                    .. tostring(hash)
                )
            end
        end
    end

    for hash, repeat_count in pairs(duplicate_hashes) do
        logp(
            "[PawnResearch] PASO 82 EDITVALUES DUPLICADO hash="
            .. tostring(hash)
            .. " repeticiones_extra=" .. tostring(repeat_count)
        )
    end

    logp(
        "[PawnResearch] PASO 82 GETEDITVALUE RESUMEN ok="
        .. tostring(get_edit_value_ok)
        .. " fail=" .. tostring(get_edit_value_fail)
    )

    return {
        type_name = array_type_name,
        count = size,
        enumerated = true,
        found = found,
        values = snapshot_values,
        unique_values = get_edit_value_rows,
        unique_hash_count = #unique_order,
        get_edit_value_ok = get_edit_value_ok,
        get_edit_value_fail = get_edit_value_fail,
    }
end


local function paso82_find_body_edit_method(obj, method_name, param_type_names, return_type_name)
    if obj == nil then return nil end

    local td = safe(function() return obj:get_type_definition() end)
    if td == nil then return nil end

    local methods = safe(function() return td:get_methods() end) or {}
    for _, method in ipairs(methods) do
        local name = safe(function() return method:get_name() end)
        if name == method_name then
            local params = safe(function() return method:get_param_types() end) or {}
            local return_type = safe(function()
                local rt = method:get_return_type()
                return rt and rt:get_full_name() or "<?>"
            end) or "<?>"

            if #params == #param_type_names
                and return_type == return_type_name
            then
                local compatible = true
                for i, expected in ipairs(param_type_names) do
                    local actual = safe(function()
                        return params[i]:get_full_name()
                    end) or "<?>"
                    if actual ~= expected then
                        compatible = false
                        break
                    end
                end

                if compatible then
                    return method
                end
            end
        end
    end

    return nil
end

local function paso82_find_height_hash(payload)
    if type(payload) ~= "table"
        or type(payload.body_edit_detail) ~= "table"
        or type(payload.body_edit_detail.values) ~= "table"
    then
        return nil, "la plantilla no contiene body_edit_detail.values"
    end

    local expected_height = nil
    if type(payload.body_scale_detail) == "table"
        and type(payload.body_scale_detail.BodyHeight) == "number"
    then
        expected_height = payload.body_scale_detail.BodyHeight
    end

    if expected_height == nil then
        return nil, "la plantilla no contiene body_scale_detail.BodyHeight"
    end

    local matches = {}
    for _, row in ipairs(payload.body_edit_detail.values) do
        if type(row) == "table"
            and type(row.edit_key_hash) == "number"
            and type(row.value) == "number"
        then
            if tostring(row.value) == tostring(expected_height) then
                matches[#matches + 1] = row.edit_key_hash
            end
        end
    end

    if #matches == 1 then
        return matches[1], expected_height
    end

    if #matches == 0 then
        return nil, "no se encontro un hash unico cuyo valor coincida con BodyHeight=" .. tostring(expected_height)
    end

    return nil, "BodyHeight coincide con " .. tostring(#matches) .. " hashes; no se escribe nada"
end

local function paso82_enumerate_height_hash_values(body_edit_context, height_hash)
    local rows = {}
    if body_edit_context == nil or height_hash == nil then
        return rows
    end

    local values = safe(function()
        return body_edit_context:get_field("_EditValues")
    end)
    if values == nil then return rows end

    local size = safe(function() return values:get_size() end)
    local count = tonumber(size) or 0
    if count < 0 then count = 0 end
    if count > 256 then count = 256 end

    for i = 0, count - 1 do
        local element = safe(function()
            return values:get_element(i)
        end)
        if element ~= nil then
            local element_td = safe(function() return element:get_type_definition() end)
            if element_td ~= nil then
                local hash = nil
                local value = nil
                local fields = safe(function() return element_td:get_fields() end) or {}
                for _, field in ipairs(fields) do
                    local name = safe(function() return field:get_name() end)
                    if name == "_EditKeyHash" then
                        hash = safe(function() return field:get_data(element) end)
                    elseif name == "_Value" then
                        value = safe(function() return field:get_data(element) end)
                    end
                end

                if tonumber(hash) == tonumber(height_hash) then
                    rows[#rows + 1] = {
                        index = i,
                        value = value,
                    }
                end
            end
        end
    end

    return rows
end

local function paso82_try_height_edit(character, template_name)
    local result = {
        wrote = false,
        editmode_updated = false,
        verify_ok = false,
    }

    if character == nil then
        return false, "character nil", result
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    if is_character_protected(cid) then
        return false,
            "BLOQUEADO: CharacterID " .. tostring(cid)
            .. " coincide con el candado de seguridad. No se escribio nada.",
            result
    end

    local payload, load_err = paso82_load_template(template_name)
    if type(payload) ~= "table" then
        return false, tostring(load_err), result
    end

    local height_hash, expected_height = paso82_find_height_hash(payload)
    if height_hash == nil then
        return false, tostring(expected_height), result
    end

    result.height_hash = height_hash
    result.expected_height = expected_height

    logp(
        "[PawnResearch] PASO 82 ALTURA CANDIDATO"
        .. " CID=" .. tostring(cid)
        .. " hash=" .. tostring(height_hash)
        .. " valor_plantilla=" .. tostring(expected_height)
    )

    local ps = get_part_swapper(character)
    if ps == nil then
        return false, "PartSwapper nil", result
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        return false, "BodyEditor nil", result
    end

    local body_edit_context = get_field_value_by_name(body_editor, "_BodyEditContext")
    if body_edit_context == nil then
        return false, "BodyEditContext nil", result
    end

    local set_method = paso82_find_body_edit_method(
        body_edit_context,
        "setEditValue",
        { "System.UInt32", "System.Single" },
        "System.Void"
    )
    if set_method == nil then
        logp("[PawnResearch] PASO 82 ALTURA setEditValue NO confirmado por reflexion")
        return false,
            "setEditValue(UInt32,Single)->Void no confirmado por reflexion",
            result
    end

    local get_method = paso82_find_body_edit_method(
        body_edit_context,
        "getEditValue",
        { "System.UInt32" },
        "System.Single"
    )
    if get_method == nil then
        logp("[PawnResearch] PASO 82 ALTURA getEditValue NO confirmado por reflexion")
        return false,
            "getEditValue(UInt32)->Single no confirmado por reflexion",
            result
    end

    local before = safe(function()
        return body_edit_context:call("getEditValue", height_hash)
    end)
    logp(
        "[PawnResearch] PASO 82 ALTURA ANTES"
        .. " hash=" .. tostring(height_hash)
        .. " getEditValue=" .. tostring(before)
    )

    local direct_rows_before = paso82_enumerate_height_hash_values(
        body_edit_context,
        height_hash
    )
    for _, row in ipairs(direct_rows_before) do
        logp(
            "[PawnResearch] PASO 82 ALTURA ARRAY ANTES"
            .. " index=" .. tostring(row.index)
            .. " value=" .. tostring(row.value)
        )
    end

    local ok_write = pcall(function()
        body_edit_context:call("setEditValue", height_hash, expected_height)
    end)
    if not ok_write then
        logp("[PawnResearch] PASO 82 ALTURA WRITE FALLA")
        return false, "setEditValue produjo una excepcion", result
    end
    result.wrote = true

    local after_set = safe(function()
        return body_edit_context:call("getEditValue", height_hash)
    end)
    logp(
        "[PawnResearch] PASO 82 ALTURA DESPUES SET"
        .. " hash=" .. tostring(height_hash)
        .. " getEditValue=" .. tostring(after_set)
    )

    local body_detail_editor = get_field_value_by_name(body_editor, "_BodyDetailEditor")
    if body_detail_editor == nil then
        return false, "BodyDetailEditor nil despues de setEditValue", result
    end

    local update_method = paso82_find_body_edit_method(
        body_detail_editor,
        "editModeUpdate",
        {},
        "System.Void"
    )
    if update_method == nil then
        logp("[PawnResearch] PASO 82 ALTURA editModeUpdate NO confirmado por reflexion")
        return false,
            "editModeUpdate()->Void no confirmado por reflexion",
            result
    end

    local ok_update = pcall(function()
        body_detail_editor:call("editModeUpdate")
    end)
    if not ok_update then
        logp("[PawnResearch] PASO 82 ALTURA editModeUpdate FALLA")
        return false, "editModeUpdate produjo una excepcion", result
    end
    result.editmode_updated = true
    logp("[PawnResearch] PASO 82 ALTURA editModeUpdate OK")

    local ps_fresh = get_part_swapper(character)
    local body_editor_fresh = ps_fresh and get_field_value_by_name(ps_fresh, "_BodyEditor") or nil
    local ctx_fresh = body_editor_fresh and get_field_value_by_name(body_editor_fresh, "_BodyEditContext") or nil
    local fresh_value = ctx_fresh and safe(function()
        return ctx_fresh:call("getEditValue", height_hash)
    end) or nil

    logp(
        "[PawnResearch] PASO 82 ALTURA VERIFY FRESCA"
        .. " hash=" .. tostring(height_hash)
        .. " getEditValue=" .. tostring(fresh_value)
    )

    local direct_rows_after = paso82_enumerate_height_hash_values(
        ctx_fresh,
        height_hash
    )
    for _, row in ipairs(direct_rows_after) do
        logp(
            "[PawnResearch] PASO 82 ALTURA ARRAY DESPUES"
            .. " index=" .. tostring(row.index)
            .. " value=" .. tostring(row.value)
        )
    end

    local human_fresh = get_human(character)
    local body_height_actual = nil
    if human_fresh ~= nil then
        local td = safe(function() return human_fresh:get_type_definition() end)
        local field = td and find_field_in_hierarchy(td, "BodyHeight") or nil
        if field ~= nil then
            body_height_actual = safe(function()
                return field:get_data(human_fresh)
            end)
        end
    end

    logp(
        "[PawnResearch] PASO 82 ALTURA HUMAN FRESCO"
        .. " BodyHeight=" .. tostring(body_height_actual)
    )

    result.fresh_value = fresh_value
    result.body_height_actual = body_height_actual
    result.verify_ok =
        fresh_value ~= nil
        and tostring(fresh_value) == tostring(expected_height)
        and body_height_actual ~= nil
        and tostring(body_height_actual) == tostring(expected_height)

    if result.verify_ok then
        logp("[PawnResearch] PASO 82 ALTURA VERIFY OK")
        return true,
            "altura aplicada y verificada: " .. tostring(expected_height),
            result
    end

    logp(
        "[PawnResearch] PASO 82 ALTURA VERIFY FAIL"
        .. " esperado=" .. tostring(expected_height)
        .. " getEditValue_fresco=" .. tostring(fresh_value)
        .. " BodyHeight_fresco=" .. tostring(body_height_actual)
    )

    return false, "la altura no sobrevivio la verificacion fresca", result
end

local function paso74_snapshot_body_scale(human)
    local result = {}
    if human == nil then return result end

    local body_scale = safe_call(human, "get_BodyScale")
    local scale_enum = safe_call(human, "get_Scale")

    local td = safe(function() return human:get_type_definition() end)
    local field_names = {
        "BodyHeight",
        "ScaleY",
        "BodyWeight",
        "RequestedRemoveHeight",
    }

    if td ~= nil then
        for _, field_name in ipairs(field_names) do
            local field = find_field_in_hierarchy(td, field_name)
            if field ~= nil then
                local field_type = safe(function()
                    local ft = field:get_type()
                    return ft and ft:get_full_name() or "<?>"
                end)

                if field_type == "System.Single" then
                    result[field_name] = safe(function()
                        return field:get_data(human)
                    end)
                end
            end
        end
    end

    if body_scale ~= nil then
        result.body_scale = body_scale
    end
    if scale_enum ~= nil then
        result.scale_enum = scale_enum
    end

    logp(
        "[PawnResearch] PASO 74 BODY SCALE CAPTURADO"
        .. " body_scale=" .. tostring(body_scale)
        .. " scale_enum=" .. tostring(scale_enum)
        .. " BodyHeight=" .. tostring(result.BodyHeight)
        .. " ScaleY=" .. tostring(result.ScaleY)
        .. " BodyWeight=" .. tostring(result.BodyWeight)
        .. " RequestedRemoveHeight=" .. tostring(result.RequestedRemoveHeight)
    )

    return result
end

local function paso74_log_body_edit_candidates(human, ps)
    local candidates = {
        { label = "Human", obj = human },
        { label = "PartSwapper", obj = ps },
    }
    local keywords = {
        "bodyedit", "bodyeditcontext", "editvalues", "editvalue",
        "bodyscale", "height", "scale", "joint", "morph",
        "hair", "color", "material", "apply", "swap", "mesh"
    }

    -- Paso 74: el diagnostico anterior no entraba al BodyEditor vivo.
    -- Lo inspeccionamos primero y no escribimos nada aqui.
    if ps ~= nil then
        local body_editor = get_field_value_by_name(ps, "_BodyEditor")

        if body_editor ~= nil then
            local body_editor_td = safe(function()
                return body_editor:get_type_definition()
            end)

            if body_editor_td ~= nil then
                local body_editor_type = safe(function()
                    return body_editor_td:get_full_name()
                end) or "<?>"

                logp(
                    "[PawnResearch] PASO 82 BODY CONTEXT BODYEDITOR tipo="
                    .. body_editor_type
                )

                local body_edit_context = get_field_value_by_name(
                    body_editor,
                    "_BodyEditContext"
                )
                if body_edit_context ~= nil then
                    logp(
                        "[PawnResearch] PASO 82 BODY CONTEXT EDITVALUES tipo="
                        .. object_type_name(body_edit_context)
                    )
                    paso82_snapshot_body_edit_values(ps)
                else
                    logp("[PawnResearch] PASO 82 BODY CONTEXT EDITVALUES nil")
                end

                local body_editor_fields = safe(function()
                    return body_editor_td:get_fields()
                end) or {}

                for _, f in ipairs(body_editor_fields) do
                    local field_name = safe(function() return f:get_name() end)
                    local is_static = safe(function() return f:is_static() end)

                    if field_name ~= nil and is_static ~= true
                        and text_contains_any(field_name, {
                            "context", "edit", "value", "hash",
                            "body", "height", "scale", "key"
                        })
                    then
                        local field_type = safe(function()
                            local ft = f:get_type()
                            return ft and ft:get_full_name() or "<?>"
                        end) or "<?>"

                        local value = safe(function()
                            return f:get_data(body_editor)
                        end)

                        logp(
                            "[PawnResearch] PASO 74 BODY CONTEXT CAMPO "
                            .. "BodyEditor::" .. field_name
                            .. " tipo=" .. field_type
                            .. " valor=" .. value_to_string(value)
                        )

                        if value ~= nil
                            and type(value) ~= "number"
                            and type(value) ~= "string"
                            and type(value) ~= "boolean"
                        then
                            local child_td = safe(function()
                                return value:get_type_definition()
                            end)

                            if child_td ~= nil then
                                local child_type = safe(function()
                                    return child_td:get_full_name()
                                end) or "<?>"

                                logp(
                                    "[PawnResearch] PASO 82 BODY CONTEXT HIJO "
                                    .. field_name .. " tipo=" .. child_type
                                )

                                local child_fields = safe(function()
                                    return child_td:get_fields()
                                end) or {}

                                for _, cf in ipairs(child_fields) do
                                    local child_field_name =
                                        safe(function() return cf:get_name() end)
                                    local child_static =
                                        safe(function() return cf:is_static() end)

                                    if child_field_name ~= nil
                                        and child_static ~= true
                                        and text_contains_any(child_field_name, {
                                            "context", "edit", "value", "hash",
                                            "body", "height", "scale", "key"
                                        })
                                    then
                                        local child_field_type = safe(function()
                                            local cft = cf:get_type()
                                            return cft and cft:get_full_name() or "<?>"
                                        end) or "<?>"

                                        local child_value = safe(function()
                                            return cf:get_data(value)
                                        end)

                                        logp(
                                            "[PawnResearch] PASO 82 BODY CONTEXT HIJO CAMPO "
                                            .. field_name .. "::" .. child_field_name
                                            .. " tipo=" .. child_field_type
                                            .. " valor=" .. value_to_string(child_value)
                                        )
                                    end
                                end

                                local child_methods = safe(function()
                                    return child_td:get_methods()
                                end) or {}

                                for _, cm in ipairs(child_methods) do
                                    local method_name =
                                        safe(function() return cm:get_name() end)
                                    local method_static =
                                        safe(function() return cm:is_static() end)

                                    if method_name ~= nil
                                        and method_static ~= true
                                        and text_contains_any(method_name, {
                                            "context", "edit", "value", "hash",
                                            "body", "height", "scale", "key"
                                        })
                                    then
                                        local params = safe(function()
                                            return cm:get_param_types()
                                        end) or {}

                                        local return_type = safe(function()
                                            return cm:get_return_type()
                                        end)

                                        local return_name =
                                            return_type and safe(function()
                                                return return_type:get_full_name()
                                            end) or "<?>"

                                        local param_names = {}
                                        for _, p in ipairs(params) do
                                            param_names[#param_names + 1] =
                                                safe(function()
                                                    return p:get_full_name()
                                                end) or "<?>"
                                        end

                                        logp(
                                            "[PawnResearch] PASO 82 BODY CONTEXT HIJO METODO "
                                            .. field_name .. "::" .. method_name
                                            .. " params="
                                            .. table.concat(param_names, ",")
                                            .. " return=" .. return_name
                                        )
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            logp(
                "[PawnResearch] PASO 82 BODY CONTEXT: BodyEditor nil"
            )
        end
    end

    for _, c in ipairs(candidates) do
        if c.obj ~= nil then
            local td = safe(function() return c.obj:get_type_definition() end)
            local seen = {}
            while td ~= nil do
                local tn = safe(function() return td:get_full_name() end) or "<?>"
                if seen[tn] then break end
                seen[tn] = true

                local fields = safe(function() return td:get_fields() end) or {}
                for _, f in ipairs(fields) do
                    local fn = safe(function() return f:get_name() end)
                    local fs = safe(function() return f:is_static() end)
                    if fn ~= nil and fs ~= true and text_contains_any(fn, keywords) then
                        local ft = safe(function()
                            local t = f:get_type()
                            return t and t:get_full_name() or "<?>"
                        end) or "<?>"
                        local fv = safe(function() return f:get_data(c.obj) end)
                        logp(
                            "[PawnResearch] PASO 73 BODY EDIT CAMPO "
                            .. c.label .. "::" .. fn
                            .. " tipo=" .. ft
                            .. " valor=" .. value_to_string(fv)
                        )
                    end
                end

                local methods = safe(function() return td:get_methods() end) or {}
                for _, m in ipairs(methods) do
                    local mn = safe(function() return m:get_name() end)
                    local ms = safe(function() return m:is_static() end)
                    if mn ~= nil and ms ~= true and text_contains_any(mn, keywords) then
                        local params = safe(function() return m:get_param_types() end) or {}
                        local ret = safe(function() return m:get_return_type() end)
                        local rn = ret and safe(function() return ret:get_full_name() end) or "<?>"
                        local pn = {}
                        for _, p in ipairs(params) do
                            pn[#pn + 1] = safe(function() return p:get_full_name() end) or "<?>"
                        end
                        logp(
                            "[PawnResearch] PASO 73 BODY EDIT METODO "
                            .. c.label .. "::" .. mn
                            .. " params=" .. table.concat(pn, ",")
                            .. " return=" .. rn
                        )
                    end
                end

                td = safe(function() return td:get_parent_type() end)
            end
        end
    end
end

local function get_all_meta_cloneable_fields(meta)
    local result = {}
    local skipped = {}

    if meta == nil then
        return result, skipped
    end

    -- NO dependemos de list_all_field_names(), porque esa funcion esta
    -- declarada mas abajo en el archivo combinado Paso 67. A esta altura
    -- de la ejecucion podria no existir en este scope.
    -- Recorremos directamente la jerarquia real del tipo de MetaData.
    local fields = {}
    local td = safe(function() return meta:get_type_definition() end)
    local seen_types = {}

    while td ~= nil do
        local type_name = safe(function() return td:get_full_name() end) or "<?>"
        if seen_types[type_name] then break end
        seen_types[type_name] = true

        local type_fields = safe(function() return td:get_fields() end) or {}
        for _, f in ipairs(type_fields) do
            local field_name = safe(function() return f:get_name() end)
            if field_name ~= nil then
                local is_static = safe(function() return f:is_static() end)
                if not is_static then
                    local field_type = safe(function()
                        local ft = f:get_type()
                        return ft and ft:get_full_name() or "<?>"
                    end) or "<?>"

                    fields[#fields + 1] = {
                        name = field_name,
                        type_name = field_type,
                        declaring_type = type_name,
                    }
                end
            end
        end

        td = safe(function() return td:get_parent_type() end)
    end

    for _, field in ipairs(fields) do
        local field_name = field.name

        if not META_FIELDS_NEVER_COPY[field_name] then
            local ok, value = pcall(function()
                return get_field_value_by_name(meta, field_name)
            end)

            if ok and is_simple_lua_value(value) then
                result[field_name] = value
            else
                skipped[#skipped + 1] = {
                    name = field_name,
                    type_name = field.type_name,
                    value_type = type(value),
                    reason = ok and "valor_no_primitivo" or "lectura_exception",
                }
            end
        end
    end

    return result, skipped
end

local function log_meta_skipped_fields(prefix, skipped)
    if skipped == nil or #skipped == 0 then return end

    for _, field in ipairs(skipped) do
        logp(
            "[PawnResearch] PASO 69 META OMITIDO "
            .. prefix
            .. " :: " .. tostring(field.name)
            .. " tipo=" .. tostring(field.type_name)
            .. " lua=" .. tostring(field.value_type)
            .. " razon=" .. tostring(field.reason)
        )
    end
end

local function get_roster()
    local out = {}
    local pm = get_pawn_manager()
    local list = safe_call(pm, "get_PawnCharacterList")
    local count = safe_call(list, "get_Count") or 0

    for i = 0, count - 1 do
        local c = safe_call(list, "get_Item", i)
        if c ~= nil then
            local cid = get_field_value_by_name(c, "CharacterID")
            local ctx = get_pawn_context_for_character(c)
            local name = ctx and safe_call(ctx, "get_Name") or "<sin nombre>"
            local nick = ctx and safe_call(ctx, "get_Nickname") or ""
            out[#out + 1] = {
                index = i,
                character = c,
                id = cid,
                name = tostring(name),
                nick = tostring(nick),
                label = string.format("[%d] %s (%s)  CID=%s", i, tostring(name), tostring(nick), tostring(cid)),
            }
        end
    end

    return out
end

local function find_roster_by_id(roster, character_id)
    if character_id == nil then return nil end
    for _, item in ipairs(roster) do
        if tostring(item.id) == tostring(character_id) then
            return item
        end
    end
    return nil
end

-- Traduce un CharacterID "pelado" a algo legible ("Nombre "Apodo" (CID=...)")
-- buscandolo en el roster actual. Se usa en TODA la UI para que nunca se
-- muestre un ID solo, sin importar si el peon dueno de ese ID sigue
-- presente en la partida en este momento o no.
local function describe_character_id(roster, character_id)
    if character_id == nil or character_id == "" then
        return "<sin CharacterID>"
    end
    local item = find_roster_by_id(roster, character_id)
    if item ~= nil then
        local nick_part = (item.nick ~= nil and item.nick ~= "") and (" \"" .. item.nick .. "\"") or ""
        return item.name .. nick_part .. " (CID=" .. tostring(character_id) .. ")"
    end
    return "Peon no presente en el roster actual (CID=" .. tostring(character_id) .. ")"
end

local function sanitize_name(name)
    local s = tostring(name or "MiPlantilla")
    s = s:gsub("[^a-zA-Z0-9_%-]", "_")
    if s == "" then s = "MiPlantilla" end
    return s
end

local function normalize_template_name(template_name)
    local s = tostring(template_name or "MiPlantilla")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("%.json$", "")
    s = s:gsub("[^a-zA-Z0-9_%-]", "_")
    if s == "" then s = "MiPlantilla" end
    return s
end

local function template_path(template_name)
    return TEMPLATE_DIR .. "/" .. normalize_template_name(template_name) .. ".json"
end

paso82_load_template = function(template_name)
    local normalized = normalize_template_name(template_name)
    local path = template_path(normalized)
    logp("[PawnResearch] PASO 82 TEMPLATE LOAD intento raw=\"" .. tostring(template_name)
        .. "\" normalizado=\"" .. normalized .. "\" path=\"" .. path .. "\"")

    local ok, payload_or_error = pcall(function()
        return json.load_file(path)
    end)

    if not ok then
        logp("[PawnResearch] PASO 82 TEMPLATE LOAD EXCEPCION path=" .. path
            .. " error=" .. tostring(payload_or_error))
        return nil, "excepcion cargando " .. path .. ": " .. tostring(payload_or_error), path
    end

    if type(payload_or_error) ~= "table" then
        logp("[PawnResearch] PASO 82 TEMPLATE LOAD INVALIDO path=" .. path
            .. " tipo=" .. tostring(type(payload_or_error)))
        return nil, "no se pudo cargar " .. path .. " (tipo="
            .. tostring(type(payload_or_error)) .. ")", path
    end

    logp("[PawnResearch] PASO 82 TEMPLATE LOAD OK path=" .. path)
    return payload_or_error, nil, path
end

local function load_assignments()
    local data = safe(function() return json.load_file(ASSIGNMENTS_FILE) end)
    if type(data) ~= "table" then
        return {}
    end
    if type(data.assignments) ~= "table" then
        return {}
    end
    return data.assignments
end

local function save_assignments(assignments)
    local payload = {
        version = 1,
        assignments = assignments,
    }
    local ok = safe(function()
        return json.dump_file(ASSIGNMENTS_FILE, payload, 4)
    end)
    return ok == true
end

local function find_assignment(assignments, character_id)
    if character_id == nil then return nil end
    for i, a in ipairs(assignments) do
        if tostring(a.character_id) == tostring(character_id) then
            return a, i
        end
    end
    return nil, nil
end

local function set_assignment(character_id, template_name)
    local assignments = load_assignments()
    local existing, pos = find_assignment(assignments, character_id)

    if existing ~= nil then
        existing.template = template_name
    else
        assignments[#assignments + 1] = {
            character_id = character_id,
            template = template_name,
        }
    end

    return save_assignments(assignments)
end

local function remove_assignment(character_id)
    local assignments = load_assignments()
    local _, pos = find_assignment(assignments, character_id)
    if pos == nil then return true end
    table.remove(assignments, pos)
    return save_assignments(assignments)
end


local function snapshot_character(character)
    if character == nil then return nil, "character nil" end

    local human = get_human(character)
    local status = get_status(character)
    local job_ctx = get_job_context(character)
    local ctx = get_pawn_context_for_character(character)

    local meta, ps = get_meta(character)
    if meta == nil then return nil, "_Meta nil" end

    local cid = get_field_value_by_name(character, "CharacterID")
    local gender = meta_get(meta, "_Gender")
    local species = meta_get(meta, "_Species")

    local appearance, skipped_meta_fields = get_all_meta_cloneable_fields(meta)
    local hair_detail = paso73_snapshot_hair_data(ps)
    local body_scale_detail = paso74_snapshot_body_scale(human)
    local body_edit_detail = paso82_snapshot_body_edit_values(ps)
    local body_properties_meta, skipped_properties_meta = snapshot_body_properties(
        meta,
        "MetaData",
        "MetaData"
    )
    local body_properties_ps, skipped_properties_ps = snapshot_body_properties(
        ps,
        "PartSwapper",
        "PartSwapper"
    )

    -- Diagnostico solo lectura para localizar colores del pelo y otros
    -- datos que no aparecen como campos primitivos de MetaData.
    local cid_diag_key = tostring(cid)
    if not paso71_hair_diag_done[cid_diag_key] then
        paso71_hair_diag_done[cid_diag_key] = true
        paso71_dump_hair_color_candidates(ps)
        paso72_dump_deep_body_candidates(ps, character)
        paso74_log_body_edit_candidates(human, ps)
    end

    local appearance_properties = {}
    for _, prop in ipairs(body_properties_meta) do
        appearance_properties[#appearance_properties + 1] = prop
    end
    for _, prop in ipairs(body_properties_ps) do
        appearance_properties[#appearance_properties + 1] = prop
    end

    log_meta_skipped_fields(
        "ORIGEN CID=" .. tostring(cid),
        skipped_meta_fields
    )

    for _, field in ipairs(skipped_properties_meta) do
        logp(
            "[PawnResearch] PASO 72 BODY PROP OMITIDA ORIGEN CID="
            .. tostring(cid)
            .. " :: origen=MetaData :: " .. tostring(field.name)
            .. " getter=" .. tostring(field.getter)
            .. " setter=" .. tostring(field.setter)
            .. " tipo=" .. tostring(field.type_name)
            .. " lua=" .. tostring(field.lua)
            .. " razon=" .. tostring(field.reason)
        )
    end

    for _, field in ipairs(skipped_properties_ps) do
        logp(
            "[PawnResearch] PASO 72 BODY PROP OMITIDA ORIGEN CID="
            .. tostring(cid)
            .. " :: origen=PartSwapper :: " .. tostring(field.name)
            .. " getter=" .. tostring(field.getter)
            .. " setter=" .. tostring(field.setter)
            .. " tipo=" .. tostring(field.type_name)
            .. " lua=" .. tostring(field.lua)
            .. " razon=" .. tostring(field.reason)
        )
    end

    return {
        version = 1,
        source_character_id = cid,
        source_name = ctx and safe_call(ctx, "get_Name") or "",
        source_nickname = ctx and safe_call(ctx, "get_Nickname") or "",
        gender = gender,
        species = species,
        name = ctx and safe_call(ctx, "get_Name") or "",
        nickname = ctx and safe_call(ctx, "get_Nickname") or "",
        appearance = appearance,
        appearance_properties = appearance_properties,
        hair_detail = hair_detail,
        body_scale_detail = body_scale_detail,
        body_edit_detail = body_edit_detail,
        appearance_schema = "BodyMetaAndProperties.v8.EditValues",
        appearance_field_count = (function()
            local n = 0
            for _ in pairs(appearance) do n = n + 1 end
            return n
        end)(),
        appearance_property_count = #appearance_properties,
        source_part_swapper = value_to_string(ps),
    }, nil
end

local function save_template_from_character(character, template_name)
    local payload, err = snapshot_character(character)
    if payload == nil then return false, err end

    local path = template_path(template_name)
    local ok = safe(function()
        return json.dump_file(path, payload, 4)
    end)

    if ok ~= true then
        return false, "json.dump_file fallo"
    end

    logp("[PawnResearch] PASO 33 plantilla guardada: reframework/data/" .. path)
    return true, path
end

local function apply_refresh(ps)
    if ps == nil then return end

    local previous_all_meta = safe_call(ps, "get_IsAllMetaUpdate")
    pcall(function() ps:call("set_IsAllMetaUpdate", true) end)

    local methods = {
        "updateStatusOfHair",
        "updateStatusOfBeard",
        "updateStatusOfBody",
        "updateHeadPartsEnable",
        "updateStatusOfFaceJointMask",
        "swapHair",
        "swapTops",
        "swapPants",
        "swapMantle",
        "swapHelm",
        "swapUnderwear",
        "swapFacewear",
    }

    for _, method_name in ipairs(methods) do
        pcall(function() ps:call(method_name) end)
    end

    pcall(function()
        ps:call("requestSwap(app.PartSwapper.Parts)", 480)
    end)

    pcall(function() ps:call("lateUpdate") end)

    if previous_all_meta ~= nil then
        pcall(function() ps:call("set_IsAllMetaUpdate", previous_all_meta) end)
    end
end

resolve_property_setter = function(obj, setter_name, expected_type_name)
    if obj == nil or setter_name == nil then return nil end

    local td = safe(function() return obj:get_type_definition() end)
    local seen_types = {}
    while td ~= nil do
        local type_name = safe(function() return td:get_full_name() end) or "<?>"
        if seen_types[type_name] then break end
        seen_types[type_name] = true

        local methods = safe(function() return td:get_methods() end) or {}
        for _, method in ipairs(methods) do
            local is_static = safe(function() return method:is_static() end)
            local method_name = safe(function() return method:get_name() end)
            if is_static ~= true and method_name == setter_name then
                local param_types = safe(function() return method:get_param_types() end) or {}
                if #param_types == 1 then
                    local param_name = safe(function() return param_types[1]:get_full_name() end) or "<?>"
                    if expected_type_name == nil or param_name == expected_type_name then
                        return method
                    end
                end
            end
        end

        td = safe(function() return td:get_parent_type() end)
    end

    return nil
end

resolve_property_getter = function(obj, getter_name, expected_type_name)
    if obj == nil or getter_name == nil then return nil end

    local td = safe(function() return obj:get_type_definition() end)
    local seen_types = {}
    while td ~= nil do
        local type_name = safe(function() return td:get_full_name() end) or "<?>"
        if seen_types[type_name] then break end
        seen_types[type_name] = true

        local methods = safe(function() return td:get_methods() end) or {}
        for _, method in ipairs(methods) do
            local is_static = safe(function() return method:is_static() end)
            local method_name = safe(function() return method:get_name() end)
            if is_static ~= true and method_name == getter_name then
                local param_types = safe(function() return method:get_param_types() end) or {}
                local return_type = safe(function() return method:get_return_type() end)
                local return_name = return_type and safe(function() return return_type:get_full_name() end) or "<?>"
                if #param_types == 0
                    and (expected_type_name == nil or return_name == expected_type_name)
                then
                    return method
                end
            end
        end

        td = safe(function() return td:get_parent_type() end)
    end

    return nil
end

local function apply_body_properties(character, target_meta, ps, payload, results)
    if character == nil or type(payload) ~= "table" then return end
    if type(payload.appearance_properties) ~= "table" then return end

    if ps == nil then return end

    for _, prop in ipairs(payload.appearance_properties) do
        if type(prop) == "table"
            and is_body_property_name(prop.name)
            and prop.setter ~= nil
            and is_simple_lua_value(prop.value)
        then
            -- En Paso 70 mezclamos propiedades capturadas desde MetaData y
            -- PartSwapper. Cada setter se confirma sobre EL MISMO OBJETO que
            -- expuso la propiedad al guardar la plantilla.
            local target_obj = nil

            if tostring(prop.owner) == "MetaData" then
                target_obj = target_meta
            elseif tostring(prop.owner) == "PartSwapper" then
                target_obj = ps
            else
                -- Plantillas v3/viejas no guardaban owner. En ese caso
                -- resolvemos el setter por reflexion sobre MetaData primero
                -- y solo despues sobre PartSwapper.
                if target_meta ~= nil
                    and resolve_property_setter(target_meta, prop.setter, prop.type_name) ~= nil
                then
                    target_obj = target_meta
                elseif ps ~= nil
                    and resolve_property_setter(ps, prop.setter, prop.type_name) ~= nil
                then
                    target_obj = ps
                end
            end

            if target_obj == nil then
                logp(
                    "[PawnResearch] PASO 72 BODY PROP WRITE FALLA :: "
                    .. tostring(prop.name)
                    .. " owner=" .. tostring(prop.owner)
                    .. " motivo=objeto_owner_nil"
                )
            else
                local setter = resolve_property_setter(
                    target_obj,
                    prop.setter,
                    prop.type_name
                )
                if setter == nil then
                    logp(
                        "[PawnResearch] PASO 72 BODY PROP WRITE FALLA :: "
                        .. tostring(prop.name)
                        .. " owner=" .. tostring(prop.owner)
                        .. " setter=" .. tostring(prop.setter)
                        .. " tipo=" .. tostring(prop.type_name)
                        .. " motivo=setter_no_confirmado_por_reflexion"
                    )
                else
                    local ok = pcall(function()
                        target_obj:call(prop.setter, prop.value)
                    end)
                    if ok then
                        results.appearance_properties = results.appearance_properties + 1
                    else
                        logp(
                            "[PawnResearch] PASO 72 BODY PROP WRITE EXCEPTION :: "
                            .. tostring(prop.name)
                            .. " owner=" .. tostring(prop.owner)
                            .. " setter=" .. tostring(prop.setter)
                        )
                    end
                end
            end
        end
    end
end

local function verify_body_properties(character, target_meta, ps, payload, results)
    if character == nil or type(payload) ~= "table" then return end
    if type(payload.appearance_properties) ~= "table" then return end

    if target_meta == nil or ps == nil then return end

    local verify_ok = 0
    local verify_fail = 0

    for _, prop in ipairs(payload.appearance_properties) do
        if type(prop) == "table"
            and is_body_property_name(prop.name)
            and prop.getter ~= nil
            and is_simple_lua_value(prop.value)
        then
            -- Igual que al escribir, verificamos sobre el objeto que fue
            -- propietario de la propiedad al guardar la plantilla.
            local target_obj = nil

            if tostring(prop.owner) == "MetaData" then
                target_obj = target_meta
            elseif tostring(prop.owner) == "PartSwapper" then
                target_obj = ps
            else
                -- Compatibilidad con plantillas anteriores al campo owner.
                if target_meta ~= nil
                    and resolve_property_getter(target_meta, prop.getter, prop.type_name) ~= nil
                then
                    target_obj = target_meta
                elseif ps ~= nil
                    and resolve_property_getter(ps, prop.getter, prop.type_name) ~= nil
                then
                    target_obj = ps
                end
            end

            local getter = resolve_property_getter(
                target_obj,
                prop.getter,
                prop.type_name
            )
            if getter ~= nil then
                local ok, actual = pcall(function()
                    return target_obj:call(prop.getter)
                end)
                if ok and tostring(actual) == tostring(prop.value) then
                    verify_ok = verify_ok + 1
                else
                    verify_fail = verify_fail + 1
                    logp(
                        "[PawnResearch] PASO 72 BODY PROP VERIFY FAIL :: "
                        .. tostring(prop.name)
                        .. " getter=" .. tostring(prop.getter)
                        .. " esperado=" .. tostring(prop.value)
                        .. " actual=" .. tostring(actual)
                    )
                end
            else
                verify_fail = verify_fail + 1
                logp(
                    "[PawnResearch] PASO 72 BODY PROP VERIFY FALLA :: "
                    .. tostring(prop.name)
                    .. " getter=" .. tostring(prop.getter)
                    .. " motivo=getter_no_confirmado_por_reflexion"
                )
            end
        end
    end

    results.appearance_properties_verify_ok = verify_ok
    results.appearance_properties_verify_fail = verify_fail
end

local function apply_template_to_character(character, template_name, require_same_variant)
    if post_update_audit_only then
        return false, "BLOQUEADO: modo de auditoria post-TU4 activo; no se aplican plantillas hasta validar las APIs."
    end
    local char_id_check = get_field_value_by_name(character, "CharacterID")
    if is_character_protected(char_id_check) then
        return false,
            "BLOQUEADO: CharacterID " .. tostring(char_id_check)
            .. " coincide con el candado de seguridad (" .. tostring(protected_id_value[1]) .. "). No se escribio nada."
    end

    local payload, load_err = paso82_load_template(template_name)

    if type(payload) ~= "table" then
        return false, tostring(load_err)
    end

    local target_meta, target_ps = get_meta(character)
    if target_meta == nil then
        return false, "_Meta del destino nil"
    end

    local source_gender = payload.gender
    local source_species = payload.species
    local target_gender = meta_get(target_meta, "_Gender")
    local target_species = meta_get(target_meta, "_Species")

    if require_same_variant and (
        tostring(source_gender) ~= tostring(target_gender)
        or tostring(source_species) ~= tostring(target_species)
    ) then
        return false,
            "Gender/Species incompatibles (plantilla="
            .. tostring(source_gender) .. "/" .. tostring(source_species)
            .. ", destino=" .. tostring(target_gender) .. "/" .. tostring(target_species) .. ")"
    end

    local human = get_human(character)
    local status = get_status(character)
    local job_ctx = get_job_context(character)
    local ctx = get_pawn_context_for_character(character)

    -- Paso 74: inspeccion del destino, una sola vez por CID, para descubrir
    -- el contexto vivo y cualquier ruta nativa de color/material.
    local target_diag_key = "paso74-target:" .. tostring(char_id_check)
    if not paso71_hair_diag_done[target_diag_key] then
        paso71_hair_diag_done[target_diag_key] = true
        paso74_log_body_edit_candidates(human, target_ps)
        paso82_snapshot_body_edit_values(target_ps)
    end

    local results = {
        level = false,
        job = false,
        name = false,
        nickname = false,
        appearance = 0,
        appearance_properties = 0,
    }

    -- PASO 74: la plantilla corporal no cambia nivel ni vocacion.
    -- Esos datos se dejan intactos en el destino.

    -- El nombre y nickname forman parte de la identidad del peon.
    -- Desde este paso solo se conservan como datos de referencia de la plantilla;
    -- no se escriben sobre el destino.
    results.name = false
    results.nickname = false
    logp("[PawnResearch] PASO 82 IDENTIDAD: name/nickname NO se modifican")

    if type(payload.appearance) == "table" then
        for field_name, value in pairs(payload.appearance) do
            -- Nunca copiamos raza/sexo, incluso si aparece accidentalmente
            -- en una plantilla antigua/editada manualmente.
            if not META_FIELDS_NEVER_COPY[field_name]
                and is_simple_lua_value(value)
            then
                local ok = meta_set(target_meta, field_name, value)
                if ok then
                    results.appearance = results.appearance + 1
                else
                    logp(
                        "[PawnResearch] PASO 72 META WRITE FALLA "
                        .. tostring(field_name)
                    )
                end
            end
        end

        -- Reasignamos el backing field del contenedor, igual que en los
        -- pasos anteriores, por si _Meta se maneja como copia de valor.
        pcall(function() target_ps:set_field("_Meta", target_meta) end)
    end

    -- Las propiedades simples se escriben primero sobre sus propietarios
    -- confirmados por reflexion.
    apply_body_properties(character, target_meta, target_ps, payload, results)

    -- PASO 76: no hacemos refresh de PartSwapper y no tocamos Human.Scale,
    -- BodyHeight, ScaleY, BodyWeight ni RequestedRemoveHeight.
    -- Paso 74 demostro que esos writes alteraron de verdad el destino y
    -- despues el modelo quedo desacoplado del equipo. Esta version evita
    -- repetir esa operacion mientras estudiamos _BodyEditContext._EditValues.
    -- Tampoco intentamos pintar colores aqui: los setters de Hair cambiaron
    -- el dato interno, pero no hubo cambio visual, asi que primero hay que
    -- encontrar la ruta nativa que actualiza el modelo.
    logp("[PawnResearch] PASO 82 MODO DIAGNOSTICO: sin refresh de PartSwapper, sin writes de escala, sin writes de color y sin writes de EditValues ni identidad")

    local diag_scale = paso74_snapshot_body_scale(
        get_human(character)
    )

    if diag_scale ~= nil then
        results.body_scale_seen = diag_scale.body_scale
        results.scale_enum_seen = diag_scale.scale_enum
        results.body_height_seen = diag_scale.BodyHeight
        results.scale_y_seen = diag_scale.ScaleY
        results.body_weight_seen = diag_scale.BodyWeight
    end

    -- Relectura desde un _Meta recien obtenido. No confiamos en la referencia
    -- que acabamos de modificar para declarar que el clon persistió.
    local verify_meta = nil
    local verify_ps = get_part_swapper(character)
    if verify_ps ~= nil then
        verify_meta = get_field_value_by_name(verify_ps, "_Meta")
    end

    if verify_meta ~= nil and type(payload.appearance) == "table" then
        local verify_ok = 0
        local verify_fail = 0

        for field_name, expected in pairs(payload.appearance) do
            if not META_FIELDS_NEVER_COPY[field_name]
                and is_simple_lua_value(expected)
            then
                local actual = get_field_value_by_name(verify_meta, field_name)
                if tostring(actual) == tostring(expected) then
                    verify_ok = verify_ok + 1
                else
                    verify_fail = verify_fail + 1
                    logp(
                        "[PawnResearch] PASO 72 META VERIFY FAIL "
                        .. tostring(field_name)
                        .. " esperado=" .. tostring(expected)
                        .. " actual=" .. tostring(actual)
                    )
                end
            end
        end

        results.appearance_verify_ok = verify_ok
        results.appearance_verify_fail = verify_fail
    end

    -- Verificacion de las propiedades corporales desde el PartSwapper actual.
    verify_body_properties(character, verify_meta, verify_ps, payload, results)

    -- Relectura fresca de Human para comprobar que la escala no solo se
    -- escribio, sino que sobrevivio al recalculo.
    local verify_human_fresh = get_human(character)
    if verify_human_fresh ~= nil and type(payload.body_scale_detail) == "table" then
        local body_src = payload.body_scale_detail
        local checks = {
            "BodyHeight",
            "ScaleY",
            "BodyWeight",
            "RequestedRemoveHeight",
        }

        local ok_count = 0
        local fail_count = 0
        local verify_td = safe(function()
            return verify_human_fresh:get_type_definition()
        end)

        for _, field_name in ipairs(checks) do
            if type(body_src[field_name]) == "number"
                and verify_td ~= nil
            then
                local field = find_field_in_hierarchy(
                    verify_td,
                    field_name
                )

                local actual = nil
                if field ~= nil then
                    actual = safe(function()
                        return field:get_data(verify_human_fresh)
                    end)
                end

                if tostring(actual) == tostring(body_src[field_name]) then
                    ok_count = ok_count + 1
                else
                    fail_count = fail_count + 1
                    logp(
                        "[PawnResearch] PASO 74 BODY FIELD VERIFY FAIL "
                        .. field_name
                        .. " esperado=" .. tostring(body_src[field_name])
                        .. " actual=" .. tostring(actual)
                    )
                end
            end
        end

        if body_src.scale_enum ~= nil then
            local getter = resolve_property_getter(
                verify_human_fresh,
                "get_Scale",
                "app.Character.ScaleEnum"
            )

            if getter ~= nil then
                local ok, actual = pcall(function()
                    return verify_human_fresh:call("get_Scale")
                end)

                if ok and tostring(actual) == tostring(body_src.scale_enum) then
                    ok_count = ok_count + 1
                else
                    fail_count = fail_count + 1
                    logp(
                        "[PawnResearch] PASO 74 SCALE VERIFY FAIL"
                        .. " esperado=" .. tostring(body_src.scale_enum)
                        .. " actual=" .. tostring(actual)
                    )
                end
            end
        end

        results.body_scale_verify_ok = ok_count
        results.body_scale_verify_fail = fail_count

        logp(
            "[PawnResearch] PASO 74 BODY SCALE VERIFY resumen ok="
            .. tostring(ok_count) .. " fail=" .. tostring(fail_count)
        )
    end

    paso73_verify_hair_color_data(character, payload, results)

    return true, results
end

local function roster_signature(roster)
    -- El roster cambia por membresia de CharacterID, no por la direccion
    -- del wrapper/objeto. La direccion puede variar sin que haya entrado o
    -- salido ningun peon; incluirla aqui puede disparar restauraciones en bucle.
    local ids = {}
    for _, item in ipairs(roster) do
        if item.id ~= nil then
            ids[#ids + 1] = tostring(item.id)
        end
    end
    table.sort(ids)
    return table.concat(ids, "|")
end

local function restore_all_assigned()
    local roster = get_roster()
    if #roster == 0 then return 0, 0 end

    local assignments = load_assignments()
    local restored = 0
    local skipped = 0
    local restored_cids = {}

    for _, a in ipairs(assignments) do
        local target = find_roster_by_id(roster, a.character_id)
        if target ~= nil then
            local ok, result = apply_template_to_character(target.character, a.template, true)
            if ok then
                restored = restored + 1
                restored_cids[#restored_cids + 1] = tostring(target.id)
                logp(
                    "[PawnResearch] PASO 33 restaurado " .. target.name
                    .. " (CID=" .. tostring(a.character_id) .. ")"
                    .. " plantilla=" .. tostring(a.template)
                )
            else
                skipped = skipped + 1
                logp(
                    "[PawnResearch] PASO 33 NO restaurado " .. target.name
                    .. " (CID=" .. tostring(a.character_id) .. ")"
                    .. " plantilla=" .. tostring(a.template)
                    .. " ERROR=" .. tostring(result)
                )
            end
        end
    end

    return restored, skipped, restored_cids
end

-- ============================================================
-- UI state
-- ============================================================

local source_selected = { 1 }
local target_selected = { 1 }
local source_cid = { nil }
local target_cid = { nil }

local template_name = { "MiPeonCustom" }
local require_same_variant = true
local auto_restore = false

local last_signature = nil
local frame_counter = 0
local status_text = "Listo."

-- PASO 34-4: declarado ACA (antes de usarse) para que el re.on_frame de
-- PASO 33 de mas abajo pueda invalidarlo. Hipotesis a confirmar: la
-- plantilla clonada de PASO 33 incluye los mismos campos de _Meta que la
-- ropa (_TopsStyle, _PantsStyle, _HelmStyle, _MantleStyle, _BackpackStyle,
-- _FacewearStyle, _UnderwearStyle -- ver snapshot_character mas arriba). Si
-- el HiredPawnOverride (PASO 34) ya habia aplicado equipo sobre un peon, y
-- despues cambia el roster (contratas/despides a CUALQUIER peon) el
-- restauro automatico de PASO 33 vuelve a escribir esos mismos campos con
-- los valores clonados, pisando visualmente el equipo real. Como
-- hpo_apply_if_needed solo reaplica cuando cambia la DIRECCION del
-- Character (no cuando cambia el contenido de _Meta), sin esto el equipo
-- quedaria "revertido" visualmente hasta que vuelvas a tocar algo a mano.
local hpo_applied_cid = {}
local hpo_frame_counter = 0
local hpo_skill_ui_inputs = {}
local hpo_skill_selected_job = {}
local hpo_skill_status = "Listo."
local hpo_skill_applied_signature = {}
local hpo_skill_context_getter = nil
local hpo_skill_context_getter_logged = false
local hpo_global_loadout_system = {
    dir = "PawnResearch/GlobalLoadouts",
    index_file = "PawnResearch/GlobalLoadouts/index.json",
    active_file = "PawnResearch/GlobalLoadouts/active.json",
    index = {},
    index_loaded = false,
    active_name = nil,
    active_member_ids = {},
    active_last_roster_signature = nil,
    name = "MiEscuadra",
    selected_index = 1,
    capture_members = {},
    status = "Listo.",
    active_wait_logged = false
}

local function sync_selected(combo, selected_cid, roster)
    if #roster == 0 then
        combo[1] = 1
        selected_cid[1] = nil
        return
    end

    if selected_cid[1] ~= nil then
        for pos, item in ipairs(roster) do
            if tostring(item.id) == tostring(selected_cid[1]) then
                combo[1] = pos
                return
            end
        end
    end

    if combo[1] < 1 then combo[1] = 1 end
    if combo[1] > #roster then combo[1] = #roster end
    selected_cid[1] = roster[combo[1]].id
end



re.on_frame(function()
    frame_counter = frame_counter + 1
    if post_update_audit_only then return end

    -- Una comprobacion cada ~60 frames. Solo lee como maximo los peones
    -- actuales y sus CharacterID/direcciones.
    if frame_counter % 60 ~= 0 then return end
    if not auto_restore then return end

    local roster = get_roster()
    local sig = roster_signature(roster)

    if sig ~= "" and sig ~= last_signature then
        last_signature = sig

        local restored, skipped, restored_cids = restore_all_assigned()
        if restored > 0 or skipped > 0 then
            status_text = "Restauradas " .. tostring(restored)
                .. " plantilla(s); omitidas " .. tostring(skipped) .. "."

            -- PASO 49: solo los CIDs que acabamos de modificar por restauracion
            -- quedan pendientes para HPO. No se invalida el roster completo:
            -- asi evitamos el ciclo restore -> override -> restore que causo la
            -- caida progresiva de FPS.
            for _, restored_cid in ipairs(restored_cids or {}) do
                hpo_applied_cid[tostring(restored_cid)] = nil
                hpo_skill_applied_signature[tostring(restored_cid)] = nil
            end
        end
    end
end)


logp("[PawnResearch] ===== PASO 33 CARGADO =====")
logp("[PawnResearch] ===== PASO 50 CARGADO (correccion de alcance + anti-hot-loop de excepciones) =====")
logp("[PawnResearch] ===== PASO 51 CARGADO (fix: post-ENABLE usa backing field, no getter, para evitar falso 'sigue sin enable') =====")
logp("[PawnResearch] ===== PASO 74 CARGADO (colores y escala sobre estado vivo, sin equipo/nivel/vocacion) =====")
logp("[PawnResearch] PASO 50: HPO/skills automaticos = una tentativa por CID+configuracion; una excepcion no provoca reintentos automaticos")
logp("[PawnResearch] ===== PASO 92 CARGADO (diagnostico de condiciones applyEdit y parametros de escala; solo lectura) =====")
logp("[PawnResearch] ===== PASO 96 FIX CARGADO (CharacterID por campo + setEditValue altura) =====")
logp("[PawnResearch] Plantillas: reframework/data/" .. TEMPLATE_DIR)
logp("[PawnResearch] Asignaciones: reframework/data/" .. ASSIGNMENTS_FILE)

-- ============================================================
-- PASO 34: Hired Pawn Override integrado (equipo, personalidad,
-- especializacion y voz), sobre nuestra propia infraestructura de roster
-- por CharacterID en vez del PartyPawnList del mod original.
-- ============================================================

local HPO_DIR = "PawnResearch/HiredPawnOverride"
local HPO_ITEMDATA_FILE = HPO_DIR .. "/itemData.json"
local HPO_CONFIG_FILE = HPO_DIR .. "/config.json"
local HPO_SETTINGS_FILE = HPO_DIR .. "/settings.json"
local HPO_SKILL_CATALOG_FILE = HPO_DIR .. "/skillCatalog.json"

-- Catalogo extraido de TWINWV 1.6. La tabla de vocaciones/IDs NO se inventa
-- aqui: se carga desde el archivo que viene con este paso.
local hpo_skill_catalog = safe(function() return json.load_file(HPO_SKILL_CATALOG_FILE) end)
local hpo_skill_names_by_id = {}
local hpo_skill_ids_by_job = {}
local hpo_skill_job_names = {}

if type(hpo_skill_catalog) == "table" then
    for _, entry in ipairs(hpo_skill_catalog.skills or {}) do
        if type(entry) == "table" and entry.id ~= nil then
            local names = type(entry.names) == "table" and entry.names or {}
            hpo_skill_names_by_id[tonumber(entry.id)] = names.en or names.ru or names.ko or names.fr or names.zh
        end
    end

    if type(hpo_skill_catalog.vocation_skills) == "table" then
        for job_key, ids in pairs(hpo_skill_catalog.vocation_skills) do
            local job_num = tonumber(job_key)
            if job_num ~= nil and type(ids) == "table" then
                hpo_skill_ids_by_job[job_num] = {}
                for _, sid in ipairs(ids) do
                    hpo_skill_ids_by_job[job_num][tonumber(sid)] = true
                end
            end
        end
    end

    for _, voc in ipairs(hpo_skill_catalog.vocations or {}) do
        if type(voc) == "table" and voc.id ~= nil and voc.name ~= nil then
            hpo_skill_job_names[tonumber(voc.id)] = tostring(voc.name)
        end
    end

    local source_mod = hpo_skill_catalog.source and hpo_skill_catalog.source.mod or "TWINWV"
    local source_ver = hpo_skill_catalog.source and hpo_skill_catalog.source.version or "?"
    logp("[PawnResearch] PASO 43: catalogo de skills cargado desde " .. tostring(source_mod) .. " " .. tostring(source_ver))
else
    logp("[PawnResearch] PASO 43 AVISO: no se pudo cargar " .. HPO_SKILL_CATALOG_FILE)
end

local function hpo_skill_name(skill_id)
    local id = tonumber(skill_id)
    if id == nil then return "Skill ?" end
    return hpo_skill_names_by_id[id] or ("Skill " .. tostring(id))
end

local function hpo_skill_label(skill_id)
    local id = tonumber(skill_id)
    return hpo_skill_name(id) .. " (ID " .. tostring(id) .. ")"
end

local function hpo_skill_id_is_valid_for_job(job_id, skill_id)
    local job = tonumber(job_id)
    local id = tonumber(skill_id)
    if job == nil or id == nil then return false end
    local ids = hpo_skill_ids_by_job[job]
    return ids ~= nil and ids[id] == true
end

local hpo_skill_job_list, hpo_skill_job_values = {}, {}
do
    local temp = {}
    for job_id, name in pairs(hpo_skill_job_names) do
        temp[#temp + 1] = { id = job_id, name = name }
    end
    table.sort(temp, function(a, b) return a.id < b.id end)
    for _, j in ipairs(temp) do
        hpo_skill_job_list[#hpo_skill_job_list + 1] = j.name .. " (" .. tostring(j.id) .. ")"
        hpo_skill_job_values[#hpo_skill_job_values + 1] = j.id
    end
end

local ItemManager = sdk.get_managed_singleton("app.ItemManager")
if ItemManager == nil then
    logp("[PawnResearch] PASO 34 AVISO: app.ItemManager no disponible en este momento (se reintentara solo en runtime via safe_call/sdk cuando haga falta)")
end

local hpo_itemData = safe(function() return json.load_file(HPO_ITEMDATA_FILE) end)
local hpo_itemLists = {}
local hpo_search_text = {}

local HPO_SLOTS = {
    "Main", "Sub", "Head", "Upper", "Lower", "Mantle",
    "Jewelry_00", "Jewelry_01", "Visual"
}

local HPO_SlotEnum = {
    Main = 0, Sub = 1, Head = 2, Upper = 3, Lower = 4,
    Mantle = 5, Jewelry_00 = 6, Jewelry_01 = 7, Visual = 8
}

-- IDs tal cual figuraban en el mod original. Si en tu version alguno de
-- estos valores no coincide con lo que tu peon ya trae puesto, el log de
-- "Current specialization/personality/voice" al aplicar te va a mostrar
-- el numero real que tiene el juego para que podamos corregir la tabla.
local HPO_PersonalityNames = {
    [1477799926] = "Kindhearted",
    [3817498109] = "Calm",
    [81586066] = "Simple",
    [1301972698] = "Straightforward"
}

local HPO_SpecializationNames = {
    [0] = "None",
    [1] = "Woodland Wordsmith",
    [2] = "Chirurgeon",
    [3] = "Logistician",
    [4] = "Hawker",
    [5] = "Forager",
    [6] = "Aphonite"
}


local hpo_personality_list, hpo_personality_values = { "No Override" }, { [1] = nil }
do
    local temp = {}
    for id, name in pairs(HPO_PersonalityNames) do temp[#temp + 1] = { id = id, name = name } end
    table.sort(temp, function(a, b) return a.name < b.name end)
    for _, p in ipairs(temp) do
        hpo_personality_list[#hpo_personality_list + 1] = p.name
        hpo_personality_values[#hpo_personality_list] = p.id
    end
end

local hpo_specialization_list, hpo_specialization_values = { "No Override" }, { [1] = nil }
do
    local temp = {}
    for id, name in pairs(HPO_SpecializationNames) do temp[#temp + 1] = { id = id, name = name } end
    table.sort(temp, function(a, b) return a.id < b.id end)
    for _, s in ipairs(temp) do
        hpo_specialization_list[#hpo_specialization_list + 1] = s.name
        hpo_specialization_values[#hpo_specialization_list] = s.id
    end
end

local hpo_voice_gender_list = { "No Override", "Male", "Female" }
local hpo_voice_gender_values = { nil, 2776536455, 1910070090 }
local hpo_voice_tone_list = { "No Override", "VeryLow", "Low", "Normal", "High", "VeryHigh", "None" }
local hpo_voice_tone_values = { nil, 1, 2, 3, 4, 5, 6 }

-- PASO 35: lista de vocaciones para el combo de "Vocacion" del override.
-- Se arma desde HPO_JobRealNames (definida mas arriba, junto a
-- hpo_job_name), ordenada por numero de vocacion. No incluye [0]
-- ("Sin vocacion"): no tiene sentido forzarle esa "vocacion" a un peon.
local hpo_job_list, hpo_job_values = { "No Override" }, { [1] = nil }
do
    local temp = {}
    for id, name in pairs(HPO_JobRealNames) do
        if id ~= 0 then
            temp[#temp + 1] = { id = id, name = name }
        end
    end
    table.sort(temp, function(a, b) return a.id < b.id end)
    for _, j in ipairs(temp) do
        hpo_job_list[#hpo_job_list + 1] = j.name .. " (" .. j.id .. ")"
        hpo_job_values[#hpo_job_list] = j.id
    end
end

local function hpo_default_pawn_config()
    return {
        enabled = false,
        equipment = {
            Main = 0, Sub = 0, Head = 0, Upper = 0, Lower = 0,
            Mantle = 0, Jewelry_00 = 0, Jewelry_01 = 0, Visual = 0
        },
        personality = nil, specialization = nil,
        voice_gender = nil, voice_tone = nil,
        job = nil, -- override de vocacion (el override de nivel se elimino, ver hpo_apply_vocation)
        skills_enabled = false,
        -- Loadout por vocacion:
        -- skills["1"]["0"] = ID para Slot 0 de Job01, etc.
        -- Una clave de slot ausente significa "no tocar ese slot".
        skills = {}
    }
end

local function hpo_save_config(cfg)
    local ok = pcall(function() json.dump_file(HPO_CONFIG_FILE, cfg) end)
    if not ok then logp("[PawnResearch] PASO 34 ERROR guardando " .. HPO_CONFIG_FILE) end
    return ok
end

-- Cache en memoria: NO releemos el archivo en cada frame ni en cada frame
-- de UI. La primera vez que el archivo no existe, json.load_file de
-- REFramework escribe un [error] en re2_framework_log.txt -- eso es
-- normal en un archivo nuevo, pero si lo intentamos leer 30+ veces por
-- segundo (como hacia la version anterior) satura el log con cientos de
-- lineas identicas. Por eso lo leemos UNA vez, y si no existe lo creamos
-- vacio inmediatamente para que esa unica lectura fallida no se repita.
local function hpo_load_config_from_disk()
    local data = safe(function() return json.load_file(HPO_CONFIG_FILE) end)
    if type(data) == "table" then return data end
    return nil
end

local hpo_config_cache = hpo_load_config_from_disk()
if hpo_config_cache == nil then
    hpo_config_cache = {}
    hpo_save_config(hpo_config_cache)
    logp("[PawnResearch] PASO 34: " .. HPO_CONFIG_FILE .. " no existia, se creo vacio")
end

local function hpo_get_config()
    return hpo_config_cache
end

local function hpo_set_config(cfg)
    hpo_config_cache = cfg
    return hpo_save_config(cfg)
end

-- Ajustes GLOBALES (no por peon), en su propio archivo para no mezclar
-- claves con el config.json que esta indexado por CharacterID.
local function hpo_default_settings()
    return { lock_equipment_to_job = false }
end

local function hpo_save_settings(settings)
    local ok = pcall(function() json.dump_file(HPO_SETTINGS_FILE, settings) end)
    if not ok then logp("[PawnResearch] PASO 34 ERROR guardando " .. HPO_SETTINGS_FILE) end
    return ok
end

local function hpo_load_settings_from_disk()
    local data = safe(function() return json.load_file(HPO_SETTINGS_FILE) end)
    if type(data) == "table" then return data end
    return nil
end

local hpo_settings_cache = hpo_load_settings_from_disk()
if hpo_settings_cache == nil then
    hpo_settings_cache = hpo_default_settings()
    hpo_save_settings(hpo_settings_cache)
    logp("[PawnResearch] PASO 34: " .. HPO_SETTINGS_FILE .. " no existia, se creo con valores por defecto")
end
if hpo_settings_cache.lock_equipment_to_job == nil then
    hpo_settings_cache.lock_equipment_to_job = false
end

local function hpo_build_item_lists()
    if not hpo_itemData then
        logp("[PawnResearch] PASO 34 AVISO: no se encontro " .. HPO_ITEMDATA_FILE .. " (copia itemData.json del mod original ahi)")
        return
    end
    for _, slot in ipairs(HPO_SLOTS) do
        hpo_itemLists[slot] = { { id = 0, name = "No Override" } }
    end
    local count = 0
    for id_str, item in pairs(hpo_itemData) do
        local id = tonumber(id_str)
        if id and item.name and item.category then
            local entry = { id = id, name = item.name .. " (ID: " .. id .. ")", job = item.job }
            if item.category == "Weapon" then table.insert(hpo_itemLists.Main, entry)
            elseif item.category == "Shield" then table.insert(hpo_itemLists.Sub, entry)
            elseif item.category == "Head" then table.insert(hpo_itemLists.Head, entry)
            elseif item.category == "Chest" then table.insert(hpo_itemLists.Upper, entry)
            elseif item.category == "Legs" then table.insert(hpo_itemLists.Lower, entry)
            elseif item.category == "Mantle" then table.insert(hpo_itemLists.Mantle, entry)
            elseif item.category == "Jewelry" then
                table.insert(hpo_itemLists.Jewelry_00, entry)
                table.insert(hpo_itemLists.Jewelry_01, entry)
            elseif item.category == "Visual" then table.insert(hpo_itemLists.Visual, entry)
            end
            count = count + 1
        end
    end
    for _, list in pairs(hpo_itemLists) do
        table.sort(list, function(a, b)
            if a.id == 0 then return true end
            if b.id == 0 then return false end
            return a.name < b.name
        end)
    end
    logp("[PawnResearch] PASO 34: itemData cargado, " .. count .. " items")
end
hpo_build_item_lists()

local function hpo_filter(slot, search_key, current_job)
    local search = (hpo_search_text[search_key] or ""):lower()
    local list = hpo_itemLists[slot] or {}
    local lock_active = hpo_settings_cache.lock_equipment_to_job and current_job ~= nil

    if search == "" and not lock_active then return list end

    local out = {}
    for _, item in ipairs(list) do
        local matches_search = search == ""
            or item.name:lower():find(search, 1, true)
            or tostring(item.id):find(search, 1, true)

        -- id == 0 es "No Override": siempre se deja disponible sin importar
        -- la vocacion, para poder quitar el override en cualquier momento.
        local matches_job = (not lock_active) or item.id == 0 or is_job_bit_set(item.job, current_job)

        if matches_search and matches_job then
            out[#out + 1] = item
        end
    end
    return out
end

local function hpo_item_name(slot, item_id)
    if item_id == 0 or item_id == nil then return "No Override" end
    for _, item in ipairs(hpo_itemLists[slot] or {}) do
        if item.id == item_id then return item.name end
    end
    return "Unknown (ID: " .. tostring(item_id) .. ")"
end

-- El mod original ubicaba getItem() con un string de firma hecho a mano
-- (nombres de tipo exactos, incluido el enum anidado). Eso fue justo lo
-- que fallo en tu prueba (get_method devolvio nil -> "attempt to index a
-- nil value"): algo en esa firma exacta ya no coincide. En vez de adivinar
-- de nuevo a ciegas, la buscamos por reflexion (mismo truco que usamos en
-- pasos anteriores con log_method_signature): listamos TODAS las
-- sobrecargas llamadas "getItem", logueamos cada una, y usamos la que
-- tenga 9 parametros con un app.Character en la posicion esperada.
local hpo_getitem_method_cache = nil
local hpo_getitem_kind_cache = nil -- "character" o "characterid", segun que parametro tenga la sobrecarga elegida
local hpo_getitem_lookup_done = false

local function hpo_find_getitem_method(td)
    if hpo_getitem_lookup_done then return hpo_getitem_method_cache, hpo_getitem_kind_cache end
    hpo_getitem_lookup_done = true

    if td == nil then
        logp("[PawnResearch] PASO 34: no se pudo obtener el TypeDefinition de ItemManager")
        return nil
    end

    local methods_all = {}
    local seen_types = {}
    local walk_td = td
    while walk_td ~= nil do
        local tname = safe(function() return walk_td:get_full_name() end) or "<?>"
        if seen_types[tname] then break end
        seen_types[tname] = true
        local methods = safe(function() return walk_td:get_methods() end) or {}
        for _, m in ipairs(methods) do methods_all[#methods_all + 1] = m end
        walk_td = safe(function() return walk_td:get_parent_type() end)
    end

    local candidates = {}
    for _, m in ipairs(methods_all) do
        local mn = safe(function() return m:get_name() end)
        if mn == "getItem" then
            local pts = safe(function() return m:get_param_types() end) or {}
            local names = {}
            for _, pt in ipairs(pts) do
                names[#names + 1] = safe(function() return pt:get_full_name() end) or "<?>"
            end
            logp("[PawnResearch] PASO 34 sobrecarga hallada: getItem(" .. table.concat(names, ", ") .. ")  [" .. #names .. " parametros]")
            candidates[#candidates + 1] = { method = m, count = #names, names = names }
        end
    end

    if #candidates == 0 then
        logp("[PawnResearch] PASO 34: ItemManager no tiene NINGUN metodo llamado 'getItem' (puede haberse renombrado)")
        return nil
    end

    -- PASO 34-4: la busqueda de "9 parametros con Character" era la firma
    -- del mod original (escrito para una version distinta del juego). En tu
    -- version, las sobrecargas reales de getItem son mucho mas simples --
    -- el propio log ya las listo (2 a 4 parametros). Usamos la de 3
    -- parametros (itemId:Int32, cantidad:Int32, Character o CharacterID),
    -- que es la que mejor calza con lo que ya tenemos (item_id, character).
    -- Preferimos la variante con app.Character (evita tener que resolver
    -- CharacterID por separado), pero aceptamos app.CharacterID si es la
    -- unica disponible.
    local best, best_kind = nil, nil
    for _, c in ipairs(candidates) do
        if c.count == 3 then
            if c.names[3] == "app.Character" then
                best, best_kind = c.method, "character"
                break
            elseif c.names[3] == "app.CharacterID" and best == nil then
                best, best_kind = c.method, "characterid"
            end
        end
    end

    if best == nil then
        logp("[PawnResearch] PASO 34 AVISO: no encontre getItem(Int32, Int32, Character/CharacterID) de 3 parametros entre las sobrecargas listadas arriba. Avisame para ajustar la llamada -- por seguridad NO se va a invocar ninguna a ciegas.")
        return nil
    end

    logp("[PawnResearch] PASO 34: usando getItem(Int32, Int32, " .. (best_kind == "character" and "Character" or "CharacterID") .. ")")
    hpo_getitem_method_cache = best
    hpo_getitem_kind_cache = best_kind
    return best, best_kind
end

-- Equipo: opera directo sobre un app.Character (ya lo obtenemos de
-- get_roster(), no hace falta traducir desde ningun "pawn wrapper").
local function hpo_apply_equipment(character, equipment_config)
    if ItemManager == nil then
        ItemManager = sdk.get_managed_singleton("app.ItemManager")
        if ItemManager == nil then return false, "ItemManager no disponible" end
    end

    local char_id = get_field_value_by_name(character, "CharacterID")
    local equipData = safe_call(ItemManager, "getEquipData", char_id)
    if equipData == nil then return false, "getEquipData devolvio nil (CID=" .. tostring(char_id) .. ")" end

    local any_ok, any_fail = 0, 0
    for slot_name, item_id in pairs(equipment_config) do
        if item_id and item_id > 0 then
            local slot_enum = HPO_SlotEnum[slot_name]
            if slot_enum ~= nil then
                local current_item = safe_call(equipData, "get(app.EquipData.SlotEnum)", slot_enum)
                local current_id = current_item and get_field_value_by_name(current_item, "_ItemId") or 0
                if current_id ~= item_id then
                    local itemData = safe_call(ItemManager, "getItemData", item_id)
                    if itemData == nil then
                        any_fail = any_fail + 1
                        logp("[PawnResearch] PASO 34 equipo: getItemData(" .. item_id .. ") devolvio nil")
                    else
                        local td = safe(function() return ItemManager:get_type_definition() end)
                        local getItemMethod, getItemKind = hpo_find_getitem_method(td)
                        if getItemMethod == nil then
                            any_fail = any_fail + 1
                            logp("[PawnResearch] PASO 34 equipo: no se encontro un getItem() utilizable, se omite este item (revisa el AVISO de arriba en el log)")
                        else
                        -- PASO 34-4: llamada real de 3 parametros
                        -- (getItem(itemId, cantidad, Character/CharacterID)),
                        -- ya no los 9 argumentos inventados que no existen
                        -- en tu version del juego.
                        local target_arg = (getItemKind == "character") and character or char_id
                        local ok1, err1 = pcall(function()
                            getItemMethod:call(ItemManager, item_id, 1, target_arg)
                        end)
                        if not ok1 then
                            any_fail = any_fail + 1
                            logp("[PawnResearch] PASO 34 equipo: getItem() fallo -> " .. tostring(err1))
                        else
                            local storageData = safe_call(ItemManager, "getStorageData", item_id, char_id)
                            if storageData == nil then
                                any_fail = any_fail + 1
                                logp("[PawnResearch] PASO 34 equipo: getStorageData nil para item " .. item_id)
                            else
                                pcall(function()
                                    storageData:set_field("_ItemData", itemData)
                                    storageData:set_field("_IsEquipped", false)
                                    storageData:set_field("_IsNew", false)
                                end)
                                local ok2, err2 = pcall(function()
                                    ItemManager:call("setEquip", storageData, character, slot_enum, true, true)
                                end)
                                if ok2 then
                                    any_ok = any_ok + 1
                                    logp("[PawnResearch] PASO 34 equipo: " .. slot_name .. " <- ID " .. item_id .. " (antes " .. tostring(current_id) .. ")")
                                else
                                    any_fail = any_fail + 1
                                    logp("[PawnResearch] PASO 34 equipo: setEquip fallo en " .. slot_name .. " -> " .. tostring(err2))
                                end
                            end
                        end
                        end
                    end
                end
            end
        end
    end
    -- PASO 34-4: el equipo "real" via ItemManager/setEquip no llamaba a
    -- ningun refresco visual -- a diferencia del clonado de PASO 27/30, que
    -- SI llama apply_refresh() despues de tocar _Meta. Si setEquip por si
    -- solo no repinta el modelo (mismo tipo de problema que ya tuvimos con
    -- _HairStyle en el Paso 19-22), esto lo cubre reusando la MISMA funcion
    -- de refresco ya confirmada, en vez de inventar una nueva.
    if any_ok > 0 then
        local ps = get_part_swapper(character)
        apply_refresh(ps)
    end

    return any_fail == 0, "ok=" .. any_ok .. " fail=" .. any_fail
end

-- Personalidad/especializacion/voz: via HumanPartSwapper._PawnDataContext,
-- usando nuestro propio get_part_swapper(character) ya confirmado.
local function hpo_apply_attributes(character, personality, specialization, voice_gender, voice_tone)
    local ps = get_part_swapper(character)
    if ps == nil then return false, "PartSwapper nil" end

    local pawnDataContext = get_field_value_by_name(ps, "_PawnDataContext")
    if pawnDataContext == nil then return false, "_PawnDataContext nil (puede que el nombre real del campo haya cambiado)" end

    local notes = {}

    if personality ~= nil then
        local current = safe_call(pawnDataContext, "get_Personality")
        local ok, err = pcall(function() pawnDataContext:call("setPersonarity", personality) end)
        if ok then
            notes[#notes + 1] = "personalidad " .. tostring(current) .. " -> " .. tostring(personality)
        else
            notes[#notes + 1] = "ERROR personalidad: " .. tostring(err)
        end
    end

    if voice_gender ~= nil or voice_tone ~= nil then
        local target_gender = voice_gender or safe_call(pawnDataContext, "get_VoiceGender")
        local target_tone = voice_tone or safe_call(pawnDataContext, "get_VoiceToneType")
        local ok, err = pcall(function()
            pawnDataContext:call("setVoiceGender", target_gender)
            pawnDataContext:call("setVoiceToneType", target_tone)
        end)
        if ok then
            notes[#notes + 1] = "voz -> genero=" .. tostring(target_gender) .. " tono=" .. tostring(target_tone)
        else
            notes[#notes + 1] = "ERROR voz: " .. tostring(err)
        end
    end

    if specialization ~= nil then
        local current = get_field_value_by_name(pawnDataContext, "_SubSkill")
        local ok, err = set_field_value_by_name(pawnDataContext, "_SubSkill", specialization)
        if ok then
            notes[#notes + 1] = "especializacion " .. tostring(current) .. " -> " .. tostring(specialization)
        else
            notes[#notes + 1] = "ERROR especializacion: " .. tostring(err)
        end
    end

    return true, table.concat(notes, " | ")
end

-- Vocacion sobre un peon YA EXISTENTE (set_field_value_by_name sobre
-- CurrentJob, confirmado que persiste leyendo de vuelta), aplicada en
-- caliente sobre el roster actual en vez de solo en el momento de
-- contratar (hook de hirePawn). Tambien reescribimos el backing field
-- del contenedor (JobContext) por si el juego usa una copia en vez de
-- una referencia -- mismo cuidado que ya teniamos en el hook.
--
-- NOTA: el cambio de NIVEL se probo y se descarto -- el campo _Level se
-- escribe y persiste, pero no recalcula vida/fuerza/magia/etc, asi que
-- solo cambiaba un numero sin efecto real. Se elimino esa parte tanto de
-- aqui como de la UI.
local function hpo_apply_vocation(character, job)
    if job == nil then return true, "sin cambios (job en nil)" end

    local human = get_field_value_by_name(character, "<Human>k__BackingField")
    if human == nil then return false, "Human nil" end

    local job_ctx = get_field_value_by_name(human, "<JobContext>k__BackingField")
    if job_ctx == nil then
        return false, "ERROR vocacion: JobContext nil"
    end

    local before = get_field_value_by_name(job_ctx, "CurrentJob")
    local ok, err = set_field_value_by_name(job_ctx, "CurrentJob", job)
    if not ok then
        return false, "ERROR vocacion: " .. tostring(err)
    end

    safe(function() human:set_field("<JobContext>k__BackingField", job_ctx) end)
    return true, "vocacion " .. hpo_job_name(before) .. " -> " .. hpo_job_name(job)
end


-- ============================================================
-- PASO 42: LOADOUT DE SKILLS EQUIPADAS
--
-- Confirmado en PASO 39:
--   * Human.<SkillContext>k__BackingField = app.HumanSkillContext
--   * SkillSlotValues = app.HumanSkillContext.SkillSlot[] con 6 slots (0..5)
--   * getSkillID(job, slot) -> HumanCustomSkillID
--   * setSkill(job, HumanCustomSkillID, slot) -> Boolean
--   * getEquipList(job) -> EquipedSkill
--   * EquipedSkills[] contiene 11 EquipedSkill; cada uno tiene Skills[]
--   * El Job0XActionController actual NO expuso campos/arrays de loadout.
--
-- Por eso la escritura se hace SOLO mediante HumanSkillContext:setSkill(),
-- pasando el JobEnum real del personaje y el SkillSlot real obtenido de
-- SkillSlotValues. NO se modifica EquipedSkills[] a mano.
--
-- La reflexion de PASO 39 NO mostro un campo/tabla "job bit" para los IDs
-- de HumanCustomSkillID equivalente a itemData.json. No se inventa una
-- tabla. La vocacion se conserva directamente en el parametro job de la
-- API real del juego.
-- ============================================================

local HPO_SKILL_SLOT_COUNT = 6
local HPO_SKILL_CONTEXT_FIELD = "<SkillContext>k__BackingField"

-- TWINWV obtiene SkillContext mediante get_SkillContext(). Lo usamos tambien
-- aqui, pero SOLO despues de reconfirmar por reflexion la firma exacta. El
-- backing field queda como fallback diagnostico, nunca como supuesto exclusivo.
local function hpo_resolve_skill_context_getter(human)
    if human == nil then return nil end
    if hpo_skill_context_getter ~= nil then return hpo_skill_context_getter end

    local td = safe(function() return human:get_type_definition() end)
    if td == nil then return nil end

    local methods = safe(function() return td:get_methods() end) or {}
    for _, method in ipairs(methods) do
        local name = safe(function() return method:get_name() end)
        local params = safe(function() return method:get_param_types() end) or {}
        local ret_type = safe(function() return method:get_return_type() end)
        local ret_name = ret_type ~= nil and safe(function() return ret_type:get_full_name() end) or nil
        if name == "get_SkillContext" and #params == 0 and ret_name == "app.HumanSkillContext" then
            hpo_skill_context_getter = method
            if not hpo_skill_context_getter_logged then
                logp("[PawnResearch] PASO 43: get_SkillContext() -> app.HumanSkillContext confirmado por reflexion")
                hpo_skill_context_getter_logged = true
            end
            return method
        end
    end

    return nil
end

local function hpo_get_skill_context(human)
    if human == nil then return nil end

    local getter = hpo_resolve_skill_context_getter(human)
    if getter ~= nil then
        local ok, ctx = pcall(function() return getter:call(human) end)
        if ok and ctx ~= nil then return ctx end
    end

    return get_field_value_by_name(human, HPO_SKILL_CONTEXT_FIELD)
end

local function hpo_skill_context_parts(character)
    if character == nil then
        return nil, nil, nil, nil, nil
    end

    local human = get_human(character)
    if human == nil then
        return nil, nil, nil, nil, nil
    end

    local job_ctx = get_job_context(character)
    if job_ctx == nil then
        return human, nil, nil, nil, nil
    end

    local current_job = get_field_value_by_name(job_ctx, "CurrentJob")
    local skill_context = hpo_get_skill_context(human)
    local slot_values = skill_context ~= nil
        and get_field_value_by_name(skill_context, "SkillSlotValues")
        or nil

    return human, job_ctx, skill_context, current_job, slot_values
end

-- PASO 51: en Paso 50 encontramos que, justo despues de escribir con
-- setCustomSkillEnable(), volver a pedir el estado por DOS caminos distintos
-- da resultados distintos:
--   - hpo_step47_enable_skills_only() releia el SkillContext SIEMPRE por el
--     backing field crudo (<SkillContext>k__BackingField) para su propio
--     "ENABLE VERIFY", y ese camino confirmo enable=true/level=2 para los 4
--     IDs (log50: "PASO 49 ENABLE VERIFY ... enable=true level=2").
--   - hpo_apply_skill_loadout() (la funcion de mas abajo), en cambio, volvia
--     a pedir el SkillContext con hpo_skill_context_parts(), que PREFIERE el
--     getter get_SkillContext() sobre el backing field. Con ESE camino, la
--     misma comprobacion de isCustomSkillEnable() para los mismos 4 IDs, en
--     el mismo frame, dio false ("PASO 50 skill omitida: ... sigue sin
--     enable=true"), y por eso setSkill() nunca llegaba a intentarse.
-- Paso 43 ya habia comparado getter vs backing field UNA vez (en una lectura
-- normal, sin escribir nada) y coincidian ("SkillContext misma
-- referencia=true"). El log50 es la primera vez que tenemos evidencia de que
-- pueden divergir justo en la ventana de lectura-tras-escritura. La funcion
-- de mas abajo (hpo_apply_skill_loadout) deja de llamar a
-- hpo_skill_context_parts() para su re-lectura POST-ENABLE y en su lugar lee
-- el backing field directamente ahi mismo (sin agregar una funcion nueva a
-- nivel de archivo -- el .lua ya esta al limite de 200 locales de Lua por
-- chunk principal, tal como paso con skills_selected/skills_cid en el Paso
-- 47). No se toca hpo_skill_context_parts() en el resto del archivo (otros
-- llamadores siguen igual) porque no hay evidencia de que el problema exista
-- ahi tambien -- si aparece, se corrige con la misma disciplina, no por
-- adelantado.

local function hpo_enum_underlying_number(value, expected_type_name)
    if value == nil then
        return nil
    end

    -- Los enum value-types que devuelve la API Lua pueden llegar ya como su
    -- valor integral subyacente (por ejemplo Int32). Ese es el formato que
    -- se puede pasar de vuelta como parametro de enum.
    if type(value) == "number" then
        local n = tonumber(value)
        if n ~= nil and n == math.floor(n) then
            return n
        end
        return nil
    end

    -- Los elementos de SkillSlotValues obtenidos mediante get_elements()
    -- pueden llegar como ValueType/objeto boxed. En ese caso usamos SOLO el
    -- campo value__ que Paso 39 ya confirmo por reflexion.
    local td = safe(function() return value:get_type_definition() end)
    if td ~= nil then
        local type_name = safe(function() return td:get_full_name() end)
        if expected_type_name == nil or type_name == expected_type_name then
            local underlying = safe(function() return value:get_field("value__") end)
            local n = tonumber(underlying)
            if n ~= nil and n == math.floor(n) then
                return n
            end
        end
    end

    return nil
end

local function hpo_skill_slot_value(skill_context, slot_values, slot_index)
    if skill_context == nil or slot_values == nil then
        return nil
    end
    if slot_index == nil or slot_index < 0 or slot_index >= HPO_SKILL_SLOT_COUNT then
        return nil
    end

    local elements = safe(function() return slot_values:get_elements() end)
    if elements == nil then
        return nil
    end

    return hpo_enum_underlying_number(
        elements[slot_index + 1],
        "app.HumanSkillContext.SkillSlot"
    )
end

local function hpo_skill_id_value(raw_skill_id)
    return hpo_enum_underlying_number(
        raw_skill_id,
        "app.HumanCustomSkillID"
    )
end

local hpo_skill_get_method = nil
local hpo_skill_set_method = nil
local hpo_skill_methods_logged = false

local function hpo_resolve_skill_context_methods(skill_context)
    if skill_context == nil then
        return nil, nil, "SkillContext nil"
    end

    if hpo_skill_get_method ~= nil and hpo_skill_set_method ~= nil then
        return hpo_skill_get_method, hpo_skill_set_method, nil
    end

    local td = safe(function() return skill_context:get_type_definition() end)
    if td == nil then
        return nil, nil, "no se pudo obtener TypeDefinition de HumanSkillContext"
    end

    local methods = safe(function() return td:get_methods() end) or {}
    local get_candidate, set_candidate = nil, nil

    for _, method in ipairs(methods) do
        local name = safe(function() return method:get_name() end)
        local params = safe(function() return method:get_param_types() end) or {}
        local ret_type = safe(function() return method:get_return_type() end)
        local ret_name = ret_type ~= nil and safe(function() return ret_type:get_full_name() end) or nil

        if name == "getSkillID"
            and #params == 2
            and safe(function() return params[1]:get_full_name() end) == "app.Character.JobEnum"
            and safe(function() return params[2]:get_full_name() end) == "app.HumanSkillContext.SkillSlot"
            and ret_name == "app.HumanCustomSkillID"
        then
            get_candidate = method
        elseif name == "setSkill"
            and #params == 3
            and safe(function() return params[1]:get_full_name() end) == "app.Character.JobEnum"
            and safe(function() return params[2]:get_full_name() end) == "app.HumanCustomSkillID"
            and safe(function() return params[3]:get_full_name() end) == "app.HumanSkillContext.SkillSlot"
            and ret_name == "System.Boolean"
        then
            set_candidate = method
        end
    end

    if get_candidate == nil or set_candidate == nil then
        return nil, nil, "no se pudo reconfirmar por reflexion getSkillID/setSkill con las firmas de Paso 39"
    end

    hpo_skill_get_method = get_candidate
    hpo_skill_set_method = set_candidate

    if not hpo_skill_methods_logged then
        logp("[PawnResearch] PASO 42: getSkillID(job, SkillSlot) confirmado por reflexion")
        logp("[PawnResearch] PASO 42: setSkill(job, HumanCustomSkillID, SkillSlot) -> Boolean confirmado por reflexion")
        hpo_skill_methods_logged = true
    end

    return hpo_skill_get_method, hpo_skill_set_method, nil
end

local function hpo_read_skill_loadout(character, requested_job)
    local human, job_ctx, skill_context, current_job, slot_values =
        hpo_skill_context_parts(character)

    if human == nil then
        return false, "Human nil", nil
    end
    if job_ctx == nil then
        return false, "JobContext nil", nil
    end
    if skill_context == nil then
        return false, "SkillContext nil", nil
    end
    if current_job == nil then
        return false, "CurrentJob nil", nil
    end
    if slot_values == nil then
        return false, "SkillSlotValues nil", nil
    end

    local target_job = requested_job ~= nil and tonumber(requested_job) or tonumber(current_job)
    if target_job == nil then
        return false, "job objetivo nil", nil
    end

    local get_skill_method, _, method_err =
        hpo_resolve_skill_context_methods(skill_context)
    if get_skill_method == nil then
        return false, method_err or "getSkillID no disponible", nil
    end

    local out = {
        current_job = current_job,
        current_job_num = tonumber(current_job),
        read_job = target_job,
        slots = {}
    }

    for slot = 0, HPO_SKILL_SLOT_COUNT - 1 do
        local slot_value = hpo_skill_slot_value(skill_context, slot_values, slot)
        if slot_value == nil then
            return false, "SkillSlotValues[" .. tostring(slot) .. "] no disponible", out
        end

        local ok, skill_id = pcall(function()
            return get_skill_method:call(
                skill_context,
                target_job,
                slot_value
            )
        end)

        if ok then
            out.slots[slot] = hpo_skill_id_value(skill_id)
            if out.slots[slot] == nil and skill_id ~= nil then
                local raw_type = safe(function() return skill_id:get_type_definition():get_full_name() end)
                local raw_value = safe(function() return skill_id:get_field("value__") end)
                logp("[PawnResearch] PASO 42: getSkillID devolvio tipo=" .. tostring(raw_type) .. " value__=" .. tostring(raw_value))
            end
        else
            out.slots[slot] = nil
        end
    end

    return true, nil, out
end

local hpo_skill_refresh_method = nil
local hpo_skill_refresh_logged = false

local function hpo_resolve_skill_refresh_method()
    if hpo_skill_refresh_method ~= nil then
        return hpo_skill_refresh_method
    end

    local gui = safe(function() return sdk.get_managed_singleton("app.GuiManager") end)
    if gui == nil then
        return nil
    end

    local td = safe(function() return gui:get_type_definition() end)
    if td == nil then return nil end

    local methods = safe(function() return td:get_methods() end) or {}
    for _, method in ipairs(methods) do
        local name = safe(function() return method:get_name() end)
        local params = safe(function() return method:get_param_types() end) or {}
        if name == "setupKeyGuideCustomSkill" and #params == 0 then
            hpo_skill_refresh_method = { instance = gui, method = method }
            if not hpo_skill_refresh_logged then
                logp("[PawnResearch] PASO 42: GuiManager.setupKeyGuideCustomSkill() confirmado por reflexion")
                hpo_skill_refresh_logged = true
            end
            return hpo_skill_refresh_method
        end
    end

    if not hpo_skill_refresh_logged then
        logp("[PawnResearch] PASO 43 AVISO: GuiManager no expone setupKeyGuideCustomSkill() con 0 parametros")
        hpo_skill_refresh_logged = true
    end
    return nil
end

local function hpo_refresh_skill_key_guide()
    local resolved = hpo_resolve_skill_refresh_method()
    if resolved == nil then return false end
    local ok, result = pcall(function()
        return resolved.method:call(resolved.instance)
    end)
    if ok then
        logp("[PawnResearch] PASO 42: setupKeyGuideCustomSkill() ejecutado -> " .. tostring(result))
        return true
    end
    logp("[PawnResearch] PASO 43 AVISO: setupKeyGuideCustomSkill() fallo -> " .. tostring(result))
    return false
end

local hpo_step47_enable_skills_only

-- PASO 59: collector funcional usado por "Guardar loadout" y "Guardar + aplicar".
-- Un campo vacio/"No modificar" no entra al mapa. ID 0, en cambio, es un valor
-- real y validado para limpiar un slot mediante setSkill().
local function hpo_collect_skill_config(skill_inputs)
    local result = {}

    for slot = 0, HPO_SKILL_SLOT_COUNT - 1 do
        local text = tostring(skill_inputs[slot] or "")
        text = text:gsub("^%s+", ""):gsub("%s+$", "")

        if text ~= "" then
            local numeric_id = tonumber(text)
            if numeric_id == nil
                or numeric_id ~= math.floor(numeric_id)
                or numeric_id < 0
            then
                return false,
                    "Slot " .. tostring(slot) .. ": ID invalido '" .. text .. "'"
            end

            result[tostring(slot)] = numeric_id
        end
    end

    return true, nil, result
end

local function hpo_apply_skill_loadout(character, skill_config, target_job)
    if post_update_audit_only then
        return false, "BLOQUEADO: modo de auditoria post-TU4 activo.", 0, 0
    end
    local cid = get_field_value_by_name(character, "CharacterID")

    if is_character_protected(cid) then
        return false, "BLOQUEADO por candado de seguridad (" .. describe_character_id(get_roster(), cid) .. ")", 0, 0
    end

    if type(skill_config) ~= "table" then
        return true, "sin configuracion de skills para esta vocacion", 0, 0
    end

    local human, job_ctx, skill_context, current_job, slot_values =
        hpo_skill_context_parts(character)

    if human == nil then
        return false, "Human nil", 0, 0
    end
    if job_ctx == nil then
        return false, "JobContext nil", 0, 0
    end
    if skill_context == nil then
        return false, "SkillContext nil", 0, 0
    end
    if current_job == nil then
        return false, "CurrentJob nil", 0, 0
    end
    if slot_values == nil then
        return false, "SkillSlotValues nil", 0, 0
    end

    local job_to_apply = target_job ~= nil and tonumber(target_job) or tonumber(current_job)
    if job_to_apply == nil then
        return false, "job objetivo nil", 0, 0
    end

    if next(hpo_skill_ids_by_job) ~= nil and hpo_skill_ids_by_job[job_to_apply] == nil then
        return false,
            "el catalogo TWINWV 1.6 no define skills para " .. hpo_job_name(job_to_apply),
            0,
            0
    end

    local get_skill_method, set_skill_method, method_err =
        hpo_resolve_skill_context_methods(skill_context)
    if get_skill_method == nil or set_skill_method == nil then
        return false, method_err or "getSkillID/setSkill no disponibles", 0, 0
    end

    local enable_ok, enable_msg, enable_writes, enable_fail, enable_verified =
        hpo_step47_enable_skills_only(character, skill_config, job_to_apply)
    logp("[PawnResearch] PASO 60 fase ENABLE -> " .. tostring(enable_msg))
    local verified_count = 0
    if type(enable_verified) == "table" then
        for _ in pairs(enable_verified) do verified_count = verified_count + 1 end
    end
    logp("[PawnResearch] PASO 60: IDs confirmados por la verificacion fresca de ENABLE=" .. tostring(verified_count))
    if not enable_ok and enable_writes == 0 and verified_count == 0 then
        return false, "fase ENABLE fallo: " .. tostring(enable_msg), 0, enable_fail
    end
    if not enable_ok and verified_count > 0 then
        logp(
            "[PawnResearch] PASO 59: fase ENABLE tuvo " .. tostring(enable_fail)
            .. " fallo(s), pero continuara con las " .. tostring(verified_count)
            .. " ID(s) confirmadas en la verificacion FRESCA"
        )
    end

    -- IMPORTANTE: setCustomSkillEnable() puede actualizar/reemplazar el
    -- SkillContext que usa el personaje. No se reutiliza el objeto capturado
    -- antes de habilitar. Se obtiene de nuevo el roster y, sobre ese Character
    -- fresco, se vuelve a resolver Human/SkillContext/SkillSlotValues y las
    -- firmas reales de getSkillID/setSkill.
    local post_enable_roster = get_roster()
    local post_enable_entry = find_roster_by_id(post_enable_roster, cid)
    if post_enable_entry == nil or post_enable_entry.character == nil then
        return false,
            "habilitacion realizada pero no se pudo obtener Character fresco para continuar con setSkill",
            enable_writes,
            enable_fail
    end

    local post_character = post_enable_entry.character
    -- PASO 51: antes se llamaba aqui a hpo_skill_context_parts(), que
    -- prefiere el getter get_SkillContext(). Log50 demostro que eso puede
    -- devolver un estado de enable/level distinto al que la propia fase de
    -- habilitacion (arriba) ya verifico por el backing field. Se repite en
    -- linea el mismo camino ya probado (backing field directo) en vez de
    -- agregar una funcion nueva a nivel de archivo, porque el chunk
    -- principal ya esta al limite de 200 locales de Lua (el mismo problema
    -- que ya hubo con skills_selected/skills_cid en el Paso 47).
    local post_human = get_human(post_character)
    local post_job_ctx = post_human ~= nil and get_job_context(post_character) or nil
    local post_current_job = post_job_ctx ~= nil and get_field_value_by_name(post_job_ctx, "CurrentJob") or nil
    local post_skill_context = post_human ~= nil and get_field_value_by_name(post_human, HPO_SKILL_CONTEXT_FIELD) or nil
    local post_slot_values = post_skill_context ~= nil and get_field_value_by_name(post_skill_context, "SkillSlotValues") or nil

    if post_human == nil or post_job_ctx == nil or post_skill_context == nil or post_slot_values == nil then
        return false,
            "habilitacion realizada pero faltan Human/JobContext/SkillContext/SkillSlotValues en Character fresco",
            enable_writes,
            enable_fail
    end

    logp("[PawnResearch] PASO 51 CONTEXTO POST-ENABLE: SkillContext fresco obtenido desde backing field")
    human = post_human
    job_ctx = post_job_ctx
    skill_context = post_skill_context
    current_job = post_current_job
    slot_values = post_slot_values

    local post_get_skill_method, post_set_skill_method, post_method_err =
        hpo_resolve_skill_context_methods(skill_context)
    if post_get_skill_method == nil or post_set_skill_method == nil then
        return false,
            "habilitacion realizada pero no se pudieron resolver getSkillID/setSkill sobre SkillContext fresco: "
                .. tostring(post_method_err),
            enable_writes,
            enable_fail
    end

    get_skill_method = post_get_skill_method
    set_skill_method = post_set_skill_method

    logp("[PawnResearch] PASO 50: getSkillID/setSkill resueltos nuevamente sobre SkillContext FRESCO")

    local before = {}
    local writes = {}
    local failed = 0

    for slot = 0, HPO_SKILL_SLOT_COUNT - 1 do
        local raw = skill_config[tostring(slot)]
        if raw == nil then
            raw = skill_config[slot]
        end

        if raw ~= nil and tostring(raw) ~= "" then
            local desired_id = tonumber(raw)

            if desired_id == nil or desired_id ~= math.floor(desired_id) or desired_id < 0 then
                failed = failed + 1
                logp(
                    "[PawnResearch] PASO 42 skill Slot " .. tostring(slot)
                    .. ": ID invalido -> " .. tostring(raw)
                )
            elseif not hpo_skill_id_is_valid_for_job(job_to_apply, desired_id) then
                failed = failed + 1
                logp(
                    "[PawnResearch] PASO 42 skill Slot " .. tostring(slot)
                    .. ": ID " .. tostring(desired_id)
                    .. " no figura en el catalogo TWINWV para "
                    .. hpo_job_name(job_to_apply) .. ". No se adivina compatibilidad."
                )
            else
                local slot_value = hpo_skill_slot_value(skill_context, slot_values, slot)
                if slot_value == nil then
                    failed = failed + 1
                    logp(
                        "[PawnResearch] PASO 42 skill Slot " .. tostring(slot)
                        .. ": no se pudo obtener el valor real del enum SkillSlot"
                    )
                else
                    local ok_read, old_skill = pcall(function()
                        return get_skill_method:call(
                            skill_context,
                            job_to_apply,
                            slot_value
                        )
                    end)

                    if ok_read then
                        before[slot] = hpo_skill_id_value(old_skill)
                    end

                    -- PASO 60: no volvemos a consultar isCustomSkillEnable() aqui.
                    -- La fase ENABLE ya hizo la unica comprobacion autoritativa
                    -- que importa para este experimento: Character fresco ->
                    -- backing field SkillContext fresco -> isCustomSkillEnable=true
                    -- y level>=2. El log50/51 demostro que una segunda llamada
                    -- aparentemente identica puede devolver false aun cuando la
                    -- primera verificacion fresca acababa de dar true. Reconsultarla
                    -- haria que nunca lleguemos a setSkill(), que es precisamente
                    -- la llamada que necesitamos medir ahora.
                    local enabled_verified_now =
                        desired_id == 0
                        or (type(enable_verified) == "table" and enable_verified[desired_id] == true)

                    if not enabled_verified_now then
                        failed = failed + 1
                        logp("[PawnResearch] PASO 59 skill omitida: ID " .. tostring(desired_id) .. " no quedo confirmado en la verificacion FRESCA de ENABLE")
                    elseif before[slot] ~= desired_id then
                        local ok_set, result_set = pcall(function()
                            return set_skill_method:call(
                                skill_context,
                                job_to_apply,
                                desired_id,
                                slot_value
                            )
                        end)

                        if ok_set and result_set == true then
                            writes[#writes + 1] = {
                                slot = slot,
                                requested = desired_id,
                                before = before[slot]
                            }
                            logp(
                                "[PawnResearch] PASO 60 skill: "
                                .. hpo_job_name(job_to_apply)
                                .. " Slot " .. tostring(slot)
                                .. " <- " .. hpo_skill_label(desired_id)
                                .. " (antes " .. tostring(before[slot]) .. ")"
                                .. (desired_id == 0 and " | CLEAR" or "")
                            )
                        elseif ok_set and result_set == false then
                            failed = failed + 1
                            logp(
                                "[PawnResearch] PASO 60 skill: setSkill devolvio FALSE"
                                .. " en Slot " .. tostring(slot)
                                .. " para ID " .. tostring(desired_id)
                                .. " / " .. hpo_job_name(job_to_apply)
                            )
                        else
                            failed = failed + 1
                            logp(
                                "[PawnResearch] PASO 60 skill: setSkill fallo en Slot "
                                .. tostring(slot) .. " -> " .. tostring(result_set)
                            )
                        end
                    end
                end
            end
        end
    end

    if #writes == 0 then
        return failed == 0,
            "sin cambios (la loadout ya coincide o no habia slots configurados)",
            0,
            failed
    end

    local ok_reassign, err_reassign = pcall(function()
        human:set_field(HPO_SKILL_CONTEXT_FIELD, skill_context)
    end)

    if not ok_reassign then
        logp(
            "[PawnResearch] PASO 43 AVISO: no se pudo reasignar "
            .. HPO_SKILL_CONTEXT_FIELD .. " -> " .. tostring(err_reassign)
        )
    end

    local fresh_roster = get_roster()
    local fresh_entry = find_roster_by_id(fresh_roster, cid)

    if fresh_entry == nil or fresh_entry.character == nil then
        return false,
            "escritura realizada pero no se pudo obtener Character fresco para verificar",
            #writes,
            failed
    end

    local verify_ok, verify_err, fresh_loadout =
        hpo_read_skill_loadout(fresh_entry.character, job_to_apply)

    if not verify_ok then
        return false,
            "escritura realizada pero fallo la relectura fresca: " .. tostring(verify_err),
            #writes,
            failed
    end

    local verify_fail = 0
    for _, w in ipairs(writes) do
        local got = fresh_loadout.slots[w.slot]
        if got ~= w.requested then
            verify_fail = verify_fail + 1
            logp(
                "[PawnResearch] PASO 43 VERIFY FAIL: "
                .. hpo_job_name(job_to_apply)
                .. " Slot " .. tostring(w.slot)
                .. " pedido=" .. tostring(w.requested)
                .. " (" .. hpo_skill_name(w.requested) .. ")"
                .. " leido_fresco=" .. tostring(got)
                .. " (" .. hpo_skill_name(got or 0) .. ")"
            )
        else
            logp(
                "[PawnResearch] PASO 43 VERIFY OK: "
                .. hpo_job_name(job_to_apply)
                .. " Slot " .. tostring(w.slot)
                .. " persistio " .. hpo_skill_label(got)
            )
        end
    end

    local refresh_ok = hpo_refresh_skill_key_guide()
    local total_fail = failed + verify_fail + enable_fail
    local message =
        "job=" .. hpo_job_name(job_to_apply)
        .. " escritos=" .. tostring(#writes)
        .. " fallos=" .. tostring(total_fail)
        .. " refresh=" .. tostring(refresh_ok)

    if verify_fail > 0 then
        return false, message, #writes, total_fail
    end

    return total_fail == 0, message, #writes, total_fail
end

local function hpo_skill_config_for_current_job(pawn_cfg, character)
    if type(pawn_cfg) ~= "table" or pawn_cfg.skills_enabled ~= true then
        return nil, nil
    end

    local job_ctx = get_job_context(character)
    local current_job = get_field_value_by_name(job_ctx, "CurrentJob")
    local job_num = tonumber(current_job)
    if job_num == nil then
        return nil, current_job
    end

    local all_skills = pawn_cfg.skills
    if type(all_skills) ~= "table" then
        return nil, current_job
    end

    return all_skills[tostring(job_num)], current_job
end

local hpo_availability_methods = {}
local hpo_availability_methods_logged = false
local hpo_skillcontext_extra_methods = {}
local hpo_skillcontext_extra_logged = false

local function hpo_resolve_skill_availability_methods(availability)
    if availability == nil then
        return nil, "SkillAvailability nil"
    end
    local cached = hpo_availability_methods
    if cached.isCustomSkillAvailable and cached.isCustomSkillAvailableWithoutItemCondition and cached.hasItemNeededByCustomSkill then
        return cached, nil
    end

    local td = safe(function() return availability:get_type_definition() end)
    if td == nil then return nil, "no se pudo obtener TypeDefinition de SkillAvailability" end
    local methods = safe(function() return td:get_methods() end) or {}
    local wanted = {
        isCustomSkillAvailable = {1, "app.HumanCustomSkillID", "System.Boolean"},
        isCustomSkillAvailableWithoutItemCondition = {1, "app.HumanCustomSkillID", "System.Boolean"},
        hasItemNeededByCustomSkill = {1, "app.HumanCustomSkillID", "System.Boolean"},
    }
    local found = {}
    for _, method in ipairs(methods) do
        local name = safe(function() return method:get_name() end)
        local spec = wanted[name]
        if spec then
            local params = safe(function() return method:get_param_types() end) or {}
            local ret = safe(function() local rt=method:get_return_type(); return rt and rt:get_full_name() or "System.Void" end)
            local pname = (#params==1 and safe(function() return params[1]:get_full_name() end) or nil)
            if #params == spec[1] and pname == spec[2] and ret == spec[3] then
                found[name] = method
            end
        end
    end
    for name in pairs(wanted) do
        if found[name] == nil then
            return nil, "no se pudo reconfirmar por reflexion " .. name .. "(app.HumanCustomSkillID)->Boolean"
        end
    end
    hpo_availability_methods = found
    if not hpo_availability_methods_logged then
        logp("[PawnResearch] PASO 44: SkillAvailability methods confirmados por reflexion")
        logp("[PawnResearch]   isCustomSkillAvailable(HumanCustomSkillID) -> Boolean")
        logp("[PawnResearch]   isCustomSkillAvailableWithoutItemCondition(HumanCustomSkillID) -> Boolean")
        logp("[PawnResearch]   hasItemNeededByCustomSkill(HumanCustomSkillID) -> Boolean")
        hpo_availability_methods_logged = true
    end
    return hpo_availability_methods, nil
end

local function hpo_resolve_skillcontext_extra_methods(skill_context)
    if skill_context == nil then return nil, "SkillContext nil" end
    local cached = hpo_skillcontext_extra_methods
    if cached.isCustomSkillEnable and cached.getCustomSkillLevel and cached.hasEquipedSkill then
        return cached, nil
    end
    local td = safe(function() return skill_context:get_type_definition() end)
    if td == nil then return nil, "no se pudo obtener TypeDefinition de SkillContext" end
    local wanted = {
        isCustomSkillEnable = {1, "app.HumanCustomSkillID", "System.Boolean"},
        getCustomSkillLevel = {1, "app.HumanCustomSkillID", "app.HumanCustomSkillLevelNo"},
        hasEquipedSkill = {2, "app.Character.JobEnum", "app.HumanCustomSkillID", "System.Boolean"},
    }
    local found = {}
    for _, method in ipairs(safe(function() return td:get_methods() end) or {}) do
        local name = safe(function() return method:get_name() end)
        local spec = wanted[name]
        if spec then
            local params = safe(function() return method:get_param_types() end) or {}
            local ret = safe(function() local rt=method:get_return_type(); return rt and rt:get_full_name() or "System.Void" end)
            if #params == spec[1] and ret == spec[#spec] then
                local ok = true
                for i = 1, spec[1] do
                    local pn = safe(function() return params[i]:get_full_name() end)
                    if pn ~= spec[i+1] then ok = false break end
                end
                if ok then found[name] = method end
            end
        end
    end
    for name in pairs(wanted) do
        if found[name] == nil then
            return nil, "no se pudo reconfirmar por reflexion " .. name .. " en HumanSkillContext"
        end
    end
    hpo_skillcontext_extra_methods = found
    if not hpo_skillcontext_extra_logged then
        logp("[PawnResearch] PASO 45: HumanSkillContext extra methods confirmados por reflexion")
        logp("[PawnResearch]   isCustomSkillEnable(HumanCustomSkillID) -> Boolean")
        logp("[PawnResearch]   getCustomSkillLevel(HumanCustomSkillID) -> HumanCustomSkillLevelNo")
        logp("[PawnResearch]   hasEquipedSkill(JobEnum, HumanCustomSkillID) -> Boolean")
        hpo_skillcontext_extra_logged = true
    end
    return found, nil
end

-- ============================================================
-- PASO 47: HABILITAR CUSTOM SKILLS ANTES DE EQUIPARLAS
--
-- PASO 46 demostro que el problema de Momo no es la ausencia de IDs: ambos
-- peones tienen EnabledCustomSkills registrado 0..120, pero el peon funcional
-- tiene las skills de su vocacion en enable=true y con niveles reales.
--
-- Este paso usa SOLO el metodo confirmado por reflexion:
--   setCustomSkillEnable(HumanCustomSkillID, HumanCustomSkillLevelNo) -> Void
--
-- La prueba usa Lv2 porque las skills Mage equipadas del peon funcional fueron
-- observadas en Lv2. Lv2 se obtiene del enum real por reflexion; no se toca
-- EnabledCustomSkills manualmente.
--
-- Orden:
--   1) setCustomSkillEnable(ID, Lv2)
--   2) reasignar Human.<SkillContext>k__BackingField
--   3) releer Character fresco y verificar enable/level
--   4) consultar Availability fresca
--   5) solamente si queda habilitada, intentar setSkill()
--   6) releer slots desde Character fresco
--
-- Toda escritura mantiene el candado CharacterID.
-- ============================================================

local function hpo_step47_level_number(level)
    if level == nil then return nil end
    local n = tonumber(level)
    if n ~= nil then return n end
    return safe(function() return level:get_field("value__") end)
end

local hpo_step47_skill_enable_logged = false

local function hpo_step47_resolve_set_custom_skill_enable(skill_context)
    if skill_context == nil then
        return nil, nil, "SkillContext nil"
    end

    -- No conservar el Method entre instancias de SkillContext.
    -- El fallo observado en Paso 60 era:
    --   attempt to index a userdata value (upvalue 'enable_method')
    -- Al resolverlo otra vez sobre el contexto fresco evitamos reutilizar
    -- un handle userdata viejo.
    local td = safe(function() return skill_context:get_type_definition() end)
    if td == nil then
        return nil, nil, "no se pudo obtener TypeDefinition de HumanSkillContext"
    end

    local method_candidate = nil
    for _, method in ipairs(safe(function() return td:get_methods() end) or {}) do
        local name = safe(function() return method:get_name() end)
        if name == "setCustomSkillEnable" then
            local params = safe(function() return method:get_param_types() end) or {}
            local ret = safe(function()
                local rt = method:get_return_type()
                return rt and rt:get_full_name() or "<?>"
            end)
            if #params == 2
                and safe(function() return params[1]:get_full_name() end) == "app.HumanCustomSkillID"
                and safe(function() return params[2]:get_full_name() end) == "app.HumanCustomSkillLevelNo"
                and ret == "System.Void"
            then
                method_candidate = method
                break
            end
        end
    end

    if method_candidate == nil then
        return nil, nil,
            "no se pudo reconfirmar por reflexion setCustomSkillEnable(HumanCustomSkillID, HumanCustomSkillLevelNo)"
    end

    local level_td = sdk.find_type_definition("app.HumanCustomSkillLevelNo")
    if level_td == nil then
        return nil, nil, "TypeDefinition app.HumanCustomSkillLevelNo no disponible"
    end

    local level_field = safe(function() return level_td:get_field("Lv2") end)
    if level_field == nil then
        return nil, nil, "campo estatico Lv2 no disponible en app.HumanCustomSkillLevelNo"
    end

    local level_value = safe(function() return level_field:get_data(nil) end)
    if level_value == nil then
        return nil, nil, "no se pudo obtener el valor estatico Lv2"
    end

    if not hpo_step47_skill_enable_logged then
        logp("[PawnResearch] PASO 61: setCustomSkillEnable(ID, Lv2) reconfirmado por reflexion en SkillContext actual")
        logp("[PawnResearch] PASO 61: app.HumanCustomSkillLevelNo::Lv2 obtenido por reflexion")
        hpo_step47_skill_enable_logged = true
    end

    return method_candidate, level_value, nil
end

hpo_step47_enable_skills_only = function(character, skill_config, target_job)
    local cid = get_field_value_by_name(character, "CharacterID")
    if is_character_protected(cid) then
        return false,
            "BLOQUEADO por candado de seguridad (" .. describe_character_id(get_roster(), cid) .. ")",
            0, 0
    end

    if type(skill_config) ~= "table" then
        return true, "sin configuracion de skills", 0, 0
    end

    local human, job_ctx, skill_context = hpo_skill_context_parts(character)
    if human == nil then return false, "Human nil", 0, 0 end
    if job_ctx == nil then return false, "JobContext nil", 0, 0 end
    if skill_context == nil then return false, "SkillContext nil", 0, 0 end

    local job_to_report = target_job ~= nil and tonumber(target_job)
        or tonumber(get_field_value_by_name(job_ctx, "CurrentJob"))
    if job_to_report == nil then return false, "job objetivo nil", 0, 0 end

    if next(hpo_skill_ids_by_job) ~= nil and hpo_skill_ids_by_job[job_to_report] == nil then
        return false,
            "el catalogo TWINWV 1.6 no define skills para " .. hpo_job_name(job_to_report),
            0, 0
    end

    local enable_method, level_value, method_err =
        hpo_step47_resolve_set_custom_skill_enable(skill_context)
    if enable_method == nil then
        return false, method_err or "setCustomSkillEnable no disponible", 0, 0
    end

    local extra_methods, extra_err = hpo_resolve_skillcontext_extra_methods(skill_context)
    if extra_methods == nil then
        return false, extra_err or "metodos de verificacion no disponibles", 0, 0
    end

    local requested = {}
    local enable_writes = 0
    local failures = 0

    for slot = 0, HPO_SKILL_SLOT_COUNT - 1 do
        local raw = skill_config[tostring(slot)]
        if raw == nil then raw = skill_config[slot] end
        if raw ~= nil and tostring(raw) ~= "" then
            local sid = tonumber(raw)
            if sid == nil or sid ~= math.floor(sid) or sid < 0 then
                failures = failures + 1
                logp("[PawnResearch] PASO 49 Slot " .. tostring(slot) .. ": ID invalido -> " .. tostring(raw))
            elseif sid == 0 then
                logp("[PawnResearch] PASO 49 Slot " .. tostring(slot) .. ": ID 0 omitido")
            elseif not hpo_skill_id_is_valid_for_job(job_to_report, sid) then
                failures = failures + 1
                logp("[PawnResearch] PASO 49 Slot " .. tostring(slot) .. ": ID " .. tostring(sid) .. " no figura en el catalogo TWINWV para " .. hpo_job_name(job_to_report))
            else
                requested[#requested + 1] = { id = sid, slot = slot }
                local bok, ben = pcall(function() return extra_methods.isCustomSkillEnable:call(skill_context, sid) end)
                local bok2, blevel = pcall(function() return extra_methods.getCustomSkillLevel:call(skill_context, sid) end)
                logp("[PawnResearch] PASO 49 ENABLE antes Slot " .. tostring(slot) .. " ID=" .. tostring(sid) .. " enable=" .. tostring(bok and ben) .. " level=" .. tostring(bok2 and hpo_step47_level_number(blevel)))

                if not (bok and ben == true) then
                    local ok_set, err_set = pcall(function()
                        enable_method:call(skill_context, sid, level_value)
                    end)
                    if ok_set then
                        enable_writes = enable_writes + 1
                        logp("[PawnResearch] PASO 49 ENABLE: ID " .. tostring(sid) .. " <- Lv2 / " .. hpo_skill_label(sid) .. " | llamada OK (void)")
                    else
                        failures = failures + 1
                        logp("[PawnResearch] PASO 49 ENABLE ERROR ID " .. tostring(sid) .. " -> " .. tostring(err_set))
                    end
                else
                    logp("[PawnResearch] PASO 49 ENABLE omitido: ID " .. tostring(sid) .. " ya estaba enabled")
                end
            end
        end
    end

    if enable_writes > 0 then
        local ok_reassign, err_reassign = pcall(function()
            human:set_field(HPO_SKILL_CONTEXT_FIELD, skill_context)
        end)
        logp("[PawnResearch] PASO 50 reasignacion " .. HPO_SKILL_CONTEXT_FIELD .. " -> " .. tostring(ok_reassign) .. (ok_reassign and "" or (" error=" .. tostring(err_reassign))))
    end

    local fresh_entry = find_roster_by_id(get_roster(), cid)
    if fresh_entry == nil or fresh_entry.character == nil then
        return false, "habilitacion realizada pero no se pudo obtener Character fresco", enable_writes, failures
    end

    local fresh_human = get_human(fresh_entry.character)
    local fresh_context = fresh_human and get_field_value_by_name(fresh_human, HPO_SKILL_CONTEXT_FIELD) or nil
    if fresh_context == nil then
        return false, "habilitacion realizada pero SkillContext fresco es nil", enable_writes, failures
    end

    local fresh_extra, fresh_err = hpo_resolve_skillcontext_extra_methods(fresh_context)
    if fresh_extra == nil then
        return false, "habilitacion realizada pero metodos frescos no disponibles: " .. tostring(fresh_err), enable_writes, failures
    end

    local verify_fail = 0
    local verified_enabled = {}
    for _, item in ipairs(requested) do
        local eok, enabled = pcall(function() return fresh_extra.isCustomSkillEnable:call(fresh_context, item.id) end)
        local lok, level = pcall(function() return fresh_extra.getCustomSkillLevel:call(fresh_context, item.id) end)
        local level_num = lok and hpo_step47_level_number(level) or nil
        logp("[PawnResearch] PASO 49 ENABLE VERIFY Slot " .. tostring(item.slot) .. " ID=" .. tostring(item.id) .. " enable=" .. tostring(eok and enabled) .. " level=" .. tostring(level_num))
        if not (eok and enabled == true and lok and level_num ~= nil and level_num >= 2) then
            verify_fail = verify_fail + 1
        else
            verified_enabled[item.id] = true
        end
    end

    local fresh_av = get_field_value_by_name(fresh_human, "<SkillAvailability>k__BackingField")
    if fresh_av ~= nil then
        local av_methods, av_err = hpo_resolve_skill_availability_methods(fresh_av)
        if av_methods ~= nil then
            logp("[PawnResearch] ----- PASO 49 AVAILABILITY FRESCA -----")
            for _, item in ipairs(requested) do
                local sid = item.id
                local aok, av = pcall(function() return av_methods.isCustomSkillAvailable:call(fresh_av, sid) end)
                local wok, wi = pcall(function() return av_methods.isCustomSkillAvailableWithoutItemCondition:call(fresh_av, sid) end)
                local hok, hi = pcall(function() return av_methods.hasItemNeededByCustomSkill:call(fresh_av, sid) end)
                logp("[PawnResearch]   ID=" .. tostring(sid) .. " name=" .. hpo_skill_name(sid) .. " available=" .. tostring(aok and av) .. " withoutItem=" .. tostring(wok and wi) .. " hasItem=" .. tostring(hok and hi))
            end
            logp("[PawnResearch] ----- FIN PASO 49 AVAILABILITY FRESCA -----")
        else
            logp("[PawnResearch] PASO 50 AVAILABILITY ERROR=" .. tostring(av_err))
        end
    end

    local total_fail = failures + verify_fail
    return total_fail == 0,
        "job=" .. hpo_job_name(job_to_report) .. " enable_escritos=" .. tostring(enable_writes) .. " verify_fail=" .. tostring(total_fail),
        enable_writes, total_fail, verified_enabled
end

-- PASO 49: la aplicacion automatica se limita a una tentativa por
-- CharacterID/configuracion. La tabla hpo_applied_cid y el contador se
-- declararon MAS ARRIBA, antes del primer re.on_frame de PASO 33, para que
-- ese callback pueda invalidar selectivamente un CID que acaba de restaurarse.

local function hpo_apply_if_needed(entry, pawn_cfg)
    if post_update_audit_only then return end
    if type(pawn_cfg) ~= "table" then return end

    local base_enabled = pawn_cfg.enabled == true
    local skills_enabled = pawn_cfg.skills_enabled == true

    if not base_enabled and not skills_enabled then return end
    if is_character_protected(entry.id) then return end

    local cid_str = tostring(entry.id)

    if hpo_global_loadout_system.active_name ~= nil
        and hpo_global_loadout_system.active_member_ids[cid_str] == true
    then
        return
    end

    -- PASO 50: reclamar la tentativa ANTES de ejecutar escrituras. Asi, si una
    -- llamada reflejada lanza una excepcion inesperada, el callback no vuelve
    -- a martillarla cada 30 frames. El boton manual limpia estas marcas para
    -- permitir un reintento controlado.
    local first_base_apply = not hpo_applied_cid[cid_str]
    if base_enabled and first_base_apply then
        hpo_applied_cid[cid_str] = true
    end

    if base_enabled and first_base_apply then
        logp(
            "[PawnResearch] PASO 34: aplicando override a CID="
            .. tostring(entry.id) .. " (" .. entry.name .. ")"
        )

        local base_call_ok, base_result = pcall(function()
            local eq_ok, eq_msg = hpo_apply_equipment(entry.character, pawn_cfg.equipment)
            logp("[PawnResearch] PASO 34 equipo -> " .. tostring(eq_msg))

            local attr_ok, attr_msg = hpo_apply_attributes(
                entry.character, pawn_cfg.personality, pawn_cfg.specialization,
                pawn_cfg.voice_gender, pawn_cfg.voice_tone
            )
            logp("[PawnResearch] PASO 34 atributos -> " .. tostring(attr_msg))

            if pawn_cfg.job ~= nil then
                local voc_ok, voc_msg = hpo_apply_vocation(entry.character, pawn_cfg.job)
                logp("[PawnResearch] PASO 34 vocacion -> " .. tostring(voc_msg))
            end

            return true
        end)

        if not base_call_ok then
            logp("[PawnResearch] PASO 50 ERROR HPO automatico CID=" .. cid_str
                .. " -> " .. tostring(base_result)
                .. " | no se reintentara automaticamente")
        end
    end

    -- Las skills son por vocacion. PASO 50 guarda una firma estable por
    -- CID+job+contenido. La marca se escribe ANTES de la llamada para evitar
    -- hot-loops incluso cuando una llamada reflejada lanza una excepcion.
    if skills_enabled then
        local skill_cfg, current_job =
            hpo_skill_config_for_current_job(pawn_cfg, entry.character)

        if skill_cfg ~= nil then
            local cfg_parts = { tostring(current_job or "?") }
            for slot = 0, HPO_SKILL_SLOT_COUNT - 1 do
                local raw = skill_cfg[tostring(slot)]
                if raw == nil then raw = skill_cfg[slot] end
                cfg_parts[#cfg_parts + 1] = tostring(raw or "")
            end
            local skill_signature = table.concat(cfg_parts, "|")

            if hpo_skill_applied_signature[cid_str] ~= skill_signature then
                -- Marcar antes del intento para que un error no cree otro
                -- reintento automatico en el siguiente frame.
                hpo_skill_applied_signature[cid_str] = skill_signature

                local skill_call_ok, skill_ok, skill_msg = pcall(function()
                    return hpo_apply_skill_loadout(entry.character, skill_cfg, current_job)
                end)

                if not skill_call_ok then
                    logp("[PawnResearch] PASO 60 ERROR skills automatico CID=" .. cid_str
                        .. " -> " .. tostring(skill_ok)
                        .. " | no se reintentara automaticamente")
                else
                    logp(
                        "[PawnResearch] PASO 60 skills intento-unico -> "
                        .. tostring(skill_msg)
                        .. " / " .. hpo_job_name(current_job)
                    )
                end
            end
        end
    end
end

-- ============================================================
-- PASO 67: LOADOUTS GENERALES DE ESCUADRA
--
-- Cada JSON guarda una escuadra nombrada por CharacterID:
-- vocacion + 6 skills + 9 slots de equipo por miembro.
--
-- Aplicar ahora: cambio en vivo.
-- Aplicar + activar: cambio en vivo y deja el set activo para que
-- se restaure al reconstruirse el roster.
--
-- Toda escritura reutiliza los campos/metodos ya confirmados.
-- ============================================================

hpo_global_loadout_system.load_index = function()
    if hpo_global_loadout_system.index_loaded then
        return hpo_global_loadout_system.index
    end

    local index_data = safe(function()
        return json.load_file(hpo_global_loadout_system.index_file)
    end)

    if type(index_data) == "table"
        and type(index_data.loadouts) == "table"
    then
        hpo_global_loadout_system.index = index_data.loadouts
    else
        hpo_global_loadout_system.index = {}
        safe(function()
            return json.dump_file(
                hpo_global_loadout_system.index_file,
                { version = 1, loadouts = {} },
                4
            )
        end)
    end

    hpo_global_loadout_system.index_loaded = true

    local active_data = safe(function()
        return json.load_file(hpo_global_loadout_system.active_file)
    end)

    if type(active_data) == "table"
        and active_data.name ~= nil
        and tostring(active_data.name) ~= ""
    then
        hpo_global_loadout_system.active_name = tostring(active_data.name)
    end

    return hpo_global_loadout_system.index
end

hpo_global_loadout_system.save_index = function()
    local ok = safe(function()
        return json.dump_file(
            hpo_global_loadout_system.index_file,
            {
                version = 1,
                loadouts = hpo_global_loadout_system.index
            },
            4
        )
    end)
    return ok == true
end

hpo_global_loadout_system.find_index = function(name)
    local wanted = tostring(name or "")
    for i, item in ipairs(hpo_global_loadout_system.index) do
        if type(item) == "table"
            and tostring(item.name or "") == wanted
        then
            return item, i
        end
    end
    return nil, nil
end

hpo_global_loadout_system.load_payload = function(name)
    local item = hpo_global_loadout_system.find_index(name)
    if item == nil then
        return nil, "Loadout no registrado: " .. tostring(name)
    end

    local file_name =
        tostring(item.file or (sanitize_name(name) .. ".json"))
    local path =
        hpo_global_loadout_system.dir .. "/" .. file_name

    local payload = safe(function()
        return json.load_file(path)
    end)

    if type(payload) ~= "table" then
        return nil, "No se pudo cargar " .. path
    end

    if type(payload.members) ~= "table" then
        return nil, "El JSON no contiene 'members'"
    end

    return payload, nil
end

hpo_global_loadout_system.snapshot_equipment = function(character)
    if character == nil then
        return nil, "Character nil"
    end

    if ItemManager == nil then
        ItemManager = sdk.get_managed_singleton("app.ItemManager")
    end

    if ItemManager == nil then
        return nil, "ItemManager no disponible"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    local equip_data =
        safe_call(ItemManager, "getEquipData", cid)

    if equip_data == nil then
        return nil,
            "getEquipData devolvio nil para CID="
            .. tostring(cid)
    end

    local result = {}

    for _, slot_name in ipairs(HPO_SLOTS) do
        local slot_enum = HPO_SlotEnum[slot_name]
        if slot_enum == nil then
            return nil, "SlotEnum no disponible para " .. tostring(slot_name)
        end

        local item = safe_call(
            equip_data,
            "get(app.EquipData.SlotEnum)",
            slot_enum
        )

        local item_id = 0
        if item ~= nil then
            item_id =
                tonumber(get_field_value_by_name(item, "_ItemId")) or 0
        end

        result[slot_name] = item_id
    end

    return result, nil
end

hpo_global_loadout_system.snapshot_member = function(entry)
    if entry == nil or entry.character == nil then
        return nil, "entrada de roster invalida"
    end

    local character = entry.character
    local cid = get_field_value_by_name(character, "CharacterID")

    if cid == nil then
        return nil, "CharacterID nil"
    end

    if is_character_protected(cid) then
        return nil, "BLOQUEADO por candado de seguridad"
    end

    local job_ctx = get_job_context(character)
    local job =
        job_ctx ~= nil
        and tonumber(get_field_value_by_name(job_ctx, "CurrentJob"))
        or nil

    if job == nil then
        return nil, "CurrentJob nil"
    end

    local equipment, equipment_err =
        hpo_global_loadout_system.snapshot_equipment(character)

    if equipment == nil then
        return nil, equipment_err
    end

    local skill_ok, skill_err, skill_data =
        hpo_read_skill_loadout(character, job)

    if not skill_ok or type(skill_data) ~= "table" then
        return nil,
            "No se pudieron leer las skills actuales: "
            .. tostring(skill_err)
    end

    local skills = {}
    for slot = 0, HPO_SKILL_SLOT_COUNT - 1 do
        local skill_id = tonumber(skill_data.slots[slot])
        if skill_id ~= nil then
            skills[tostring(slot)] = skill_id
        end
    end

    return {
        character_id = tostring(cid),
        name = tostring(entry.name or ""),
        nickname = tostring(entry.nick or ""),
        job = job,
        equipment = equipment,
        skills = skills
    }, nil
end

hpo_global_loadout_system.capture_current = function(name, roster)
    local clean_name =
        tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if clean_name == "" then
        return false, "Escribe un nombre para el loadout."
    end

    roster = roster or get_roster()

    if #roster == 0 then
        return false, "No hay peones en el roster actual."
    end

    local members = {}
    local selected_count = 0
    local skipped = 0
    local errors = {}

    for _, entry in ipairs(roster) do
        local cid_str = tostring(entry.id)

        if hpo_global_loadout_system.capture_members[cid_str] == true then
            selected_count = selected_count + 1

            if is_character_protected(entry.id) then
                skipped = skipped + 1
                errors[#errors + 1] =
                    entry.name .. ": protegido por CharacterID"
            else
                local member, member_err =
                    hpo_global_loadout_system.snapshot_member(entry)

                if member ~= nil then
                    members[#members + 1] = member
                else
                    skipped = skipped + 1
                    errors[#errors + 1] =
                        entry.name .. ": " .. tostring(member_err)
                end
            end
        end
    end

    if selected_count == 0 then
        return false, "No hay miembros seleccionados."
    end

    if #members == 0 then
        return false, "No se pudo capturar ningun miembro seleccionado."
    end

    local file_name = sanitize_name(clean_name) .. ".json"
    local path =
        hpo_global_loadout_system.dir .. "/" .. file_name

    local payload = {
        version = 1,
        name = clean_name,
        members = members
    }

    local save_ok = safe(function()
        return json.dump_file(path, payload, 4)
    end)

    if save_ok ~= true then
        return false, "No se pudo guardar " .. path
    end

    local existing, existing_pos =
        hpo_global_loadout_system.find_index(clean_name)

    if existing ~= nil then
        existing.file = file_name
        existing.member_count = #members
    else
        hpo_global_loadout_system.index[#hpo_global_loadout_system.index + 1] = {
            name = clean_name,
            file = file_name,
            member_count = #members
        }
    end

    if not hpo_global_loadout_system.save_index() then
        return false, "El loadout se guardo, pero fallo index.json"
    end

    local _, new_pos =
        hpo_global_loadout_system.find_index(clean_name)

    hpo_global_loadout_system.selected_index =
        new_pos or existing_pos or 1

    logp(
        "[PawnResearch] PASO 64 Loadout general guardado: "
        .. clean_name
        .. " | miembros=" .. tostring(#members)
    )

    local msg =
        "Guardado: " .. clean_name
        .. " | miembros=" .. tostring(#members)

    if skipped > 0 then
        msg = msg .. " | omitidos=" .. tostring(skipped)
    end

    if #errors > 0 then
        msg = msg .. " | " .. table.concat(errors, " ; ")
    end

    return true, msg
end

hpo_global_loadout_system.apply_payload = function(payload, roster)
    if post_update_audit_only then return false, "BLOQUEADO: modo de auditoria post-TU4 activo." end
    if type(payload) ~= "table"
        or type(payload.members) ~= "table"
    then
        return false, "payload de loadout invalido"
    end

    roster = roster or get_roster()

    local applied = 0
    local skipped = 0
    local failures = 0
    local notes = {}

    for _, member in ipairs(payload.members) do
        local cid = tostring(member.character_id or "")
        local entry = find_roster_by_id(roster, cid)

        if entry == nil or entry.character == nil then
            skipped = skipped + 1
            notes[#notes + 1] =
                "No presente: " .. tostring(member.name or cid)
        elseif is_character_protected(entry.id) then
            skipped = skipped + 1
            notes[#notes + 1] =
                entry.name .. ": protegido"
        elseif tonumber(member.job) == nil then
            failures = failures + 1
            notes[#notes + 1] =
                entry.name .. ": vocacion invalida"
        else
            local target = entry.character

            local job_ok, job_msg =
                hpo_apply_vocation(target, tonumber(member.job))

            if not job_ok then
                failures = failures + 1
                notes[#notes + 1] =
                    entry.name .. ": " .. tostring(job_msg)
            else
                local fresh_entry =
                    find_roster_by_id(get_roster(), cid)

                if fresh_entry ~= nil
                    and fresh_entry.character ~= nil
                then
                    target = fresh_entry.character
                end

                local equipment = member.equipment
                local equip_ok, equip_msg =
                    hpo_apply_equipment(
                        target,
                        type(equipment) == "table" and equipment or {}
                    )

                local skill_ok = true
                local skill_msg = "sin skills configuradas"

                if type(member.skills) == "table" then
                    skill_ok, skill_msg =
                        hpo_apply_skill_loadout(
                            target,
                            member.skills,
                            tonumber(member.job)
                        )
                end

                if equip_ok and skill_ok then
                    applied = applied + 1
                    notes[#notes + 1] =
                        entry.name
                        .. " -> "
                        .. hpo_job_name(member.job)
                else
                    failures = failures + 1
                    notes[#notes + 1] =
                        entry.name
                        .. ": equipo="
                        .. tostring(equip_msg)
                        .. " | skills="
                        .. tostring(skill_msg)
                end
            end
        end
    end

    return failures == 0 and skipped == 0,
        "aplicados=" .. tostring(applied)
        .. " omitidos=" .. tostring(skipped)
        .. " fallos=" .. tostring(failures)
        .. (#notes > 0 and " | " .. table.concat(notes, " ; ") or "")
end

hpo_global_loadout_system.apply_named = function(name, activate)
    if post_update_audit_only then return false, "BLOQUEADO: modo de auditoria post-TU4 activo." end
    hpo_global_loadout_system.load_index()

    local payload, payload_err =
        hpo_global_loadout_system.load_payload(name)

    if payload == nil then
        return false, payload_err
    end

    local roster = get_roster()
    local ok, msg =
        hpo_global_loadout_system.apply_payload(payload, roster)

    if ok and activate == true then
        hpo_global_loadout_system.active_wait_logged = false
        hpo_global_loadout_system.active_name =
            tostring(payload.name or name)

        hpo_global_loadout_system.active_member_ids = {}

        for _, member in ipairs(payload.members) do
            hpo_global_loadout_system.active_member_ids[
                tostring(member.character_id)
            ] = true
        end

        hpo_global_loadout_system.active_last_roster_signature =
            roster_signature(roster)

        safe(function()
            return json.dump_file(
                hpo_global_loadout_system.active_file,
                {
                    version = 1,
                    name = hpo_global_loadout_system.active_name
                },
                4
            )
        end)
    end

    return ok, msg
end

hpo_global_loadout_system.deactivate = function()
    local old_name = hpo_global_loadout_system.active_name

    hpo_global_loadout_system.active_name = nil
    hpo_global_loadout_system.active_member_ids = {}
    hpo_global_loadout_system.active_last_roster_signature = nil
    hpo_global_loadout_system.active_wait_logged = false

    safe(function()
        return json.dump_file(
            hpo_global_loadout_system.active_file,
            { version = 1 },
            4
        )
    end)

    if old_name ~= nil then
        -- Al salir del modo global, permitimos que las configuraciones
        -- individuales vuelvan a ejecutarse.
        hpo_applied_cid = {}
        hpo_skill_applied_signature = {}
    end

    return true,
        old_name ~= nil
        and ("Loadout global desactivado: " .. tostring(old_name))
        or "No habia loadout global activo."
end

hpo_global_loadout_system.apply_active_if_needed = function(roster)
    if post_update_audit_only then return false, "BLOQUEADO: modo de auditoria post-TU4 activo." end
    if hpo_global_loadout_system.active_name == nil then
        return
    end

    local current_signature = roster_signature(roster)

    if current_signature ==
        hpo_global_loadout_system.active_last_roster_signature
    then
        return
    end

    local payload, payload_err =
        hpo_global_loadout_system.load_payload(
            hpo_global_loadout_system.active_name
        )

    if payload == nil then
        logp(
            "[PawnResearch] PASO 64 ERROR Loadout activo -> "
            .. tostring(payload_err)
        )
        hpo_global_loadout_system.active_last_roster_signature =
            current_signature
        return
    end

    local ok, msg =
        hpo_global_loadout_system.apply_payload(payload, roster)

    -- Si todos los miembros estan temporalmente ausentes, normalmente estamos
    -- viendo una reconstruccion parcial del roster. No consumimos esa firma:
    -- el mismo loadout se volvera a intentar cuando aparezcan los personajes.
    local present_count = 0
    local total_members = #payload.members

    for _, member in ipairs(payload.members) do
        if find_roster_by_id(roster, member.character_id) ~= nil then
            present_count = present_count + 1
        end
    end

    if present_count > 0 or total_members == 0 then
        hpo_global_loadout_system.active_last_roster_signature =
            current_signature
        hpo_global_loadout_system.active_wait_logged = false
    else
        if not hpo_global_loadout_system.active_wait_logged then
            logp(
                "[PawnResearch] PASO 67 Loadout activo: esperando a que "
                .. "aparezcan los CharacterID del set."
            )
            hpo_global_loadout_system.active_wait_logged = true
        end
    end

    if present_count > 0 then
        logp(
            "[PawnResearch] PASO 67 Loadout activo -> "
            .. tostring(hpo_global_loadout_system.active_name)
            .. " | " .. tostring(ok)
            .. " | presentes=" .. tostring(present_count)
            .. "/" .. tostring(total_members)
            .. " | " .. tostring(msg)
        )
    end
end

re.on_frame(function()
    hpo_frame_counter = hpo_frame_counter + 1
    if post_update_audit_only then return end
    if hpo_frame_counter % 30 ~= 0 then return end

    -- Los Loadouts Generales son independientes de HiredPawnOverride/config.json.
    -- Por eso se carga su indice primero y puede aplicarse aunque el config
    -- individual este vacio.
    hpo_global_loadout_system.load_index()

    local roster = get_roster()
    hpo_global_loadout_system.apply_active_if_needed(roster)

    local cfg = hpo_get_config()
    if next(cfg) == nil then return end

    -- Si un CID sale del roster, olvidamos su marca. Si vuelve a entrar mas
    -- tarde con el mismo CID, recibira una sola aplicacion automatica.
    local present_cids = {}
    for _, entry in ipairs(roster) do
        local cid_str = tostring(entry.id)
        present_cids[cid_str] = true
    end
    for cid_str in pairs(hpo_applied_cid) do
        if not present_cids[cid_str] then
            hpo_applied_cid[cid_str] = nil
            hpo_skill_applied_signature[cid_str] = nil
        end
    end
    for cid_str in pairs(hpo_skill_applied_signature) do
        if not present_cids[cid_str] then
            hpo_skill_applied_signature[cid_str] = nil
        end
    end

    for _, entry in ipairs(roster) do
        local pawn_cfg = cfg[tostring(entry.id)]
        if pawn_cfg ~= nil then
            hpo_apply_if_needed(entry, pawn_cfg)
        end
    end
end)

local hpo_selected = { 1 }
local hpo_status = "Listo."

-- ============================================================
-- PASO 37: investigacion de SKILLS (habilidades equipadas). Todavia no
-- sabemos donde vive esto -- ni el nombre del campo/metodo, ni el enum de
-- IDs de skill, ni si esta filtrado por vocacion de alguna forma parecida
-- al bit de itemData.json. En vez de adivinar (como hubiera sido inventar
-- "_Skill1", "_EquippedSkill", etc. a ciegas), reusamos la MISMA disciplina
-- que nos funciono con _Meta (Paso 18-19) y con getItem (Paso 34/34-4):
-- reflexion primero, sobre los objetos que YA sabemos que existen
-- (app.Character, Human, JobContext, PartSwapper, _PawnDataContext -- este
-- ultimo es donde vive _SubSkill/Personalidad/Voz, buen candidato a tener
-- hermanos relacionados con skills), buscando campos y metodos cuyo nombre
-- contenga "skill", "action" o "ability". Es de SOLO LECTURA: no escribe
-- nada todavia. El resultado (que campos/metodos aparecen y de que tipo
-- son) es lo que hace falta para disenar la escritura real en el proximo
-- paso, en vez de festinar codigo que no sabemos si sirve.
local function list_all_field_names(obj)
    if obj == nil then return {} end
    local td = safe(function() return obj:get_type_definition() end)
    local results = {}
    local seen_types = {}
    while td ~= nil do
        local tname = safe(function() return td:get_full_name() end) or "<?>"
        if seen_types[tname] then break end
        seen_types[tname] = true
        local fields = safe(function() return td:get_fields() end) or {}
        for _, f in ipairs(fields) do
            local fname = safe(function() return f:get_name() end)
            if fname ~= nil then
                local ftype_name = safe(function()
                    local ft = f:get_type()
                    return ft and ft:get_full_name() or nil
                end) or "<?>"
                results[#results + 1] = { name = fname, type_name = ftype_name, declaring_type = tname }
            end
        end
        td = safe(function() return td:get_parent_type() end)
    end
    return results
end

local function list_all_method_names(obj)
    if obj == nil then return {} end
    local td = safe(function() return obj:get_type_definition() end)
    local results = {}
    local seen_types = {}
    while td ~= nil do
        local tname = safe(function() return td:get_full_name() end) or "<?>"
        if seen_types[tname] then break end
        seen_types[tname] = true
        local methods = safe(function() return td:get_methods() end) or {}
        for _, m in ipairs(methods) do
            local mname = safe(function() return m:get_name() end)
            if mname ~= nil then
                results[#results + 1] = { name = mname, declaring_type = tname }
            end
        end
        td = safe(function() return td:get_parent_type() end)
    end
    return results
end


-- PASO 39: diagnostico PROFUNDO de skills (SOLO LECTURA).
--
-- El Paso 38 confirmo que, para el peon seleccionado, el candidato fuerte
-- es Human.<SkillContext>k__BackingField (app.HumanSkillContext), y que el
-- Job0XActionController de la vocacion actual NO mostro slots de skills.
--
-- Paso 39 no escribe absolutamente nada. Entra un nivel mas profundo:
--
--   1) Vuelca TODOS los campos y metodos del HumanSkillContext.
--   2) Para los campos cuyo valor sea un System.Array, intenta abrir el
--      array y volcar cada elemento con todos sus campos y metodos.
--   3) Hace lo mismo especificamente con SkillSlotValues y EquipedSkills,
--      que ya fueron confirmados en el Paso 38.
--   4) Vuelca las firmas REALES de los metodos: retorno y parametros.
--   5) Vuelca TODOS los campos y metodos del Job0XActionCtrl de la
--      vocacion actual, construido dinamicamente a partir de CurrentJob.
--   6) Opcionalmente hace lo mismo con AbilityContext, sin inventar
--      ningun nombre de slot.
--
-- No se llama ningun setter ni se usa set_field().
-- ============================================================

local function type_name_from_definition(td)
    if td == nil then return "<?>" end
    return safe(function() return td:get_full_name() end) or "<?>"
end

object_type_name = function(obj)
    if obj == nil then return "<?>" end
    local td = safe(function() return obj:get_type_definition() end)
    return type_name_from_definition(td)
end

local function dump_method_signature(method, prefix)
    if method == nil then return end

    local method_name = safe(function() return method:get_name() end) or "<?>"
    local return_td = safe(function() return method:get_return_type() end)
    local return_name = type_name_from_definition(return_td)

    local param_types = safe(function() return method:get_param_types() end) or {}
    local param_names = safe(function() return method:get_param_names() end) or {}

    local params = {}
    for i, param_td in ipairs(param_types) do
        local ptype = type_name_from_definition(param_td)
        local pname = param_names[i]
        if pname == nil or pname == "" then
            pname = "param" .. tostring(i)
        end
        params[#params + 1] = pname .. " :: " .. ptype
    end

    local is_static = safe(function() return method:is_static() end)

    logp(
        prefix
        .. method_name
        .. "("
        .. table.concat(params, ", ")
        .. ") -> "
        .. return_name
        .. " | static="
        .. tostring(is_static)
    )
end

local function dump_all_method_signatures(obj, label)
    if obj == nil then
        logp("[PawnResearch]   " .. label .. " = NIL, no se pueden listar metodos")
        return
    end

    logp("[PawnResearch]   ---- FIRMAS DE METODOS: " .. label .. " ----")

    local td = safe(function() return obj:get_type_definition() end)
    local seen_types = {}

    while td ~= nil do
        local declaring_name = type_name_from_definition(td)
        if seen_types[declaring_name] then break end
        seen_types[declaring_name] = true

        logp("[PawnResearch]     TIPO: " .. declaring_name)

        local methods = safe(function() return td:get_methods() end) or {}
        for _, method in ipairs(methods) do
            dump_method_signature(method, "[PawnResearch]       ")
        end

        td = safe(function() return td:get_parent_type() end)
    end
end

local function dump_all_fields_with_values(obj, label)
    if obj == nil then
        logp("[PawnResearch]   " .. label .. " = NIL, no se pudo revisar")
        return
    end

    logp(
        "[PawnResearch]   ---- CAMPOS: "
        .. label
        .. " (tipo real="
        .. object_type_name(obj)
        .. ") ----"
    )

    local fields = list_all_field_names(obj)
    if #fields == 0 then
        logp("[PawnResearch]     (sin campos)")
        return
    end

    for _, f in ipairs(fields) do
        local current_value = get_field_value_by_name(obj, f.name)
        logp(
            "[PawnResearch]     CAMPO: "
            .. f.declaring_type
            .. "::"
            .. f.name
            .. " (tipo="
            .. tostring(f.type_name)
            .. ") valor actual="
            .. value_to_string(current_value)
        )
    end
end


-- PASO 86: busca el BodyEditorRoot real en los GameObject asociados al
-- BodyEditor y al PartSwapper. No escribe nada.
function paso86_diagnosticar_body_editor_root(character)
    if character == nil then
        logp("[PawnResearch] PASO 86: character nil")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    if is_character_protected(cid) then
        logp("[PawnResearch] PASO 86: BLOQUEADO CID=" .. tostring(cid))
        return false, "CharacterID protegido"
    end

    logp("[PawnResearch] ===== PASO 86 BUSCAR BODYEDITORROOT =====")
    logp("[PawnResearch] PASO 86 CID=" .. tostring(cid))

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 86 PartSwapper=nil")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 86 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    logp("[PawnResearch] PASO 86 BodyEditor tipo=" .. object_type_name(body_editor))

    local be_fields = list_all_field_names(body_editor)
    for _, f in ipairs(be_fields) do
        local n = string.lower(tostring(f.name))
        if string.find(n, "basebodyeditor", 1, true) or string.find(n, "bodyeditor", 1, true) then
            local v = get_field_value_by_name(body_editor, f.name)
            logp("[PawnResearch] PASO 86 BODYEDITOR CAMPO "
                .. f.declaring_type .. "::" .. f.name
                .. " tipo=" .. tostring(f.type_name)
                .. " valor=" .. value_to_string(v))
        end
    end

    local game_objects = {}
    local ps_go = safe(function() return ps:get_GameObject() end)
    local be_go = safe(function() return body_editor:get_GameObject() end)
    local char_go = safe(function() return character:get_GameObject() end)
    game_objects[1] = {label="PartSwapper", go=ps_go}
    game_objects[2] = {label="BodyEditor", go=be_go}
    game_objects[3] = {label="Character", go=char_go}

    local seen_go = {}
    local found_root = nil

    for _, entry in ipairs(game_objects) do
        local go = entry.go
        if go ~= nil then
            local key = tostring(go)
            if not seen_go[key] then
                seen_go[key] = true
                local go_name = safe(function() return go:get_Name() end)
                logp("[PawnResearch] PASO 86 GAMEOBJECT " .. entry.label
                    .. " tipo=" .. object_type_name(go)
                    .. " name=" .. tostring(go_name))

                local methods = list_all_method_names(go)
                local has_get_components = false
                local has_get_component = false
                for _, m in ipairs(methods) do
                    if m.name == "get_Components" then has_get_components = true end
                    if m.name == "getComponent" then has_get_component = true end
                end
                logp("[PawnResearch] PASO 86 GAMEOBJECT METODOS get_Components="
                    .. tostring(has_get_components)
                    .. " getComponent=" .. tostring(has_get_component))

                if has_get_components then
                    local components = safe(function() return go:call("get_Components") end)
                    if components ~= nil then
                        local elements = safe(function() return components:get_elements() end)
                        if elements ~= nil then
                            logp("[PawnResearch] PASO 86 COMPONENTES count=" .. tostring(#elements))
                            for i, comp in ipairs(elements) do
                                if comp ~= nil then
                                    local ct = object_type_name(comp)
                                    logp("[PawnResearch] PASO 86 COMPONENT index=" .. tostring(i - 1)
                                        .. " tipo=" .. tostring(ct))
                                    if ct == "app.BodyEditorRoot" then
                                        found_root = comp
                                        logp("[PawnResearch] PASO 86 BODYEDITORROOT ENCONTRADO en " .. entry.label)
                                    end
                                end
                            end
                        else
                            logp("[PawnResearch] PASO 86 COMPONENTES get_elements=nil")
                        end
                    else
                        logp("[PawnResearch] PASO 86 COMPONENTES get_Components devolvio nil")
                    end
                end
            end
        else
            logp("[PawnResearch] PASO 86 GAMEOBJECT " .. entry.label .. " = nil")
        end
    end

    if found_root ~= nil then
        local root_h = safe(function() return found_root:get_BodyHeight() end)
        logp("[PawnResearch] PASO 86 ROOT BODYHEIGHT ACTUAL=" .. tostring(root_h))
        logp("[PawnResearch] PASO 86 RESULTADO: BodyEditorRoot localizado")
        logp("[PawnResearch] ===== FIN PASO 86 =====")
        return true, "BodyEditorRoot localizado"
    end

    logp("[PawnResearch] PASO 86 RESULTADO: BodyEditorRoot no aparecio como componente")
    logp("[PawnResearch] ===== FIN PASO 86 =====")
    return false, "BodyEditorRoot no encontrado"
end

-- PASO 87: usa directamente el objeto app.BodyEditor obtenido desde
-- PartSwapper::_BodyEditor. Ese objeto hereda de app.BodyEditorRoot y por
-- reflexion ya confirmamos que expone set_BodyHeight(Single). No usa
-- Human.BodyHeight ni get_BaseBodyEditor().
function paso87_probar_setter_bodyeditor_directo(character, template_name)
    if character == nil then
        logp("[PawnResearch] PASO 87: character nil")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    if is_character_protected(cid) then
        logp("[PawnResearch] PASO 87: BLOQUEADO CID=" .. tostring(cid))
        return false, "CharacterID protegido"
    end

    local payload, load_err = paso82_load_template(template_name)
    if payload == nil then
        logp("[PawnResearch] PASO 87 TEMPLATE ERROR=" .. tostring(load_err))
        return false, load_err
    end

    local expected_height = nil
    if payload.body_scale_detail ~= nil then
        expected_height = tonumber(payload.body_scale_detail.BodyHeight)
    end
    if expected_height == nil then
        logp("[PawnResearch] PASO 87: plantilla sin body_scale_detail.BodyHeight")
        return false, "plantilla sin BodyHeight"
    end

    logp("[PawnResearch] ===== PASO 87 SETTER BODYEDITOR DIRECTO =====")
    logp("[PawnResearch] PASO 87 CID=" .. tostring(cid))
    logp("[PawnResearch] PASO 87 altura_esperada=" .. tostring(expected_height))

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 87 PartSwapper=nil")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 87 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    logp("[PawnResearch] PASO 87 BodyEditor tipo=" .. object_type_name(body_editor))

    local before = safe(function() return body_editor:get_BodyHeight() end)
    local human_before_obj = get_human(character)
    local human_before = nil
    if human_before_obj ~= nil then
        human_before = safe(function() return human_before_obj:get_BodyHeight() end)
    end
    logp("[PawnResearch] PASO 87 ANTES BodyEditor.BodyHeight=" .. tostring(before) .. " Human.BodyHeight=" .. tostring(human_before))

    local write_ok, write_err = pcall(function()
        body_editor:set_BodyHeight(expected_height)
    end)
    if not write_ok then
        logp("[PawnResearch] PASO 87 SETTER ERROR=" .. tostring(write_err))
        logp("[PawnResearch] ===== FIN PASO 87 SETTER BODYEDITOR DIRECTO =====")
        return false, "setter error: " .. tostring(write_err)
    end

    local after = safe(function() return body_editor:get_BodyHeight() end)
    local human_after_obj = get_human(character)
    local human_after = nil
    if human_after_obj ~= nil then
        human_after = safe(function() return human_after_obj:get_BodyHeight() end)
    end
    logp("[PawnResearch] PASO 87 DESPUES MISMO OBJETO BodyEditor.BodyHeight=" .. tostring(after) .. " Human.BodyHeight=" .. tostring(human_after))

    -- Reobtenemos el peon desde PawnCharacterList para verificar que el dato
    -- del BodyEditor sobrevive la resolucion de un objeto fresco.
    local fresh_character = nil
    local pm = get_pawn_manager()
    local fresh_list = nil
    if pm ~= nil then
        fresh_list = safe_call(pm, "get_PawnCharacterList")
    end
    if fresh_list ~= nil then
        local count = safe_call(fresh_list, "get_Count") or 0
        for i = 0, count - 1 do
            local candidate = safe_call(fresh_list, "get_Item", i)
            if candidate ~= nil then
                local candidate_id = get_field_value_by_name(candidate, "CharacterID")
                if tostring(candidate_id) == tostring(cid) then
                    fresh_character = candidate
                    break
                end
            end
        end
    end

    local fresh_body_editor = nil
    local fresh_human = nil
    if fresh_character ~= nil then
        fresh_human = get_human(fresh_character)
        local fresh_ps = get_part_swapper(fresh_character)
        if fresh_ps ~= nil then
            fresh_body_editor = get_field_value_by_name(fresh_ps, "_BodyEditor")
        end
    end

    local fresh_editor_height = nil
    local fresh_human_height = nil
    if fresh_body_editor ~= nil then
        fresh_editor_height = safe(function() return fresh_body_editor:get_BodyHeight() end)
    end
    if fresh_human ~= nil then
        fresh_human_height = safe(function() return fresh_human:get_BodyHeight() end)
    end
    logp("[PawnResearch] PASO 87 VERIFY FRESCA BodyEditor.BodyHeight=" .. tostring(fresh_editor_height) .. " Human.BodyHeight=" .. tostring(fresh_human_height))

    if fresh_editor_height == expected_height then
        logp("[PawnResearch] PASO 87 RESULTADO: setter directo aceptado por BodyEditorRoot y sobrevive objeto fresco")
        logp("[PawnResearch] PASO 87 NOTA: Human.BodyHeight todavia no se usa como destino de escritura")
        logp("[PawnResearch] ===== FIN PASO 87 SETTER BODYEDITOR DIRECTO =====")
        return true, "BodyEditor directo OK"
    end

    logp("[PawnResearch] PASO 87 RESULTADO: setter no persistio en BodyEditor fresco")
    logp("[PawnResearch] ===== FIN PASO 87 SETTER BODYEDITOR DIRECTO =====")
    return false, "setter no persistio"
end


-- PASO 89: prueba controlada del metodo nativo applyEditModel().
-- Primero fija BodyHeight en BodyEditorRoot con el setter confirmado.
-- Luego llama SOLO applyEditModel() y revisa si la altura llega a Human
-- o al calculador de escala. No escribe Human directamente ni usa
-- setupScale/updateScale ni PartSwapper.swap*.
function paso89_probar_apply_edit_model(character, template_name)
    if character == nil then
        logp("[PawnResearch] PASO 89: character nil")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    if is_character_protected(cid) then
        logp("[PawnResearch] PASO 89: BLOQUEADO CID=" .. tostring(cid))
        return false, "CharacterID protegido"
    end

    local payload, load_err = paso82_load_template(template_name)
    if payload == nil then
        logp("[PawnResearch] PASO 89 TEMPLATE ERROR=" .. tostring(load_err))
        return false, load_err
    end

    local expected_height = nil
    if payload.body_scale_detail ~= nil then
        expected_height = tonumber(payload.body_scale_detail.BodyHeight)
    end
    if expected_height == nil then
        logp("[PawnResearch] PASO 89: plantilla sin body_scale_detail.BodyHeight")
        return false, "plantilla sin BodyHeight"
    end

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 89 PartSwapper=nil")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 89 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    local human = get_human(character)
    local calc = nil
    if human ~= nil then
        calc = safe(function() return human:get_RootTransScaleCalculator() end)
    end

    local before_editor_h = safe(function() return body_editor:get_BodyHeight() end)
    local before_human_scale = nil
    local before_scale_y = nil
    local before_weight = nil
    local before_calc_scale = nil
    if human ~= nil then
        before_human_scale = safe(function() return human:get_Scale() end)
        before_scale_y = get_field_value_by_name(human, "ScaleY")
        before_weight = get_field_value_by_name(human, "BodyWeight")
    end
    if calc ~= nil then
        before_calc_scale = safe(function() return calc:get_Scale() end)
    end

    logp("[PawnResearch] ===== PASO 89 APPLYEDITMODEL =====")
    logp("[PawnResearch] PASO 89 CID=" .. tostring(cid))
    logp("[PawnResearch] PASO 89 altura_esperada=" .. tostring(expected_height))
    logp("[PawnResearch] PASO 89 ANTES editor.BodyHeight=" .. tostring(before_editor_h))
    logp("[PawnResearch] PASO 89 ANTES human.Scale=" .. tostring(before_human_scale)
        .. " ScaleY=" .. tostring(before_scale_y)
        .. " BodyWeight=" .. tostring(before_weight))
    logp("[PawnResearch] PASO 89 ANTES calculator.Scale=" .. tostring(before_calc_scale))

    local set_ok, set_err = pcall(function()
        body_editor:set_BodyHeight(expected_height)
    end)
    if not set_ok then
        logp("[PawnResearch] PASO 89 SET BODYHEIGHT ERROR=" .. tostring(set_err))
        logp("[PawnResearch] ===== FIN PASO 89 APPLYEDITMODEL =====")
        return false, "set_BodyHeight error: " .. tostring(set_err)
    end

    logp("[PawnResearch] PASO 89 SET BODYHEIGHT OK editor.BodyHeight="
        .. tostring(safe(function() return body_editor:get_BodyHeight() end)))

    local apply_ok, apply_err = pcall(function()
        body_editor:applyEditModel()
    end)
    if not apply_ok then
        logp("[PawnResearch] PASO 89 APPLYEDITMODEL ERROR=" .. tostring(apply_err))
        logp("[PawnResearch] ===== FIN PASO 89 APPLYEDITMODEL =====")
        return false, "applyEditModel error: " .. tostring(apply_err)
    end
    logp("[PawnResearch] PASO 89 APPLYEDITMODEL OK")

    local after_editor_h = safe(function() return body_editor:get_BodyHeight() end)
    local after_human_scale = nil
    local after_scale_y = nil
    local after_weight = nil
    local after_calc_scale = nil
    if human ~= nil then
        after_human_scale = safe(function() return human:get_Scale() end)
        after_scale_y = get_field_value_by_name(human, "ScaleY")
        after_weight = get_field_value_by_name(human, "BodyWeight")
    end
    if calc ~= nil then
        after_calc_scale = safe(function() return calc:get_Scale() end)
    end

    logp("[PawnResearch] PASO 89 DESPUES editor.BodyHeight=" .. tostring(after_editor_h))
    logp("[PawnResearch] PASO 89 DESPUES human.Scale=" .. tostring(after_human_scale)
        .. " ScaleY=" .. tostring(after_scale_y)
        .. " BodyWeight=" .. tostring(after_weight))
    logp("[PawnResearch] PASO 89 DESPUES calculator.Scale=" .. tostring(after_calc_scale))

    -- Obtener nuevamente el mismo CharacterID desde PawnCharacterList para comprobar
    -- que el efecto tambien quedo en el objeto fresco.
    local fresh_character = nil
    local pm = get_pawn_manager()
    local fresh_list = nil
    if pm ~= nil then
        fresh_list = safe_call(pm, "get_PawnCharacterList")
    end
    if fresh_list ~= nil then
        local count = safe_call(fresh_list, "get_Count") or 0
        for i = 0, count - 1 do
            local candidate = safe_call(fresh_list, "get_Item", i)
            if candidate ~= nil then
                local candidate_id = get_field_value_by_name(candidate, "CharacterID")
                if tostring(candidate_id) == tostring(cid) then
                    fresh_character = candidate
                    break
                end
            end
        end
    end

    local fresh_editor = nil
    local fresh_human = nil
    local fresh_calc = nil
    if fresh_character ~= nil then
        fresh_human = get_human(fresh_character)
        if fresh_human ~= nil then
            fresh_calc = safe(function() return fresh_human:get_RootTransScaleCalculator() end)
        end
        local fresh_ps = get_part_swapper(fresh_character)
        if fresh_ps ~= nil then
            fresh_editor = get_field_value_by_name(fresh_ps, "_BodyEditor")
        end
    end

    local fresh_editor_h = nil
    local fresh_scale = nil
    local fresh_scale_y = nil
    local fresh_weight = nil
    local fresh_calc_scale = nil
    if fresh_editor ~= nil then
        fresh_editor_h = safe(function() return fresh_editor:get_BodyHeight() end)
    end
    if fresh_human ~= nil then
        fresh_scale = safe(function() return fresh_human:get_Scale() end)
        fresh_scale_y = get_field_value_by_name(fresh_human, "ScaleY")
        fresh_weight = get_field_value_by_name(fresh_human, "BodyWeight")
    end
    if fresh_calc ~= nil then
        fresh_calc_scale = safe(function() return fresh_calc:get_Scale() end)
    end

    logp("[PawnResearch] PASO 89 FRESCA editor.BodyHeight=" .. tostring(fresh_editor_h)
        .. " human.Scale=" .. tostring(fresh_scale)
        .. " ScaleY=" .. tostring(fresh_scale_y)
        .. " BodyWeight=" .. tostring(fresh_weight)
        .. " calculator.Scale=" .. tostring(fresh_calc_scale))

    if after_editor_h == expected_height then
        logp("[PawnResearch] PASO 89 RESULTADO: applyEditModel ejecutado sin error y BodyHeight conserva el valor")
    else
        logp("[PawnResearch] PASO 89 RESULTADO: applyEditModel altero BodyHeight inesperadamente")
    end

    logp("[PawnResearch] PASO 89 NOTA: no se llamo applyEdit, setupScale, updateScale ni PartSwapper.swap*")
    logp("[PawnResearch] ===== FIN PASO 89 APPLYEDITMODEL =====")
    return true, "applyEditModel terminado"
end


-- PASO 90: prueba controlada del metodo nativo applyEdit().
-- Primero fija BodyHeight en BodyEditorRoot con el setter confirmado.
-- Luego llama SOLO applyEdit() y revisa si la altura llega a la escala real.
-- No escribe Human directamente ni usa applyEditModel/setupScale/updateScale.
function paso90_probar_apply_edit(character, template_name)
    if character == nil then
        logp("[PawnResearch] PASO 90: character nil")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    if is_character_protected(cid) then
        logp("[PawnResearch] PASO 90: BLOQUEADO CID=" .. tostring(cid))
        return false, "CharacterID protegido"
    end

    local payload, load_err = paso82_load_template(template_name)
    if payload == nil then
        logp("[PawnResearch] PASO 90 TEMPLATE ERROR=" .. tostring(load_err))
        return false, load_err
    end

    local expected_height = nil
    if payload.body_scale_detail ~= nil then
        expected_height = tonumber(payload.body_scale_detail.BodyHeight)
    end
    if expected_height == nil then
        logp("[PawnResearch] PASO 90: plantilla sin body_scale_detail.BodyHeight")
        return false, "plantilla sin BodyHeight"
    end

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 90 PartSwapper=nil")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 90 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    local human = get_human(character)
    local calc = nil
    if human ~= nil then
        calc = safe(function() return human:get_RootTransScaleCalculator() end)
    end

    local before_editor_h = safe(function() return body_editor:get_BodyHeight() end)
    local before_human_scale = nil
    local before_scale_y = nil
    local before_weight = nil
    local before_calc_scale = nil
    if human ~= nil then
        before_human_scale = safe(function() return human:get_Scale() end)
        before_scale_y = get_field_value_by_name(human, "ScaleY")
        before_weight = get_field_value_by_name(human, "BodyWeight")
    end
    if calc ~= nil then
        before_calc_scale = safe(function() return calc:get_Scale() end)
    end

    logp("[PawnResearch] ===== PASO 90 APPLYEDIT =====")
    logp("[PawnResearch] PASO 90 CID=" .. tostring(cid))
    logp("[PawnResearch] PASO 90 altura_esperada=" .. tostring(expected_height))
    logp("[PawnResearch] PASO 90 ANTES editor.BodyHeight=" .. tostring(before_editor_h))
    logp("[PawnResearch] PASO 90 ANTES human.Scale=" .. tostring(before_human_scale)
        .. " ScaleY=" .. tostring(before_scale_y)
        .. " BodyWeight=" .. tostring(before_weight))
    logp("[PawnResearch] PASO 90 ANTES calculator.Scale=" .. tostring(before_calc_scale))

    local set_ok, set_err = pcall(function()
        body_editor:set_BodyHeight(expected_height)
    end)
    if not set_ok then
        logp("[PawnResearch] PASO 90 SET BODYHEIGHT ERROR=" .. tostring(set_err))
        logp("[PawnResearch] ===== FIN PASO 90 APPLYEDIT =====")
        return false, "set_BodyHeight error: " .. tostring(set_err)
    end

    logp("[PawnResearch] PASO 90 SET BODYHEIGHT OK editor.BodyHeight="
        .. tostring(safe(function() return body_editor:get_BodyHeight() end)))

    local apply_ok, apply_result = pcall(function()
        return body_editor:applyEdit()
    end)
    if not apply_ok then
        logp("[PawnResearch] PASO 90 APPLYEDIT ERROR=" .. tostring(apply_result))
        logp("[PawnResearch] ===== FIN PASO 90 APPLYEDIT =====")
        return false, "applyEdit error: " .. tostring(apply_result)
    end
    logp("[PawnResearch] PASO 90 APPLYEDIT OK retorno=" .. tostring(apply_result))

    local after_editor_h = safe(function() return body_editor:get_BodyHeight() end)
    local after_human_scale = nil
    local after_scale_y = nil
    local after_weight = nil
    local after_calc_scale = nil
    if human ~= nil then
        after_human_scale = safe(function() return human:get_Scale() end)
        after_scale_y = get_field_value_by_name(human, "ScaleY")
        after_weight = get_field_value_by_name(human, "BodyWeight")
    end
    if calc ~= nil then
        after_calc_scale = safe(function() return calc:get_Scale() end)
    end

    logp("[PawnResearch] PASO 90 DESPUES editor.BodyHeight=" .. tostring(after_editor_h))
    logp("[PawnResearch] PASO 90 DESPUES human.Scale=" .. tostring(after_human_scale)
        .. " ScaleY=" .. tostring(after_scale_y)
        .. " BodyWeight=" .. tostring(after_weight))
    logp("[PawnResearch] PASO 90 DESPUES calculator.Scale=" .. tostring(after_calc_scale))

    local fresh_character = nil
    local pm = get_pawn_manager()
    local fresh_list = nil
    if pm ~= nil then
        fresh_list = safe_call(pm, "get_PawnCharacterList")
    end
    if fresh_list ~= nil then
        local count = safe_call(fresh_list, "get_Count") or 0
        for i = 0, count - 1 do
            local candidate = safe_call(fresh_list, "get_Item", i)
            if candidate ~= nil then
                local candidate_id = get_field_value_by_name(candidate, "CharacterID")
                if tostring(candidate_id) == tostring(cid) then
                    fresh_character = candidate
                    break
                end
            end
        end
    end

    local fresh_editor = nil
    local fresh_human = nil
    local fresh_calc = nil
    if fresh_character ~= nil then
        fresh_human = get_human(fresh_character)
        if fresh_human ~= nil then
            fresh_calc = safe(function() return fresh_human:get_RootTransScaleCalculator() end)
        end
        local fresh_ps = get_part_swapper(fresh_character)
        if fresh_ps ~= nil then
            fresh_editor = get_field_value_by_name(fresh_ps, "_BodyEditor")
        end
    end

    local fresh_editor_h = nil
    local fresh_scale = nil
    local fresh_scale_y = nil
    local fresh_weight = nil
    local fresh_calc_scale = nil
    if fresh_editor ~= nil then
        fresh_editor_h = safe(function() return fresh_editor:get_BodyHeight() end)
    end
    if fresh_human ~= nil then
        fresh_scale = safe(function() return fresh_human:get_Scale() end)
        fresh_scale_y = get_field_value_by_name(fresh_human, "ScaleY")
        fresh_weight = get_field_value_by_name(fresh_human, "BodyWeight")
    end
    if fresh_calc ~= nil then
        fresh_calc_scale = safe(function() return fresh_calc:get_Scale() end)
    end

    logp("[PawnResearch] PASO 90 FRESCA editor.BodyHeight=" .. tostring(fresh_editor_h)
        .. " human.Scale=" .. tostring(fresh_scale)
        .. " ScaleY=" .. tostring(fresh_scale_y)
        .. " BodyWeight=" .. tostring(fresh_weight)
        .. " calculator.Scale=" .. tostring(fresh_calc_scale))

    if fresh_editor_h == expected_height then
        logp("[PawnResearch] PASO 90 RESULTADO: applyEdit termino y BodyHeight conserva el valor en objeto fresco")
    else
        logp("[PawnResearch] PASO 90 RESULTADO: applyEdit termino pero BodyHeight no conservo el valor esperado")
    end

    logp("[PawnResearch] PASO 90 NOTA: no se escribio Human.BodyHeight, Human.Scale, ScaleY o BodyWeight; no se uso applyEditModel/setupScale/updateScale ni PartSwapper.swap*")
    logp("[PawnResearch] ===== FIN PASO 90 APPLYEDIT =====")
    return true, "applyEdit terminado"
end



-- PASO 91: prueba controlada del metodo nativo setupApplyEditScales().
-- Primero fija BodyHeight en BodyEditorRoot con el setter confirmado.
-- Luego prepara las escalas con setupApplyEditScales() y revisa si el
-- estado de escala de Human/Calculator se actualiza. No escribe Human
-- directamente ni usa setupScale/updateScale/PartSwapper.swap*.
function paso91_probar_setup_apply_edit_scales(character, template_name)
    if character == nil then
        logp("[PawnResearch] PASO 91: character nil")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    if is_character_protected(cid) then
        logp("[PawnResearch] PASO 91: BLOQUEADO CID=" .. tostring(cid))
        return false, "CharacterID protegido"
    end

    local payload, load_err = paso82_load_template(template_name)
    if payload == nil then
        logp("[PawnResearch] PASO 91 TEMPLATE ERROR=" .. tostring(load_err))
        return false, load_err
    end

    local expected_height = nil
    if payload.body_scale_detail ~= nil then
        expected_height = tonumber(payload.body_scale_detail.BodyHeight)
    end
    if expected_height == nil then
        logp("[PawnResearch] PASO 91: plantilla sin body_scale_detail.BodyHeight")
        return false, "plantilla sin BodyHeight"
    end

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 91 PartSwapper=nil")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 91 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    local human = get_human(character)
    local calc = nil
    if human ~= nil then
        calc = safe(function() return human:get_RootTransScaleCalculator() end)
    end

    local before_editor_h = safe(function() return body_editor:get_BodyHeight() end)
    local before_scale = nil
    local before_scale_y = nil
    local before_weight = nil
    local before_calc_scale = nil
    local before_ratio = nil
    if human ~= nil then
        before_scale = safe(function() return human:get_Scale() end)
        before_scale_y = get_field_value_by_name(human, "ScaleY")
        before_weight = get_field_value_by_name(human, "BodyWeight")
    end
    if calc ~= nil then
        before_calc_scale = safe(function() return calc:get_Scale() end)
        before_ratio = safe(function() return calc:get_ScaleParameterRatio() end)
    end

    logp("[PawnResearch] ===== PASO 91 SETUPAPPLYEDIT SCALES =====")
    logp("[PawnResearch] PASO 91 CID=" .. tostring(cid))
    logp("[PawnResearch] PASO 91 altura_esperada=" .. tostring(expected_height))
    logp("[PawnResearch] PASO 91 ANTES editor.BodyHeight=" .. tostring(before_editor_h))
    logp("[PawnResearch] PASO 91 ANTES human.Scale=" .. tostring(before_scale)
        .. " ScaleY=" .. tostring(before_scale_y)
        .. " BodyWeight=" .. tostring(before_weight))
    logp("[PawnResearch] PASO 91 ANTES calculator.Scale=" .. tostring(before_calc_scale)
        .. " ScaleParameterRatio=" .. tostring(before_ratio))

    local set_ok, set_err = pcall(function()
        body_editor:set_BodyHeight(expected_height)
    end)
    if not set_ok then
        logp("[PawnResearch] PASO 91 SET BODYHEIGHT ERROR=" .. tostring(set_err))
        logp("[PawnResearch] ===== FIN PASO 91 SETUPAPPLYEDIT SCALES =====")
        return false, "set_BodyHeight error: " .. tostring(set_err)
    end

    logp("[PawnResearch] PASO 91 SET BODYHEIGHT OK editor.BodyHeight="
        .. tostring(safe(function() return body_editor:get_BodyHeight() end)))

    local setup_ok, setup_err = pcall(function()
        body_editor:setupApplyEditScales()
    end)
    if not setup_ok then
        logp("[PawnResearch] PASO 91 SETUPAPPLYEDIT SCALES ERROR=" .. tostring(setup_err))
        logp("[PawnResearch] ===== FIN PASO 91 SETUPAPPLYEDIT SCALES =====")
        return false, "setupApplyEditScales error: " .. tostring(setup_err)
    end

    logp("[PawnResearch] PASO 91 SETUPAPPLYEDIT SCALES OK")

    local after_editor_h = safe(function() return body_editor:get_BodyHeight() end)
    local after_scale = nil
    local after_scale_y = nil
    local after_weight = nil
    local after_calc_scale = nil
    local after_ratio = nil
    if human ~= nil then
        after_scale = safe(function() return human:get_Scale() end)
        after_scale_y = get_field_value_by_name(human, "ScaleY")
        after_weight = get_field_value_by_name(human, "BodyWeight")
    end
    if calc ~= nil then
        after_calc_scale = safe(function() return calc:get_Scale() end)
        after_ratio = safe(function() return calc:get_ScaleParameterRatio() end)
    end

    logp("[PawnResearch] PASO 91 DESPUES editor.BodyHeight=" .. tostring(after_editor_h))
    logp("[PawnResearch] PASO 91 DESPUES human.Scale=" .. tostring(after_scale)
        .. " ScaleY=" .. tostring(after_scale_y)
        .. " BodyWeight=" .. tostring(after_weight))
    logp("[PawnResearch] PASO 91 DESPUES calculator.Scale=" .. tostring(after_calc_scale)
        .. " ScaleParameterRatio=" .. tostring(after_ratio))

    local fresh_character = nil
    local pm = get_pawn_manager()
    local fresh_list = nil
    if pm ~= nil then
        fresh_list = safe_call(pm, "get_PawnCharacterList")
    end
    if fresh_list ~= nil then
        local count = safe_call(fresh_list, "get_Count") or 0
        for i = 0, count - 1 do
            local candidate = safe_call(fresh_list, "get_Item", i)
            if candidate ~= nil then
                local candidate_id = get_field_value_by_name(candidate, "CharacterID")
                if tostring(candidate_id) == tostring(cid) then
                    fresh_character = candidate
                    break
                end
            end
        end
    end

    local fresh_editor = nil
    local fresh_human = nil
    local fresh_calc = nil
    if fresh_character ~= nil then
        fresh_human = get_human(fresh_character)
        if fresh_human ~= nil then
            fresh_calc = safe(function() return fresh_human:get_RootTransScaleCalculator() end)
        end
        local fresh_ps = get_part_swapper(fresh_character)
        if fresh_ps ~= nil then
            fresh_editor = get_field_value_by_name(fresh_ps, "_BodyEditor")
        end
    end

    local fresh_editor_h = nil
    local fresh_scale = nil
    local fresh_scale_y = nil
    local fresh_weight = nil
    local fresh_calc_scale = nil
    local fresh_ratio = nil
    if fresh_editor ~= nil then
        fresh_editor_h = safe(function() return fresh_editor:get_BodyHeight() end)
    end
    if fresh_human ~= nil then
        fresh_scale = safe(function() return fresh_human:get_Scale() end)
        fresh_scale_y = get_field_value_by_name(fresh_human, "ScaleY")
        fresh_weight = get_field_value_by_name(fresh_human, "BodyWeight")
    end
    if fresh_calc ~= nil then
        fresh_calc_scale = safe(function() return fresh_calc:get_Scale() end)
        fresh_ratio = safe(function() return fresh_calc:get_ScaleParameterRatio() end)
    end

    logp("[PawnResearch] PASO 91 FRESCA editor.BodyHeight=" .. tostring(fresh_editor_h)
        .. " human.Scale=" .. tostring(fresh_scale)
        .. " ScaleY=" .. tostring(fresh_scale_y)
        .. " BodyWeight=" .. tostring(fresh_weight)
        .. " calculator.Scale=" .. tostring(fresh_calc_scale)
        .. " ScaleParameterRatio=" .. tostring(fresh_ratio))

    if fresh_editor_h == expected_height then
        logp("[PawnResearch] PASO 91 RESULTADO: setupApplyEditScales termino y BodyHeight conserva el valor en objeto fresco")
    else
        logp("[PawnResearch] PASO 91 RESULTADO: setupApplyEditScales altero BodyHeight")
    end

    logp("[PawnResearch] PASO 91 NOTA: no se escribio Human.BodyHeight, Human.Scale, ScaleY o BodyWeight; no se uso setupScale/updateScale ni PartSwapper.swap*")
    logp("[PawnResearch] ===== FIN PASO 91 SETUPAPPLYEDIT SCALES =====")
    return true, "setupApplyEditScales terminado"
end


-- PASO 92: diagnostico SOLO LECTURA del estado que puede impedir que
-- BodyEditor:applyEdit() propague BodyHeight hacia la escala real.
-- No ejecuta setters ni metodos de aplicacion, y no modifica Human.
function paso92_diagnosticar_condiciones_apply_edit(character)
    if character == nil then
        logp("[PawnResearch] PASO 92: character nil")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    if is_character_protected(cid) then
        logp("[PawnResearch] PASO 92: BLOQUEADO CID=" .. tostring(cid))
        return false, "CharacterID protegido"
    end

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 92 PartSwapper=nil")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 92 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    logp("[PawnResearch] ===== PASO 92 CONDICIONES APPLYEDIT =====")
    logp("[PawnResearch] PASO 92 CID=" .. tostring(cid))
    logp("[PawnResearch] PASO 92 BodyEditor tipo=" .. object_type_name(body_editor))

    -- Estado de ejecucion del BodyEditorRoot.
    local edit_mode = safe(function() return body_editor:get_EditMode() end)
    local bound = safe(function() return body_editor:get_Bound() end)
    local binding = safe(function() return body_editor:get_Binding() end)
    local passive = safe(function() return body_editor:get_Passive() end)
    local joint_segment_scale = safe(function() return body_editor:get_JointSegmentScale() end)
    local body_height = safe(function() return body_editor:get_BodyHeight() end)
    local body_weight = safe(function() return body_editor:get_BodyWeight() end)
    local body_editor_scale = nil

    logp("[PawnResearch] PASO 92 ESTADO EditMode=" .. tostring(edit_mode)
        .. " Bound=" .. tostring(bound)
        .. " Binding=" .. tostring(binding)
        .. " Passive=" .. tostring(passive)
        .. " JointSegmentScale=" .. tostring(joint_segment_scale))
    logp("[PawnResearch] PASO 92 VALORES BodyHeight=" .. tostring(body_height)
        .. " BodyWeight=" .. tostring(body_weight)
        .. " getBodyScale=no ejecutado (enum no asumido)" )

    -- Campos de BodyEditorRoot relacionados con edit/scale/height/weight.
    logp("[PawnResearch] PASO 92 ---- CAMPOS BODYEDITOR RELACIONADOS ----")
    local fields = list_all_field_names(body_editor)
    for _, f in ipairs(fields) do
        local n = string.lower(tostring(f.name))
        if string.find(n, "scale", 1, true)
            or string.find(n, "height", 1, true)
            or string.find(n, "weight", 1, true)
            or string.find(n, "edit", 1, true)
            or string.find(n, "bind", 1, true)
        then
            local value = get_field_value_by_name(body_editor, f.name)
            logp("[PawnResearch] PASO 92 CAMPO "
                .. f.declaring_type .. "::" .. f.name
                .. " tipo=" .. tostring(f.type_name)
                .. " valor=" .. value_to_string(value))
        end
    end

    -- Metodos relacionados: lectura de firmas, sin ejecutarlos.
    logp("[PawnResearch] PASO 92 ---- METODOS BODYEDITOR RELACIONADOS ----")
    local td = safe(function() return body_editor:get_type_definition() end)
    local seen_types = {}
    while td ~= nil do
        local tn = type_name_from_definition(td)
        if seen_types[tn] then break end
        seen_types[tn] = true
        local methods = safe(function() return td:get_methods() end) or {}
        for _, method in ipairs(methods) do
            local mn = safe(function() return method:get_name() end) or ""
            local low = string.lower(mn)
            if string.find(low, "scale", 1, true)
                or string.find(low, "height", 1, true)
                or string.find(low, "weight", 1, true)
                or string.find(low, "edit", 1, true)
                or string.find(low, "bind", 1, true)
            then
                dump_method_signature(method, "[PawnResearch]   ")
            end
        end
        td = safe(function() return td:get_parent_type() end)
    end

    -- El calculator tiene un Param real; inspeccionamos ese parametro y
    -- tambien el tipo base de parametro para localizar los datos que alimentan
    -- la escala, sin inventar nombres de campos.
    local human = get_human(character)
    local calc = nil
    if human ~= nil then
        calc = safe(function() return human:get_RootTransScaleCalculator() end)
    end
    if calc ~= nil then
        logp("[PawnResearch] PASO 92 calculator tipo=" .. object_type_name(calc))

        local calc_param = get_field_value_by_name(calc, "Param")
        if calc_param ~= nil then
            logp("[PawnResearch] PASO 92 calculator.Param tipo=" .. object_type_name(calc_param))
            dump_all_fields_with_values(calc_param, "PASO 92 HumanRootTransScaleCalculatorParameter")
            dump_all_method_signatures(calc_param, "PASO 92 HumanRootTransScaleCalculatorParameter")
        else
            logp("[PawnResearch] PASO 92 calculator.Param=nil")
        end

        local calc_fields = list_all_field_names(calc)
        logp("[PawnResearch] PASO 92 ---- CAMPOS CALCULATOR RELACIONADOS ----")
        for _, f in ipairs(calc_fields) do
            local n = string.lower(tostring(f.name))
            if string.find(n, "scale", 1, true)
                or string.find(n, "param", 1, true)
                or string.find(n, "height", 1, true)
                or string.find(n, "weight", 1, true)
            then
                local value = get_field_value_by_name(calc, f.name)
                logp("[PawnResearch] PASO 92 CALC CAMPO "
                    .. f.declaring_type .. "::" .. f.name
                    .. " tipo=" .. tostring(f.type_name)
                    .. " valor=" .. value_to_string(value))
            end
        end
    else
        logp("[PawnResearch] PASO 92 calculator=nil")
    end

    logp("[PawnResearch] PASO 92 RESULTADO: diagnostico terminado; no hubo escrituras")
    logp("[PawnResearch] ===== FIN PASO 92 CONDICIONES APPLYEDIT =====")
    return true, "diagnostico terminado"
end


-- PASO 88: prueba controlada del metodo nativo collectBodyScale().
-- Primero confirma que BodyEditorRoot ya tiene la altura esperada, luego
-- ejecuta collectBodyScale() y verifica si el estado de escala del personaje
-- se actualiza. No escribe Human.BodyHeight ni Human.Scale directamente.
function paso88_probar_collect_body_scale(character, template_name)
    if character == nil then
        logp("[PawnResearch] PASO 88: character nil")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    if is_character_protected(cid) then
        logp("[PawnResearch] PASO 88: BLOQUEADO CID=" .. tostring(cid))
        return false, "CharacterID protegido"
    end

    local payload, load_err = paso82_load_template(template_name)
    if payload == nil then
        logp("[PawnResearch] PASO 88 TEMPLATE ERROR=" .. tostring(load_err))
        return false, load_err
    end

    local expected_height = nil
    if payload.body_scale_detail ~= nil then
        expected_height = tonumber(payload.body_scale_detail.BodyHeight)
    end
    if expected_height == nil then
        logp("[PawnResearch] PASO 88: plantilla sin body_scale_detail.BodyHeight")
        return false, "plantilla sin BodyHeight"
    end

    logp("[PawnResearch] ===== PASO 88 COLLECT BODYSCALE =====")
    logp("[PawnResearch] PASO 88 CID=" .. tostring(cid))
    logp("[PawnResearch] PASO 88 altura_esperada=" .. tostring(expected_height))

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 88 PartSwapper=nil")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 88 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    local human = get_human(character)
    local calc = nil
    if human ~= nil then
        calc = safe(function() return human:get_RootTransScaleCalculator() end)
    end

    local before_editor_h = safe(function() return body_editor:get_BodyHeight() end)
    local before_human_h = nil
    local before_human_scale = nil
    local before_scale_y = nil
    local before_body_weight = nil
    local before_remove_height = nil
    local before_calc_scale = nil
    local before_calc_ratio = nil
    if human ~= nil then
        before_human_h = safe(function() return human:get_BodyHeight() end)
        before_human_scale = safe(function() return human:get_Scale() end)
        before_scale_y = get_field_value_by_name(human, "ScaleY")
        before_body_weight = get_field_value_by_name(human, "BodyWeight")
        before_remove_height = get_field_value_by_name(human, "RequestedRemoveHeight")
    end
    if calc ~= nil then
        before_calc_scale = safe(function() return calc:get_Scale() end)
        before_calc_ratio = safe(function() return calc:get_ScaleParameterRatio() end)
    end

    logp("[PawnResearch] PASO 88 ANTES editor.BodyHeight=" .. tostring(before_editor_h))
    logp("[PawnResearch] PASO 88 ANTES human.BodyHeight=" .. tostring(before_human_h)
        .. " Scale=" .. tostring(before_human_scale)
        .. " ScaleY=" .. tostring(before_scale_y)
        .. " BodyWeight=" .. tostring(before_body_weight)
        .. " RequestedRemoveHeight=" .. tostring(before_remove_height))
    logp("[PawnResearch] PASO 88 ANTES calculator.Scale=" .. tostring(before_calc_scale)
        .. " ScaleParameterRatio=" .. tostring(before_calc_ratio))

    local set_ok, set_err = pcall(function()
        body_editor:set_BodyHeight(expected_height)
    end)
    if not set_ok then
        logp("[PawnResearch] PASO 88 SET BODYHEIGHT ERROR=" .. tostring(set_err))
        logp("[PawnResearch] ===== FIN PASO 88 COLLECT BODYSCALE =====")
        return false, "set_BodyHeight error: " .. tostring(set_err)
    end

    local after_set_h = safe(function() return body_editor:get_BodyHeight() end)
    logp("[PawnResearch] PASO 88 SET BODYHEIGHT OK editor.BodyHeight=" .. tostring(after_set_h))

    local collect_ok, collect_err = pcall(function()
        body_editor:collectBodyScale()
    end)
    if not collect_ok then
        logp("[PawnResearch] PASO 88 COLLECT ERROR=" .. tostring(collect_err))
        logp("[PawnResearch] ===== FIN PASO 88 COLLECT BODYSCALE =====")
        return false, "collectBodyScale error: " .. tostring(collect_err)
    end
    logp("[PawnResearch] PASO 88 COLLECT OK")

    local after_collect_editor_h = safe(function() return body_editor:get_BodyHeight() end)
    local after_collect_human_h = nil
    local after_collect_human_scale = nil
    local after_collect_scale_y = nil
    local after_collect_body_weight = nil
    local after_collect_remove_height = nil
    local after_collect_calc_scale = nil
    local after_collect_calc_ratio = nil
    if human ~= nil then
        after_collect_human_h = safe(function() return human:get_BodyHeight() end)
        after_collect_human_scale = safe(function() return human:get_Scale() end)
        after_collect_scale_y = get_field_value_by_name(human, "ScaleY")
        after_collect_body_weight = get_field_value_by_name(human, "BodyWeight")
        after_collect_remove_height = get_field_value_by_name(human, "RequestedRemoveHeight")
    end
    if calc ~= nil then
        after_collect_calc_scale = safe(function() return calc:get_Scale() end)
        after_collect_calc_ratio = safe(function() return calc:get_ScaleParameterRatio() end)
    end

    logp("[PawnResearch] PASO 88 DESPUES editor.BodyHeight=" .. tostring(after_collect_editor_h))
    logp("[PawnResearch] PASO 88 DESPUES human.BodyHeight=" .. tostring(after_collect_human_h)
        .. " Scale=" .. tostring(after_collect_human_scale)
        .. " ScaleY=" .. tostring(after_collect_scale_y)
        .. " BodyWeight=" .. tostring(after_collect_body_weight)
        .. " RequestedRemoveHeight=" .. tostring(after_collect_remove_height))
    logp("[PawnResearch] PASO 88 DESPUES calculator.Scale=" .. tostring(after_collect_calc_scale)
        .. " ScaleParameterRatio=" .. tostring(after_collect_calc_ratio))

    local fresh_character = nil
    local pm = get_pawn_manager()
    local fresh_list = nil
    if pm ~= nil then
        fresh_list = safe_call(pm, "get_PawnCharacterList")
    end
    if fresh_list ~= nil then
        local count = safe_call(fresh_list, "get_Count") or 0
        for i = 0, count - 1 do
            local candidate = safe_call(fresh_list, "get_Item", i)
            if candidate ~= nil then
                local candidate_id = get_field_value_by_name(candidate, "CharacterID")
                if tostring(candidate_id) == tostring(cid) then
                    fresh_character = candidate
                    break
                end
            end
        end
    end

    local fresh_editor = nil
    local fresh_human = nil
    local fresh_calc = nil
    if fresh_character ~= nil then
        fresh_human = get_human(fresh_character)
        if fresh_human ~= nil then
            fresh_calc = safe(function() return fresh_human:get_RootTransScaleCalculator() end)
        end
        local fresh_ps = get_part_swapper(fresh_character)
        if fresh_ps ~= nil then
            fresh_editor = get_field_value_by_name(fresh_ps, "_BodyEditor")
        end
    end

    local fresh_editor_h = nil
    local fresh_human_h = nil
    local fresh_scale = nil
    local fresh_scale_y = nil
    local fresh_weight = nil
    local fresh_calc_scale = nil
    if fresh_editor ~= nil then
        fresh_editor_h = safe(function() return fresh_editor:get_BodyHeight() end)
    end
    if fresh_human ~= nil then
        fresh_human_h = safe(function() return fresh_human:get_BodyHeight() end)
        fresh_scale = safe(function() return fresh_human:get_Scale() end)
        fresh_scale_y = get_field_value_by_name(fresh_human, "ScaleY")
        fresh_weight = get_field_value_by_name(fresh_human, "BodyWeight")
    end
    if fresh_calc ~= nil then
        fresh_calc_scale = safe(function() return fresh_calc:get_Scale() end)
    end

    logp("[PawnResearch] PASO 88 FRESCA editor.BodyHeight=" .. tostring(fresh_editor_h)
        .. " human.BodyHeight=" .. tostring(fresh_human_h)
        .. " human.Scale=" .. tostring(fresh_scale)
        .. " ScaleY=" .. tostring(fresh_scale_y)
        .. " BodyWeight=" .. tostring(fresh_weight)
        .. " calculator.Scale=" .. tostring(fresh_calc_scale))

    logp("[PawnResearch] PASO 88 NOTA: no se llamo applyEdit, applyEditModel, setupScale, updateScale ni PartSwapper.swap*")

    if after_collect_editor_h == expected_height then
        logp("[PawnResearch] PASO 88 RESULTADO: collectBodyScale ejecutado sin error y el BodyEditor conserva la altura")
    else
        logp("[PawnResearch] PASO 88 RESULTADO: collectBodyScale cambio inesperadamente BodyEditor.BodyHeight")
    end

    logp("[PawnResearch] ===== FIN PASO 88 COLLECT BODYSCALE =====")
    return true, "collectBodyScale terminado"
end

-- PASO 85: diagnostico SOLO LECTURA del camino nativo que conecta
-- BodyEditContext.EditValues con la escala corporal real de Human.
-- No llama setters ni metodos de refresh/apply; solo enumera firmas reales
-- sobre los objetos que ya confirmamos que existen.
function paso85_diagnosticar_setter_altura(character, template_name)
    if character == nil then
        logp("[PawnResearch] PASO 85: character nil")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    if is_character_protected(cid) then
        logp("[PawnResearch] PASO 85: BLOQUEADO CID=" .. tostring(cid))
        return false, "CharacterID protegido"
    end

    local payload, load_err, load_path = paso82_load_template(template_name)
    if payload == nil then
        logp("[PawnResearch] PASO 85 TEMPLATE ERROR=" .. tostring(load_err))
        return false, load_err
    end

    local expected_height = nil
    if payload.body_scale_detail ~= nil then
        expected_height = tonumber(payload.body_scale_detail.BodyHeight)
    end
    if expected_height == nil then
        return false, "plantilla sin body_scale_detail.BodyHeight"
    end

    logp("[PawnResearch] ===== PASO 85 SETTER ALTURA =====")
    logp("[PawnResearch] PASO 85 CID=" .. tostring(cid))
    logp("[PawnResearch] PASO 85 plantilla=" .. tostring(load_path))
    logp("[PawnResearch] PASO 85 altura_esperada=" .. tostring(expected_height))

    local ps = get_part_swapper(character)
    if ps == nil then
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        return false, "BodyEditor nil"
    end

    local root = safe(function() return body_editor:get_BaseBodyEditor() end)
    if root == nil then
        logp("[PawnResearch] PASO 85 BodyEditorRoot=nil")
        return false, "BodyEditorRoot nil"
    end

    logp("[PawnResearch] PASO 85 BodyEditorRoot tipo=" .. object_type_name(root))
    local before_root = safe(function() return root:get_BodyHeight() end)
    local human_before = get_human(character)
    local before_human = nil
    if human_before ~= nil then
        before_human = safe(function() return human_before:get_BodyHeight() end)
    end
    logp("[PawnResearch] PASO 85 ANTES root.BodyHeight=" .. tostring(before_root) .. " human.BodyHeight=" .. tostring(before_human))

    local write_ok, write_err = pcall(function()
        root:set_BodyHeight(expected_height)
    end)
    if not write_ok then
        logp("[PawnResearch] PASO 85 SETTER ERROR=" .. tostring(write_err))
        return false, "setter error: " .. tostring(write_err)
    end
    logp("[PawnResearch] PASO 85 SETTER root:set_BodyHeight OK")

    local after_root = safe(function() return root:get_BodyHeight() end)
    local human_after_same = get_human(character)
    local after_human_same = nil
    if human_after_same ~= nil then
        after_human_same = safe(function() return human_after_same:get_BodyHeight() end)
    end
    logp("[PawnResearch] PASO 85 DESPUES MISMO OBJETO root.BodyHeight=" .. tostring(after_root) .. " human.BodyHeight=" .. tostring(after_human_same))

    local fresh_character = nil
    local pm = get_pawn_manager()
    local fresh_list = nil
    if pm ~= nil then
        fresh_list = safe_call(pm, "get_PawnCharacterList")
    end
    if fresh_list ~= nil then
        local count = safe_call(fresh_list, "get_Count") or 0
        for i = 0, count - 1 do
            local candidate = safe_call(fresh_list, "get_Item", i)
            local candidate_id = get_field_value_by_name(candidate, "CharacterID")
            if candidate ~= nil and tostring(candidate_id) == tostring(cid) then
                fresh_character = candidate
                break
            end
        end
    end

    local fresh_human = nil
    local fresh_body_editor = nil
    local fresh_root = nil
    if fresh_character ~= nil then
        fresh_human = get_human(fresh_character)
        local fresh_ps = get_part_swapper(fresh_character)
        if fresh_ps ~= nil then
            fresh_body_editor = get_field_value_by_name(fresh_ps, "_BodyEditor")
            if fresh_body_editor ~= nil then
                fresh_root = safe(function() return fresh_body_editor:get_BaseBodyEditor() end)
            end
        end
    end

    local fresh_root_height = nil
    local fresh_human_height = nil
    if fresh_root ~= nil then
        fresh_root_height = safe(function() return fresh_root:get_BodyHeight() end)
    end
    if fresh_human ~= nil then
        fresh_human_height = safe(function() return fresh_human:get_BodyHeight() end)
    end
    logp("[PawnResearch] PASO 85 VERIFY FRESCA root.BodyHeight=" .. tostring(fresh_root_height) .. " human.BodyHeight=" .. tostring(fresh_human_height))

    if fresh_root_height == expected_height and fresh_human_height == expected_height then
        logp("[PawnResearch] PASO 85 RESULTADO OK setter nativo propago a Human")
        logp("[PawnResearch] ===== FIN PASO 85 SETTER ALTURA =====")
        return true, "setter nativo propago altura"
    end

    logp("[PawnResearch] PASO 85 RESULTADO: setter escrito pero falta propagacion")
    logp("[PawnResearch] ===== FIN PASO 85 SETTER ALTURA =====")
    return false, "setter escrito pero no propago"
end


dump_array_object = function(array_obj, label, max_elements)
    if array_obj == nil then
        logp("[PawnResearch]     " .. label .. " = NIL")
        return false
    end

    -- Confirmamos que el objeto expone la API de SystemArray antes de
    -- intentar leer elementos. No se modifica el objeto.
    local elements = safe(function() return array_obj:get_elements() end)
    if elements == nil then
        return false
    end

    local size = safe(function() return array_obj:get_size() end)
    if size == nil then
        size = #elements
    end

    logp(
        "[PawnResearch]     ARRAY: "
        .. label
        .. " | tipo="
        .. object_type_name(array_obj)
        .. " | SIZE="
        .. tostring(size)
    )

    local limit = size
    if max_elements ~= nil then
        limit = math.min(size, max_elements)
    end

    for i = 1, limit do
        local element = elements[i]
        local idx = i - 1

        if element == nil then
            logp(
                "[PawnResearch]       ELEMENT["
                .. tostring(idx)
                .. "] = NIL"
            )
        else
            logp(
                "[PawnResearch]       ELEMENT["
                .. tostring(idx)
                .. "] tipo="
                .. object_type_name(element)
                .. " valor="
                .. value_to_string(element)
            )

            -- Si el elemento tiene campos, abrirlos por completo.
            local element_fields = list_all_field_names(element)
            if #element_fields > 0 then
                dump_all_fields_with_values(
                    element,
                    label .. "[" .. tostring(idx) .. "]"
                )
            end

            -- Y listar sus metodos con firmas reales.
            dump_all_method_signatures(
                element,
                label .. "[" .. tostring(idx) .. "]"
            )
        end
    end

    if size > limit then
        logp(
            "[PawnResearch]       ... "
            .. tostring(size - limit)
            .. " elementos adicionales omitidos"
        )
    end

    return true
end

dump_known_array_field = function(obj, field_name, label, max_elements)
    if obj == nil then
        logp("[PawnResearch]   " .. label .. " = NIL (objeto padre NIL)")
        return
    end

    local value = get_field_value_by_name(obj, field_name)

    logp(
        "[PawnResearch]   CAMPO INTERNO CONFIRMADO: "
        .. field_name
        .. " | tipo objetivo="
        .. tostring(object_type_name(value))
        .. " | valor="
        .. value_to_string(value)
    )

    if not dump_array_object(value, label, max_elements) then
        logp(
            "[PawnResearch]     No se pudo abrir "
            .. label
            .. " como System.Array"
        )
    end
end

dump_all_array_like_fields = function(obj, label, max_elements)
    if obj == nil then return end

    logp(
        "[PawnResearch]   ---- BUSQUEDA DE ARRAYS EN: "
        .. label
        .. " ----"
    )

    local fields = list_all_field_names(obj)
    for _, f in ipairs(fields) do
        local value = get_field_value_by_name(obj, f.name)

        if value ~= nil then
            local elements = safe(function() return value:get_elements() end)
            if elements ~= nil then
                dump_array_object(
                    value,
                    label .. "::" .. f.name,
                    max_elements
                )
            end
        end
    end
end


-- ============================================================
-- PASO 93: diagnostico SOLO LECTURA de las tablas que alimentan la escala.
--
-- PASO 92 confirmo tres estructuras relevantes dentro de BodyEditorRoot:
--   _ApplyEditValues  -> Dictionary<UInt32,FusionValue>
--   _ApplyEditScales  -> Dictionary<UInt32,Dictionary<UInt32,JointEditData>>
--   _BodyScale        -> Dictionary<BodyScaleKey,via.vec3>
--
-- Aqui no se escribe ninguna de ellas. Primero se inspeccionan sus metodos
-- reales por reflexion y, solo si una API de diccionario queda confirmada,
-- se leen Count/Keys/Item. Tambien se enumeran los valores reales del enum
-- BodyScaleKey y se consulta getBodyScale() con esos valores confirmados.
-- ============================================================

paso93_tiene_metodo = function(obj, wanted_name)
    if obj == nil then return false end
    local methods = safe(function() return obj:get_type_definition():get_methods() end) or {}
    for _, method in ipairs(methods) do
        local method_name = safe(function() return method:get_name() end)
        if method_name == wanted_name then
            return true
        end
    end
    return false
end

paso93_log_dict = function(dict_obj, label, max_items)
    if dict_obj == nil then
        logp("[PawnResearch] PASO 93 " .. label .. " = nil")
        return
    end

    logp("[PawnResearch] PASO 93 " .. label .. " tipo=" .. object_type_name(dict_obj))
    dump_all_method_signatures(dict_obj, "PASO 93 " .. label .. " METODOS")

    local has_count = paso93_tiene_metodo(dict_obj, "get_Count")
    local has_keys = paso93_tiene_metodo(dict_obj, "get_Keys")
    local has_item = paso93_tiene_metodo(dict_obj, "get_Item")

    logp("[PawnResearch] PASO 93 " .. label .. " CAPACIDADES get_Count="
        .. tostring(has_count) .. " get_Keys=" .. tostring(has_keys)
        .. " get_Item=" .. tostring(has_item))

    local count = nil
    if has_count then
        count = safe_call(dict_obj, "get_Count")
        logp("[PawnResearch] PASO 93 " .. label .. " COUNT=" .. tostring(count))
    end

    if not has_keys then
        logp("[PawnResearch] PASO 93 " .. label .. " SIN get_Keys confirmable")
        return
    end

    local keys = safe_call(dict_obj, "get_Keys")
    if keys == nil then
        logp("[PawnResearch] PASO 93 " .. label .. " get_Keys devolvio nil")
        return
    end

    logp("[PawnResearch] PASO 93 " .. label .. " KEYS tipo=" .. object_type_name(keys))
    local key_elements = safe(function() return keys:get_elements() end)
    local key_size = safe(function() return keys:get_size() end)
    if key_elements == nil then
        logp("[PawnResearch] PASO 93 " .. label .. " KEYS no expone get_elements")
        return
    end
    if key_size == nil then
        key_size = #key_elements
    end

    local limit = key_size
    if max_items ~= nil then limit = math.min(limit, max_items) end

    for i = 1, limit do
        local key = key_elements[i]
        logp("[PawnResearch] PASO 93 " .. label .. " KEY[" .. tostring(i - 1) .. "]=" .. value_to_string(key))

        if has_item and key ~= nil then
            local item_value = safe_call(dict_obj, "get_Item", key)
            logp("[PawnResearch] PASO 93 " .. label .. " ITEM[" .. tostring(i - 1) .. "]=" .. value_to_string(item_value))

            if item_value ~= nil then
                local item_fields = list_all_field_names(item_value)
                if #item_fields > 0 then
                    dump_all_fields_with_values(
                        item_value,
                        "PASO 93 " .. label .. " ITEM[" .. tostring(i - 1) .. "]"
                    )
                end

                -- Solo abrimos un nivel adicional si el valor vuelve a ser un diccionario.
                if paso93_tiene_metodo(item_value, "get_Keys") then
                    paso93_log_dict(
                        item_value,
                        label .. " ITEM[" .. tostring(i - 1) .. "] NESTED",
                        20
                    )
                end
            end
        end
    end

    if key_size > limit then
        logp("[PawnResearch] PASO 93 " .. label .. " ... " .. tostring(key_size - limit) .. " claves omitidas")
    end
end

paso93_diagnosticar_tablas_escala = function(character)
    if character == nil then
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] ===== PASO 94 TABLAS ESCALA =====")
    logp("[PawnResearch] PASO 93 CID=" .. tostring(cid))

    if cid == nil then
        return false, "CID nil"
    end
    if is_character_protected(cid) then
        logp("[PawnResearch] PASO 93 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 94 TABLAS ESCALA =====")
        return false, "CharacterID protegido"
    end

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 93 PartSwapper=nil")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 93 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    logp("[PawnResearch] PASO 93 BodyEditor tipo=" .. object_type_name(body_editor))
    logp("[PawnResearch] PASO 93 BODYEDITORROOT BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))
    logp("[PawnResearch] PASO 93 BODYEDITORROOT BodyWeight=" .. tostring(safe_call(body_editor, "get_BodyWeight")))
    logp("[PawnResearch] PASO 93 BODYEDITORROOT EditMode=" .. tostring(safe_call(body_editor, "get_EditMode")))
    logp("[PawnResearch] PASO 93 BODYEDITORROOT Binding=" .. tostring(safe_call(body_editor, "get_Binding")))

    local apply_values = get_field_value_by_name(body_editor, "_ApplyEditValues")
    local apply_scales = get_field_value_by_name(body_editor, "_ApplyEditScales")
    local body_scale = get_field_value_by_name(body_editor, "_BodyScale")
    local joint_values = get_field_value_by_name(body_editor, "_JointEditValueDict")

    paso93_log_dict(apply_values, "_ApplyEditValues", 20)
    paso93_log_dict(apply_scales, "_ApplyEditScales", 20)
    paso93_log_dict(body_scale, "_BodyScale", 20)
    paso93_log_dict(joint_values, "_JointEditValueDict", 20)

    logp("[PawnResearch] PASO 93 ---- ENUM BODY SCALE KEY ----")
    local enum_td = safe(function() return sdk.find_type_definition("app.CharacterEditDefine.BodyScaleKey") end)
    if enum_td == nil then
        logp("[PawnResearch] PASO 93 BodyScaleKey type=nil")
    else
        local enum_fields = safe(function() return enum_td:get_fields() end) or {}
        local enum_count = 0
        for _, ef in ipairs(enum_fields) do
            local static_flag = safe(function() return ef:is_static() end)
            if static_flag then
                local enum_name = safe(function() return ef:get_name() end)
                local enum_value = safe(function() return ef:get_data(nil) end)
                if enum_name ~= nil and enum_value ~= nil then
                    enum_count = enum_count + 1
                    logp("[PawnResearch] PASO 93 ENUM BodyScaleKey " .. tostring(enum_name)
                        .. "=" .. value_to_string(enum_value))
                    local got_scale = safe_call(body_editor, "getBodyScale", enum_value)
                    logp("[PawnResearch] PASO 93 GETBODYSCALE " .. tostring(enum_name)
                        .. " -> " .. value_to_string(got_scale))
                end
            end
        end
        logp("[PawnResearch] PASO 93 ENUM BodyScaleKey static_count=" .. tostring(enum_count))
    end

    logp("[PawnResearch] PASO 93 RESULTADO: diagnostico terminado; no hubo escrituras")
    logp("[PawnResearch] ===== FIN PASO 93 TABLAS ESCALA =====")
    return true, "diagnostico terminado"
end


-- ============================================================
-- PASO 94: localizar el registro exacto del EditValue de altura dentro
-- de las tablas internas que BodyEditorRoot usa para aplicar escalas.
-- Solo lectura: no cambia EditValues, BodyScale, Human ni PartSwapper.
-- ============================================================
paso94_inspeccionar_hash_escala = function(character, target_hash)
    logp("[PawnResearch] ===== PASO 94 REGISTRO HASH ESCALA =====")

    if character == nil then
        logp("[PawnResearch] PASO 94 character=nil")
        logp("[PawnResearch] ===== FIN PASO 94 REGISTRO HASH ESCALA =====")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] PASO 94 CID=" .. tostring(cid))
    logp("[PawnResearch] PASO 94 hash_objetivo=" .. tostring(target_hash))

    if cid == nil then
        return false, "CID nil"
    end
    if is_character_protected(cid) then
        logp("[PawnResearch] PASO 94 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 94 REGISTRO HASH ESCALA =====")
        return false, "CharacterID protegido"
    end

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 94 PartSwapper=nil")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 94 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    logp("[PawnResearch] PASO 94 BodyEditor tipo=" .. object_type_name(body_editor))
    logp("[PawnResearch] PASO 94 BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))
    logp("[PawnResearch] PASO 94 BodyWeight=" .. tostring(safe_call(body_editor, "get_BodyWeight")))

    local apply_values = get_field_value_by_name(body_editor, "_ApplyEditValues")
    local apply_scales = get_field_value_by_name(body_editor, "_ApplyEditScales")
    local joint_values = get_field_value_by_name(body_editor, "_JointEditValueDict")

    logp("[PawnResearch] PASO 94 ---- APPLYEDITVALUES TARGET ----")
    if apply_values == nil then
        logp("[PawnResearch] PASO 94 _ApplyEditValues=nil")
    else
        local has_contains = paso93_tiene_metodo(apply_values, "ContainsKey")
        local has_item = paso93_tiene_metodo(apply_values, "get_Item")
        logp("[PawnResearch] PASO 94 _ApplyEditValues ContainsKey=" .. tostring(has_contains)
            .. " get_Item=" .. tostring(has_item))
        if target_hash ~= nil and has_contains then
            local contains = safe_call(apply_values, "ContainsKey", target_hash)
            logp("[PawnResearch] PASO 94 _ApplyEditValues ContainsKey(" .. tostring(target_hash) .. ")=" .. tostring(contains))
            if contains and has_item then
                local fv = safe_call(apply_values, "get_Item", target_hash)
                logp("[PawnResearch] PASO 94 _ApplyEditValues ITEM tipo=" .. value_to_string(fv))
                if fv ~= nil then
                    dump_all_fields_with_values(fv, "PASO 94 FusionValue altura")
                    logp("[PawnResearch] PASO 94 FusionValue METODOS")
                    local fms = list_all_method_names(fv)
                    for _, fm in ipairs(fms) do
                        if string.find(string.lower(fm.name or ""), "value", 1, true)
                            or string.find(string.lower(fm.name or ""), "edit", 1, true)
                            or string.find(string.lower(fm.name or ""), "scale", 1, true) then
                            logp("[PawnResearch]   " .. tostring(fm.declaring_type) .. "::" .. tostring(fm.name))
                        end
                    end
                end
            end
        end
    end

    logp("[PawnResearch] PASO 94 ---- APPLYEDIT SCALES TARGET ----")
    if apply_scales == nil then
        logp("[PawnResearch] PASO 94 _ApplyEditScales=nil")
    else
        local has_contains = paso93_tiene_metodo(apply_scales, "ContainsKey")
        local has_item = paso93_tiene_metodo(apply_scales, "get_Item")
        local count = safe_call(apply_scales, "get_Count")
        logp("[PawnResearch] PASO 94 _ApplyEditScales Count=" .. tostring(count)
            .. " ContainsKey=" .. tostring(has_contains) .. " get_Item=" .. tostring(has_item))

        if target_hash ~= nil and has_contains then
            local contains = safe_call(apply_scales, "ContainsKey", target_hash)
            logp("[PawnResearch] PASO 94 _ApplyEditScales ContainsKey(" .. tostring(target_hash) .. ")=" .. tostring(contains))
            if contains and has_item then
                local nested = safe_call(apply_scales, "get_Item", target_hash)
                logp("[PawnResearch] PASO 94 _ApplyEditScales TARGET tipo=" .. value_to_string(nested))
                if nested ~= nil then
                    logp("[PawnResearch] PASO 94 NESTED TYPE=" .. object_type_name(nested))
                    logp("[PawnResearch] PASO 94 NESTED COUNT=" .. tostring(safe_call(nested, "get_Count")))

                    local nd = safe(function() return nested:get_type_definition() end)
                    if nd ~= nil then
                        logp("[PawnResearch] PASO 94 NESTED METODOS")
                        local nms = safe(function() return nd:get_methods() end) or {}
                        for _, nm in ipairs(nms) do
                            local mn = safe(function() return nm:get_name() end)
                            if mn == "GetEnumerator" or mn == "get_Item" or mn == "ContainsKey" then
                                logp("[PawnResearch]   " .. tostring(mn))
                            end
                        end
                    end

                    local enumerator = safe_call(nested, "GetEnumerator")
                    if enumerator ~= nil then
                        local pair_count = 0
                        logp("[PawnResearch] PASO 94 NESTED ENUMERADOR OK tipo=" .. object_type_name(enumerator))
                        while pair_count < 30 do
                            local moved = safe_call(enumerator, "MoveNext")
                            if moved ~= true then break end
                            local pair = safe_call(enumerator, "get_Current")
                            if pair == nil then break end
                            local pair_key = safe_call(pair, "get_Key")
                            local pair_value = safe_call(pair, "get_Value")
                            logp("[PawnResearch] PASO 94 JOINTDATA[" .. tostring(pair_count) .. "] joint_hash="
                                .. tostring(pair_key) .. " value=" .. value_to_string(pair_value))
                            if pair_value ~= nil then
                                dump_all_fields_with_values(
                                    pair_value,
                                    "PASO 94 JointEditData joint_hash=" .. tostring(pair_key)
                                )
                            end
                            pair_count = pair_count + 1
                        end
                        logp("[PawnResearch] PASO 94 NESTED ENUMERADOS=" .. tostring(pair_count))
                    else
                        logp("[PawnResearch] PASO 94 NESTED GetEnumerator devolvio nil")
                    end
                end
            end
        end
    end

    logp("[PawnResearch] PASO 94 ---- JOINTEDITVALUEDICT TARGET ----")
    if joint_values == nil then
        logp("[PawnResearch] PASO 94 _JointEditValueDict=nil")
    else
        local has_contains = paso93_tiene_metodo(joint_values, "ContainsKey")
        local has_item = paso93_tiene_metodo(joint_values, "get_Item")
        logp("[PawnResearch] PASO 94 _JointEditValueDict Count=" .. tostring(safe_call(joint_values, "get_Count"))
            .. " ContainsKey=" .. tostring(has_contains) .. " get_Item=" .. tostring(has_item))
        if target_hash ~= nil and has_contains then
            local contains = safe_call(joint_values, "ContainsKey", target_hash)
            logp("[PawnResearch] PASO 94 _JointEditValueDict ContainsKey(" .. tostring(target_hash) .. ")=" .. tostring(contains))
            if contains and has_item then
                local jv = safe_call(joint_values, "get_Item", target_hash)
                logp("[PawnResearch] PASO 94 JointEditValue TARGET=" .. value_to_string(jv))
                if jv ~= nil then
                    dump_all_fields_with_values(jv, "PASO 94 JointEditValue altura")
                    logp("[PawnResearch] PASO 94 JointEditValue METODOS")
                    local jms = list_all_method_names(jv)
                    for _, jm in ipairs(jms) do
                        logp("[PawnResearch]   " .. tostring(jm.declaring_type) .. "::" .. tostring(jm.name))
                    end
                end
            end
        end
    end

    logp("[PawnResearch] PASO 94 RESULTADO: diagnostico de registro terminado; no hubo escrituras")
    logp("[PawnResearch] ===== FIN PASO 94 REGISTRO HASH ESCALA =====")
    return true, "diagnostico terminado"
end


-- ============================================================
-- PASO 96: probar el setter nativo de BodyEditorRoot usando el BodyEditID
-- confirmado por reflexion para General_Height_Height. Se prueban los dos
-- valores del tercer parametro BOOL sin asumir su significado. No se escribe
-- ningun campo directo de Human y el destino se protege por CharacterID.
paso96_probar_bodyeditor_set_editvalue = function(character, template_name)
    logp("[PawnResearch] ===== PASO 96 BODYEDITOR SETEDITVALUE =====")

    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] PASO 96 CID=" .. tostring(cid))

    if cid == nil or is_character_protected(cid) then
        logp("[PawnResearch] PASO 96 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 96 BODYEDITOR SETEDITVALUE =====")
        return false, "CID bloqueado"
    end

    local template = paso82_load_template(template_name)
    if template == nil then
        logp("[PawnResearch] PASO 96 plantilla=nil")
        logp("[PawnResearch] ===== FIN PASO 96 BODYEDITOR SETEDITVALUE =====")
        return false, "No se pudo cargar la plantilla"
    end

    local height_hash, expected_height = paso82_find_height_hash(template)
    if height_hash == nil then
        logp("[PawnResearch] PASO 96 altura hash=nil")
        logp("[PawnResearch] ===== FIN PASO 96 BODYEDITOR SETEDITVALUE =====")
        return false, tostring(expected_height)
    end

    logp("[PawnResearch] PASO 96 altura_hash=" .. tostring(height_hash) .. " altura_esperada=" .. tostring(expected_height))

    local ps = get_part_swapper(character)
    local body_editor = ps and get_field_value_by_name(ps, "_BodyEditor") or nil
    if body_editor == nil then
        logp("[PawnResearch] PASO 96 BodyEditor=nil")
        logp("[PawnResearch] ===== FIN PASO 96 BODYEDITOR SETEDITVALUE =====")
        return false, "BodyEditor nil"
    end

    logp("[PawnResearch] PASO 96 BodyEditor tipo=" .. tostring(object_type_name(body_editor)))

    local edit_id_td = safe(function() return sdk.find_type_definition("app.BodyEditID") end)
    if edit_id_td == nil then
        logp("[PawnResearch] PASO 96 app.BodyEditID type=nil")
        logp("[PawnResearch] ===== FIN PASO 96 BODYEDITOR SETEDITVALUE =====")
        return false, "BodyEditID type nil"
    end

    local edit_id = nil
    local fields = safe(function() return edit_id_td:get_fields() end) or {}
    for _, field in ipairs(fields) do
        local is_static = safe(function() return field:is_static() end)
        if is_static then
            local name = safe(function() return field:get_name() end)
            local value = safe(function() return field:get_data(nil) end)
            if name == "General_Height_Height" and value ~= nil then
                edit_id = value
                break
            end
        end
    end

    if edit_id == nil then
        logp("[PawnResearch] PASO 96 no se encontro BodyEditID.General_Height_Height")
        logp("[PawnResearch] ===== FIN PASO 96 BODYEDITOR SETEDITVALUE =====")
        return false, "General_Height_Height nil"
    end

    logp("[PawnResearch] PASO 96 BodyEditID General_Height_Height=" .. value_to_string(edit_id))

    local set_method = paso82_find_body_edit_method(
        body_editor,
        "setEditValue",
        { "app.BodyEditID", "System.Single", "System.Boolean" },
        "System.Void"
    )
    if set_method == nil then
        logp("[PawnResearch] PASO 96 setEditValue(BodyEditID,Single,Boolean) NO confirmado")
        logp("[PawnResearch] ===== FIN PASO 96 BODYEDITOR SETEDITVALUE =====")
        return false, "Setter BodyEditorRoot no confirmado"
    end

    local get_method = paso82_find_body_edit_method(
        body_editor,
        "getEditValue",
        { "app.BodyEditID" },
        "System.Single"
    )

    if get_method == nil then
        logp("[PawnResearch] PASO 96 getEditValue(BodyEditID) NO confirmado")
        logp("[PawnResearch] ===== FIN PASO 96 BODYEDITOR SETEDITVALUE =====")
        return false, "Getter BodyEditorRoot no confirmado"
    end

    local before = safe_call(body_editor, "getEditValue", edit_id)
    logp("[PawnResearch] PASO 96 ANTES BodyEditor.getEditValue=" .. tostring(before))
    logp("[PawnResearch] PASO 96 ANTES BodyEditor.BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))

    local function aplicar(flag)
        local ok, err = pcall(function()
            body_editor:call("setEditValue", edit_id, expected_height, flag)
        end)
        logp("[PawnResearch] PASO 96 SETEDITVALUE bool=" .. tostring(flag) .. " ok=" .. tostring(ok) .. (ok and "" or (" error=" .. tostring(err))))
        logp("[PawnResearch] PASO 96 DESPUES bool=" .. tostring(flag)
            .. " getEditValue=" .. tostring(safe_call(body_editor, "getEditValue", edit_id))
            .. " BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))
        return ok
    end

    local ok_false = aplicar(false)
    local value_false = safe_call(body_editor, "getEditValue", edit_id)
    local height_false = safe_call(body_editor, "get_BodyHeight")

    local ok_true = aplicar(true)
    local value_true = safe_call(body_editor, "getEditValue", edit_id)
    local height_true = safe_call(body_editor, "get_BodyHeight")

    local fresh_ps = get_part_swapper(character)
    local fresh_editor = fresh_ps and get_field_value_by_name(fresh_ps, "_BodyEditor") or nil
    local fresh_value = fresh_editor and safe_call(fresh_editor, "getEditValue", edit_id) or nil
    local fresh_height = fresh_editor and safe_call(fresh_editor, "get_BodyHeight") or nil

    logp("[PawnResearch] PASO 96 FRESCA getEditValue=" .. tostring(fresh_value) .. " BodyHeight=" .. tostring(fresh_height))
    logp("[PawnResearch] PASO 96 RESULTADO false_ok=" .. tostring(ok_false)
        .. " false_value=" .. tostring(value_false)
        .. " false_height=" .. tostring(height_false)
        .. " true_ok=" .. tostring(ok_true)
        .. " true_value=" .. tostring(value_true)
        .. " true_height=" .. tostring(height_true))
    logp("[PawnResearch] PASO 96 NOTA: no se escribio Human.BodyHeight, Human.Scale, ScaleY, BodyWeight; no se uso applyEditModel/setupScale/updateScale ni PartSwapper.swap*")
    logp("[PawnResearch] ===== FIN PASO 96 BODYEDITOR SETEDITVALUE =====")

    return true, "Prueba terminada; revisar log."
end


-- ============================================================
-- PASO 97: llamada directa a setEditValue de BodyEditorRoot.
-- La firma ya fue confirmada por reflexion en PASO 84.
-- Este paso no usa el helper estricto de firmas de PASO 96.
-- El destino sigue protegido por CharacterID.
-- ============================================================
paso97_probar_set_editvalue_directo = function(character, template_name)
    logp("[PawnResearch] ===== PASO 97 SETEDITVALUE DIRECTO =====")

    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] PASO 97 CID=" .. tostring(cid))

    if cid == nil or is_character_protected(cid) then
        logp("[PawnResearch] PASO 97 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 97 SETEDITVALUE DIRECTO =====")
        return false, "CID bloqueado"
    end

    local template = paso82_load_template(template_name)
    if template == nil then
        logp("[PawnResearch] PASO 97 plantilla=nil")
        logp("[PawnResearch] ===== FIN PASO 97 SETEDITVALUE DIRECTO =====")
        return false, "No se pudo cargar la plantilla"
    end

    local height_hash, expected_height = paso82_find_height_hash(template)
    if height_hash == nil then
        logp("[PawnResearch] PASO 97 altura hash=nil")
        logp("[PawnResearch] ===== FIN PASO 97 SETEDITVALUE DIRECTO =====")
        return false, tostring(expected_height)
    end

    logp("[PawnResearch] PASO 97 altura_hash=" .. tostring(height_hash)
        .. " altura_esperada=" .. tostring(expected_height))

    local ps = get_part_swapper(character)
    local body_editor = ps and get_field_value_by_name(ps, "_BodyEditor") or nil
    if body_editor == nil then
        logp("[PawnResearch] PASO 97 BodyEditor=nil")
        logp("[PawnResearch] ===== FIN PASO 97 SETEDITVALUE DIRECTO =====")
        return false, "BodyEditor nil"
    end

    local edit_id_td = safe(function() return sdk.find_type_definition("app.BodyEditID") end)
    if edit_id_td == nil then
        logp("[PawnResearch] PASO 97 app.BodyEditID type=nil")
        logp("[PawnResearch] ===== FIN PASO 97 SETEDITVALUE DIRECTO =====")
        return false, "BodyEditID type nil"
    end

    local edit_id = nil
    local fields = safe(function() return edit_id_td:get_fields() end) or {}
    for _, field in ipairs(fields) do
        local is_static = safe(function() return field:is_static() end)
        if is_static then
            local name = safe(function() return field:get_name() end)
            if name == "General_Height_Height" then
                edit_id = safe(function() return field:get_data(nil) end)
                break
            end
        end
    end

    if edit_id == nil then
        logp("[PawnResearch] PASO 97 BodyEditID.General_Height_Height=nil")
        logp("[PawnResearch] ===== FIN PASO 97 SETEDITVALUE DIRECTO =====")
        return false, "General_Height_Height nil"
    end

    logp("[PawnResearch] PASO 97 BodyEditID=" .. value_to_string(edit_id))
    logp("[PawnResearch] PASO 97 ANTES getEditValue=" .. tostring(safe_call(body_editor, "getEditValue", edit_id)))
    logp("[PawnResearch] PASO 97 ANTES BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))

    local ok_false, err_false = pcall(function()
        body_editor:call("setEditValue", edit_id, expected_height, false)
    end)
    logp("[PawnResearch] PASO 97 SETEDITVALUE false ok=" .. tostring(ok_false)
        .. (ok_false and "" or (" error=" .. tostring(err_false))))
    logp("[PawnResearch] PASO 97 DESPUES false getEditValue="
        .. tostring(safe_call(body_editor, "getEditValue", edit_id))
        .. " BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))

    local ok_true, err_true = pcall(function()
        body_editor:call("setEditValue", edit_id, expected_height, true)
    end)
    logp("[PawnResearch] PASO 97 SETEDITVALUE true ok=" .. tostring(ok_true)
        .. (ok_true and "" or (" error=" .. tostring(err_true))))
    logp("[PawnResearch] PASO 97 DESPUES true getEditValue="
        .. tostring(safe_call(body_editor, "getEditValue", edit_id))
        .. " BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))

    local fresh_ps = get_part_swapper(character)
    local fresh_editor = fresh_ps and get_field_value_by_name(fresh_ps, "_BodyEditor") or nil
    local fresh_value = fresh_editor and safe_call(fresh_editor, "getEditValue", edit_id) or nil
    local fresh_height = fresh_editor and safe_call(fresh_editor, "get_BodyHeight") or nil

    logp("[PawnResearch] PASO 97 FRESCA getEditValue=" .. tostring(fresh_value)
        .. " BodyHeight=" .. tostring(fresh_height))
    logp("[PawnResearch] PASO 97 RESULTADO false_ok=" .. tostring(ok_false)
        .. " true_ok=" .. tostring(ok_true)
        .. " false_err=" .. tostring(err_false)
        .. " true_err=" .. tostring(err_true))
    logp("[PawnResearch] PASO 97 NOTA: no se escribio Human.BodyHeight, Human.Scale, ScaleY, BodyWeight; no se uso applyEditModel/setupScale/updateScale ni PartSwapper.swap*")
    logp("[PawnResearch] ===== FIN PASO 97 SETEDITVALUE DIRECTO =====")

    return true, "Prueba terminada; revisar log."
end


-- ============================================================
-- PASO 98: diagnostico del efecto real de BodyEditorRoot.setEditValue.
-- Repite la llamada ya confirmada, pero inspecciona el FusionValue
-- de General_Height_Height despues de cada intento.
-- No modifica Human ni llama rutas de escala.
-- ============================================================
paso98_diagnosticar_set_editvalue_interno = function(character, template_name)
    logp("[PawnResearch] ===== PASO 98 EFECTO INTERNO SETEDITVALUE =====")

    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] PASO 98 CID=" .. tostring(cid))

    if cid == nil or is_character_protected(cid) then
        logp("[PawnResearch] PASO 98 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 98 EFECTO INTERNO SETEDITVALUE =====")
        return false, "CID bloqueado"
    end

    local template = paso82_load_template(template_name)
    if template == nil then
        logp("[PawnResearch] PASO 98 plantilla=nil")
        logp("[PawnResearch] ===== FIN PASO 98 EFECTO INTERNO SETEDITVALUE =====")
        return false, "No se pudo cargar la plantilla"
    end

    local height_hash, expected_height = paso82_find_height_hash(template)
    if height_hash == nil then
        logp("[PawnResearch] PASO 98 altura hash=nil")
        logp("[PawnResearch] ===== FIN PASO 98 EFECTO INTERNO SETEDITVALUE =====")
        return false, tostring(expected_height)
    end

    local ps = get_part_swapper(character)
    local body_editor = ps and get_field_value_by_name(ps, "_BodyEditor") or nil
    if body_editor == nil then
        logp("[PawnResearch] PASO 98 BodyEditor=nil")
        logp("[PawnResearch] ===== FIN PASO 98 EFECTO INTERNO SETEDITVALUE =====")
        return false, "BodyEditor nil"
    end

    local edit_id_td = safe(function() return sdk.find_type_definition("app.BodyEditID") end)
    if edit_id_td == nil then
        logp("[PawnResearch] PASO 98 app.BodyEditID type=nil")
        logp("[PawnResearch] ===== FIN PASO 98 EFECTO INTERNO SETEDITVALUE =====")
        return false, "BodyEditID type nil"
    end

    local edit_id = nil
    local fields = safe(function() return edit_id_td:get_fields() end) or {}
    for _, field in ipairs(fields) do
        if safe(function() return field:is_static() end) then
            local name = safe(function() return field:get_name() end)
            if name == "General_Height_Height" then
                edit_id = safe(function() return field:get_data(nil) end)
                break
            end
        end
    end

    if edit_id == nil then
        logp("[PawnResearch] PASO 98 BodyEditID.General_Height_Height=nil")
        logp("[PawnResearch] ===== FIN PASO 98 EFECTO INTERNO SETEDITVALUE =====")
        return false, "General_Height_Height nil"
    end

    local edit_dict = safe_call(body_editor, "getEditValue")
    local edit_fusion = edit_dict and safe_call(edit_dict, "get_Item", height_hash) or nil

    logp("[PawnResearch] PASO 98 altura_hash=" .. tostring(height_hash)
        .. " altura_esperada=" .. tostring(expected_height))
    logp("[PawnResearch] PASO 98 BodyEditID=" .. value_to_string(edit_id))
    logp("[PawnResearch] PASO 98 ANTES BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))
    logp("[PawnResearch] PASO 98 ANTES FusionValue=" .. value_to_string(edit_fusion))
    if edit_fusion ~= nil then
        dump_all_fields_with_values(edit_fusion, "PASO 98 FusionValue ANTES")
    end

    local function inspeccionar(etiqueta)
        local dict = safe_call(body_editor, "getEditValue")
        local fusion = dict and safe_call(dict, "get_Item", height_hash) or nil
        logp("[PawnResearch] PASO 98 " .. etiqueta .. " BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))
        logp("[PawnResearch] PASO 98 " .. etiqueta .. " FusionValue=" .. value_to_string(fusion))
        if fusion ~= nil then
            dump_all_fields_with_values(fusion, "PASO 98 FusionValue " .. etiqueta)
        end
        return fusion
    end

    local ok_false, err_false = pcall(function()
        body_editor:call("setEditValue", edit_id, expected_height, false)
    end)
    logp("[PawnResearch] PASO 98 SETEDITVALUE false ok=" .. tostring(ok_false)
        .. (ok_false and "" or (" error=" .. tostring(err_false))))
    local fusion_false = inspeccionar("DESPUES FALSE")

    local ok_true, err_true = pcall(function()
        body_editor:call("setEditValue", edit_id, expected_height, true)
    end)
    logp("[PawnResearch] PASO 98 SETEDITVALUE true ok=" .. tostring(ok_true)
        .. (ok_true and "" or (" error=" .. tostring(err_true))))
    local fusion_true = inspeccionar("DESPUES TRUE")

    local fresh_ps = get_part_swapper(character)
    local fresh_editor = fresh_ps and get_field_value_by_name(fresh_ps, "_BodyEditor") or nil
    local fresh_dict = fresh_editor and safe_call(fresh_editor, "getEditValue") or nil
    local fresh_fusion = fresh_dict and safe_call(fresh_dict, "get_Item", height_hash) or nil

    logp("[PawnResearch] PASO 98 FRESCA BodyHeight=" .. tostring(fresh_editor and safe_call(fresh_editor, "get_BodyHeight") or nil))
    logp("[PawnResearch] PASO 98 FRESCA FusionValue=" .. value_to_string(fresh_fusion))
    if fresh_fusion ~= nil then
        dump_all_fields_with_values(fresh_fusion, "PASO 98 FusionValue FRESCA")
    end

    logp("[PawnResearch] PASO 98 RESULTADO false_ok=" .. tostring(ok_false)
        .. " true_ok=" .. tostring(ok_true)
        .. " false_err=" .. tostring(err_false)
        .. " true_err=" .. tostring(err_true)
        .. " fusion_false=" .. value_to_string(fusion_false)
        .. " fusion_true=" .. value_to_string(fusion_true)
        .. " fusion_fresca=" .. value_to_string(fresh_fusion))
    logp("[PawnResearch] PASO 98 NOTA: no se escribio Human.BodyHeight, Human.Scale, ScaleY, BodyWeight; no se uso applyEditModel/setupScale/updateScale ni PartSwapper.swap*")
    logp("[PawnResearch] ===== FIN PASO 98 EFECTO INTERNO SETEDITVALUE =====")

    return true, "Prueba terminada; revisar log."
end


-- ============================================================
-- PASO 100: prueba controlada de BodyEditor.restore(EditValue[]).
-- Usa el array real de EditValues del BodyEditor, cambia SOLO la entrada de
-- altura confirmada y llama restore(EditValue[]). No escribe Human ni usa
-- setupScale/updateScale, applyEditModel ni PartSwapper.swap*.
-- ============================================================
function paso100_probar_restore_editvalues_altura(character, template_name)
    if character == nil then
        logp("[PawnResearch] PASO 100: character nil")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    if cid == nil or is_character_protected(cid) then
        logp("[PawnResearch] PASO 100 BLOQUEADO CID=" .. tostring(cid))
        return false, "CharacterID protegido o nil"
    end

    local payload, load_err = paso82_load_template(template_name)
    if payload == nil then
        logp("[PawnResearch] PASO 100 TEMPLATE ERROR=" .. tostring(load_err))
        return false, load_err
    end

    local expected_height = nil
    if payload.body_scale_detail ~= nil then
        expected_height = tonumber(payload.body_scale_detail.BodyHeight)
    end
    if expected_height == nil then
        logp("[PawnResearch] PASO 100: plantilla sin body_scale_detail.BodyHeight")
        return false, "plantilla sin BodyHeight"
    end

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 100 PartSwapper=nil")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 100 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    local human = get_human(character)
    local calc = nil
    if human ~= nil then
        calc = safe(function() return human:get_RootTransScaleCalculator() end)
    end

    logp("[PawnResearch] ===== PASO 100 RESTORE EDITVALUES =====")
    logp("[PawnResearch] PASO 100 CID=" .. tostring(cid))
    logp("[PawnResearch] PASO 100 altura_esperada=" .. tostring(expected_height))
    logp("[PawnResearch] PASO 100 ANTES BodyHeight=" .. tostring(safe(function() return body_editor:get_BodyHeight() end)))

    local edit_values = safe(function() return body_editor:getEditValues() end)
    if edit_values == nil then
        logp("[PawnResearch] PASO 100 getEditValues=nil")
        logp("[PawnResearch] ===== FIN PASO 100 RESTORE EDITVALUES =====")
        return false, "getEditValues nil"
    end

    local count = safe(function() return edit_values:get_size() end)
    logp("[PawnResearch] PASO 100 EditValues tipo=" .. object_type_name(edit_values) .. " size=" .. tostring(count))

    local height_found = false
    local height_before = nil
    local safe_count = tonumber(count) or 0
    for i = 0, safe_count - 1 do
        local ev = safe(function() return edit_values:get_element(i) end)
        if ev ~= nil then
            local hash = get_field_value_by_name(ev, "_EditKeyHash")
            if tostring(hash) == "1497737450" then
                height_found = true
                height_before = get_field_value_by_name(ev, "_Value")
                logp("[PawnResearch] PASO 100 ALTURA EditValue index=" .. tostring(i)
                    .. " hash=" .. tostring(hash) .. " antes=" .. tostring(height_before))

                local write_ok, write_err = pcall(function()
                    ev:set_field("_Value", expected_height)
                end)
                logp("[PawnResearch] PASO 100 ALTURA EditValue WRITE ok=" .. tostring(write_ok)
                    .. " err=" .. tostring(write_err)
                    .. " despues=" .. tostring(get_field_value_by_name(ev, "_Value")))
                break
            end
        end
    end

    if not height_found then
        logp("[PawnResearch] PASO 100 ALTURA EditValue no encontrado en getEditValues()")
        logp("[PawnResearch] ===== FIN PASO 100 RESTORE EDITVALUES =====")
        return false, "EditValue altura no encontrado"
    end

    local restore_ok, restore_err = pcall(function()
        body_editor:restore(edit_values)
    end)
    logp("[PawnResearch] PASO 100 RESTORE(EditValue[]) ok=" .. tostring(restore_ok)
        .. " err=" .. tostring(restore_err))

    local after_editor_height = safe(function() return body_editor:get_BodyHeight() end)
    local after_scale = nil
    local after_scale_y = nil
    local after_weight = nil
    local after_calc_scale = nil
    if human ~= nil then
        after_scale = safe(function() return human:get_Scale() end)
        after_scale_y = get_field_value_by_name(human, "ScaleY")
        after_weight = get_field_value_by_name(human, "BodyWeight")
    end
    if calc ~= nil then
        after_calc_scale = safe(function() return calc:get_Scale() end)
    end

    logp("[PawnResearch] PASO 100 DESPUES BodyHeight=" .. tostring(after_editor_height))
    logp("[PawnResearch] PASO 100 DESPUES human.Scale=" .. tostring(after_scale)
        .. " ScaleY=" .. tostring(after_scale_y)
        .. " BodyWeight=" .. tostring(after_weight))
    logp("[PawnResearch] PASO 100 DESPUES calculator.Scale=" .. tostring(after_calc_scale))

    local fresh_character = nil
    local pm = get_pawn_manager()
    local fresh_list = nil
    if pm ~= nil then
        fresh_list = safe_call(pm, "get_PawnCharacterList")
    end
    if fresh_list ~= nil then
        local fresh_count = safe_call(fresh_list, "get_Count") or 0
        for i = 0, fresh_count - 1 do
            local candidate = safe_call(fresh_list, "get_Item", i)
            if candidate ~= nil then
                local candidate_id = get_field_value_by_name(candidate, "CharacterID")
                if tostring(candidate_id) == tostring(cid) then
                    fresh_character = candidate
                    break
                end
            end
        end
    end

    local fresh_editor = nil
    local fresh_human = nil
    local fresh_calc = nil
    if fresh_character ~= nil then
        fresh_human = get_human(fresh_character)
        if fresh_human ~= nil then
            fresh_calc = safe(function() return fresh_human:get_RootTransScaleCalculator() end)
        end
        local fresh_ps = get_part_swapper(fresh_character)
        if fresh_ps ~= nil then
            fresh_editor = get_field_value_by_name(fresh_ps, "_BodyEditor")
        end
    end

    local fresh_height = nil
    local fresh_scale = nil
    local fresh_scale_y = nil
    local fresh_weight = nil
    local fresh_calc_scale = nil
    if fresh_editor ~= nil then
        fresh_height = safe(function() return fresh_editor:get_BodyHeight() end)
    end
    if fresh_human ~= nil then
        fresh_scale = safe(function() return fresh_human:get_Scale() end)
        fresh_scale_y = get_field_value_by_name(fresh_human, "ScaleY")
        fresh_weight = get_field_value_by_name(fresh_human, "BodyWeight")
    end
    if fresh_calc ~= nil then
        fresh_calc_scale = safe(function() return fresh_calc:get_Scale() end)
    end

    logp("[PawnResearch] PASO 100 FRESCA BodyHeight=" .. tostring(fresh_height)
        .. " human.Scale=" .. tostring(fresh_scale)
        .. " ScaleY=" .. tostring(fresh_scale_y)
        .. " BodyWeight=" .. tostring(fresh_weight)
        .. " calculator.Scale=" .. tostring(fresh_calc_scale))

    if restore_ok and after_editor_height == expected_height then
        logp("[PawnResearch] PASO 100 RESULTADO: restore(EditValue[]) acepto el array y BodyHeight queda en la altura esperada")
    else
        logp("[PawnResearch] PASO 100 RESULTADO: restore(EditValue[]) no dejo BodyHeight en la altura esperada")
    end

    logp("[PawnResearch] PASO 100 NOTA: no se escribio Human.BodyHeight, Human.Scale, ScaleY o BodyWeight; no se uso applyEditModel/setupScale/updateScale ni PartSwapper.swap*")
    logp("[PawnResearch] ===== FIN PASO 100 RESTORE EDITVALUES =====")
    return true, "restore(EditValue[]) terminado"
end


-- ============================================================
-- ============================================================
-- PASO 101: probar la actualizacion nativa de FusionValue para altura.
--
-- El diagnostico anterior mostro un estado desacoplado:
--   FusionValue._Value = 161
--   FusionValue._RawValue = 161
--   pero FusionValue._Ratio seguia con el ratio de 200.
--
-- Esta prueba usa SOLO setters/metodos confirmados por reflexion:
--   set_RawValue(Single)
--   updateValue()
--   updateValueIgnoreParent()
-- y despues prueba applyEdit() para ver si el ratio recalculado
-- alimenta la altura/escala real.
--
-- No escribe Human directamente ni usa PartSwapper.swap*.
-- ============================================================
paso101_probar_update_fusionvalue_altura = function(character, template_name)
    if character == nil then
        logp("[PawnResearch] PASO 101 character=nil")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] ===== PASO 101 FUSIONVALUE ALTURA =====")
    logp("[PawnResearch] PASO 101 CID=" .. tostring(cid))

    if cid == nil or is_character_protected(cid) then
        logp("[PawnResearch] PASO 101 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 101 FUSIONVALUE ALTURA =====")
        return false, "CharacterID protegido"
    end

    local payload, load_err = paso82_load_template(template_name)
    if payload == nil then
        logp("[PawnResearch] PASO 101 TEMPLATE ERROR=" .. tostring(load_err))
        logp("[PawnResearch] ===== FIN PASO 101 FUSIONVALUE ALTURA =====")
        return false, load_err
    end

    local expected_height = nil
    if payload.body_scale_detail ~= nil then
        expected_height = tonumber(payload.body_scale_detail.BodyHeight)
    end
    if expected_height == nil then
        logp("[PawnResearch] PASO 101 plantilla sin body_scale_detail.BodyHeight")
        return false, "plantilla sin BodyHeight"
    end

    local height_hash = 1497737450
    logp("[PawnResearch] PASO 101 altura_hash=" .. tostring(height_hash)
        .. " altura_esperada=" .. tostring(expected_height))

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 101 PartSwapper=nil")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 101 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    local human = get_human(character)
    local calc = human ~= nil
        and safe(function() return human:get_RootTransScaleCalculator() end)
        or nil

    local edit_dict = safe(function() return body_editor:getEditValue() end)
    if edit_dict == nil then
        logp("[PawnResearch] PASO 101 BodyEditor.getEditValue() dictionary=nil")
        return false, "edit dictionary nil"
    end

    local fusion = safe_call(edit_dict, "get_Item", height_hash)
    if fusion == nil then
        logp("[PawnResearch] PASO 101 FusionValue altura=nil")
        return false, "FusionValue altura nil"
    end

    local function fusion_snapshot(label)
        local value = safe_call(fusion, "get_Value")
        local raw_value = safe_call(fusion, "get_RawValue")
        local ratio = get_field_value_by_name(fusion, "_Ratio")
        local raw_ratio = get_field_value_by_name(fusion, "<RawRatio>k__BackingField")
        local last_ratio = get_field_value_by_name(fusion, "<LastRatio>k__BackingField")
        logp("[PawnResearch] PASO 101 " .. label
            .. " Value=" .. tostring(value)
            .. " RawValue=" .. tostring(raw_value)
            .. " Ratio=" .. tostring(ratio)
            .. " RawRatio=" .. tostring(raw_ratio)
            .. " LastRatio=" .. tostring(last_ratio))
    end

    local before_height = safe_call(body_editor, "get_BodyHeight")
    local before_scale = human and safe(function() return human:get_Scale() end) or nil
    local before_scale_y = human and get_field_value_by_name(human, "ScaleY") or nil
    local before_weight = human and get_field_value_by_name(human, "BodyWeight") or nil
    local before_calc_scale = calc and safe(function() return calc:get_Scale() end) or nil

    logp("[PawnResearch] PASO 101 ANTES BodyHeight=" .. tostring(before_height)
        .. " Human.Scale=" .. tostring(before_scale)
        .. " ScaleY=" .. tostring(before_scale_y)
        .. " BodyWeight=" .. tostring(before_weight))
    logp("[PawnResearch] PASO 101 ANTES calculator.Scale=" .. tostring(before_calc_scale))
    fusion_snapshot("FUSION ANTES")

    local set_raw_ok, set_raw_err = pcall(function()
        fusion:set_RawValue(expected_height)
    end)
    logp("[PawnResearch] PASO 101 set_RawValue(" .. tostring(expected_height)
        .. ") ok=" .. tostring(set_raw_ok)
        .. " err=" .. tostring(set_raw_err))
    fusion_snapshot("FUSION DESPUES set_RawValue")

    local update_ok, update_err = pcall(function()
        fusion:updateValue()
    end)
    logp("[PawnResearch] PASO 101 updateValue ok=" .. tostring(update_ok)
        .. " err=" .. tostring(update_err))
    fusion_snapshot("FUSION DESPUES updateValue")

    local update_ignore_ok, update_ignore_err = pcall(function()
        fusion:updateValueIgnoreParent()
    end)
    logp("[PawnResearch] PASO 101 updateValueIgnoreParent ok=" .. tostring(update_ignore_ok)
        .. " err=" .. tostring(update_ignore_err))
    fusion_snapshot("FUSION DESPUES updateValueIgnoreParent")

    local apply_ok, apply_result_or_err = pcall(function()
        return body_editor:applyEdit()
    end)
    logp("[PawnResearch] PASO 101 applyEdit ok=" .. tostring(apply_ok)
        .. " retorno=" .. tostring(apply_result_or_err))

    local after_height = safe_call(body_editor, "get_BodyHeight")
    local after_scale = human and safe(function() return human:get_Scale() end) or nil
    local after_scale_y = human and get_field_value_by_name(human, "ScaleY") or nil
    local after_weight = human and get_field_value_by_name(human, "BodyWeight") or nil
    local after_calc_scale = calc and safe(function() return calc:get_Scale() end) or nil

    logp("[PawnResearch] PASO 101 DESPUES BodyHeight=" .. tostring(after_height)
        .. " Human.Scale=" .. tostring(after_scale)
        .. " ScaleY=" .. tostring(after_scale_y)
        .. " BodyWeight=" .. tostring(after_weight))
    logp("[PawnResearch] PASO 101 DESPUES calculator.Scale=" .. tostring(after_calc_scale))
    fusion_snapshot("FUSION DESPUES applyEdit")

    local fresh_entry = find_roster_by_id(get_roster(), cid)
    local fresh_editor = fresh_entry and fresh_entry.character and get_part_swapper(fresh_entry.character) or nil
    fresh_editor = fresh_editor and get_field_value_by_name(fresh_editor, "_BodyEditor") or nil
    local fresh_fusion = nil
    local fresh_height = nil
    if fresh_editor ~= nil then
        fresh_height = safe_call(fresh_editor, "get_BodyHeight")
        local fresh_dict = safe(function() return fresh_editor:getEditValue() end)
        if fresh_dict ~= nil then
            fresh_fusion = safe_call(fresh_dict, "get_Item", height_hash)
        end
    end

    logp("[PawnResearch] PASO 101 FRESCA BodyHeight=" .. tostring(fresh_height))
    if fresh_fusion ~= nil then
        local fresh_value = safe_call(fresh_fusion, "get_Value")
        local fresh_raw = safe_call(fresh_fusion, "get_RawValue")
        local fresh_ratio = get_field_value_by_name(fresh_fusion, "_Ratio")
        logp("[PawnResearch] PASO 101 FRESCA FusionValue Value=" .. tostring(fresh_value)
            .. " RawValue=" .. tostring(fresh_raw)
            .. " Ratio=" .. tostring(fresh_ratio))
    end

    if fresh_fusion ~= nil then
        local fresh_value = safe_call(fresh_fusion, "get_Value")
        local fresh_ratio = get_field_value_by_name(fresh_fusion, "_Ratio")
        if fresh_value == expected_height and fresh_ratio ~= nil and fresh_ratio ~= -0.47500002384186 then
            logp("[PawnResearch] PASO 101 RESULTADO: FusionValue recalculo su ratio; revisar si la escala ya puede seguir esta ruta")
        else
            logp("[PawnResearch] PASO 101 RESULTADO: FusionValue conserva valor pero no se demostro propagacion completa a escala")
        end
    else
        logp("[PawnResearch] PASO 101 RESULTADO: no se pudo obtener FusionValue fresca")
    end

    logp("[PawnResearch] PASO 101 NOTA: no se escribio Human.BodyHeight, Human.Scale, ScaleY ni BodyWeight; no se uso applyEditModel, setupScale/updateScale ni PartSwapper.swap*")
    logp("[PawnResearch] ===== FIN PASO 101 FUSIONVALUE ALTURA =====")
    return true, "Prueba FusionValue terminada"
end

-- ============================================================
-- ============================================================
-- PASO 102: probar set_Value() nativo, y ademas forzar un _Ratio
-- consistente a mano.
--
-- Por que esto y no solo "probar set_Value" como decia el plan original:
-- el volcado completo de FusionValue en los Pasos 94-95 (log
-- pawn_research_log94-100.txt) revelo los campos que el Paso 101 no
-- tenia a la vista: DefaultValue=180, MinValue=140, MaxValue=215,
-- DefaultRatio=0, MinRatio=-1, MaxRatio=1. Con esos 6 numeros la
-- relacion Value->Ratio queda determinada (es un "fusion" de dos
-- tramos lineales alrededor del valor por defecto):
--
--   si Value >= DefaultValue:
--       Ratio = (Value - DefaultValue) / (MaxValue - DefaultValue) * MaxRatio
--   si Value <  DefaultValue:
--       Ratio = (Value - DefaultValue) / (DefaultValue - MinValue) * (-MinRatio)
--
-- Verificacion contra el dato real del Paso 101 (Value=200 ANTES de
-- tocar nada): la formula da 0.57142857142857, que coincide exacto
-- con el _Ratio observado (0.57142859697342, diferencia solo de
-- precision float). Para el objetivo Value=161 la formula da
-- Ratio=-0.475 exacto.
--
-- Dato curioso: el propio Paso 101 ya comparaba contra -0.47500002384186
-- en su verificacion de RESULTADO, pero con el operador alreves (~=
-- en vez de ==) -- es decir, el chequeo decia "exito" precisamente
-- cuando el ratio NO llegaba a -0.475, cuando en realidad -0.475 ES el
-- ratio correcto para 161. Probablemente una confusion al escribirlo.
-- Este paso corrige esa comparacion tambien.
--
-- Secuencia de este paso (una escritura nueva a la vez, con snapshot
-- despues de cada una, igual que el Paso 101):
--   1) set_Value(161) nativo (esto es literalmente lo que pedia el
--      plan original para el Paso 102)
--   2) updateValue() / updateValueIgnoreParent() (ya sabemos por el
--      Paso 101 que es poco probable que recalculen el ratio solos,
--      pero se repiten para no romper la cadena de evidencia)
--   3) COMO DIAGNOSTICO ADICIONAL: escribir _Ratio, <RawRatio> y
--      <LastRatio> directamente al valor que la formula predice, para
--      dejar el objeto en el mismo estado consistente que tendria si
--      el jugador hubiera movido el slider el mismo. Esto aisla si el
--      problema de Paso 101 era "Ratio nunca se calculo" (y con esto
--      se arregla) o "algo mas abajo no lee Ratio en absoluto" (y con
--      esto seguira sin moverse).
--   4) applyEdit() otra vez, con snapshot ANTES/DESPUES/FRESCA igual
--      que el Paso 101 para poder comparar linea por linea.
--
-- NO escribe Human.Scale/BodyHeight/ScaleY/BodyWeight directamente.
-- NO usa applyEditModel, setupScale/updateScale ni PartSwapper.swap*.
-- ============================================================
function paso102_fusion_ratio_esperado(value, default_value, max_value, min_value, max_ratio, min_ratio)
    if value == nil or default_value == nil or max_value == nil or min_value == nil then
        return nil
    end
    if value >= default_value then
        if max_value == default_value then return nil end
        return (value - default_value) / (max_value - default_value) * (max_ratio or 1.0)
    else
        if default_value == min_value then return nil end
        return (value - default_value) / (default_value - min_value) * (-(min_ratio or -1.0))
    end
end

paso102_probar_set_value_y_ratio_altura = function(character, template_name)
    if character == nil then
        logp("[PawnResearch] PASO 102 character=nil")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] ===== PASO 102 SET_VALUE + RATIO CONSISTENTE ALTURA =====")
    logp("[PawnResearch] PASO 102 CID=" .. tostring(cid))

    if cid == nil or is_character_protected(cid) then
        logp("[PawnResearch] PASO 102 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 102 SET_VALUE + RATIO CONSISTENTE ALTURA =====")
        return false, "CharacterID protegido"
    end

    local payload, load_err = paso82_load_template(template_name)
    if payload == nil then
        logp("[PawnResearch] PASO 102 TEMPLATE ERROR=" .. tostring(load_err))
        logp("[PawnResearch] ===== FIN PASO 102 SET_VALUE + RATIO CONSISTENTE ALTURA =====")
        return false, load_err
    end

    local expected_height = nil
    if payload.body_scale_detail ~= nil then
        expected_height = tonumber(payload.body_scale_detail.BodyHeight)
    end
    if expected_height == nil then
        logp("[PawnResearch] PASO 102 plantilla sin body_scale_detail.BodyHeight")
        return false, "plantilla sin BodyHeight"
    end

    local height_hash = 1497737450
    logp("[PawnResearch] PASO 102 altura_hash=" .. tostring(height_hash)
        .. " altura_esperada=" .. tostring(expected_height))

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 102 PartSwapper=nil")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 102 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    local human = get_human(character)
    local calc = human ~= nil
        and safe(function() return human:get_RootTransScaleCalculator() end)
        or nil

    local edit_dict = safe(function() return body_editor:getEditValue() end)
    if edit_dict == nil then
        logp("[PawnResearch] PASO 102 BodyEditor.getEditValue() dictionary=nil")
        return false, "edit dictionary nil"
    end

    local fusion = safe_call(edit_dict, "get_Item", height_hash)
    if fusion == nil then
        logp("[PawnResearch] PASO 102 FusionValue altura=nil")
        return false, "FusionValue altura nil"
    end

    -- Leemos los 6 parametros de la formula directamente del objeto vivo
    -- (no los hardcodeamos) para que el calculo sea correcto aunque este
    -- peon en particular tenga otros limites que los observados en el
    -- Paso 94-95.
    local default_value = get_field_value_by_name(fusion, "<DefaultValue>k__BackingField")
    local max_value = get_field_value_by_name(fusion, "<MaxValue>k__BackingField")
    local min_value = get_field_value_by_name(fusion, "<MinValue>k__BackingField")
    local max_ratio = get_field_value_by_name(fusion, "MaxRatio")
    local min_ratio = get_field_value_by_name(fusion, "MinRatio")

    local expected_ratio = paso102_fusion_ratio_esperado(
        expected_height, default_value, max_value, min_value, max_ratio, min_ratio
    )

    logp("[PawnResearch] PASO 102 LIMITES leidos del objeto vivo: DefaultValue="
        .. tostring(default_value) .. " MinValue=" .. tostring(min_value)
        .. " MaxValue=" .. tostring(max_value) .. " MinRatio=" .. tostring(min_ratio)
        .. " MaxRatio=" .. tostring(max_ratio))
    logp("[PawnResearch] PASO 102 ratio_esperado_calculado=" .. tostring(expected_ratio))

    local function fusion_snapshot(label)
        local value = safe_call(fusion, "get_Value")
        local raw_value = safe_call(fusion, "get_RawValue")
        local ratio = get_field_value_by_name(fusion, "_Ratio")
        local raw_ratio = get_field_value_by_name(fusion, "<RawRatio>k__BackingField")
        local last_ratio = get_field_value_by_name(fusion, "<LastRatio>k__BackingField")
        logp("[PawnResearch] PASO 102 " .. label
            .. " Value=" .. tostring(value)
            .. " RawValue=" .. tostring(raw_value)
            .. " Ratio=" .. tostring(ratio)
            .. " RawRatio=" .. tostring(raw_ratio)
            .. " LastRatio=" .. tostring(last_ratio))
    end

    local before_height = safe_call(body_editor, "get_BodyHeight")
    local before_scale = human and safe(function() return human:get_Scale() end) or nil
    local before_scale_y = human and get_field_value_by_name(human, "ScaleY") or nil
    local before_weight = human and get_field_value_by_name(human, "BodyWeight") or nil
    local before_calc_scale = calc and safe(function() return calc:get_Scale() end) or nil

    logp("[PawnResearch] PASO 102 ANTES BodyHeight=" .. tostring(before_height)
        .. " Human.Scale=" .. tostring(before_scale)
        .. " ScaleY=" .. tostring(before_scale_y)
        .. " BodyWeight=" .. tostring(before_weight))
    logp("[PawnResearch] PASO 102 ANTES calculator.Scale=" .. tostring(before_calc_scale))
    fusion_snapshot("FUSION ANTES")

    -- 1) set_Value nativo (lo que pedia el plan original para este paso)
    local set_value_ok, set_value_err = pcall(function()
        fusion:set_Value(expected_height)
    end)
    logp("[PawnResearch] PASO 102 set_Value(" .. tostring(expected_height)
        .. ") ok=" .. tostring(set_value_ok)
        .. " err=" .. tostring(set_value_err))
    fusion_snapshot("FUSION DESPUES set_Value")

    -- 2) los dos update* confirmados, igual que en el Paso 101
    local update_ok, update_err = pcall(function()
        fusion:updateValue()
    end)
    logp("[PawnResearch] PASO 102 updateValue ok=" .. tostring(update_ok)
        .. " err=" .. tostring(update_err))
    fusion_snapshot("FUSION DESPUES updateValue")

    local update_ignore_ok, update_ignore_err = pcall(function()
        fusion:updateValueIgnoreParent()
    end)
    logp("[PawnResearch] PASO 102 updateValueIgnoreParent ok=" .. tostring(update_ignore_ok)
        .. " err=" .. tostring(update_ignore_err))
    fusion_snapshot("FUSION DESPUES updateValueIgnoreParent")

    -- 3) diagnostico adicional: forzar _Ratio/RawRatio/LastRatio al valor
    -- que la formula predice, SOLO si los update* de arriba no lo dejaron
    -- ya consistente por si solos.
    local ratio_after_updates = get_field_value_by_name(fusion, "_Ratio")
    local ratio_forced = false
    if expected_ratio ~= nil and (ratio_after_updates == nil
        or math.abs(ratio_after_updates - expected_ratio) > 0.0001) then
        local ok1 = set_field_value_by_name(fusion, "_Ratio", expected_ratio)
        local ok2 = set_field_value_by_name(fusion, "<RawRatio>k__BackingField", expected_ratio)
        local ok3 = set_field_value_by_name(fusion, "<LastRatio>k__BackingField", expected_ratio)
        ratio_forced = true
        logp("[PawnResearch] PASO 102 FORZANDO ratio a mano porque updateValue* no lo dejo consistente: "
            .. "_Ratio ok=" .. tostring(ok1)
            .. " RawRatio ok=" .. tostring(ok2)
            .. " LastRatio ok=" .. tostring(ok3))
        fusion_snapshot("FUSION DESPUES forzar ratio a mano")
    else
        logp("[PawnResearch] PASO 102 el ratio ya quedo consistente solo con updateValue*, no hizo falta forzarlo")
    end

    -- 4) applyEdit otra vez, igual que el Paso 101, para comparar linea
    -- por linea si ahora si propaga con el ratio ya consistente.
    local apply_ok, apply_result_or_err = pcall(function()
        return body_editor:applyEdit()
    end)
    logp("[PawnResearch] PASO 102 applyEdit ok=" .. tostring(apply_ok)
        .. " retorno=" .. tostring(apply_result_or_err))

    local after_height = safe_call(body_editor, "get_BodyHeight")
    local after_scale = human and safe(function() return human:get_Scale() end) or nil
    local after_scale_y = human and get_field_value_by_name(human, "ScaleY") or nil
    local after_weight = human and get_field_value_by_name(human, "BodyWeight") or nil
    local after_calc_scale = calc and safe(function() return calc:get_Scale() end) or nil

    logp("[PawnResearch] PASO 102 DESPUES BodyHeight=" .. tostring(after_height)
        .. " Human.Scale=" .. tostring(after_scale)
        .. " ScaleY=" .. tostring(after_scale_y)
        .. " BodyWeight=" .. tostring(after_weight))
    logp("[PawnResearch] PASO 102 DESPUES calculator.Scale=" .. tostring(after_calc_scale))
    fusion_snapshot("FUSION DESPUES applyEdit")

    local fresh_entry = find_roster_by_id(get_roster(), cid)
    local fresh_editor = fresh_entry and fresh_entry.character and get_part_swapper(fresh_entry.character) or nil
    fresh_editor = fresh_editor and get_field_value_by_name(fresh_editor, "_BodyEditor") or nil
    local fresh_fusion = nil
    local fresh_height = nil
    if fresh_editor ~= nil then
        fresh_height = safe_call(fresh_editor, "get_BodyHeight")
        local fresh_dict = safe(function() return fresh_editor:getEditValue() end)
        if fresh_dict ~= nil then
            fresh_fusion = safe_call(fresh_dict, "get_Item", height_hash)
        end
    end

    logp("[PawnResearch] PASO 102 FRESCA BodyHeight=" .. tostring(fresh_height))
    local fresh_value, fresh_ratio = nil, nil
    if fresh_fusion ~= nil then
        fresh_value = safe_call(fresh_fusion, "get_Value")
        local fresh_raw = safe_call(fresh_fusion, "get_RawValue")
        fresh_ratio = get_field_value_by_name(fresh_fusion, "_Ratio")
        logp("[PawnResearch] PASO 102 FRESCA FusionValue Value=" .. tostring(fresh_value)
            .. " RawValue=" .. tostring(fresh_raw)
            .. " Ratio=" .. tostring(fresh_ratio))
    end

    -- Comparacion CORREGIDA (el Paso 101 tenia el operador alreves):
    -- exito de la capa FusionValue = el ratio fresco SI coincide con el
    -- calculado por la formula. Exito de la capa siguiente = BodyHeight
    -- fresco ya refleja 161.
    local ratio_matches_formula = expected_ratio ~= nil and fresh_ratio ~= nil
        and math.abs(fresh_ratio - expected_ratio) < 0.001

    if fresh_height ~= nil and math.abs(fresh_height - expected_height) < 0.01 then
        logp("[PawnResearch] PASO 102 RESULTADO: EXITO COMPLETO, BodyHeight fresco ya es " .. tostring(fresh_height))
    elseif ratio_matches_formula then
        logp("[PawnResearch] PASO 102 RESULTADO: FusionValue (Value+Ratio) quedo consistente con la formula, "
            .. "pero BodyEditor.BodyHeight todavia no se movio -> el problema esta MAS ABAJO en la cadena "
            .. "(revisar _ApplyEditScales/_BodyScale en el Paso 103/104, no FusionValue)")
    else
        logp("[PawnResearch] PASO 102 RESULTADO: ni siquiera se logro un Ratio consistente con la formula "
            .. "(ratio_forzado=" .. tostring(ratio_forced) .. ") -- revisar si _Ratio es realmente escribible "
            .. "en este build o si hay otro campo intermedio")
    end

    logp("[PawnResearch] PASO 102 NOTA: no se escribio Human.BodyHeight, Human.Scale, ScaleY ni BodyWeight; no se uso applyEditModel, setupScale/updateScale ni PartSwapper.swap*")
    logp("[PawnResearch] ===== FIN PASO 102 SET_VALUE + RATIO CONSISTENTE ALTURA =====")
    return true, "Prueba set_Value + ratio consistente terminada"
end

-- PASO 99: diagnostico de la relacion entre el valor de altura,
-- _ApplyEditScales, _JointEditValueDict y _BodyScale.
--
-- No cambia Human ni llama metodos de aplicacion visual.
-- Solo prepara la tabla interna confirmada y la inspecciona.
--
-- Para diccionarios se usa GetEnumerator solo si la firma real existe.
-- Para via.vec3 se leen x/y/z solo si sus getters o campos reales existen.
-- ============================================================
paso99_tiene_metodo = function(obj, wanted_name)
    if obj == nil then return false end
    local methods = safe(function() return obj:get_type_definition():get_methods() end) or {}
    for _, method in ipairs(methods) do
        local method_name = safe(function() return method:get_name() end)
        if method_name == wanted_name then
            return true
        end
    end
    return false
end

paso99_dump_vec3 = function(vec, label)
    if vec == nil then
        logp("[PawnResearch] PASO 99 " .. label .. " vec=nil")
        return
    end

    logp("[PawnResearch] PASO 99 " .. label .. " tipo=" .. object_type_name(vec))

    local has_x = paso99_tiene_metodo(vec, "get_x")
    local has_y = paso99_tiene_metodo(vec, "get_y")
    local has_z = paso99_tiene_metodo(vec, "get_z")

    local x = has_x and safe_call(vec, "get_x") or nil
    local y = has_y and safe_call(vec, "get_y") or nil
    local z = has_z and safe_call(vec, "get_z") or nil

    logp("[PawnResearch] PASO 99 " .. label .. " getters x=" .. tostring(has_x)
        .. " y=" .. tostring(has_y) .. " z=" .. tostring(has_z)
        .. " valores=" .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z))

    local fields = list_all_field_names(vec)
    for _, f in ipairs(fields) do
        local name = f.name
        if name == "x" or name == "y" or name == "z"
            or name == "X" or name == "Y" or name == "Z" then
            local value = get_field_value_by_name(vec, name)
            logp("[PawnResearch] PASO 99 " .. label .. " CAMPO " .. name .. "=" .. tostring(value))
        end
    end
end

paso99_get_enumerator = function(obj, label)
    if obj == nil then
        logp("[PawnResearch] PASO 99 " .. label .. " enumerator obj=nil")
        return nil
    end
    if not paso99_tiene_metodo(obj, "GetEnumerator") then
        logp("[PawnResearch] PASO 99 " .. label .. " GetEnumerator=no confirmado")
        return nil
    end

    local enumerator = safe_call(obj, "GetEnumerator")
    logp("[PawnResearch] PASO 99 " .. label .. " enumerator=" .. value_to_string(enumerator))
    if enumerator ~= nil then
        dump_all_method_signatures(enumerator, "PASO 99 " .. label .. " ENUMERATOR")
    end
    return enumerator
end

paso99_diagnosticar_escalas = function(character)
    logp("[PawnResearch] ===== PASO 99 DIAGNOSTICO ESCALAS =====")

    if character == nil then
        logp("[PawnResearch] PASO 99 character=nil")
        logp("[PawnResearch] ===== FIN PASO 99 DIAGNOSTICO ESCALAS =====")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] PASO 99 CID=" .. tostring(cid))

    if cid == nil or is_character_protected(cid) then
        logp("[PawnResearch] PASO 99 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 99 DIAGNOSTICO ESCALAS =====")
        return false, "CID bloqueado"
    end

    local ps = get_part_swapper(character)
    local body_editor = ps and get_field_value_by_name(ps, "_BodyEditor") or nil
    if body_editor == nil then
        logp("[PawnResearch] PASO 99 BodyEditor=nil")
        logp("[PawnResearch] ===== FIN PASO 99 DIAGNOSTICO ESCALAS =====")
        return false, "BodyEditor nil"
    end

    local height_hash = 1497737450
    local body_height_before = safe_call(body_editor, "get_BodyHeight")
    logp("[PawnResearch] PASO 99 BodyEditor tipo=" .. object_type_name(body_editor))
    logp("[PawnResearch] PASO 99 BodyHeight=" .. tostring(body_height_before))
    logp("[PawnResearch] PASO 99 hash altura=" .. tostring(height_hash))

    local setup_ok, setup_err = pcall(function()
        body_editor:call("setupApplyEditScales")
    end)
    logp("[PawnResearch] PASO 99 setupApplyEditScales ok=" .. tostring(setup_ok)
        .. (setup_ok and "" or (" error=" .. tostring(setup_err))))

    local apply_scales = get_field_value_by_name(body_editor, "_ApplyEditScales")
    logp("[PawnResearch] PASO 99 _ApplyEditScales=" .. value_to_string(apply_scales))

    if apply_scales ~= nil then
        local contains_height = paso99_tiene_metodo(apply_scales, "ContainsKey")
        local item_height = paso99_tiene_metodo(apply_scales, "get_Item")
        logp("[PawnResearch] PASO 99 _ApplyEditScales capacidades ContainsKey=" .. tostring(contains_height)
            .. " get_Item=" .. tostring(item_height))

        if contains_height then
            local outer_has_height = safe_call(apply_scales, "ContainsKey", height_hash)
            logp("[PawnResearch] PASO 99 _ApplyEditScales ContainsKey(" .. tostring(height_hash)
                .. ")=" .. tostring(outer_has_height))

            if outer_has_height and item_height then
                local nested = safe_call(apply_scales, "get_Item", height_hash)
                logp("[PawnResearch] PASO 99 OUTER HEIGHT ITEM=" .. value_to_string(nested))
                if nested ~= nil then
                    logp("[PawnResearch] PASO 99 OUTER HEIGHT ITEM TIPO=" .. object_type_name(nested))
                    dump_all_method_signatures(nested, "PASO 99 OUTER HEIGHT NESTED")
                end
            end
        end

        local enumerator = paso99_get_enumerator(apply_scales, "_ApplyEditScales")
        if enumerator ~= nil and paso99_tiene_metodo(enumerator, "MoveNext") and paso99_tiene_metodo(enumerator, "get_Current") then
            local found_nested_height = 0
            local shown = 0
            for i = 1, 130 do
                local moved = safe_call(enumerator, "MoveNext")
                if moved ~= true then break end
                local current = safe_call(enumerator, "get_Current")
                if current == nil then break end

                local key = paso99_tiene_metodo(current, "get_Key") and safe_call(current, "get_Key") or nil
                local value = paso99_tiene_metodo(current, "get_Value") and safe_call(current, "get_Value") or nil

                if key ~= nil then
                    if key == height_hash then
                        logp("[PawnResearch] PASO 99 OUTER ENUM MATCH altura key=" .. tostring(key)
                            .. " value=" .. value_to_string(value))
                    end
                end

                if value ~= nil and paso99_tiene_metodo(value, "ContainsKey") then
                    local nested_has_height = safe_call(value, "ContainsKey", height_hash)
                    if nested_has_height then
                        found_nested_height = found_nested_height + 1
                        logp("[PawnResearch] PASO 99 NESTED MATCH outer_key=" .. tostring(key)
                            .. " contains_height=true")
                        local nested_item = paso99_tiene_metodo(value, "get_Item")
                            and safe_call(value, "get_Item", height_hash) or nil
                        logp("[PawnResearch] PASO 99 NESTED HEIGHT ITEM=" .. value_to_string(nested_item))
                        if nested_item ~= nil then
                            dump_all_fields_with_values(nested_item, "PASO 99 JointEditData HEIGHT")
                        end
                    end
                end

                shown = shown + 1
                if shown <= 3 then
                    logp("[PawnResearch] PASO 99 OUTER ENUM[" .. tostring(shown - 1) .. "] key="
                        .. tostring(key) .. " value=" .. value_to_string(value))
                end
            end
            logp("[PawnResearch] PASO 99 _ApplyEditScales nested_height_matches=" .. tostring(found_nested_height))
        end
    end

    local joint_dict = get_field_value_by_name(body_editor, "_JointEditValueDict")
    logp("[PawnResearch] PASO 99 _JointEditValueDict=" .. value_to_string(joint_dict))
    if joint_dict ~= nil then
        local enumerator = paso99_get_enumerator(joint_dict, "_JointEditValueDict")
        if enumerator ~= nil and paso99_tiene_metodo(enumerator, "MoveNext") and paso99_tiene_metodo(enumerator, "get_Current") then
            for i = 1, 3 do
                local moved = safe_call(enumerator, "MoveNext")
                if moved ~= true then break end
                local current = safe_call(enumerator, "get_Current")
                if current == nil then break end
                local key = paso99_tiene_metodo(current, "get_Key") and safe_call(current, "get_Key") or nil
                local value = paso99_tiene_metodo(current, "get_Value") and safe_call(current, "get_Value") or nil
                logp("[PawnResearch] PASO 99 JOINT ENUM[" .. tostring(i - 1) .. "] key="
                    .. tostring(key) .. " value=" .. value_to_string(value))
                if value ~= nil then
                    dump_all_fields_with_values(value, "PASO 99 JointEditValue[" .. tostring(i - 1) .. "]")
                end
            end
        end
    end

    local body_scale = get_field_value_by_name(body_editor, "_BodyScale")
    logp("[PawnResearch] PASO 99 _BodyScale=" .. value_to_string(body_scale))

    if body_scale ~= nil then
        local enum_td = safe(function() return sdk.find_type_definition("app.CharacterEditDefine.BodyScaleKey") end)
        if enum_td ~= nil then
            local enum_fields = safe(function() return enum_td:get_fields() end) or {}
            for _, field in ipairs(enum_fields) do
                if safe(function() return field:is_static() end) then
                    local enum_name = safe(function() return field:get_name() end)
                    if enum_name == "General" or enum_name == "UpperBody" or enum_name == "LowerBody" then
                        local enum_value = safe(function() return field:get_data(nil) end)
                        if enum_value ~= nil then
                            local vec = safe_call(body_editor, "getBodyScale", enum_value)
                            paso99_dump_vec3(vec, "BodyScale " .. tostring(enum_name))
                        end
                    end
                end
            end
        end
    end

    logp("[PawnResearch] PASO 99 RESULTADO: diagnostico terminado; no hubo escrituras de valores de Human ni PartSwapper")
    logp("[PawnResearch] ===== FIN PASO 99 DIAGNOSTICO ESCALAS =====")
    return true, "Diagnostico terminado; revisar log."
end

-- PASO 95: relacionar el hash de altura con app.BodyEditID y con
-- BodyEditorRoot:getEditValue(BodyEditID).
-- Solo lectura: no cambia FusionValue, EditValues, escala ni Human.
-- ============================================================
paso95_diagnosticar_body_edit_id = function(character, target_hash)
    logp("[PawnResearch] ===== PASO 95 BODYEDITID ALTURA =====")

    if character == nil then
        logp("[PawnResearch] PASO 95 character=nil")
        logp("[PawnResearch] ===== FIN PASO 95 BODYEDITID ALTURA =====")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] PASO 95 CID=" .. tostring(cid))
    logp("[PawnResearch] PASO 95 hash_objetivo=" .. tostring(target_hash))

    if cid == nil then
        return false, "CID nil"
    end
    if is_character_protected(cid) then
        logp("[PawnResearch] PASO 95 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 95 BODYEDITID ALTURA =====")
        return false, "CharacterID protegido"
    end

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 95 PartSwapper=nil")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 95 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    logp("[PawnResearch] PASO 95 BodyEditor tipo=" .. object_type_name(body_editor))
    logp("[PawnResearch] PASO 95 BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))

    local edit_id_td = safe(function()
        return sdk.find_type_definition("app.BodyEditID")
    end)

    if edit_id_td == nil then
        logp("[PawnResearch] PASO 95 app.BodyEditID type=nil")
        logp("[PawnResearch] ===== FIN PASO 95 BODYEDITID ALTURA =====")
        return false, "BodyEditID type nil"
    end

    local edit_id_type_name = safe(function() return edit_id_td:get_full_name() end)
    logp("[PawnResearch] PASO 95 BodyEditID tipo=" .. tostring(edit_id_type_name))

    local fields = safe(function() return edit_id_td:get_fields() end) or {}
    local static_count = 0
    local hash_matches = 0
    local name_matches = 0

    logp("[PawnResearch] PASO 95 ---- CAMPOS BodyEditID ----")
    for _, field in ipairs(fields) do
        local is_static = safe(function() return field:is_static() end)
        if is_static then
            local field_name = safe(function() return field:get_name() end)
            local field_value = safe(function() return field:get_data(nil) end)

            if field_name ~= nil and field_value ~= nil then
                static_count = static_count + 1
                logp(
                    "[PawnResearch] PASO 95 BodyEditID :: "
                    .. tostring(field_name) .. "=" .. value_to_string(field_value)
                )

                local numeric_value = tonumber(field_value)
                local numeric_hash = tonumber(target_hash)
                local name_has_height = string.find(
                    string.lower(tostring(field_name)),
                    "height",
                    1,
                    true
                ) ~= nil

                if numeric_hash ~= nil and numeric_value ~= nil and numeric_value == numeric_hash then
                    hash_matches = hash_matches + 1
                    logp(
                        "[PawnResearch] PASO 95 MATCH HASH: "
                        .. tostring(target_hash) .. " -> " .. tostring(field_name)
                    )

                    local got = safe_call(body_editor, "getEditValue", field_value)
                    logp(
                        "[PawnResearch] PASO 95 GETEDITVALUE MATCH: "
                        .. tostring(field_name) .. " -> " .. tostring(got)
                    )
                end

                if name_has_height then
                    name_matches = name_matches + 1
                    local got_by_name_candidate = safe_call(body_editor, "getEditValue", field_value)
                    logp(
                        "[PawnResearch] PASO 95 HEIGHT NAME CANDIDATE: "
                        .. tostring(field_name)
                        .. " id=" .. value_to_string(field_value)
                        .. " getEditValue=" .. tostring(got_by_name_candidate)
                    )
                end
            end
        end
    end

    logp(
        "[PawnResearch] PASO 95 BodyEditID resumen static_count="
        .. tostring(static_count)
        .. " hash_matches=" .. tostring(hash_matches)
        .. " name_height_matches=" .. tostring(name_matches)
    )

    logp("[PawnResearch] PASO 95 ---- BODYEDITOR getEditValue() DICTIONARY ----")
    local edit_dict = safe_call(body_editor, "getEditValue")
    if edit_dict == nil then
        logp("[PawnResearch] PASO 95 getEditValue() dictionary=nil")
    else
        logp("[PawnResearch] PASO 95 getEditValue() tipo=" .. object_type_name(edit_dict))
        logp("[PawnResearch] PASO 95 getEditValue() COUNT=" .. tostring(safe_call(edit_dict, "get_Count")))

        local enumerator = safe_call(edit_dict, "GetEnumerator")
        if enumerator == nil then
            logp("[PawnResearch] PASO 95 getEditValue() GetEnumerator=nil")
        else
            local row_count = 0
            local target_found = false

            while row_count < 100 do
                local moved = safe_call(enumerator, "MoveNext")
                if moved ~= true then
                    break
                end

                local pair = safe_call(enumerator, "get_Current")
                if pair == nil then
                    break
                end

                local key = safe_call(pair, "get_Key")
                local value = safe_call(pair, "get_Value")

                if key ~= nil then
                    local key_num = tonumber(key)
                    local target_num = tonumber(target_hash)
                    if target_num ~= nil and key_num ~= nil and key_num == target_num then
                        target_found = true
                        logp(
                            "[PawnResearch] PASO 95 DICT TARGET hash="
                            .. tostring(key)
                            .. " value=" .. value_to_string(value)
                        )
                        if value ~= nil then
                            dump_all_fields_with_values(
                                value,
                                "PASO 95 FusionValue TARGET desde BodyEditor.getEditValue"
                            )
                        end
                    end
                end

                row_count = row_count + 1
            end

            logp(
                "[PawnResearch] PASO 95 DICT enumerados="
                .. tostring(row_count)
                .. " target_found=" .. tostring(target_found)
            )
        end
    end

    logp("[PawnResearch] PASO 95 RESULTADO: diagnostico BodyEditID terminado; no hubo escrituras")
    logp("[PawnResearch] ===== FIN PASO 95 BODYEDITID ALTURA =====")
    return true, "diagnostico terminado"
end

re.on_draw_ui(function()
    if imgui.tree_node("Editor de Peones") then
        if post_update_audit_only then
            imgui.text_colored("MODO AUDITORIA POST-TU4: aplicaciones automaticas y botones de escritura bloqueados.", 0xFFFFCC66)
            imgui.text("Selecciona el peon por CharacterID. Esta fase solo inspecciona APIs y datos.")
            local audit_roster = get_roster()
            sync_selected(target_selected, target_cid, audit_roster)
            if #audit_roster > 0 then
                local audit_labels = {}
                for _, item in ipairs(audit_roster) do audit_labels[#audit_labels + 1] = item.label end
                local changed, selected = imgui.combo("Peon a auditar", target_selected[1], audit_labels)
                if changed then
                    target_selected[1] = math.max(1, math.min(selected, #audit_roster))
                    target_cid[1] = audit_roster[target_selected[1]].id
                end
                target_cid[1] = audit_roster[target_selected[1]].id
                imgui.text("CharacterID: " .. tostring(target_cid[1]))
                if imgui.button("PASO 110 - Inspeccionar via.vec3") then
                    local target = find_roster_by_id(audit_roster, target_cid[1])
                    if target ~= nil then
                        local ok, result = paso110_inspeccionar_vec3(target.character)
                        status_text = ok and "PASO 110 terminado; revisar log." or tostring(result)
                    end
                end
                if imgui.button("PASO 111 - Auditar compatibilidad TU4 y ruta PAM") then
                    local target = find_roster_by_id(audit_roster, target_cid[1])
                    if target ~= nil then
                        local ok, result = paso111_auditar_compatibilidad(target.character)
                        status_text = ok and "PASO 111 terminado; revisar log." or tostring(result)
                    end
                end
                if imgui.button("PASO 112 - Auditar catalogos DLC (equipo y skills)") then
                    local target = find_roster_by_id(audit_roster, target_cid[1])
                    if target ~= nil then
                        local ok, result = paso112_auditar_catalogos_dlc(target.character)
                        status_text = ok and "PASO 112 terminado; revisar log." or tostring(result)
                    end
                end
                if imgui.button("PASO 113 - Construir catalogos dinamicos (solo lectura)") then
                    local target = find_roster_by_id(audit_roster, target_cid[1])
                    if target ~= nil then
                        local ok, result = paso113_construir_catalogos_y_diagnosticar(target.character)
                        status_text = ok and "PASO 113 terminado; revisar log." or tostring(result)
                    end
                end
                if imgui.button("PASO 114 - Validar catalogos y componentes vec3 (solo lectura)") then
                    local target = find_roster_by_id(audit_roster, target_cid[1])
                    if target ~= nil then
                        local ok, result = paso114_auditar_catalogos_y_vec3(target.character)
                        status_text = ok and "PASO 114 terminado; revisar log." or tostring(result)
                    end
                end
                if imgui.button("PASO 115 - Auditar joints y hashes anatomicos (solo lectura)") then
                    local target = find_roster_by_id(audit_roster, target_cid[1])
                    if target ~= nil then
                        local ok, result = paso115_auditar_joints(target.character)
                        status_text = ok and "PASO 115 terminado; revisar log." or tostring(result)
                    end
                end
                imgui.text("Estado: " .. tostring(status_text))
            else
                imgui.text("No se encontraron peones en PawnCharacterList.")
            end
            imgui.tree_pop()
            return
        end

        imgui.text_colored(
            "Herramientas para clonar un peon a una plantilla y hacerla permanente entre partidas,",
            0xFF66CCFF
        )
        imgui.text_colored(
            "y para personalizar el equipo, vocacion, personalidad y voz de un peon ya contratado.",
            0xFF66CCFF
        )
        imgui.separator()
        imgui.spacing()


        if imgui.tree_node("Loadouts Generales de Escuadra") then
            hpo_global_loadout_system.load_index()

            imgui.text_colored(
                "Guarda una escuadra completa como un set con nombre.",
                0xFF66CCFF
            )
            imgui.text(
                "Incluye vocacion, habilidades equipadas y equipo de cada miembro seleccionado."
            )
            imgui.text(
                "Los miembros se reconocen por CharacterID. El peon protegido nunca se incluye."
            )
            imgui.separator()

            if hpo_global_loadout_system.active_name ~= nil then
                imgui.text_colored(
                    "Loadout activo: "
                    .. tostring(hpo_global_loadout_system.active_name),
                    0xFF66FF99
                )
            else
                imgui.text_colored(
                    "Loadout activo: ninguno",
                    0xFFAAAAAA
                )
            end

            imgui.spacing()

            local name_changed
            name_changed, hpo_global_loadout_system.name =
                imgui.input_text(
                    "Nombre##global_loadout_name",
                    hpo_global_loadout_system.name
                )

            imgui.text("Miembros de la escuadra a guardar:")

            local global_roster = get_roster()
            local selected_count = 0

            for _, entry in ipairs(global_roster) do
                local cid_str = tostring(entry.id)

                if is_character_protected(entry.id) then
                    imgui.text_colored(
                        entry.name .. " - protegido",
                        0xFFAAAAAA
                    )
                else
                    if hpo_global_loadout_system.capture_members[cid_str] == nil then
                        hpo_global_loadout_system.capture_members[cid_str] = true
                    end

                    local member_changed
                    member_changed,
                    hpo_global_loadout_system.capture_members[cid_str] =
                        imgui.checkbox(
                            entry.name .. "##global_member_" .. cid_str,
                            hpo_global_loadout_system.capture_members[cid_str] == true
                        )

                    if hpo_global_loadout_system.capture_members[cid_str] == true then
                        selected_count = selected_count + 1
                    end
                end
            end

            imgui.same_line()
            if imgui.button("Todos##global_members") then
                for _, entry in ipairs(global_roster) do
                    if not is_character_protected(entry.id) then
                        hpo_global_loadout_system.capture_members[
                            tostring(entry.id)
                        ] = true
                    end
                end
            end

            imgui.same_line()
            if imgui.button("Ninguno##global_members") then
                for _, entry in ipairs(global_roster) do
                    hpo_global_loadout_system.capture_members[
                        tostring(entry.id)
                    ] = false
                end
            end

            imgui.text(
                "Seleccionados: " .. tostring(selected_count)
            )

            imgui.spacing()

            if imgui.button("Guardar / actualizar##global_save") then
                local ok, msg =
                    hpo_global_loadout_system.capture_current(
                        hpo_global_loadout_system.name,
                        global_roster
                    )

                hpo_global_loadout_system.status =
                    (ok and "OK: " or "ERROR: ") .. tostring(msg)
            end

            imgui.spacing()

            local global_labels = { "(ninguno)" }
            for _, item in ipairs(hpo_global_loadout_system.index) do
                if type(item) == "table" and item.name ~= nil then
                    global_labels[#global_labels + 1] =
                        tostring(item.name)
                        .. " ("
                        .. tostring(item.member_count or "?")
                        .. ")"
                end
            end

            local combo_index =
                math.max(
                    1,
                    math.min(
                        hpo_global_loadout_system.selected_index + 1,
                        #global_labels
                    )
                )

            local combo_changed, new_index =
                imgui.combo(
                    "Loadout guardado##global_selected",
                    combo_index,
                    global_labels
                )

            if combo_changed then
                hpo_global_loadout_system.selected_index =
                    math.max(1, new_index - 1)
            end

            local selected_global =
                hpo_global_loadout_system.index[
                    hpo_global_loadout_system.selected_index
                ]

            if selected_global ~= nil then
                imgui.spacing()

                if imgui.button("Aplicar ahora##global_apply") then
                    local ok, msg =
                        hpo_global_loadout_system.apply_named(
                            selected_global.name,
                            false
                        )
                    hpo_global_loadout_system.status =
                        (ok and "OK: " or "ERROR: ") .. tostring(msg)
                end

                imgui.same_line()
                if imgui.button("Aplicar + activar##global_apply_active") then
                    local ok, msg =
                        hpo_global_loadout_system.apply_named(
                            selected_global.name,
                            true
                        )
                    hpo_global_loadout_system.status =
                        (ok and "OK: " or "ERROR: ") .. tostring(msg)
                end

                imgui.same_line()
                if imgui.button("Desactivar##global_deactivate") then
                    local ok, msg =
                        hpo_global_loadout_system.deactivate()
                    hpo_global_loadout_system.status =
                        (ok and "OK: " or "ERROR: ") .. tostring(msg)
                end

                local preview, preview_err =
                    hpo_global_loadout_system.load_payload(
                        selected_global.name
                    )

                if type(preview) == "table"
                    and type(preview.members) == "table"
                then
                    imgui.spacing()
                    imgui.text_colored(
                        "Contenido:",
                        0xFFFFCC66
                    )

                    for _, member in ipairs(preview.members) do
                        imgui.text(
                            tostring(member.name or "<sin nombre>")
                            .. " -> "
                            .. hpo_job_name(member.job)
                        )
                        imgui.same_line()
                        imgui.text_colored(
                            "(6 skills / 9 equipo)",
                            0xFFAAAAAA
                        )
                    end
                elseif preview_err ~= nil then
                    imgui.text_colored(
                        tostring(preview_err),
                        0xFF8888FF
                    )
                end
            end

            imgui.separator()
            imgui.text_colored(
                "Estado: " .. tostring(hpo_global_loadout_system.status),
                0xFFFFFFFF
            )
            imgui.text(
                "JSON: reframework/data/PawnResearch/GlobalLoadouts/"
            )

            imgui.spacing()
            imgui.tree_pop()
        end

        if imgui.tree_node("Plantillas de Peon (clonar y hacer permanente)") then
            local roster = get_roster()
            sync_selected(source_selected, source_cid, roster)
            sync_selected(target_selected, target_cid, roster)

            imgui.text("Objetivo: modificar un peon EXISTENTE y restaurar la plantilla")
            imgui.text_colored("PASO 70: clona cuerpo y colores detectados por reflexion; NO clona visuales del equipo ni raza/sexo.", 0xFF66CCFF)
            imgui.text("automaticamente despues de cargar/abrir la partida.")
            imgui.separator()

            imgui.text_colored("-- Candado de seguridad --", 0xFF66CCFF)
            imgui.text("CharacterID protegido (vacio = sin candado). Bloquea aplicar/restaurar sobre el.")
            local changed_lock
            changed_lock, protected_id_value[1] = imgui.input_text("CharacterID protegido", protected_id_value[1])
            imgui.text_colored("-> " .. describe_character_id(roster, protected_id_value[1]), 0xFFAAAAAA)
            imgui.separator()

            imgui.text_colored("-- Peon origen --", 0xFF66FF66)
            if #roster > 0 then
                local labels = {}
                for _, item in ipairs(roster) do labels[#labels + 1] = item.label end

                local changed
                changed, source_selected[1] = imgui.combo("Origen", source_selected[1], labels)
                if changed then
                    source_selected[1] = math.max(1, math.min(source_selected[1], #roster))
                    source_cid[1] = roster[source_selected[1]].id
                end
                source_cid[1] = roster[source_selected[1]].id
                imgui.text("Origen: " .. describe_character_id(roster, source_cid[1]))
            else
                imgui.text("No hay peones disponibles.")
            end

            imgui.separator()
            imgui.text_colored("-- Peon destino --", 0xFF66CCFF)
            if #roster > 0 then
                local labels = {}
                for _, item in ipairs(roster) do labels[#labels + 1] = item.label end

                local changed
                changed, target_selected[1] = imgui.combo("Destino", target_selected[1], labels)
                if changed then
                    target_selected[1] = math.max(1, math.min(target_selected[1], #roster))
                    target_cid[1] = roster[target_selected[1]].id
                end
                target_cid[1] = roster[target_selected[1]].id
                imgui.text("Destino: " .. describe_character_id(roster, target_cid[1]))
            end

            imgui.separator()
            changed, template_name[1] = imgui.input_text("Nombre de plantilla", template_name[1])
            changed, require_same_variant = imgui.checkbox(
                "Bloquear si Gender/Species difieren",
                require_same_variant
            )

            if imgui.button("Guardar plantilla DESDE el origen") then
                local source = find_roster_by_id(roster, source_cid[1])
                if source == nil then
                    status_text = "No se encontro el origen."
                else
                    local ok, result = save_template_from_character(
                        source.character,
                        template_name[1]
                    )
                    if ok then
                        status_text = "Plantilla guardada: " .. tostring(result)
                    else
                        status_text = "ERROR guardando plantilla: " .. tostring(result)
                    end
                end
            end

            if imgui.button("Aplicar plantilla AL destino") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = apply_template_to_character(
                        target.character,
                        template_name[1],
                        require_same_variant
                    )
                    if ok then
                        status_text = "Aplicada al destino. Appearance fields="
                            .. tostring(result.appearance)
                    else
                        status_text = "ERROR aplicando: " .. tostring(result)
                    end
                end
            end

            if imgui.button("PASO 82 - Probar CARGA JSON") then
                local payload, load_err, load_path = paso82_load_template(template_name[1])
                if payload ~= nil then
                    status_text = "PASO 82 JSON OK: " .. tostring(load_path)
                else
                    status_text = "PASO 82 JSON ERROR: " .. tostring(load_err)
                end
            end

            if imgui.button("PASO 86 - Buscar BodyEditorRoot") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso86_diagnosticar_body_editor_root(target.character)
                    status_text = ok
                        and "PASO 86: BodyEditorRoot localizado; revisar log."
                        or ("PASO 86: " .. tostring(result))
                end
            end

            if imgui.button("PASO 87 - Probar SETTER BodyEditor directo") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    status_text = "PASO 87: ejecutar setter; revisar log."
                    paso87_probar_setter_bodyeditor_directo(target.character, template_name[1])
                end
            end



            if imgui.button("PASO 90 - Probar applyEdit") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    status_text = "PASO 90: ejecutar applyEdit; revisar log."
                    paso90_probar_apply_edit(target.character, template_name[1])
                end
            end

            if imgui.button("PASO 93 - Diagnosticar tablas de escala") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso93_diagnosticar_tablas_escala(target.character)
                    status_text = ok
                        and "PASO 93: diagnostico terminado; revisar log."
                        or ("PASO 93: " .. tostring(result))
                end
            end

            if imgui.button("PASO 94 - Inspeccionar hash altura") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso94_inspeccionar_hash_escala(target.character, 1497737450)
                    status_text = ok
                        and "PASO 94: diagnostico terminado; revisar log."
                        or ("PASO 94: " .. tostring(result))
                end
            end

            if imgui.button("PASO 95 - Diagnosticar BodyEditID altura") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso95_diagnosticar_body_edit_id(target.character, 1497737450)
                    status_text = ok
                        and "PASO 95: diagnostico terminado; revisar log."
                        or ("PASO 95: " .. tostring(result))
                end
            end

            if imgui.button("PASO 96 - Probar setEditValue nativo altura") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso96_probar_bodyeditor_set_editvalue(target.character, template_name[1])
                    status_text = ok
                        and "PASO 96: prueba terminada; revisar log."
                        or ("PASO 96: " .. tostring(result))
                end
            end

            if imgui.button("PASO 97 - Probar setEditValue directo altura") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso97_probar_set_editvalue_directo(target.character, template_name[1])
                    status_text = ok
                        and "PASO 97: prueba terminada; revisar log."
                        or ("PASO 97: " .. tostring(result))
                end
            end


            if imgui.button("PASO 100 - Probar restore(EditValue[]) altura") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso100_probar_restore_editvalues_altura(target.character, template_name[1])
                    status_text = ok
                        and "PASO 100: prueba terminada; revisar log."
                        or ("PASO 100: " .. tostring(result))
                end
            end

            if imgui.button("PASO 101 - Probar update FusionValue altura") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso101_probar_update_fusionvalue_altura(target.character, template_name[1])
                    status_text = ok
                        and "PASO 101: prueba terminada; revisar log."
                        or ("PASO 101: " .. tostring(result))
                end
            end

            if imgui.button("PASO 102 - set_Value + forzar Ratio consistente") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso102_probar_set_value_y_ratio_altura(target.character, template_name[1])
                    status_text = ok
                        and "PASO 102: prueba terminada; revisar log."
                        or ("PASO 102: " .. tostring(result))
                end
            end

            if imgui.button("PASO 103 - Inspeccionar escalas numericas") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso103_diagnosticar_escalas_numericas(target.character)
                    status_text = ok
                        and "PASO 103: diagnostico terminado; revisar log."
                        or ("PASO 103: " .. tostring(result))
                end
            end

            if imgui.button("PASO 106 - Leer via.vec3 con Field:get_data") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso106_diagnosticar_escalas(target.character)
                    status_text = ok
                        and "PASO 106: diagnostico terminado; revisar log."
                        or ("PASO 105: " .. tostring(result))
                end
            end

            if imgui.button("PASO 107 - Preparar escalas y leer via.vec3") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso107_diagnosticar_escalas(target.character)
                    status_text = ok
                        and "PASO 107: diagnostico terminado; revisar log."
                        or ("PASO 107: " .. tostring(result))
                end
            end

            if imgui.button("PASO 108 - Comparar ApplyEditScales antes/despues") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso108_comparar_apply_edit_scales(target.character)
                    status_text = ok
                        and "PASO 108: comparacion terminada; revisar log."
                        or ("PASO 108: " .. tostring(result))
                end
            end

            if imgui.button("PASO 109 - Enumerar ApplyEditScales real") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso109_diagnosticar_apply_edit_scales(target.character)
                    status_text = ok
                        and "PASO 109: enumeracion terminada; revisar log."
                        or ("PASO 109: " .. tostring(result))
                end
            end

            if imgui.button("PASO 110 - Inspeccionar via.vec3 (lectura)") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso110_inspeccionar_vec3(target.character)
                    status_text = ok
                        and "PASO 110: inspeccion terminada; revisar log."
                        or ("PASO 110: " .. tostring(result))
                end
            end

            if imgui.button("PASO 111 - Auditar compatibilidad TU4 y ruta PAM") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso111_auditar_compatibilidad(target.character)
                    status_text = ok
                        and "PASO 111: auditoria terminada; revisar log."
                        or ("PASO 111: " .. tostring(result))
                end
            end

            if imgui.button("PASO 112 - Auditar catalogos DLC (equipo y skills)") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso112_auditar_catalogos_dlc(target.character)
                    status_text = ok
                        and "PASO 112: catalogos auditados; revisar log."
                        or ("PASO 112: " .. tostring(result))
                end
            end

            if imgui.button("PASO 113 - Construir catalogos dinamicos (solo lectura)") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso113_construir_catalogos_y_diagnosticar(target.character)
                    status_text = ok
                        and "PASO 113: catalogos en memoria; revisar log."
                        or ("PASO 113: " .. tostring(result))
                end
            end

            if imgui.button("PASO 114 - Validar catalogos y componentes vec3 (solo lectura)") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso114_auditar_catalogos_y_vec3(target.character)
                    status_text = ok
                        and "PASO 114: auditoria terminada; revisar log."
                        or ("PASO 114: " .. tostring(result))
                end
            end

            if imgui.button("PASO 115 - Auditar joints y hashes anatomicos (solo lectura)") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso115_auditar_joints(target.character)
                    status_text = ok
                        and "PASO 115: auditoria terminada; revisar log."
                        or ("PASO 115: " .. tostring(result))
                end
            end

            if imgui.button("PASO 99 - Diagnosticar tablas escala") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso99_diagnosticar_escalas(target.character)
                    status_text = ok
                        and "PASO 99: diagnostico terminado; revisar log."
                        or ("PASO 99: " .. tostring(result))
                end
            end

            if imgui.button("PASO 98 - Diagnosticar efecto interno setEditValue") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso98_diagnosticar_set_editvalue_interno(target.character, template_name[1])
                    status_text = ok
                        and "PASO 98: diagnostico terminado; revisar log."
                        or ("PASO 98: " .. tostring(result))
                end
            end

            if imgui.button("PASO 92 - Diagnosticar condiciones applyEdit") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso92_diagnosticar_condiciones_apply_edit(target.character)
                    status_text = ok
                        and "PASO 92: diagnostico terminado; revisar log."
                        or ("PASO 92: " .. tostring(result))
                end
            end

            if imgui.button("PASO 91 - Probar setupApplyEditScales") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    status_text = "PASO 91: ejecutar setupApplyEditScales; revisar log."
                    paso91_probar_setup_apply_edit_scales(target.character, template_name[1])
                end
            end

            if imgui.button("PASO 89 - Probar applyEditModel") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    status_text = "PASO 89: ejecutar applyEditModel; revisar log."
                    paso89_probar_apply_edit_model(target.character, template_name[1])
                end
            end

            if imgui.button("PASO 88 - Probar collectBodyScale") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    status_text = "PASO 88: ejecutar collectBodyScale; revisar log."
                    paso88_probar_collect_body_scale(target.character, template_name[1])
                end
            end

            if imgui.button("PASO 85 - Probar SETTER nativo altura") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result = paso85_diagnosticar_setter_altura(target.character, template_name[1])
                    status_text = ok
                        and "PASO 85: diagnostico terminado; revisar log."
                        or ("PASO 84 ERROR: " .. tostring(result))
                end
            end

            if imgui.button("PASO 82 - Probar SOLO altura") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok, result, detail = paso82_try_height_edit(
                        target.character,
                        sanitize_name(template_name[1])
                    )
                    if ok then
                        status_text = "PASO 82 OK: " .. tostring(result)
                    else
                        status_text = "PASO 82 ERROR: " .. tostring(result)
                    end
                end
            end

            imgui.text("PASO 82: esta prueba escribe unicamente el hash del slider de altura detectado desde la plantilla.")

            if imgui.button("Guardar asignacion persistente al destino") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok = set_assignment(target.id, sanitize_name(template_name[1]))
                    if ok then
                        status_text = "Asignado permanentemente: " .. target.name
                            .. " (CID " .. tostring(target.id) .. ") -> " .. sanitize_name(template_name[1])
                    else
                        status_text = "ERROR guardando assignments.json"
                    end
                end
            end

            if imgui.button("Aplicar AHORA todas las asignaciones") then
                local restored, skipped = restore_all_assigned()
                status_text = "Restauradas " .. tostring(restored)
                    .. "; omitidas " .. tostring(skipped)
            end

            if imgui.button("Quitar asignacion del destino") then
                local target = find_roster_by_id(roster, target_cid[1])
                if target == nil then
                    status_text = "No se encontro el destino."
                else
                    local ok = remove_assignment(target.id)
                    status_text = ok
                        and ("Asignacion eliminada de " .. target.name .. " (CID " .. tostring(target.id) .. ")")
                        or "ERROR eliminando asignacion"
                end
            end

            imgui.separator()
            local changed_auto
            changed_auto, auto_restore = imgui.checkbox(
                "Restauracion automatica al detectar el roster tras cargar partida",
                auto_restore
            )

            imgui.text_colored("Estado: " .. status_text, 0xFFFFFFFF)
            imgui.text("Archivos:")
            imgui.text("  reframework/data/PawnResearch/PersistentTemplates/")
            imgui.text("  assignments.json = CharacterID -> plantilla")
            imgui.text("  *.json = contenido de cada plantilla")

            imgui.separator()
            imgui.text_colored("-- Asignaciones actuales --", 0xFFFFCC66)
            local assignments = load_assignments()
            if #assignments == 0 then
                imgui.text("<ninguna>")
            else
                for _, a in ipairs(assignments) do
                    imgui.text(
                        describe_character_id(roster, a.character_id)
                        .. " -> Plantilla: " .. tostring(a.template)
                    )
                end
            end

            imgui.tree_pop()
        end
        imgui.spacing()

        if imgui.tree_node("Personalizar Peon Contratado (equipo, vocacion, personalidad, voz)") then
            imgui.text_colored("Adaptado del mod 'Hired Pawn Override' v1.5.3 (Evo) a nuestra propia infraestructura.", 0xFF66CCFF)
            imgui.text("Se guarda por CharacterID en HiredPawnOverride/config.json, sin limite de 2 peones.")
            if not hpo_itemData then
                imgui.text_colored("Falta itemData.json en reframework/data/" .. HPO_ITEMDATA_FILE, 0xFF0000FF)
            end
            imgui.separator()
            local roster = get_roster()
            if #roster == 0 then
                imgui.text("No hay peones disponibles.")
            else
                local labels = {}
                for _, item in ipairs(roster) do labels[#labels + 1] = item.label end

                local changed
                changed, hpo_selected[1] = imgui.combo("Peon a configurar", hpo_selected[1], labels)
                hpo_selected[1] = math.max(1, math.min(hpo_selected[1], #roster))
                local entry = roster[hpo_selected[1]]

                local cfg = hpo_get_config()
                local cid_str = tostring(entry.id)
                local pawn_cfg = cfg[cid_str] or hpo_default_pawn_config()

                if is_character_protected(entry.id) then
                    imgui.text_colored("Este peon coincide con el candado de seguridad -- no se le aplicara nada.", 0xFFFF6666)
                end

                local changed_en
                changed_en, pawn_cfg.enabled = imgui.checkbox("Activar override para este peon", pawn_cfg.enabled)
                if changed_en then
                        cfg[cid_str] = pawn_cfg
                        hpo_set_config(cfg)
                        hpo_applied_cid[cid_str] = nil
                        hpo_skill_applied_signature[cid_str] = nil
                    end

                -- Compartida por las secciones de Vocacion/Nivel y de
                -- Personalidad/Especializacion/Voz, ambas usan combos con
                -- "No Override" como primera opcion (valor nil).
                local function pick_idx(values, current, count)
                    for i = 1, count do if values[i] == current then return i end end
                    return 1
                end

                if pawn_cfg.enabled then
                    imgui.spacing()
                    if imgui.tree_node("Equipo##" .. cid_str) then
                        local current_job = get_field_value_by_name(get_job_context(entry.character), "CurrentJob")

                        local lc
                        lc, hpo_settings_cache.lock_equipment_to_job = imgui.checkbox(
                            "Solo mostrar equipo de la vocacion actual (" .. hpo_job_name(current_job) .. ")",
                            hpo_settings_cache.lock_equipment_to_job
                        )
                        if lc then hpo_save_settings(hpo_settings_cache) end
                        imgui.text_colored(
                            "Aplica a todos los peones mientras este panel esta abierto, no solo a este.",
                            0xFFAAAAAA
                        )
                        imgui.spacing()

                        for _, slot_name in ipairs(HPO_SLOTS) do
                            local search_key = slot_name .. "_" .. cid_str
                            imgui.text(slot_name .. ":")
                            imgui.set_next_item_width(300)
                            local sc, sv = imgui.input_text("Buscar##" .. search_key, hpo_search_text[search_key] or "")
                            if sc then hpo_search_text[search_key] = sv end

                            local filtered = hpo_filter(slot_name, search_key, current_job)
                            local combo_items = {}
                            for i, item in ipairs(filtered) do
                                if i > 150 then break end
                                combo_items[#combo_items + 1] = item.name
                            end
                            local current_idx = 1
                            for i, item in ipairs(filtered) do
                                if item.id == pawn_cfg.equipment[slot_name] then current_idx = i break end
                            end
                            imgui.set_next_item_width(400)
                            local cc, ci = imgui.combo("##combo_" .. search_key, current_idx, combo_items)
                            if cc and filtered[ci] then
                                pawn_cfg.equipment[slot_name] = filtered[ci].id
                                cfg[cid_str] = pawn_cfg
                                hpo_set_config(cfg)
                                hpo_applied_cid[cid_str] = nil -- forzar reaplicar
                            end
                            imgui.same_line()
                            imgui.text("Actual: " .. hpo_item_name(slot_name, pawn_cfg.equipment[slot_name]))
                            imgui.spacing()
                        end
                        imgui.tree_pop()
                    end

                    imgui.spacing()
                    if imgui.tree_node("Vocación##" .. cid_str) then
                        imgui.text_colored(
                            "Cambia la vocacion del peon. Los nombres Mystic Spearhand/Trickster/Magick Archer son deduccion; confirma en el juego la primera vez.",
                            0xFFAAAAAA
                        )
                        imgui.spacing()

                        imgui.text("Vocacion:")
                        local jc, ji = imgui.combo("##job_" .. cid_str, pick_idx(hpo_job_values, pawn_cfg.job, #hpo_job_list), hpo_job_list)
                        if jc then
                            pawn_cfg.job = hpo_job_values[ji]
                            cfg[cid_str] = pawn_cfg; hpo_set_config(cfg); hpo_applied_cid[cid_str] = nil
                        end

                        imgui.text_colored(
                            "Nota: si cambias la vocacion, el equipo que ya tenia puesto puede dejar de servirle."
                            .. " Activa 'Solo mostrar equipo de la vocacion actual' en Equipo para que los combos se filtren solos.",
                            0xFFAAAAAA
                        )
                        imgui.tree_pop()
                    end

                    imgui.spacing()
                    if imgui.tree_node("Habilidades y Loadouts##" .. cid_str) then
                        imgui.text_colored(
                            "Loadout = conjunto de habilidades equipadas para una vocacion. "
                            .. "Cada vocacion se guarda por separado para este peon.",
                            0xFF66CCFF
                        )
                        imgui.text(
                            "Selecciona una vocacion para editar su loadout. Esto no cambia la vocacion del peon."
                        )
                        imgui.text(
                            "No modificar = conservar el slot actual | None = limpiar el slot."
                        )
                        imgui.text(
                            "Guardar = guardar la configuracion | Guardar + aplicar = guardar y cambiarla ahora."
                        )
                        imgui.spacing()

                        local skill_actual_ok, skill_actual_err, actual_current_loadout =
                            hpo_read_skill_loadout(entry.character)

                        if not skill_actual_ok then
                            imgui.text_colored(
                                "No se pudo leer el loadout actual: " .. tostring(skill_actual_err),
                                0xFF6666FF
                            )
                        else
                            imgui.text(
                                "Vocacion actual del peon: "
                                .. hpo_job_name(actual_current_loadout.current_job)
                            )

                            if #hpo_skill_job_list == 0 then
                                imgui.text_colored(
                                    "No hay catalogo de vocaciones cargado.",
                                    0xFF6666FF
                                )
                            else
                                local selected_job = tonumber(hpo_skill_selected_job[cid_str])
                                if selected_job == nil or hpo_skill_job_names[selected_job] == nil then
                                    selected_job = actual_current_loadout.current_job_num
                                    if selected_job == nil or hpo_skill_job_names[selected_job] == nil then
                                        selected_job = hpo_skill_job_values[1]
                                    end
                                    hpo_skill_selected_job[cid_str] = selected_job
                                end

                                imgui.text("Vocacion del loadout a editar:")
                                local sjc, sji = imgui.combo(
                                    "##skill_job_" .. cid_str,
                                    pick_idx(hpo_skill_job_values, selected_job, #hpo_skill_job_values),
                                    hpo_skill_job_list
                                )
                                if sjc and hpo_skill_job_values[sji] ~= nil then
                                    selected_job = hpo_skill_job_values[sji]
                                    hpo_skill_selected_job[cid_str] = selected_job
                                end

                                local selected_ok, selected_err, selected_loadout =
                                    hpo_read_skill_loadout(entry.character, selected_job)

                                if not selected_ok then
                                    imgui.text_colored(
                                        "No se pudo leer " .. hpo_job_name(selected_job) .. ": " .. tostring(selected_err),
                                        0xFF6666FF
                                    )
                                else
                                    local job_key = tostring(selected_job)
                                    pawn_cfg.skills = type(pawn_cfg.skills) == "table"
                                        and pawn_cfg.skills
                                        or {}

                                    local job_skill_cfg = pawn_cfg.skills[job_key]
                                    if type(job_skill_cfg) ~= "table" then
                                        job_skill_cfg = {}
                                    end

                                    local skill_input_prefix =
                                        cid_str .. "_job" .. job_key .. "_skill"

                                    local options, option_values = { "(No modificar)" }, { false }
                                    for _, sid in ipairs(hpo_skill_catalog.vocation_skills[tostring(selected_job)] or {}) do
                                        options[#options + 1] = hpo_skill_label(sid)
                                        option_values[#option_values + 1] = tonumber(sid)
                                    end

                                    for slot = 0, HPO_SKILL_SLOT_COUNT - 1 do
                                        local actual_id = selected_loadout.slots[slot]
                                        local configured_id = job_skill_cfg[tostring(slot)]
                                        local initial_id = configured_id ~= nil and configured_id or actual_id
                                        local input_key = skill_input_prefix .. "_" .. tostring(slot)

                                        if hpo_skill_ui_inputs[input_key] == nil then
                                            hpo_skill_ui_inputs[input_key] = initial_id == nil and false or tonumber(initial_id)
                                        end

                                        local ui_value = hpo_skill_ui_inputs[input_key]
                                        local current_index = 1
                                        for oi, oid in ipairs(option_values) do
                                            if oid == ui_value then
                                                current_index = oi
                                                break
                                            end
                                        end

                                        imgui.text("Slot " .. tostring(slot + 1))
                                        imgui.same_line()
                                        imgui.set_next_item_width(390)
                                        local sc, si = imgui.combo(
                                            "##skill_combo_" .. input_key,
                                            current_index,
                                            options
                                        )
                                        if sc and option_values[si] ~= nil then
                                            hpo_skill_ui_inputs[input_key] = option_values[si]
                                        end
                                        imgui.same_line()
                                        imgui.text_colored(
                                            "Actual: " .. hpo_skill_label(actual_id or 0),
                                            0xFFAAAAAA
                                        )
                                    end

                                    imgui.spacing()

                                    local skills_enable_changed
                                    skills_enable_changed, pawn_cfg.skills_enabled =
                                        imgui.checkbox(
                                            "Activar override de habilidades",
                                            pawn_cfg.skills_enabled == true
                                        )
                                    if skills_enable_changed then
                                        cfg[cid_str] = pawn_cfg
                                        hpo_set_config(cfg)
                                        hpo_skill_applied_signature[cid_str] = nil
                                    end

                                    imgui.spacing()
                                    if imgui.button(
                                        "Guardar loadout de "
                                        .. hpo_job_name(selected_job)
                                        .. "##" .. cid_str
                                    ) then
                                        local collected_inputs = {}
                                        for slot = 0, HPO_SKILL_SLOT_COUNT - 1 do
                                            local input_key = skill_input_prefix .. "_" .. tostring(slot)
                                            local value = hpo_skill_ui_inputs[input_key]
                                            collected_inputs[slot] = (value == nil or value == false) and "" or tostring(value)
                                        end

                                        local collect_ok, collect_err, skill_map =
                                            hpo_collect_skill_config(collected_inputs)

                                        if not collect_ok then
                                            hpo_skill_status = "ERROR: " .. tostring(collect_err)
                                        else
                                            pawn_cfg.skills[job_key] = skill_map
                                            cfg[cid_str] = pawn_cfg
                                            hpo_skill_applied_signature[cid_str] = nil
                                            local save_ok = hpo_set_config(cfg)
                                            hpo_skill_status =
                                                save_ok
                                                and ("Guardado para " .. hpo_job_name(selected_job))
                                                or "ERROR guardando config.json"
                                        end
                                    end

                                    imgui.same_line()
                                    if imgui.button("Guardar + aplicar##" .. cid_str) then
                                        logp("[PawnResearch] PASO 62 UI: Guardar + aplicar CID=" .. cid_str .. " job=" .. hpo_job_name(selected_job))
                                        local collected_inputs = {}
                                        for slot = 0, HPO_SKILL_SLOT_COUNT - 1 do
                                            local input_key = skill_input_prefix .. "_" .. tostring(slot)
                                            local value = hpo_skill_ui_inputs[input_key]
                                            collected_inputs[slot] = (value == nil or value == false) and "" or tostring(value)
                                        end

                                        local collect_ok, collect_err, skill_map =
                                            hpo_collect_skill_config(collected_inputs)

                                        if not collect_ok then
                                            hpo_skill_status = "ERROR: " .. tostring(collect_err)
                                        else
                                            pawn_cfg.skills[job_key] = skill_map
                                            cfg[cid_str] = pawn_cfg

                                            local save_ok = hpo_set_config(cfg)
                                            if not save_ok then
                                                hpo_skill_status = "ERROR guardando config.json"
                                            else
                                                logp("[PawnResearch] PASO 62 UI: config.json guardado; ejecutando hpo_apply_skill_loadout")
                                                local apply_ok, apply_msg =
                                                    hpo_apply_skill_loadout(entry.character, skill_map, selected_job)
                                                hpo_skill_status =
                                                    (apply_ok and "OK: " or "ERROR: ")
                                                    .. tostring(apply_msg)
                                                logp("[PawnResearch] PASO 62 UI: hpo_apply_skill_loadout -> " .. tostring(apply_ok) .. " | " .. tostring(apply_msg))
                                            end
                                        end
                                    end

                                    imgui.same_line()
                                    if imgui.button("Copiar actuales al loadout##" .. cid_str) then
                                        local copy_map = {}
                                        for slot = 0, HPO_SKILL_SLOT_COUNT - 1 do
                                            local actual_id = selected_loadout.slots[slot]
                                            if actual_id ~= nil then
                                                copy_map[tostring(slot)] = actual_id
                                                hpo_skill_ui_inputs[skill_input_prefix .. "_" .. tostring(slot)] = actual_id
                                            else
                                                hpo_skill_ui_inputs[skill_input_prefix .. "_" .. tostring(slot)] = nil
                                            end
                                        end

                                        pawn_cfg.skills[job_key] = copy_map
                                        cfg[cid_str] = pawn_cfg
                                        local save_ok = hpo_set_config(cfg)
                                        hpo_skill_status =
                                            save_ok
                                            and ("Loadout actual copiado a config para "
                                                 .. hpo_job_name(selected_job))
                                            or "ERROR guardando config.json"
                                    end

                                    imgui.spacing()
                                    imgui.text_colored(
                                        "Estado skills: " .. tostring(hpo_skill_status),
                                        0xFFFFFFFF
                                    )
                                end
                            end
                        end

                        imgui.tree_pop()
                    end

                    imgui.spacing()
                    if imgui.tree_node("Personalidad / Especializacion / Voz##" .. cid_str) then
                        imgui.text("Personalidad:")
                        local pc, pi = imgui.combo("##pers_" .. cid_str, pick_idx(hpo_personality_values, pawn_cfg.personality, #hpo_personality_list), hpo_personality_list)
                        if pc then
                            pawn_cfg.personality = hpo_personality_values[pi]
                            cfg[cid_str] = pawn_cfg; hpo_set_config(cfg); hpo_applied_cid[cid_str] = nil
                        end

                        imgui.text("Especializacion:")
                        local sc2, si2 = imgui.combo("##spec_" .. cid_str, pick_idx(hpo_specialization_values, pawn_cfg.specialization, #hpo_specialization_list), hpo_specialization_list)
                        if sc2 then
                            pawn_cfg.specialization = hpo_specialization_values[si2]
                            cfg[cid_str] = pawn_cfg; hpo_set_config(cfg); hpo_applied_cid[cid_str] = nil
                        end

                        imgui.text_colored("IMPORTANTE: guarda y recarga la partida despues de cambiar voz/personalidad.", 0xED8585FF)

                        imgui.text("Voz - Genero:")
                        local gc, gi = imgui.combo("##vgender_" .. cid_str, pick_idx(hpo_voice_gender_values, pawn_cfg.voice_gender, #hpo_voice_gender_list), hpo_voice_gender_list)
                        if gc then
                            pawn_cfg.voice_gender = hpo_voice_gender_values[gi]
                            cfg[cid_str] = pawn_cfg; hpo_set_config(cfg); hpo_applied_cid[cid_str] = nil
                        end

                        imgui.text("Voz - Tono:")
                        local tc, ti = imgui.combo("##vtone_" .. cid_str, pick_idx(hpo_voice_tone_values, pawn_cfg.voice_tone, #hpo_voice_tone_list), hpo_voice_tone_list)
                        if tc then
                            pawn_cfg.voice_tone = hpo_voice_tone_values[ti]
                            cfg[cid_str] = pawn_cfg; hpo_set_config(cfg); hpo_applied_cid[cid_str] = nil
                        end

                        imgui.tree_pop()
                    end

                    imgui.spacing()
                    if imgui.button("Reaplicar ahora##" .. cid_str) then
                        hpo_applied_cid[cid_str] = nil
                        hpo_skill_applied_signature[cid_str] = nil
                        hpo_apply_if_needed(entry, pawn_cfg)
                        hpo_status = "Reaplicado a " .. entry.name .. " (CID=" .. cid_str .. ", revisa el log para el detalle)"
                    end
                end
            end

            imgui.separator()
            imgui.text_colored("Estado: " .. hpo_status, 0xFFFFFFFF)
            imgui.text("Archivos: reframework/data/" .. HPO_DIR .. "/config.json e itemData.json")
            imgui.tree_pop()
        end

        imgui.spacing()

        imgui.tree_pop()
    end
end)


-- ============================================================
-- PASO 103: inspeccion numerica de las tablas de escala.
--
-- Paso 99 demostro que _ApplyEditScales contiene diccionarios por
-- joint y que cada entrada de altura devuelve app.EditTable.JointEditData.
-- El diagnostico anterior no podia leer los componentes numericos de
-- via.vec3 porque este build no expone get_x/get_y/get_z.
--
-- Este paso descubre por reflexion los campos REALES de via.vec3 y,
-- usando esos campos confirmados, muestra los numeros de:
--   _BodyScale[General/UpperBody/LowerBody]
--   JointEditData._UpperScale / _LowerScale
--   JointEditData._UpperTranslate / _LowerTranslate
--
-- No escribe valores de Human y no llama applyEdit/setupScale/updateScale
-- ni PartSwapper.swap*. setupApplyEditScales solo prepara la tabla nativa
-- que ya esta confirmada como parte de BodyEditorRoot.
-- ============================================================
paso103_dump_vec3_numerico = function(vec, label)
    if vec == nil then
        logp("[PawnResearch] PASO 103 " .. label .. " vec=nil")
        return
    end

    local td = safe(function() return vec:get_type_definition() end)
    if td == nil then
        logp("[PawnResearch] PASO 103 " .. label .. " tipo=nil")
        return
    end

    local type_name = safe(function() return td:get_full_name() end) or "<?>"
    logp("[PawnResearch] PASO 103 " .. label .. " tipo=" .. tostring(type_name))

    local fields = safe(function() return td:get_fields() end) or {}
    local numeric_count = 0
    for _, field in ipairs(fields) do
        local fname = safe(function() return field:get_name() end)
        local is_static = safe(function() return field:is_static() end)
        if fname ~= nil and is_static ~= true then
            local ftype = safe(function()
                local ft = field:get_type()
                return ft and ft:get_full_name() or "<?>"
            end) or "<?>"

            if ftype == "System.Single"
                or ftype == "System.Double"
                or ftype == "System.Int32"
                or ftype == "System.Int64"
                or ftype == "System.UInt32"
                or ftype == "System.UInt64"
            then
                local value = safe(function() return field:get_data(vec) end)
                logp(
                    "[PawnResearch] PASO 103 " .. label
                    .. " CAMPO " .. tostring(fname)
                    .. " tipo=" .. tostring(ftype)
                    .. " valor=" .. tostring(value)
                )
                numeric_count = numeric_count + 1
            end
        end
    end

    if numeric_count == 0 then
        logp("[PawnResearch] PASO 103 " .. label .. " sin campos numericos expuestos")
        local methods = safe(function() return td:get_methods() end) or {}
        for _, method in ipairs(methods) do
            local mname = safe(function() return method:get_name() end)
            if mname ~= nil and (
                mname == "get_x" or mname == "get_y" or mname == "get_z"
                or mname == "get_X" or mname == "get_Y" or mname == "get_Z"
            ) then
                local ret = safe(function() return method:get_return_type() end)
                local ret_name = ret and safe(function() return ret:get_full_name() end) or "<?>"
                logp(
                    "[PawnResearch] PASO 103 " .. label
                    .. " METODO " .. tostring(mname)
                    .. " return=" .. tostring(ret_name)
                )
            end
        end
    end
end

paso103_dump_jointeditdata = function(item, label)
    if item == nil then
        logp("[PawnResearch] PASO 103 " .. label .. " JointEditData=nil")
        return
    end

    logp("[PawnResearch] PASO 103 " .. label .. " tipo=" .. object_type_name(item))

    local upper_scale = get_field_value_by_name(item, "_UpperScale")
    local lower_scale = get_field_value_by_name(item, "_LowerScale")
    local upper_translate = get_field_value_by_name(item, "_UpperTranslate")
    local lower_translate = get_field_value_by_name(item, "_LowerTranslate")

    paso103_dump_vec3_numerico(upper_scale, label .. " _UpperScale")
    paso103_dump_vec3_numerico(lower_scale, label .. " _LowerScale")
    paso103_dump_vec3_numerico(upper_translate, label .. " _UpperTranslate")
    paso103_dump_vec3_numerico(lower_translate, label .. " _LowerTranslate")
end

paso103_diagnosticar_escalas_numericas = function(character)
    logp("[PawnResearch] ===== PASO 103 ESCALAS NUMERICAS =====")

    if character == nil then
        logp("[PawnResearch] PASO 103 character=nil")
        logp("[PawnResearch] ===== FIN PASO 103 ESCALAS NUMERICAS =====")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] PASO 103 CID=" .. tostring(cid))

    if cid == nil or is_character_protected(cid) then
        logp("[PawnResearch] PASO 103 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 103 ESCALAS NUMERICAS =====")
        return false, "CID bloqueado"
    end

    local ps = get_part_swapper(character)
    local body_editor = ps and get_field_value_by_name(ps, "_BodyEditor") or nil
    if body_editor == nil then
        logp("[PawnResearch] PASO 103 BodyEditor=nil")
        logp("[PawnResearch] ===== FIN PASO 103 ESCALAS NUMERICAS =====")
        return false, "BodyEditor nil"
    end

    local height_hash = 1497737450
    logp("[PawnResearch] PASO 103 BodyEditor tipo=" .. object_type_name(body_editor))
    logp("[PawnResearch] PASO 103 BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))

    local setup_ok, setup_err = pcall(function()
        body_editor:call("setupApplyEditScales")
    end)
    logp("[PawnResearch] PASO 103 setupApplyEditScales ok=" .. tostring(setup_ok)
        .. (setup_ok and "" or (" error=" .. tostring(setup_err))))

    local body_scale = get_field_value_by_name(body_editor, "_BodyScale")
    if body_scale == nil then
        logp("[PawnResearch] PASO 103 _BodyScale=nil")
    else
        logp("[PawnResearch] PASO 103 _BodyScale=" .. value_to_string(body_scale))

        local enum_td = safe(function()
            return sdk.find_type_definition("app.CharacterEditDefine.BodyScaleKey")
        end)

        if enum_td ~= nil then
            local enum_fields = safe(function() return enum_td:get_fields() end) or {}
            for _, field in ipairs(enum_fields) do
                if safe(function() return field:is_static() end) then
                    local enum_name = safe(function() return field:get_name() end)
                    if enum_name == "General"
                        or enum_name == "UpperBody"
                        or enum_name == "LowerBody"
                    then
                        local enum_value = safe(function() return field:get_data(nil) end)
                        if enum_value ~= nil then
                            local vec = safe_call(body_editor, "getBodyScale", enum_value)
                            paso103_dump_vec3_numerico(
                                vec,
                                "BodyScale " .. tostring(enum_name)
                            )
                        end
                    end
                end
            end
        end
    end

    local apply_scales = get_field_value_by_name(body_editor, "_ApplyEditScales")
    if apply_scales == nil then
        logp("[PawnResearch] PASO 103 _ApplyEditScales=nil")
    else
        logp("[PawnResearch] PASO 103 _ApplyEditScales=" .. value_to_string(apply_scales))
        local enumerator = paso99_get_enumerator(apply_scales, "_ApplyEditScales")
        local match_count = 0
        local shown = 0

        if enumerator ~= nil
            and paso99_tiene_metodo(enumerator, "MoveNext")
            and paso99_tiene_metodo(enumerator, "get_Current")
        then
            for i = 1, 130 do
                local moved = safe_call(enumerator, "MoveNext")
                if moved ~= true then break end

                local current = safe_call(enumerator, "get_Current")
                if current == nil then break end

                local outer_key = paso99_tiene_metodo(current, "get_Key")
                    and safe_call(current, "get_Key") or nil
                local nested = paso99_tiene_metodo(current, "get_Value")
                    and safe_call(current, "get_Value") or nil

                if nested ~= nil and paso99_tiene_metodo(nested, "ContainsKey") then
                    local has_height = safe_call(nested, "ContainsKey", height_hash)
                    if has_height == true then
                        match_count = match_count + 1
                        if shown < 6 then
                            local item = paso99_tiene_metodo(nested, "get_Item")
                                and safe_call(nested, "get_Item", height_hash) or nil
                            logp(
                                "[PawnResearch] PASO 103 HEIGHT MATCH #"
                                .. tostring(match_count)
                                .. " joint_hash=" .. tostring(outer_key)
                                .. " item=" .. value_to_string(item)
                            )
                            paso103_dump_jointeditdata(
                                item,
                                "HEIGHT MATCH #" .. tostring(match_count)
                            )
                            shown = shown + 1
                        end
                    end
                end
            end
        end

        logp("[PawnResearch] PASO 103 _ApplyEditScales height_matches=" .. tostring(match_count)
            .. " muestras=" .. tostring(shown))
    end

    logp("[PawnResearch] PASO 103 NOTA: diagnostico; no hubo escrituras en Human ni PartSwapper")
    logp("[PawnResearch] ===== FIN PASO 103 ESCALAS NUMERICAS =====")
    return true, "Diagnostico numerico terminado; revisar log."
end

logp("[PawnResearch] ===== PASO 103 CARGADO (escalas numericas) =====")

logp("[PawnResearch] ===== PASO 34/35 CARGADO (Hired Pawn Override + vocacion/nivel) =====")
logp("[PawnResearch] Coloca itemData.json en reframework/data/" .. HPO_ITEMDATA_FILE)



-- ============================================================
-- PASO 106: diagnostico SOLO LECTURA de via.vec3 por Field:get_data().
-- Corrige la recuperacion del BodyEditor usando la ruta confirmada:
-- Character -> HumanPartSwapper -> _BodyEditor.
-- No se escribe nada y no se hace refresh visual.
-- ============================================================
--
-- Paso 104 confirmo que via.vec3 tiene x/y/z, pero get_field() directo
-- sobre la instancia sol.glm::vec<3,float,0> devuelve nil.
-- Aqui usamos la TypeDefinition confirmada de via.vec3 y el Field confirmado
-- para probar Field:get_data() sobre cada instancia.
-- Tambien registramos las firmas disponibles de esos Field para no adivinar
-- otra ruta de lectura.
-- No se escribe nada y no se llama applyEdit/setupScale/updateScale.
-- ============================================================
paso106_leer_campo_vec3 = function(vec, td_vec3, field_name, label)
    if vec == nil or td_vec3 == nil then
        logp("[PawnResearch] PASO 106 " .. label .. " " .. field_name .. " sin_objeto_o_td")
        return
    end

    local fields = safe(function() return td_vec3:get_fields() end) or {}
    for _, field in ipairs(fields) do
        local fname = safe(function() return field:get_name() end)
        local static_flag = safe(function() return field:is_static() end)
        if fname == field_name and static_flag ~= true then
            local ftype = safe(function()
                local ft = field:get_type()
                return ft and ft:get_full_name() or "<?>"
            end) or "<?>"

            logp("[PawnResearch] PASO 106 " .. label .. " " .. field_name
                .. " FIELD tipo=" .. tostring(ftype))

            local value_data = safe(function() return field:get_data(vec) end)
            logp("[PawnResearch] PASO 106 " .. label .. " " .. field_name
                .. " FIELD_GET_DATA=" .. value_to_string(value_data)
                .. " tipo_valor=" .. tostring(type(value_data)))

            local methods = safe(function() return field:get_methods() end) or {}
            local method_count = 0
            for _, method in ipairs(methods) do
                local mn = safe(function() return method:get_name() end)
                if mn ~= nil then
                    local params = safe(function() return method:get_parameter_types() end)
                    local ret = safe(function() return method:get_return_type() end)
                    local ret_name = ret and safe(function() return ret:get_full_name() end) or "<?>"
                    logp("[PawnResearch] PASO 106 " .. label .. " " .. field_name
                        .. " FIELD_METHOD " .. tostring(mn)
                        .. " return=" .. tostring(ret_name)
                        .. " params=" .. tostring(params))
                    method_count = method_count + 1
                end
            end
            logp("[PawnResearch] PASO 106 " .. label .. " " .. field_name
                .. " field_method_count=" .. tostring(method_count))
            return
        end
    end

    logp("[PawnResearch] PASO 106 " .. label .. " " .. field_name .. " FIELD_NO_ENCONTRADO")
end

paso106_dump_vec3_field_data = function(vec, label, td_vec3)
    if vec == nil then
        logp("[PawnResearch] PASO 106 " .. label .. " vec=nil")
        return
    end

    if td_vec3 == nil then
        logp("[PawnResearch] PASO 106 " .. label .. " td_vec3=nil")
        return
    end

    logp("[PawnResearch] PASO 106 " .. label
        .. " instancia=" .. value_to_string(vec))

    paso106_leer_campo_vec3(vec, td_vec3, "x", label)
    paso106_leer_campo_vec3(vec, td_vec3, "y", label)
    paso106_leer_campo_vec3(vec, td_vec3, "z", label)
end

paso106_dump_jointeditdata = function(item, label, td_vec3)
    if item == nil then
        logp("[PawnResearch] PASO 106 " .. label .. " JointEditData=nil")
        return
    end

    logp("[PawnResearch] PASO 106 " .. label .. " tipo=" .. object_type_name(item))

    local names = {
        "_UpperScale",
        "_LowerScale",
        "_UpperTranslate",
        "_LowerTranslate"
    }

    for _, field_name in ipairs(names) do
        local value = safe(function() return item:get_field(field_name) end)
        logp("[PawnResearch] PASO 106 " .. label
            .. " DIRECT " .. field_name .. "=" .. value_to_string(value))
        paso106_dump_vec3_field_data(value, label .. " " .. field_name, td_vec3)
    end
end

paso106_diagnosticar_escalas = function(character)
    logp("[PawnResearch] ===== PASO 106 ESCALAS FIELD_GET_DATA =====")

    character = character or (get_target_character_for_debug and get_target_character_for_debug() or nil)
    if character == nil then
        logp("[PawnResearch] PASO 106 character=nil")
        logp("[PawnResearch] ===== FIN PASO 106 ESCALAS FIELD_GET_DATA =====")
        return false, "character nil"
    end

    local cid = safe(function() return character:get_field("_CharacterID") end)
    if cid == nil then
        cid = safe(function() return character:get_field("CharacterID") end)
    end
    logp("[PawnResearch] PASO 106 CID=" .. tostring(cid))

    if tostring(cid) ~= "2375506998" then
        logp("[PawnResearch] PASO 106 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 106 ESCALAS FIELD_GET_DATA =====")
        return false, "CID no autorizado"
    end

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 106 PartSwapper=nil")
        logp("[PawnResearch] ===== FIN PASO 106 ESCALAS FIELD_GET_DATA =====")
        return false, "PartSwapper nil"
    end

    logp("[PawnResearch] PASO 106 PartSwapper tipo=" .. tostring(object_type_name(ps)))

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 106 BodyEditor=nil en PartSwapper::_BodyEditor")
        logp("[PawnResearch] ===== FIN PASO 106 ESCALAS FIELD_GET_DATA =====")
        return false, "BodyEditor nil"
    end

    logp("[PawnResearch] PASO 106 BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))

    local td_vec3 = safe(function() return sdk.find_type_definition("via.vec3") end)
    if td_vec3 == nil then
        logp("[PawnResearch] PASO 106 via.vec3 TypeDefinition=nil")
        return false, "via.vec3 td nil"
    end
    logp("[PawnResearch] PASO 106 via.vec3 confirmado=" .. tostring(safe(function() return td_vec3:get_full_name() end)))

    local apply_scales = safe(function() return body_editor:get_field("_ApplyEditScales") end)
    if apply_scales == nil then
        logp("[PawnResearch] PASO 106 _ApplyEditScales=nil")
        logp("[PawnResearch] ===== FIN PASO 106 ESCALAS FIELD_GET_DATA =====")
        return false, "ApplyEditScales nil"
    end

    local enumerator = safe(function() return apply_scales:GetEnumerator() end)
    if enumerator == nil then
        logp("[PawnResearch] PASO 106 enumerator=nil")
        logp("[PawnResearch] ===== FIN PASO 106 ESCALAS FIELD_GET_DATA =====")
        return false, "enumerator nil"
    end

    local height_hash = 1497737450
    local matches = 0
    local shown = 0

    while safe(function() return enumerator:MoveNext() end) do
        local outer = safe(function() return enumerator:get_Current() end)
        if outer ~= nil then
            local joint_hash = safe(function() return outer.Key end)
            local inner = safe(function() return outer.Value end)
            if inner ~= nil then
                local inner_enum = safe(function() return inner:GetEnumerator() end)
                while inner_enum ~= nil and safe(function() return inner_enum:MoveNext() end) do
                    local pair = safe(function() return inner_enum:get_Current() end)
                    if pair ~= nil then
                        local edit_hash = safe(function() return pair.Key end)
                        if tonumber(edit_hash) == height_hash then
                            matches = matches + 1
                            if shown < 3 then
                                shown = shown + 1
                                local item = safe(function() return pair.Value end)
                                logp("[PawnResearch] PASO 106 HEIGHT MATCH #" .. tostring(shown)
                                    .. " joint_hash=" .. tostring(joint_hash))
                                paso106_dump_jointeditdata(item,
                                    "HEIGHT MATCH #" .. tostring(shown),
                                    td_vec3)
                            end
                        end
                    end
                end
            end
        end
    end

    logp("[PawnResearch] PASO 106 height_matches=" .. tostring(matches)
        .. " muestras=" .. tostring(shown))
    logp("[PawnResearch] PASO 106 NOTA: solo lectura; no hubo escrituras ni refresh visual")
    logp("[PawnResearch] ===== FIN PASO 106 ESCALAS FIELD_GET_DATA =====")
    return true, "Diagnostico Paso 106 terminado; revisar log."
end

logp("[PawnResearch] ===== PASO 106 CARGADO (Field:get_data sobre via.vec3) =====")


-- ============================================================
-- PASO 107: diagnostico SOLO LECTURA de via.vec3 despues de
-- preparar _ApplyEditScales con setupApplyEditScales().
--
-- El Paso 106 encontro BodyEditor y via.vec3, pero _ApplyEditScales
-- estaba nil porque la tabla no habia sido preparada en esa ejecucion.
-- Aqui se usa el metodo nativo confirmado setupApplyEditScales().
-- Despues se vuelve a obtener _ApplyEditScales desde el BodyEditor y
-- se prueban los campos x/y/z mediante Field:get_data().
--
-- No se escribe nada, no se modifica Human y no se hace refresh visual.
-- ============================================================
paso107_leer_campo_vec3 = function(vec, td_vec3, field_name, label)
    if vec == nil or td_vec3 == nil then
        logp("[PawnResearch] PASO 107 " .. label .. " " .. field_name .. " sin_objeto_o_td")
        return
    end

    local fields = safe(function() return td_vec3:get_fields() end) or {}
    for _, field in ipairs(fields) do
        local fname = safe(function() return field:get_name() end)
        local static_flag = safe(function() return field:is_static() end)
        if fname == field_name and static_flag ~= true then
            local ftype = safe(function()
                local ft = field:get_type()
                return ft and ft:get_full_name() or "<?>"
            end) or "<?>"

            logp("[PawnResearch] PASO 107 " .. label .. " " .. field_name
                .. " FIELD tipo=" .. tostring(ftype))

            local value_data = safe(function() return field:get_data(vec) end)
            logp("[PawnResearch] PASO 107 " .. label .. " " .. field_name
                .. " FIELD_GET_DATA=" .. value_to_string(value_data)
                .. " tipo_valor=" .. tostring(type(value_data)))
            return
        end
    end

    logp("[PawnResearch] PASO 107 " .. label .. " " .. field_name .. " FIELD_NO_ENCONTRADO")
end

paso107_dump_vec3_field_data = function(vec, label, td_vec3)
    if vec == nil then
        logp("[PawnResearch] PASO 107 " .. label .. " vec=nil")
        return
    end

    logp("[PawnResearch] PASO 107 " .. label
        .. " instancia=" .. value_to_string(vec))

    paso107_leer_campo_vec3(vec, td_vec3, "x", label)
    paso107_leer_campo_vec3(vec, td_vec3, "y", label)
    paso107_leer_campo_vec3(vec, td_vec3, "z", label)
end

paso107_dump_jointeditdata = function(item, label, td_vec3)
    if item == nil then
        logp("[PawnResearch] PASO 107 " .. label .. " JointEditData=nil")
        return
    end

    logp("[PawnResearch] PASO 107 " .. label .. " tipo=" .. object_type_name(item))

    local names = {
        "_UpperScale",
        "_LowerScale",
        "_UpperTranslate",
        "_LowerTranslate"
    }

    for _, field_name in ipairs(names) do
        local value = safe(function() return item:get_field(field_name) end)
        logp("[PawnResearch] PASO 107 " .. label
            .. " DIRECT " .. field_name .. "=" .. value_to_string(value))
        paso107_dump_vec3_field_data(value, label .. " " .. field_name, td_vec3)
    end
end

paso107_diagnosticar_escalas = function(character)
    logp("[PawnResearch] ===== PASO 107 PREPARAR Y LEER ESCALAS =====")

    character = character or (get_target_character_for_debug and get_target_character_for_debug() or nil)
    if character == nil then
        logp("[PawnResearch] PASO 107 character=nil")
        logp("[PawnResearch] ===== FIN PASO 107 PREPARAR Y LEER ESCALAS =====")
        return false, "character nil"
    end

    local cid = safe(function() return character:get_field("_CharacterID") end)
    if cid == nil then
        cid = safe(function() return character:get_field("CharacterID") end)
    end
    logp("[PawnResearch] PASO 107 CID=" .. tostring(cid))

    if tostring(cid) ~= "2375506998" then
        logp("[PawnResearch] PASO 107 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 107 PREPARAR Y LEER ESCALAS =====")
        return false, "CID no autorizado"
    end

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 107 PartSwapper=nil")
        logp("[PawnResearch] ===== FIN PASO 107 PREPARAR Y LEER ESCALAS =====")
        return false, "PartSwapper nil"
    end

    logp("[PawnResearch] PASO 107 PartSwapper tipo=" .. tostring(object_type_name(ps)))

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 107 BodyEditor=nil en PartSwapper::_BodyEditor")
        logp("[PawnResearch] ===== FIN PASO 107 PREPARAR Y LEER ESCALAS =====")
        return false, "BodyEditor nil"
    end

    logp("[PawnResearch] PASO 107 BodyEditor tipo=" .. tostring(object_type_name(body_editor)))
    logp("[PawnResearch] PASO 107 BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))

    local setup_ok, setup_err = safe_call(body_editor, "setupApplyEditScales")
    logp("[PawnResearch] PASO 107 setupApplyEditScales ok=" .. tostring(setup_ok)
        .. " err=" .. tostring(setup_err))

    local td_vec3 = safe(function() return sdk.find_type_definition("via.vec3") end)
    if td_vec3 == nil then
        logp("[PawnResearch] PASO 107 via.vec3 TypeDefinition=nil")
        logp("[PawnResearch] ===== FIN PASO 107 PREPARAR Y LEER ESCALAS =====")
        return false, "via.vec3 td nil"
    end

    logp("[PawnResearch] PASO 107 via.vec3 confirmado="
        .. tostring(safe(function() return td_vec3:get_full_name() end)))

    local apply_scales = safe(function() return body_editor:get_field("_ApplyEditScales") end)
    if apply_scales == nil then
        logp("[PawnResearch] PASO 107 _ApplyEditScales=nil DESPUES de setupApplyEditScales")
        logp("[PawnResearch] ===== FIN PASO 107 PREPARAR Y LEER ESCALAS =====")
        return false, "ApplyEditScales nil after setup"
    end

    logp("[PawnResearch] PASO 107 _ApplyEditScales=" .. value_to_string(apply_scales))

    local enumerator = safe(function() return apply_scales:GetEnumerator() end)
    if enumerator == nil then
        logp("[PawnResearch] PASO 107 enumerator=nil")
        logp("[PawnResearch] ===== FIN PASO 107 PREPARAR Y LEER ESCALAS =====")
        return false, "enumerator nil"
    end

    local height_hash = 1497737450
    local matches = 0
    local shown = 0

    while safe(function() return enumerator:MoveNext() end) do
        local outer = safe(function() return enumerator:get_Current() end)
        if outer ~= nil then
            local joint_hash = safe(function() return outer.Key end)
            local inner = safe(function() return outer.Value end)
            if inner ~= nil then
                local inner_enum = safe(function() return inner:GetEnumerator() end)
                while inner_enum ~= nil and safe(function() return inner_enum:MoveNext() end) do
                    local pair = safe(function() return inner_enum:get_Current() end)
                    if pair ~= nil then
                        local edit_hash = safe(function() return pair.Key end)
                        if tonumber(edit_hash) == height_hash then
                            matches = matches + 1
                            if shown < 3 then
                                shown = shown + 1
                                local item = safe(function() return pair.Value end)
                                logp("[PawnResearch] PASO 107 HEIGHT MATCH #" .. tostring(shown)
                                    .. " joint_hash=" .. tostring(joint_hash))
                                paso107_dump_jointeditdata(item,
                                    "HEIGHT MATCH #" .. tostring(shown),
                                    td_vec3)
                            end
                        end
                    end
                end
            end
        end
    end

    logp("[PawnResearch] PASO 107 height_matches=" .. tostring(matches)
        .. " muestras=" .. tostring(shown))
    logp("[PawnResearch] PASO 107 NOTA: solo lectura; setupApplyEditScales fue llamado, no hubo escrituras ni refresh visual")
    logp("[PawnResearch] ===== FIN PASO 107 PREPARAR Y LEER ESCALAS =====")
    return true, "Diagnostico Paso 107 terminado; revisar log."
end

logp("[PawnResearch] ===== PASO 107 CARGADO (setupApplyEditScales + Field:get_data) =====")


-- ============================================================
-- PASO 108: Comparar claves de _ApplyEditScales antes/despues
-- ============================================================
-- El Paso 107 confirmo que setupApplyEditScales crea la tabla,
-- pero despues el hash de altura 1497737450 ya no aparece.
-- Aqui comparamos la estructura antes y despues, sin escribir.

paso108_inspeccionar_inner = function(inner, outer_index, phase)
    if inner == nil then
        logp("[PawnResearch] PASO 108 " .. phase .. " OUTER #" .. tostring(outer_index) .. " inner=nil")
        return 0
    end

    local count = safe(function() return inner.Count end)
    logp("[PawnResearch] PASO 108 " .. phase .. " OUTER #" .. tostring(outer_index)
        .. " inner.Count=" .. tostring(count))

    local contains_height = safe(function() return inner:ContainsKey(1497737450) end)
    logp("[PawnResearch] PASO 108 " .. phase .. " OUTER #" .. tostring(outer_index)
        .. " ContainsKey(height)= " .. tostring(contains_height))

    local shown = 0
    local en = safe(function() return inner:GetEnumerator() end)
    while en ~= nil and shown < 12 and safe(function() return en:MoveNext() end) do
        local pair = safe(function() return en:get_Current() end)
        if pair ~= nil then
            shown = shown + 1
            local key = safe(function() return pair.Key end)
            local value = safe(function() return pair.Value end)
            logp("[PawnResearch] PASO 108 " .. phase .. " OUTER #" .. tostring(outer_index)
                .. " KEY #" .. tostring(shown)
                .. " edit_hash=" .. tostring(key)
                .. " value_type=" .. tostring(object_type_name(value)))
        end
    end

    logp("[PawnResearch] PASO 108 " .. phase .. " OUTER #" .. tostring(outer_index)
        .. " keys_mostradas=" .. tostring(shown))
    return shown
end

paso108_inspeccionar_apply_scales = function(apply_scales, phase)
    if apply_scales == nil then
        logp("[PawnResearch] PASO 108 " .. phase .. " _ApplyEditScales=nil")
        return 0
    end

    logp("[PawnResearch] PASO 108 " .. phase .. " _ApplyEditScales=" .. value_to_string(apply_scales))
    local outer_count = safe(function() return apply_scales.Count end)
    logp("[PawnResearch] PASO 108 " .. phase .. " outer_count=" .. tostring(outer_count))

    local en = safe(function() return apply_scales:GetEnumerator() end)
    local shown_outer = 0
    local height_total = 0

    while en ~= nil and shown_outer < 3 and safe(function() return en:MoveNext() end) do
        local outer = safe(function() return en:get_Current() end)
        if outer ~= nil then
            shown_outer = shown_outer + 1
            local joint_hash = safe(function() return outer.Key end)
            local inner = safe(function() return outer.Value end)
            logp("[PawnResearch] PASO 108 " .. phase .. " OUTER #" .. tostring(shown_outer)
                .. " joint_hash=" .. tostring(joint_hash))
            paso108_inspeccionar_inner(inner, shown_outer, phase)
        end
    end

    -- Segundo barrido: solo cuenta cuantos inners contienen el hash de altura.
    local en2 = safe(function() return apply_scales:GetEnumerator() end)
    while en2 ~= nil and safe(function() return en2:MoveNext() end) do
        local outer = safe(function() return en2:get_Current() end)
        if outer ~= nil then
            local inner = safe(function() return outer.Value end)
            if inner ~= nil then
                local has_height = safe(function() return inner:ContainsKey(1497737450) end)
                if has_height == true then
                    height_total = height_total + 1
                end
            end
        end
    end

    logp("[PawnResearch] PASO 108 " .. phase
        .. " inners_con_height=" .. tostring(height_total))
    return height_total
end

paso108_comparar_apply_edit_scales = function(character)
    logp("[PawnResearch] ===== PASO 108 COMPARAR APPLYEDITSCales =====")

    character = character or (get_target_character_for_debug and get_target_character_for_debug() or nil)
    if character == nil then
        logp("[PawnResearch] PASO 108 character=nil")
        logp("[PawnResearch] ===== FIN PASO 108 COMPARAR APPLYEDITSCales =====")
        return false, "character nil"
    end

    local cid = safe(function() return character:get_field("_CharacterID") end)
    if cid == nil then
        cid = safe(function() return character:get_field("CharacterID") end)
    end
    logp("[PawnResearch] PASO 108 CID=" .. tostring(cid))

    if tostring(cid) ~= "2375506998" then
        logp("[PawnResearch] PASO 108 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 108 COMPARAR APPLYEDITSCales =====")
        return false, "CID no autorizado"
    end

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 108 PartSwapper=nil")
        logp("[PawnResearch] ===== FIN PASO 108 COMPARAR APPLYEDITSCales =====")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 108 BodyEditor=nil")
        logp("[PawnResearch] ===== FIN PASO 108 COMPARAR APPLYEDITSCales =====")
        return false, "BodyEditor nil"
    end

    logp("[PawnResearch] PASO 108 BodyEditor tipo=" .. tostring(object_type_name(body_editor)))
    logp("[PawnResearch] PASO 108 BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))

    local before = safe(function() return body_editor:get_field("_ApplyEditScales") end)
    local before_height = paso108_inspeccionar_apply_scales(before, "ANTES_SETUP")

    local setup_result, setup_err = safe_call(body_editor, "setupApplyEditScales")
    logp("[PawnResearch] PASO 108 setupApplyEditScales resultado=" .. tostring(setup_result)
        .. " err=" .. tostring(setup_err))

    local after = safe(function() return body_editor:get_field("_ApplyEditScales") end)
    local after_height = paso108_inspeccionar_apply_scales(after, "DESPUES_SETUP")

    logp("[PawnResearch] PASO 108 RESUMEN before_height=" .. tostring(before_height)
        .. " after_height=" .. tostring(after_height))
    logp("[PawnResearch] PASO 108 NOTA: solo lectura estructural; setupApplyEditScales es la unica llamada nativa y no hubo escrituras ni refresh visual")
    logp("[PawnResearch] ===== FIN PASO 108 COMPARAR APPLYEDITSCales =====")
    return true, "Comparacion Paso 108 terminada; revisar log."
end

logp("[PawnResearch] ===== PASO 108 CARGADO (comparacion de claves antes/despues setupApplyEditScales) =====")


-- ============================================================
-- PASO 109: Enumeracion real de _ApplyEditScales
-- ============================================================
-- En el Paso 108 se usaron propiedades como .Count, .Key y .Value.
-- Ese acceso no demostro ser fiable en estos Dictionary genericos.
-- Paso 95 y Paso 99 ya demostraron la ruta estable: safe_call() sobre
-- get_Count, GetEnumerator, MoveNext, get_Current, get_Key, get_Value
-- y ContainsKey. Aqui reutilizamos esa ruta ya confirmada.
-- Solo lectura, sin escrituras ni refresh visual.

paso109_reflexionar_dictionary = function(obj, etiqueta)
    if obj == nil then
        logp("[PawnResearch] PASO 109 " .. etiqueta .. " objeto=nil")
        return
    end

    logp("[PawnResearch] PASO 109 " .. etiqueta .. " objeto=" .. value_to_string(obj))
    logp("[PawnResearch] PASO 109 " .. etiqueta .. " tipo=" .. tostring(object_type_name(obj)))

    -- Si el objeto expone TypeDefinition, usamos la reflexion existente para
    -- confirmar solo los metodos de Dictionary que necesitamos leer.
    local td = safe(function() return obj:get_type_definition() end)
    local seen = {}
    while td ~= nil do
        local tn = safe(function() return td:get_full_name() end) or "<?>"
        if seen[tn] then break end
        seen[tn] = true

        local methods = safe(function() return td:get_methods() end) or {}
        for _, method in ipairs(methods) do
            local mn = safe(function() return method:get_name() end)
            if mn == "get_Count"
                or mn == "GetEnumerator"
                or mn == "ContainsKey"
                or mn == "TryGetValue"
                or mn == "get_Current"
                or mn == "MoveNext"
                or mn == "get_Key"
                or mn == "get_Value"
                or mn == "get_Item"
            then
                dump_method_signature(method, "[PawnResearch] PASO 109 " .. etiqueta .. " ")
            end
        end

        td = safe(function() return td:get_parent_type() end)
    end
end

paso109_leer_count = function(obj, etiqueta)
    if obj == nil then
        logp("[PawnResearch] PASO 109 " .. etiqueta .. " get_Count objeto=nil")
        return nil
    end

    local value = safe_call(obj, "get_Count")
    logp("[PawnResearch] PASO 109 " .. etiqueta .. " get_Count=" .. tostring(value))
    return value
end

paso109_obtener_pair = function(enumerator, etiqueta)
    if enumerator == nil then
        return nil, nil, nil
    end

    local current = safe_call(enumerator, "get_Current")
    if current == nil then
        logp("[PawnResearch] PASO 109 " .. etiqueta .. " get_Current=nil")
        return nil, nil, nil
    end

    local key = safe_call(current, "get_Key")
    local value = safe_call(current, "get_Value")
    return current, key, value
end

paso109_enumerar_inner = function(inner, etiqueta)
    if inner == nil then
        logp("[PawnResearch] PASO 109 " .. etiqueta .. " inner=nil")
        return 0, false
    end

    local inner_count = paso109_leer_count(inner, etiqueta)
    local has_height = safe_call(inner, "ContainsKey", 1497737450)
    logp("[PawnResearch] PASO 109 " .. etiqueta
        .. " ContainsKey(height)=" .. tostring(has_height)
        .. " count=" .. tostring(inner_count))

    local ien = safe_call(inner, "GetEnumerator")
    logp("[PawnResearch] PASO 109 " .. etiqueta
        .. " GetEnumerator=" .. tostring(ien))
    if ien == nil then
        return 0, has_height == true
    end

    local shown = 0
    while shown < 12 do
        local moved = safe_call(ien, "MoveNext")
        logp("[PawnResearch] PASO 109 " .. etiqueta
            .. " MoveNext=" .. tostring(moved))
        if moved ~= true then
            break
        end

        local _, key, value = paso109_obtener_pair(ien, etiqueta)
        if key == nil then
            break
        end

        shown = shown + 1
        logp("[PawnResearch] PASO 109 " .. etiqueta
            .. " KEY #" .. tostring(shown)
            .. " edit_hash=" .. tostring(key)
            .. " value_type=" .. tostring(object_type_name(value)))
    end

    return shown, has_height == true
end

paso109_enumerar_apply_scales = function(apply_scales, phase)
    if apply_scales == nil then
        logp("[PawnResearch] PASO 109 " .. phase .. " _ApplyEditScales=nil")
        return 0, 0
    end

    logp("[PawnResearch] PASO 109 " .. phase
        .. " _ApplyEditScales=" .. value_to_string(apply_scales))

    local total = paso109_leer_count(apply_scales, phase .. " OUTER")
    local en = safe_call(apply_scales, "GetEnumerator")
    logp("[PawnResearch] PASO 109 " .. phase
        .. " GetEnumerator=" .. tostring(en))

    if en == nil then
        return 0, 0
    end

    local outer_total = 0
    local height_total = 0
    local visible_limit = 6

    while true do
        local moved = safe_call(en, "MoveNext")
        logp("[PawnResearch] PASO 109 " .. phase
            .. " OUTER MoveNext=" .. tostring(moved))
        if moved ~= true then
            break
        end

        outer_total = outer_total + 1
        local _, joint_hash, inner = paso109_obtener_pair(en, phase .. " OUTER #" .. tostring(outer_total))
        if joint_hash == nil then
            break
        end

        if outer_total <= visible_limit then
            logp("[PawnResearch] PASO 109 " .. phase
                .. " OUTER #" .. tostring(outer_total)
                .. " joint_hash=" .. tostring(joint_hash)
                .. " inner_type=" .. tostring(object_type_name(inner)))

            local _, has_height = paso109_enumerar_inner(
                inner,
                phase .. " OUTER #" .. tostring(outer_total)
            )
            if has_height then
                height_total = height_total + 1
            end
        else
            local has_height = safe_call(inner, "ContainsKey", 1497737450)
            if has_height == true then
                height_total = height_total + 1
            end
        end
    end

    logp("[PawnResearch] PASO 109 " .. phase
        .. " RESUMEN get_Count=" .. tostring(total)
        .. " enumerados=" .. tostring(outer_total)
        .. " inners_con_height=" .. tostring(height_total))
    return outer_total, height_total
end

paso109_diagnosticar_apply_edit_scales = function(character)
    logp("[PawnResearch] ===== PASO 109 ENUMERAR APPLYEDITSCales =====")

    character = character or (get_target_character_for_debug and get_target_character_for_debug() or nil)
    if character == nil then
        logp("[PawnResearch] PASO 109 character=nil")
        logp("[PawnResearch] ===== FIN PASO 109 ENUMERAR APPLYEDITSCales =====")
        return false, "character nil"
    end

    local cid = safe(function() return character:get_field("_CharacterID") end)
    if cid == nil then
        cid = safe(function() return character:get_field("CharacterID") end)
    end
    logp("[PawnResearch] PASO 109 CID=" .. tostring(cid))

    if tostring(cid) ~= "2375506998" then
        logp("[PawnResearch] PASO 109 BLOQUEADO CID=" .. tostring(cid))
        logp("[PawnResearch] ===== FIN PASO 109 ENUMERAR APPLYEDITSCales =====")
        return false, "CID no autorizado"
    end

    local ps = get_part_swapper(character)
    if ps == nil then
        logp("[PawnResearch] PASO 109 PartSwapper=nil")
        logp("[PawnResearch] ===== FIN PASO 109 ENUMERAR APPLYEDITSCales =====")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    if body_editor == nil then
        logp("[PawnResearch] PASO 109 BodyEditor=nil")
        logp("[PawnResearch] ===== FIN PASO 109 ENUMERAR APPLYEDITSCales =====")
        return false, "BodyEditor nil"
    end

    logp("[PawnResearch] PASO 109 BodyEditor tipo=" .. tostring(object_type_name(body_editor)))
    logp("[PawnResearch] PASO 109 BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))

    local before = safe(function() return body_editor:get_field("_ApplyEditScales") end)
    if before == nil then
        logp("[PawnResearch] PASO 109 ANTES_SETUP _ApplyEditScales=nil")
        return false, "ApplyEditScales antes nil"
    end

    paso109_reflexionar_dictionary(before, "ANTES_SETUP _ApplyEditScales")
    local _, before_height = paso109_enumerar_apply_scales(before, "ANTES_SETUP")

    local setup_result = safe_call(body_editor, "setupApplyEditScales")
    logp("[PawnResearch] PASO 109 setupApplyEditScales resultado=" .. tostring(setup_result))

    local after = safe(function() return body_editor:get_field("_ApplyEditScales") end)
    if after == nil then
        logp("[PawnResearch] PASO 109 DESPUES_SETUP _ApplyEditScales=nil")
        return false, "ApplyEditScales despues nil"
    end

    paso109_reflexionar_dictionary(after, "DESPUES_SETUP _ApplyEditScales")
    local _, after_height = paso109_enumerar_apply_scales(after, "DESPUES_SETUP")

    logp("[PawnResearch] PASO 109 RESUMEN before_height=" .. tostring(before_height)
        .. " after_height=" .. tostring(after_height))
    logp("[PawnResearch] PASO 109 NOTA: solo lectura; setupApplyEditScales fue la unica llamada nativa y no hubo escrituras ni refresh visual")
    logp("[PawnResearch] ===== FIN PASO 109 ENUMERAR APPLYEDITSCales =====")
    return true, "Diagnostico Paso 109 terminado; revisar log."
end

logp("[PawnResearch] ===== PASO 109 CARGADO (enumeracion real con get_Key/get_Value/get_Count) =====")


-- ============================================================
-- PASO 110: INSPECCION DE via.vec3 (LECTURA)
-- ============================================================
-- Esta iteracion conserva el diagnostico que se ejecuto antes de la
-- auditoria post-actualizacion. No modifica ningun objeto del peon.

paso110_inspeccionar_vec3 = function(character)
    logp("[PawnResearch] ===== PASO 110 VEC3 Y METODOS =====")
    if character == nil then
        logp("[PawnResearch] PASO 110 character=nil")
        logp("[PawnResearch] ===== FIN PASO 110 VEC3 Y METODOS =====")
        return false, "character nil"
    end

    local cid = safe(function() return character:get_field("_CharacterID") end)
    if cid == nil then cid = get_field_value_by_name(character, "CharacterID") end
    logp("[PawnResearch] PASO 110 CID=" .. tostring(cid))

    local ps = get_part_swapper(character)
    local body_editor = ps and get_field_value_by_name(ps, "_BodyEditor") or nil
    logp("[PawnResearch] PASO 110 PartSwapper tipo=" .. tostring(object_type_name(ps)))
    logp("[PawnResearch] PASO 110 BodyEditor tipo=" .. tostring(object_type_name(body_editor)))
    logp("[PawnResearch] PASO 110 BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight")))

    local scales = body_editor and get_field_value_by_name(body_editor, "_ApplyEditScales") or nil
    logp("[PawnResearch] PASO 110 _ApplyEditScales tipo=" .. tostring(object_type_name(scales)))
    logp("[PawnResearch] PASO 110 _ApplyEditScales count=" .. tostring(safe_call(scales, "get_Count")))

    local vec3_td = safe(function() return sdk.find_type_definition("via.vec3") end)
    logp("[PawnResearch] PASO 110 via.vec3=" .. tostring(vec3_td and safe(function() return vec3_td:get_full_name() end)))
    if vec3_td == nil or scales == nil then
        logp("[PawnResearch] PASO 110 No se pudo inspeccionar via.vec3 o ApplyEditScales")
        logp("[PawnResearch] ===== FIN PASO 110 VEC3 Y METODOS =====")
        return false, "via.vec3 o ApplyEditScales nil"
    end

    for _, field_name in ipairs({ "x", "y", "z" }) do
        local field = find_field_in_hierarchy(vec3_td, field_name)
        local field_type = field and safe(function() return field:get_type():get_full_name() end) or "nil"
        logp("[PawnResearch] PASO 110 via.vec3 FIELD " .. field_name .. " tipo=" .. tostring(field_type))
    end
    local vec_methods = safe(function() return vec3_td:get_methods() end) or {}
    local method_count = 0
    for _, method in ipairs(vec_methods) do
        local method_name = safe(function() return method:get_name() end)
        if method_name == ".ctor" or method_name == "get_Item" or method_name == "set_Item"
            or method_name == "op_Addition" or method_name == "op_Subtraction"
            or method_name == "op_Multiply" or method_name == "op_Division"
            or method_name == "op_Explicit" then
            method_count = method_count + 1
            local ret = safe(function() return method:get_return_type():get_full_name() end)
            local nparams = safe(function() return method:get_num_params() end)
            logp("[PawnResearch] PASO 110 via.vec3 METHOD " .. tostring(method_name)
                .. " return=" .. tostring(ret) .. " num_params=" .. tostring(nparams))
        end
    end
    logp("[PawnResearch] PASO 110 via.vec3 method_count=" .. tostring(method_count))

    local outer_enum = safe_call(scales, "GetEnumerator")
    local moved = safe_call(outer_enum, "MoveNext")
    if moved ~= true then
        logp("[PawnResearch] PASO 110 ApplyEditScales sin primera entrada")
        logp("[PawnResearch] ===== FIN PASO 110 VEC3 Y METODOS =====")
        return false, "ApplyEditScales vacio"
    end
    local pair = safe_call(outer_enum, "get_Current")
    local joint_hash = safe_call(pair, "get_Key")
    local inner = safe_call(pair, "get_Value")
    local contains_height = safe_call(inner, "ContainsKey", 1497737450)
    logp("[PawnResearch] PASO 110 inner tipo=" .. tostring(object_type_name(inner))
        .. " count=" .. tostring(safe_call(inner, "get_Count")))
    logp("[PawnResearch] PASO 110 joint_hash=" .. tostring(joint_hash)
        .. " height_present=" .. tostring(contains_height))

    if contains_height == true then
        local joint = safe_call(inner, "get_Item", 1497737450)
        logp("[PawnResearch] PASO 110 JointEditData=" .. value_to_string(joint)
            .. " tipo=" .. tostring(object_type_name(joint)))
        for _, field_name in ipairs({ "_UpperScale", "_LowerScale", "_UpperTranslate", "_LowerTranslate" }) do
            local vec = safe(function() return joint:get_field(field_name) end)
            logp("[PawnResearch] PASO 110 DIRECT " .. field_name .. "=" .. tostring(vec))
            for _, axis in ipairs({ "x", "y", "z" }) do
                local field = find_field_in_hierarchy(vec3_td, axis)
                local value = field and safe(function() return field:get_data(vec) end) or nil
                logp("[PawnResearch] PASO 110 " .. field_name .. " FIELD_GET_DATA " .. axis .. "=" .. tostring(value))
            end
        end
    end

    logp("[PawnResearch] PASO 110 NOTA: solo lectura; no hubo escrituras ni refresh visual")
    logp("[PawnResearch] ===== FIN PASO 110 VEC3 Y METODOS =====")
    return true, "Diagnostico Paso 110 terminado; revisar log."
end

logp("[PawnResearch] ===== PASO 110 CARGADO (inspeccion via.vec3 solo lectura) =====")


-- ============================================================
-- PASO 111: AUDITORIA POST-TU4 E INTEGRACION GUIADA DE APARIENCIA
-- ============================================================
-- Contexto:
--   El juego recibio Title Update 4.0 y el REFramework instalado por el
--   usuario ahora es una Nightly. El mod Pawn Appearance Manager 1.2
--   (actualizado el 24/10/2026) aporta una ruta util para aplicar piel,
--   cabello, colores y EditValues, pero su seleccion de objetivos se basa
--   en SavedPartyPawnList/slots. PawnResearch conserva el roster por
--   CharacterID y su candado de seguridad.
--
-- Este paso NO importa ni ejecuta codigo del otro mod. Comprueba en el
-- TDB real de esta instalacion las firmas y campos de las APIs que usa
-- esa tecnica, para integrar despues solo los miembros que sigan presentes.
-- Tambien investiga get_Item de via.vec3, ya que Field:get_data(x) del
-- Paso 110 produjo numeros imposibles para el componente x.
--
-- Solo lectura: no se llama requestSwap, setupApplyEditScales, applyEdit,
-- restore, requestApplyProperties ni ningun setter. No se escribe ningun
-- campo de Character, PartSwapper, BodyEditor, Hair, BodyHair o Human.
-- ============================================================

paso111_log_metodo = function(method, prefix)
    if method == nil then return end
    local name = safe(function() return method:get_name() end) or "<?>"
    local is_static = safe(function() return method:is_static() end)
    local param_count = safe(function() return method:get_num_params() end)
    local params = safe(function() return method:get_param_types() end)
    local param_names = {}

    if type(params) == "table" then
        for i, ptype in ipairs(params) do
            param_names[#param_names + 1] = safe(function() return ptype:get_full_name() end) or "<?>"
        end
    elseif params ~= nil and type(param_count) == "number" then
        for i = 0, param_count - 1 do
            local ptype = safe(function() return params[i] end)
            if ptype == nil then ptype = safe(function() return params[i + 1] end) end
            param_names[#param_names + 1] = ptype and (safe(function() return ptype:get_full_name() end) or "<?>") or "<tipo no legible>"
        end
    end

    local return_type = safe(function() return method:get_return_type() end)
    local return_name = return_type and safe(function() return return_type:get_full_name() end) or "<?>"
    logp(prefix .. "METHOD " .. tostring(name)
        .. "(" .. table.concat(param_names, ", ") .. ")"
        .. " num_params=" .. tostring(param_count)
        .. " -> " .. tostring(return_name)
        .. " static=" .. tostring(is_static))
end

paso111_dump_tipo = function(type_name, wanted_fields, wanted_methods)
    local td = safe(function() return sdk.find_type_definition(type_name) end)
    if td == nil then
        logp("[PawnResearch] PASO 111 TYPE " .. tostring(type_name) .. " = nil")
        return nil
    end

    logp("[PawnResearch] PASO 111 TYPE " .. tostring(type_name) .. " = "
        .. tostring(safe(function() return td:get_full_name() end) or type_name))

    local current = td
    local seen_types = {}
    while current ~= nil do
        local current_name = safe(function() return current:get_full_name() end) or "<?>"
        if seen_types[current_name] then break end
        seen_types[current_name] = true
        local fields = safe(function() return current:get_fields() end) or {}
        for _, field in ipairs(fields) do
            local name = safe(function() return field:get_name() end)
            if name ~= nil and wanted_fields and wanted_fields[name] then
                local ft = safe(function() return field:get_type() end)
                local type_label = ft and safe(function() return ft:get_full_name() end) or "<?>"
                local is_static = safe(function() return field:is_static() end)
                local value = nil
                if is_static == true then value = safe(function() return field:get_data(nil) end) end
                logp("[PawnResearch] PASO 111 FIELD " .. tostring(type_name)
                    .. "::" .. tostring(name) .. " owner=" .. tostring(current_name)
                    .. " tipo=" .. tostring(type_label)
                    .. " static=" .. tostring(is_static)
                    .. (is_static == true and (" valor=" .. tostring(value)) or ""))
            end
        end
        current = safe(function() return current:get_parent_type() end)
    end

    current = td
    seen_types = {}
    while current ~= nil do
        local current_name = safe(function() return current:get_full_name() end) or "<?>"
        if seen_types[current_name] then break end
        seen_types[current_name] = true
        local methods = safe(function() return current:get_methods() end) or {}
        for _, method in ipairs(methods) do
            local name = safe(function() return method:get_name() end)
            if name ~= nil and wanted_methods and wanted_methods[name] then
                paso111_log_metodo(method, "[PawnResearch] PASO 111 " .. tostring(type_name) .. " ")
            end
        end
        current = safe(function() return current:get_parent_type() end)
    end
    return td
end

paso111_dump_enum = function(type_name)
    local td = safe(function() return sdk.find_type_definition(type_name) end)
    if td == nil then
        logp("[PawnResearch] PASO 111 ENUM " .. tostring(type_name) .. "=nil")
        return nil
    end
    logp("[PawnResearch] PASO 111 ENUM " .. tostring(type_name)
        .. "=" .. tostring(safe(function() return td:get_full_name() end) or type_name))
    local fields = safe(function() return td:get_fields() end) or {}
    local count = 0
    for _, field in ipairs(fields) do
        local is_static = safe(function() return field:is_static() end)
        if is_static == true then
            local name = safe(function() return field:get_name() end) or "<?>"
            local value = safe(function() return field:get_data(nil) end)
            local field_type = safe(function() return field:get_type():get_full_name() end) or "<?>"
            logp("[PawnResearch] PASO 111 ENUM FIELD " .. tostring(name)
                .. " tipo=" .. tostring(field_type) .. " valor=" .. tostring(value))
            count = count + 1
        end
    end
    logp("[PawnResearch] PASO 111 ENUM " .. tostring(type_name) .. " static_fields=" .. tostring(count))
    return td
end

paso111_log_objeto = function(label, obj)
    logp("[PawnResearch] PASO 111 OBJ " .. tostring(label)
        .. "=" .. value_to_string(obj)
        .. " lua=" .. tostring(type(obj))
        .. " type=" .. tostring(object_type_name(obj)))
end

paso111_vec3_leer_indice = function(vec, method, index, param_type_name, label)
    if vec == nil then
        logp("[PawnResearch] PASO 111 VEC3 " .. tostring(label) .. " index=" .. tostring(index) .. " vec=nil")
        return nil
    end

    if method ~= nil and (param_type_name == "System.Int32" or param_type_name == "System.UInt32") then
        local ok_def, value_def = pcall(function() return method:call(vec, index) end)
        logp("[PawnResearch] PASO 111 VEC3 " .. tostring(label)
            .. " METHOD_DEFINITION_CALL(" .. tostring(param_type_name) .. ") index=" .. tostring(index)
            .. " ok=" .. tostring(ok_def) .. " value=" .. tostring(value_def))
        if ok_def and value_def ~= nil then return value_def end
    end

    local ok_direct, value_direct = pcall(function() return vec:get_Item(index) end)
    logp("[PawnResearch] PASO 111 VEC3 " .. tostring(label)
        .. " direct get_Item index=" .. tostring(index)
        .. " ok=" .. tostring(ok_direct) .. " value=" .. tostring(value_direct))
    if ok_direct and value_direct ~= nil then return value_direct end

    local ok_index, value_index = pcall(function() return vec[index] end)
    logp("[PawnResearch] PASO 111 VEC3 " .. tostring(label)
        .. " indexer index=" .. tostring(index)
        .. " ok=" .. tostring(ok_index) .. " value=" .. tostring(value_index))
    if ok_index and value_index ~= nil then return value_index end

    if param_type_name ~= nil then
        local signature = "get_Item(" .. tostring(param_type_name) .. ")"
        local ok_call, value_call = pcall(function() return vec:call(signature, index) end)
        logp("[PawnResearch] PASO 111 VEC3 " .. tostring(label)
            .. " " .. signature .. " index=" .. tostring(index)
            .. " ok=" .. tostring(ok_call) .. " value=" .. tostring(value_call))
        if ok_call and value_call ~= nil then return value_call end
    end
    return nil
end

paso111_diagnosticar_vec3 = function(vec3_td, vec, label)
    if vec == nil or vec3_td == nil then return end
    local methods = safe(function() return vec3_td:get_methods() end) or {}
    for _, method in ipairs(methods) do
        if safe(function() return method:get_name() end) == "get_Item" then
            paso111_log_metodo(method, "[PawnResearch] PASO 111 via.vec3 ")
            local param_count = safe(function() return method:get_num_params() end)
            local params = safe(function() return method:get_param_types() end)
            local param_type_name = nil
            if type(params) == "table" and params[1] ~= nil then
                param_type_name = safe(function() return params[1]:get_full_name() end)
            elseif params ~= nil then
                local ptype = safe(function() return params[0] end)
                if ptype == nil then ptype = safe(function() return params[1] end) end
                param_type_name = ptype and safe(function() return ptype:get_full_name() end) or nil
            end
            logp("[PawnResearch] PASO 111 via.vec3 get_Item param_count=" .. tostring(param_count)
                .. " param_type=" .. tostring(param_type_name))
            if param_count == 1 then
                for index = 0, 2 do
                    paso111_vec3_leer_indice(vec, method, index, param_type_name, label)
                end
                return
            end
        end
    end
    logp("[PawnResearch] PASO 111 via.vec3 get_Item sin sobrecarga de un parametro confirmada")
end

paso111_auditar_compatibilidad = function(character)
    logp("[PawnResearch] ===== PASO 111 COMPATIBILIDAD TU4 / PAM =====")
    if character == nil then
        logp("[PawnResearch] PASO 111 character=nil")
        logp("[PawnResearch] ===== FIN PASO 111 COMPATIBILIDAD TU4 / PAM =====")
        return false, "character nil"
    end

    local cid = safe(function() return character:get_field("_CharacterID") end)
    if cid == nil then cid = get_field_value_by_name(character, "CharacterID") end
    logp("[PawnResearch] PASO 111 CID=" .. tostring(cid)
        .. " protegido=" .. tostring(is_character_protected(cid)))

    local tdb_version = safe(function() return sdk.get_tdb_version() end)
    logp("[PawnResearch] PASO 111 REFramework sdk.get_tdb_version=" .. tostring(tdb_version))
    logp("[PawnResearch] PASO 111 API sdk.find_type_definition=" .. tostring(type(sdk.find_type_definition))
        .. " sdk.get_managed_singleton=" .. tostring(type(sdk.get_managed_singleton))
        .. " sdk.hook=" .. tostring(type(sdk.hook))
        .. " re.on_frame=" .. tostring(type(re.on_frame))
        .. " re.on_pre_application_entry=" .. tostring(type(re.on_pre_application_entry))
        .. " imgui.button=" .. tostring(type(imgui.button)))

    -- Reflexion de tipos clave: los nombres se basan en los tipos que ya
    -- habia confirmado PawnResearch y en los usados por el mod version 1.2.
    paso111_dump_tipo("app.PawnManager",
        { },
        { get_PawnCharacterList = true, get_SavedPartyPawnList = true, getPartyPawn = true })
    paso111_dump_tipo("app.Character",
        { CharacterID = true, _CharacterID = true, ["<HumanPartSwapper>k__BackingField"] = true },
        { get_CharaID = true, get_HumanPartSwapper = true })
    local ps_td = paso111_dump_tipo("app.PartSwapper",
        { _Meta = true, _HumanContext = true, _BodyEditor = true },
        { get_Meta = true, get_BodyDetailEditor = true, requestSwap = true,
          set_HairObj = true, get_IsAllMetaUpdate = true, set_IsAllMetaUpdate = true })
    local be_td = paso111_dump_tipo("app.BodyEditor",
        { _BodyEditContext = true, _ApplyEditScales = true, _ApplyEditValues = true },
        { get_BodyHeight = true, getEditValues = true, get_EditValues = true,
          setupApplyEditScales = true, applyEdit = true, restore = true })
    local bde_td = paso111_dump_tipo("app.BodyDetailEditor",
        { _Context = true, _Hair = true, _BodyHair = true },
        { get_Hair = true, get_BodyHair = true, get_Skin = true,
          requestApplyProperties = true, requestForceApplyDetails = true })
    local hair_td = paso111_dump_tipo("app.charaedit.ch000.Hair",
        { _RootColor = true, _TipColor = true, _CapRootColor = true },
        { get_RootColor = true, set_RootColor = true, get_TipColor = true,
          set_TipColor = true, get_CapRootColor = true, set_CapRootColor = true,
          get_AutoCapColor = true, set_AutoCapColor = true, get_TipBlend = true,
          set_TipBlend = true, get_Sheen = true, set_Sheen = true,
          get_Gloss = true, set_Gloss = true, copyFrom = true })
    local bodyhair_td = paso111_dump_tipo("app.charaedit.ch000.BodyHair",
        { _Color = true },
        { get_Color = true, set_Color = true, get_Density = true, set_Density = true, copyFrom = true })
    local color_td = paso111_dump_tipo("via.Color",
        { rgba = true },
        { get_r = true, get_g = true, get_b = true, get_a = true,
          set_r = true, set_g = true, set_b = true, set_a = true })
    local bodyctx_td = paso111_dump_tipo("app.BodyEditContext",
        { _EditValues = true },
        { get_EditValues = true, set_EditValues = true, getEditValue = true, setEditValue = true })
    paso111_dump_tipo("app.CharacterEditDefine.EditValue",
        { _EditKeyHash = true, _Value = true },
        { get_EditKeyHash = true, set_EditKeyHash = true, get_Value = true, set_Value = true })
    paso111_dump_tipo("app.EditTable.JointEditData",
        { _JointNameHash = true, _UpperScale = true, _LowerScale = true,
          _UpperTranslate = true, _LowerTranslate = true }, { })
    local vec3_td = paso111_dump_tipo("via.vec3",
        { x = true, y = true, z = true },
        { get_Item = true, set_Item = true })
    paso111_dump_tipo("app.CharacterEditDefine.MetaData",
        { _SkinStyle = true, _HairStyle = true, _Gender = true, _Species = true },
        { copyFrom = true })
    -- Valores de las banderas nativas: no reutilizar mascaras amplias sin
    -- identificar exactamente que grupos incluyen en esta version del juego.
    paso111_dump_enum("app.PartSwapper.Parts")
    paso111_dump_enum("app.CharacterEditDefine.MetaData.MetaFlags")
    paso111_dump_tipo("app.BodyDetailContext",
        { _Skin = true, _Hair = true, _BodyHair = true, _Beard = true,
          _Eyes = true, _Eyelashes = true, _Eyebrows = true, _Freckles = true },
        {})

    -- Inspeccion del objeto real del pawn, sin depender de busqueda por slots.
    local ps = get_part_swapper(character)
    paso111_log_objeto("PartSwapper", ps)
    if ps == nil then
        logp("[PawnResearch] PASO 111 RESULTADO: PartSwapper no encontrado; detener integracion hasta recuperar esta ruta")
        logp("[PawnResearch] ===== FIN PASO 111 COMPATIBILIDAD TU4 / PAM =====")
        return false, "PartSwapper nil"
    end

    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    paso111_log_objeto("PartSwapper._BodyEditor", body_editor)
    local bde = safe_call(ps, "get_BodyDetailEditor")
    paso111_log_objeto("PartSwapper.get_BodyDetailEditor", bde)
    local human_context = get_field_value_by_name(ps, "_HumanContext")
    paso111_log_objeto("PartSwapper._HumanContext", human_context)
    local human_meta = get_field_value_by_name(human_context, "_Meta")
    paso111_log_objeto("HumanContext._Meta", human_meta)
    local live_meta = safe_call(ps, "get_Meta")
    paso111_log_objeto("PartSwapper.get_Meta", live_meta)

    if bde ~= nil then
        local detail_context = get_field_value_by_name(bde, "_Context")
        paso111_log_objeto("BodyDetailEditor._Context", detail_context)
        local skin_context = get_field_value_by_name(detail_context, "_Skin")
        local hair_context = get_field_value_by_name(detail_context, "_Hair")
        local bodyhair_context = get_field_value_by_name(detail_context, "_BodyHair")
        paso111_log_objeto("BodyDetailContext._Skin", skin_context)
        paso111_log_objeto("BodyDetailContext._Hair", hair_context)
        paso111_log_objeto("BodyDetailContext._BodyHair", bodyhair_context)
        for _, editor_field in ipairs({ "_Skin", "_Hair", "_Beard", "_BodyHair", "_Eyes", "_Eyelashes", "_Eyebrows", "_Makeup" }) do
            local editor_obj = get_field_value_by_name(bde, editor_field)
            paso111_log_objeto("BodyDetailEditor." .. editor_field, editor_obj)
            local editor_td = safe(function() return editor_obj:get_type_definition() end)
            if editor_td ~= nil then
                local editor_type_name = safe(function() return editor_td:get_full_name() end) or "<?>"
                logp("[PawnResearch] PASO 111 EDITOR TYPE " .. tostring(editor_field) .. "=" .. tostring(editor_type_name))
                local editor_methods = safe(function() return editor_td:get_methods() end) or {}
                for _, editor_method in ipairs(editor_methods) do
                    local editor_method_name = safe(function() return editor_method:get_name() end)
                    if editor_method_name == "restore" or editor_method_name == "requestApplyProperties"
                        or editor_method_name == "apply" or editor_method_name == "requestForceApplyDetails" then
                        paso111_log_metodo(editor_method, "[PawnResearch] PASO 111 EDITOR " .. tostring(editor_field) .. " ")
                    end
                end
            end
        end
        paso111_log_objeto("BodyDetailEditor.get_Hair", safe_call(bde, "get_Hair"))
        paso111_log_objeto("BodyDetailEditor.get_BodyHair", safe_call(bde, "get_BodyHair"))
        paso111_log_objeto("BodyDetailEditor.get_Skin", safe_call(bde, "get_Skin"))
    end

    if body_editor ~= nil then
        local body_edit_context = get_field_value_by_name(body_editor, "_BodyEditContext")
        paso111_log_objeto("BodyEditor._BodyEditContext", body_edit_context)
        local edit_values = safe_call(body_edit_context, "get_EditValues")
        if edit_values == nil then edit_values = get_field_value_by_name(body_edit_context, "_EditValues") end
        paso111_log_objeto("BodyEditContext.EditValues", edit_values)
        local edit_size = safe_call(edit_values, "get_size")
        logp("[PawnResearch] PASO 111 BodyHeight=" .. tostring(safe_call(body_editor, "get_BodyHeight"))
            .. " EditValues.size=" .. tostring(edit_size))
        if type(edit_size) == "number" then
            for index = 0, edit_size - 1 do
                local edit = safe_call(edit_values, "get_element", index)
                local key_hash = safe_call(edit, "get_EditKeyHash")
                if key_hash == nil then key_hash = get_field_value_by_name(edit, "_EditKeyHash") end
                if tonumber(key_hash) == 1497737450 then
                    local height_value = safe_call(edit, "get_Value")
                    if height_value == nil then height_value = get_field_value_by_name(edit, "_Value") end
                    logp("[PawnResearch] PASO 111 HEIGHT EDITVALUE index=" .. tostring(index)
                        .. " hash=" .. tostring(key_hash) .. " value=" .. tostring(height_value))
                    break
                end
            end
        end
        paso111_log_objeto("BodyEditor._ApplyEditScales", get_field_value_by_name(body_editor, "_ApplyEditScales"))
    end

    -- Comprueba la firma real de get_Item de via.vec3 y prueba unicamente
    -- lecturas. El Step110 Field:get_data(x) no se considera valido porque
    -- produjo valores fuera de rango para el primer componente.
    local scales = body_editor and get_field_value_by_name(body_editor, "_ApplyEditScales") or nil
    if scales ~= nil and vec3_td ~= nil then
        local outer_enum = safe_call(scales, "GetEnumerator")
        local moved = safe_call(outer_enum, "MoveNext")
        if moved == true then
            local pair = safe_call(outer_enum, "get_Current")
            local joint_hash = safe_call(pair, "get_Key")
            local inner = safe_call(pair, "get_Value")
            logp("[PawnResearch] PASO 111 FIRST JOINT joint_hash=" .. tostring(joint_hash)
                .. " inner_count=" .. tostring(safe_call(inner, "get_Count"))
                .. " height_present=" .. tostring(safe_call(inner, "ContainsKey", 1497737450)))
            if safe_call(inner, "ContainsKey", 1497737450) == true then
                local joint = safe_call(inner, "get_Item", 1497737450)
                paso111_log_objeto("JointEditData[height]", joint)
                for _, field_name in ipairs({ "_UpperScale", "_LowerScale", "_UpperTranslate", "_LowerTranslate" }) do
                    local vec = get_field_value_by_name(joint, field_name)
                    if vec == nil then vec = safe(function() return joint:get_field(field_name) end) end
                    paso111_log_objeto("JointEditData." .. field_name, vec)
                    paso111_diagnosticar_vec3(vec3_td, vec, field_name)
                end
            end
        else
            logp("[PawnResearch] PASO 111 ApplyEditScales: enumerador sin primera entrada")
        end
    else
        logp("[PawnResearch] PASO 111 ApplyEditScales o via.vec3 no disponible; ejecutar primero el diagnostico de Paso 107/109 si la tabla esta nil")
    end

    logp("[PawnResearch] PASO 111 RESUMEN tipos PartSwapper=" .. tostring(ps_td ~= nil)
        .. " BodyEditor=" .. tostring(be_td ~= nil)
        .. " BodyDetailEditor=" .. tostring(bde_td ~= nil)
        .. " Hair=" .. tostring(hair_td ~= nil)
        .. " BodyHair=" .. tostring(bodyhair_td ~= nil)
        .. " via.Color=" .. tostring(color_td ~= nil)
        .. " via.vec3=" .. tostring(vec3_td ~= nil))
    logp("[PawnResearch] PASO 111 NOTA: auditoria de compatibilidad/lectura solamente; no hubo escrituras ni refresh visual")
    logp("[PawnResearch] ===== FIN PASO 111 COMPATIBILIDAD TU4 / PAM =====")
    return true, "Auditoria Paso 111 terminada; revisar log antes de habilitar cualquier escritura."
end

logp("[PawnResearch] ===== PASOS 110-111 CARGADOS (vec3 y auditoria TU4/rutas de apariencia) =====")
logp("[PawnResearch] MODO AUDITORIA POST-TU4 ACTIVO: restauracion automatica, loadouts y aplicaciones HPO bloqueados hasta validar el TDB.")


-- ============================================================
-- PASO 112: AUDITORIA DE CATALOGOS DINAMICOS POST-DLC
-- Referencia metodologica: ThePawnController 2.2.0 (16-10-2026).
-- Este paso inspecciona el catalogo de equipo vivo, enums de skills,
-- augmentos/core skills y habilidades especiales de appraisal.
-- No usa el itemData.json ni skillCatalog.json como unica fuente.
-- No escribe datos, no entrega items, no equipa, no cambia skills y no
-- llama requestSwap/applyEdit/restore ni refrescos visuales.
-- ============================================================

paso112_numero_enum = function(raw)
    if type(raw) == "number" then
        return math.tointeger(raw) or raw
    end
    local underlying = safe(function() return raw:get_field("value__") end)
    local n = tonumber(underlying)
    if n ~= nil then return math.tointeger(n) or n end
    return nil
end

paso112_log_tipo_objeto = function(label, obj, wanted_fields, wanted_methods)
    logp("[PawnResearch] PASO 112 OBJ " .. tostring(label) .. "=" .. value_to_string(obj))
    if obj == nil then return nil end
    local td = safe(function() return obj:get_type_definition() end)
    if td == nil then
        logp("[PawnResearch] PASO 112 TYPE " .. tostring(label) .. "=nil")
        return nil
    end
    local tn = safe(function() return td:get_full_name() end) or "<?>"
    logp("[PawnResearch] PASO 112 TYPE " .. tostring(label) .. "=" .. tostring(tn))
    local wanted_f = wanted_fields or {}
    local fields = safe(function() return td:get_fields() end) or {}
    for _, field in ipairs(fields) do
        local name = safe(function() return field:get_name() end)
        if name ~= nil and (next(wanted_f) == nil or wanted_f[name]) then
            local ft = safe(function() return field:get_type():get_full_name() end) or "<?>"
            local value = safe(function() return field:get_data(obj) end)
            logp("[PawnResearch] PASO 112 FIELD " .. tostring(label) .. "::" .. tostring(name)
                .. " tipo=" .. tostring(ft) .. " valor=" .. tostring(value))
        end
    end
    local wanted_m = wanted_methods or {}
    local methods = safe(function() return td:get_methods() end) or {}
    for _, method in ipairs(methods) do
        local name = safe(function() return method:get_name() end)
        if name ~= nil and (next(wanted_m) == nil or wanted_m[name]) then
            paso111_log_metodo(method, "[PawnResearch] PASO 112 METHOD " .. tostring(label) .. " ")
        end
    end
    return td
end

paso112_enumerar_enum = function(type_name, pattern, compare_map, label)
    local td = safe(function() return sdk.find_type_definition(type_name) end)
    if td == nil then
        logp("[PawnResearch] PASO 112 ENUM " .. tostring(type_name) .. "=nil")
        return {}, 0
    end
    local entries = {}
    local by_job = {}
    local fields = safe(function() return td:get_fields() end) or {}
    for _, field in ipairs(fields) do
        if safe(function() return field:is_static() end) == true then
            local name = safe(function() return field:get_name() end) or "<?>"
            local raw = safe(function() return field:get_data(nil) end)
            local id = paso112_numero_enum(raw)
            if id ~= nil then
                local job, suffix = nil, nil
                if pattern ~= nil then job, suffix = name:match(pattern) end
                if pattern == nil or job ~= nil then
                    local item = { id = id, name = name, job = tonumber(job), suffix = suffix }
                    entries[#entries + 1] = item
                    if item.job ~= nil then by_job[item.job] = (by_job[item.job] or 0) + 1 end
                end
            end
        end
    end
    table.sort(entries, function(a, b)
        if (a.job or -1) ~= (b.job or -1) then return (a.job or -1) < (b.job or -1) end
        if a.id ~= b.id then return a.id < b.id end
        return a.name < b.name
    end)
    logp("[PawnResearch] PASO 112 ENUM " .. tostring(type_name)
        .. " label=" .. tostring(label or "") .. " count=" .. tostring(#entries))
    for job, count in pairs(by_job) do
        logp("[PawnResearch] PASO 112 ENUM " .. tostring(type_name)
            .. " Job=" .. tostring(job) .. " count=" .. tostring(count))
    end
    local shown = 0
    for _, item in ipairs(entries) do
        local missing = false
        if compare_map ~= nil and item.job ~= nil then
            local job_map = compare_map[item.job]
            missing = job_map == nil or job_map[item.id] ~= true
        end
        if shown < 80 then
            logp("[PawnResearch] PASO 112 ENUM ITEM " .. tostring(type_name)
                .. " id=" .. tostring(item.id) .. " name=" .. tostring(item.name)
                .. " job=" .. tostring(item.job) .. " no_en_catalogo_estatico=" .. tostring(missing))
            shown = shown + 1
        end
    end
    if #entries > shown then
        logp("[PawnResearch] PASO 112 ENUM " .. tostring(type_name)
            .. " restantes_sin_imprimir=" .. tostring(#entries - shown))
    end
    return entries, #entries
end

paso112_obtener_valor_item = function(entry)
    if entry == nil then return nil end
    local td = safe(function() return entry:get_type_definition() end)
    local value_field = nil
    if td ~= nil then
        local fields = safe(function() return td:get_fields() end) or {}
        for _, field in ipairs(fields) do
            local field_name = safe(function() return field:get_name() end)
            local field_type = safe(function() return field:get_type():get_full_name() end)
            if field_name == "value" or field_name == "Value" then
                if field_type ~= nil then
                    value_field = field_name
                    break
                end
            end
        end
    end
    if value_field ~= nil then
        return get_field_value_by_name(entry, value_field), value_field
    end
    local value = safe_call(entry, "get_Value")
    if value ~= nil then return value, "get_Value" end
    return nil, nil
end

paso112_categoria_equipo_label = function(raw)
    local n = paso112_numero_enum(raw)
    local names = {
        [0] = "Main", [1] = "Sub", [2] = "Head", [3] = "Upper",
        [4] = "Lower", [5] = "Mantle", [6] = "Jewelry_00/Jewelry_01", [7] = "Visual"
    }
    return n, names[n] or ("UNMAPPED_" .. tostring(n ~= nil and n or raw))
end

paso112_auditar_equip_param_type = function(param)
    local td = safe(function() return param:get_type_definition() end)
    if td == nil then
        logp("[PawnResearch] PASO 112 EquipParam TypeDefinition=nil")
        return
    end
    logp("[PawnResearch] PASO 112 EquipParam type="
        .. tostring(safe(function() return td:get_full_name() end)))
    local methods = safe(function() return td:get_methods() end) or {}
    local wanted = { get_EquipCategory = true, IsJob = true }
    for _, method in ipairs(methods) do
        local name = safe(function() return method:get_name() end)
        if wanted[name] then
            paso111_log_metodo(method, "[PawnResearch] PASO 112 EquipParam ")
        end
    end
end

paso112_procesar_item_vivo = function(param, stats)
    if param == nil then return end
    stats.entries = stats.entries + 1
    local is_equip = safe_call(param, "get_IsEquip")
    if is_equip ~= true then return end
    local id = tonumber(safe_call(param, "get_Id"))
    local name = safe_call(param, "get_Name")
    local equip_param = safe_call(param, "get_EquipParam")
    if id == nil or equip_param == nil then
        stats.equip_incompletos = stats.equip_incompletos + 1
        return
    end
    stats.equip = stats.equip + 1
    if id > stats.max_id then stats.max_id = id end
    if not stats.equip_param_audited then
        stats.equip_param_audited = true
        paso112_auditar_equip_param_type(equip_param)
    end
    local category_raw = safe_call(equip_param, "get_EquipCategory")
    local category, category_label = paso112_categoria_equipo_label(category_raw)
    local category_key = tostring(category ~= nil and category or category_raw)
    stats.categories[category_key] = (stats.categories[category_key] or 0) + 1
    stats.category_labels[category_key] = category_label
    local exists_static = type(hpo_itemData) == "table" and hpo_itemData[tostring(id)] ~= nil
    if not exists_static then
        stats.not_in_static = stats.not_in_static + 1
        if #stats.samples < 40 then
            stats.samples[#stats.samples + 1] = {
                id = id,
                name = tostring(name or "<?>"),
                category = category_key,
                category_label = category_label
            }
        end
    end
end

paso112_auditar_item_manager = function(character)
    logp("[PawnResearch] PASO 112 ===== ITEMMANAGER / CATALOGO VIVO =====")
    local manager = safe(function() return sdk.get_managed_singleton("app.ItemManager") end)
    if manager == nil then manager = ItemManager end
    paso112_log_tipo_objeto("ItemManager", manager,
        { _ItemDataDict = true },
        { getItemData = true, getEquipData = true, getItem = true, setEquip = true,
          getStorageMasterList = true, setEquipModel = true, updateEquipAbility = true })
    if manager == nil then
        logp("[PawnResearch] PASO 112 ItemManager no disponible")
        return
    end

    local dict = get_field_value_by_name(manager, "_ItemDataDict")
    paso111_log_objeto("ItemManager._ItemDataDict", dict)
    if dict == nil then
        logp("[PawnResearch] PASO 112 No se encontro _ItemDataDict por reflexion; no se ejecuta barrido 1..32000")
        return
    end

    local dict_td = safe(function() return dict:get_type_definition() end)
    if dict_td ~= nil then
        local fields = safe(function() return dict_td:get_fields() end) or {}
        for _, field in ipairs(fields) do
            local fname = safe(function() return field:get_name() end)
            if fname == "_entries" or fname == "entries" then
                logp("[PawnResearch] PASO 112 ItemDataDict FIELD " .. tostring(fname)
                    .. " tipo=" .. tostring(safe(function() return field:get_type():get_full_name() end)))
            end
        end
        local methods = safe(function() return dict_td:get_methods() end) or {}
        for _, method in ipairs(methods) do
            local mname = safe(function() return method:get_name() end)
            if mname == "get_Count" or mname == "GetEnumerator" or mname == "ContainsKey" then
                paso111_log_metodo(method, "[PawnResearch] PASO 112 ItemDataDict ")
            end
        end
    end

    local stats = { entries = 0, equip = 0, equip_incompletos = 0,
        not_in_static = 0, max_id = 0, categories = {}, category_labels = {}, samples = {} }
    local entries = get_field_value_by_name(dict, "_entries")
    if entries == nil then entries = get_field_value_by_name(dict, "entries") end
    local arr_size = safe_call(entries, "get_size")
    if type(arr_size) == "number" then
        logp("[PawnResearch] PASO 112 ItemDataDict entries.get_size=" .. tostring(arr_size))
        local limit = math.min(arr_size, 100000)
        for index = 0, limit - 1 do
            local entry = safe_call(entries, "get_element", index)
            local param = paso112_obtener_valor_item(entry)
            if param ~= nil then paso112_procesar_item_vivo(param, stats) end
        end
        if arr_size > limit then
            logp("[PawnResearch] PASO 112 ItemDataDict entries truncado a " .. tostring(limit))
        end
    else
        logp("[PawnResearch] PASO 112 entries array no disponible; intento GetEnumerator() sin barrido por ID")
        local enum = safe_call(dict, "GetEnumerator")
        local moved = enum ~= nil and safe_call(enum, "MoveNext") or false
        local limit = 0
        while moved == true and limit < 100000 do
            local pair = safe_call(enum, "get_Current")
            local param = safe_call(pair, "get_Value")
            if param ~= nil then paso112_procesar_item_vivo(param, stats) end
            limit = limit + 1
            moved = safe_call(enum, "MoveNext")
        end
        logp("[PawnResearch] PASO 112 Dictionary enumerator entries=" .. tostring(limit))
    end

    local static_count = 0
    if type(hpo_itemData) == "table" then
        for _ in pairs(hpo_itemData) do static_count = static_count + 1 end
    end
    logp("[PawnResearch] PASO 112 ITEM RESUMEN entries=" .. tostring(stats.entries)
        .. " equip=" .. tostring(stats.equip)
        .. " incompletos=" .. tostring(stats.equip_incompletos)
        .. " max_id=" .. tostring(stats.max_id)
        .. " fuera_de_itemData_json=" .. tostring(stats.not_in_static)
        .. " itemData_json_count=" .. tostring(static_count))
    for category, count in pairs(stats.categories) do
        logp("[PawnResearch] PASO 112 ITEM CATEGORY raw=" .. tostring(category)
            .. " slot=" .. tostring(stats.category_labels[category]) .. " count=" .. tostring(count))
    end
    for _, item in ipairs(stats.samples) do
        logp("[PawnResearch] PASO 112 ITEM NUEVO_PARA_JSON id=" .. tostring(item.id)
            .. " category=" .. tostring(item.category)
            .. " slot=" .. tostring(item.category_label) .. " name=" .. tostring(item.name))
    end
    if stats.entries == 0 then
        logp("[PawnResearch] PASO 112 NOTA: no se enumeraron registros. El proximo paso debe revisar la estructura interna de ItemDataDict.")
    end
end

paso112_auditar_habilidades = function(character)
    logp("[PawnResearch] PASO 112 ===== SKILLS / CORE / AUGMENTS =====")
    local custom, custom_count = paso112_enumerar_enum(
        "app.HumanCustomSkillID", "^Job(%d%d)_(.+)$", hpo_skill_ids_by_job, "weapon_skills")
    local core, core_count = paso112_enumerar_enum(
        "app.HumanNormalSkillID", "^Job(%d%d)_(.+)$", nil, "core_skills")
    local abilities, abilities_count = paso112_enumerar_enum(
        "app.HumanAbilityID", "^Job(%d%d)_(%d%d)$", nil, "augments")
    paso112_enumerar_enum("app.Character.JobEnum", nil, nil, "jobs")
    paso112_enumerar_enum("app.HumanSkillContext.SkillSlot", nil, nil, "skill_slots")
    paso112_enumerar_enum("app.HumanCustomSkillLevelNo", nil, nil, "skill_levels")

    local human = get_human(character)
    local job_ctx = get_job_context(character)
    local current_job = get_field_value_by_name(job_ctx, "CurrentJob")
    logp("[PawnResearch] PASO 112 current_job=" .. tostring(current_job)
        .. " custom_skill_enum_count=" .. tostring(custom_count)
        .. " core_enum_count=" .. tostring(core_count)
        .. " ability_enum_count=" .. tostring(abilities_count)
        .. " skillCatalog_json=" .. tostring(type(hpo_skill_catalog) == "table"))

    local skill_context = hpo_get_skill_context(human)
    local skill_td = paso112_log_tipo_objeto("HumanSkillContext", skill_context,
        { SkillSlotValues = true },
        { getSkillID = true, setSkill = true, isCustomSkillEnable = true,
          isCustomSkillAvailable = true, setCustomSkillEnable = true,
          getCustomSkillLevel = true, setCustomSkillLevelUp = true,
          isNormalSkillEnable = true, setNormalSkillEnable = true })
    if skill_td ~= nil then
        local methods = safe(function() return skill_td:get_methods() end) or {}
        for _, method in ipairs(methods) do
            local name = safe(function() return method:get_name() end)
            if name == "getSkillID" or name == "setSkill" or name == "isCustomSkillEnable"
                or name == "isCustomSkillAvailable" or name == "setCustomSkillEnable"
                or name == "getCustomSkillLevel" or name == "setCustomSkillLevelUp"
                or name == "isNormalSkillEnable" or name == "setNormalSkillEnable" then
                paso111_log_metodo(method, "[PawnResearch] PASO 112 HumanSkillContext ")
            end
        end
    end

    local read_ok, read_a, read_b, read_c = pcall(hpo_read_skill_loadout, character, nil)
    if read_ok and read_a == true and type(read_c) == "table" then
        logp("[PawnResearch] PASO 112 SKILL LOADOUT read_job=" .. tostring(read_c.read_job)
            .. " current_job=" .. tostring(read_c.current_job_num))
        for slot = 0, HPO_SKILL_SLOT_COUNT - 1 do
            logp("[PawnResearch] PASO 112 SKILL SLOT=" .. tostring(slot)
                .. " id=" .. tostring(read_c.slots[slot]))
        end
    else
        logp("[PawnResearch] PASO 112 SKILL LOADOUT no_reconocido ok=" .. tostring(read_ok)
            .. " result=" .. tostring(read_a) .. " detail=" .. tostring(read_b))
    end

    local ability_context = safe_call(human, "get_AbilityContext")
    if ability_context == nil then
        ability_context = get_field_value_by_name(human, "<AbilityContext>k__BackingField")
    end
    local ability_td = paso112_log_tipo_objeto("AbilityContext", ability_context,
        { DefaultNumSlots = true, IsAdditionalSlotUnlocked = true },
        { getAbility = true, setAbility = true, setAbilityEnable = true,
          unlockAdditionalSlot = true })
    if ability_td ~= nil then
        local methods = safe(function() return ability_td:get_methods() end) or {}
        for _, method in ipairs(methods) do
            local name = safe(function() return method:get_name() end)
            if name == "getAbility" or name == "setAbility" or name == "setAbilityEnable"
                or name == "unlockAdditionalSlot" then
                paso111_log_metodo(method, "[PawnResearch] PASO 112 AbilityContext ")
            end
        end
    end
end

paso112_auditar_nombres_y_definiciones = function()
    logp("[PawnResearch] PASO 112 ===== RESOLUCION DE NOMBRES / DEFINICIONES =====")
    local wanted = {
        getCustomSkillName = true,
        getAbilityName = true,
        getNormalSkillName = true,
        getCustomSkillDefine = true,
        getJobNameMsgID = true
    }
    for _, type_name in ipairs({ "app.GUIBase", "app.GuiManager" }) do
        local td = safe(function() return sdk.find_type_definition(type_name) end)
        logp("[PawnResearch] PASO 112 NAME TYPE " .. type_name .. "="
            .. tostring(td and safe(function() return td:get_full_name() end) or "nil"))
        if td ~= nil then
            local methods = safe(function() return td:get_methods() end) or {}
            for _, method in ipairs(methods) do
                local name = safe(function() return method:get_name() end)
                if wanted[name] then
                    paso111_log_metodo(method, "[PawnResearch] PASO 112 NAME " .. type_name .. " ")
                end
            end
        end
    end
    local gui = safe(function() return sdk.get_managed_singleton("app.GuiManager") end)
    paso112_log_tipo_objeto("GuiManager", gui,
        { NormalSkillDefineDictionary = true },
        { getCustomSkillName = true, getAbilityName = true, getNormalSkillName = true,
          getCustomSkillDefine = true })
end

paso112_auditar_estado_y_atributos = function(character)
    logp("[PawnResearch] PASO 112 ===== NIVEL / VOCACION / ATRIBUTOS / CONOCIMIENTO =====")
    local human = get_human(character)
    local ps = get_part_swapper(character)
    local job_ctx = get_job_context(character)
    local status_ctx = safe_call(human, "get_StatusContext")
    if status_ctx == nil then status_ctx = get_field_value_by_name(human, "<StatusContext>k__BackingField") end
    local job_value = safe_call(job_ctx, "get_Job")
    local current_job = get_field_value_by_name(job_ctx, "CurrentJob")
    local level = safe_call(status_ctx, "get_Level")
    local exp = safe_call(status_ctx, "get_Exp")
    logp("[PawnResearch] PASO 112 JOB current_job_field=" .. tostring(current_job)
        .. " get_Job=" .. tostring(job_value)
        .. " level=" .. tostring(level) .. " exp=" .. tostring(exp))

    paso112_log_tipo_objeto("JobContext", job_ctx, { CurrentJob = true },
        { get_Job = true, isJobQualified = true, setJobQualified = true, calcJobRank = true })
    paso112_log_tipo_objeto("StatusContext", status_ctx, { _IncreaseParams = true },
        { get_Level = true, get_Exp = true, set_Exp = true, levelup = true })
    if job_ctx ~= nil then
        local td = safe(function() return job_ctx:get_type_definition() end)
        local methods = td and (safe(function() return td:get_methods() end) or {}) or {}
        local wanted = { get_Job = true, isJobQualified = true, setJobQualified = true, calcJobRank = true }
        for _, method in ipairs(methods) do
            local name = safe(function() return method:get_name() end)
            if wanted[name] then paso111_log_metodo(method, "[PawnResearch] PASO 112 JobContext ") end
        end
    end
    if status_ctx ~= nil then
        local td = safe(function() return status_ctx:get_type_definition() end)
        local methods = td and (safe(function() return td:get_methods() end) or {}) or {}
        local wanted = { get_Level = true, get_Exp = true, set_Exp = true, levelup = true }
        for _, method in ipairs(methods) do
            local name = safe(function() return method:get_name() end)
            if wanted[name] then paso111_log_metodo(method, "[PawnResearch] PASO 112 StatusContext ") end
        end
    end

    local param = safe_call(human, "get_Param")
    local lvup = safe_call(param, "get_LVupInfo")
    paso112_log_tipo_objeto("LVupInfo", lvup, { __no_fields = true },
        { get_MaxLevel = true, getRequiredEXP = true })
    if lvup ~= nil then
        local td = safe(function() return lvup:get_type_definition() end)
        local methods = td and (safe(function() return td:get_methods() end) or {}) or {}
        local wanted = { get_MaxLevel = true, getRequiredEXP = true }
        for _, method in ipairs(methods) do
            local name = safe(function() return method:get_name() end)
            if wanted[name] then paso111_log_metodo(method, "[PawnResearch] PASO 112 LVupInfo ") end
        end
        logp("[PawnResearch] PASO 112 max_level=" .. tostring(safe_call(lvup, "get_MaxLevel")))
    end

    local job_changer = safe_call(human, "get_JobChanger")
    paso112_log_tipo_objeto("JobChanger", job_changer, { __no_fields = true },
        { requestChangeJob = true })
    if job_changer ~= nil then
        local td = safe(function() return job_changer:get_type_definition() end)
        local methods = td and (safe(function() return td:get_methods() end) or {}) or {}
        for _, method in ipairs(methods) do
            if safe(function() return method:get_name() end) == "requestChangeJob" then
                paso111_log_metodo(method, "[PawnResearch] PASO 112 JobChanger ")
            end
        end
    end

    local pawn_data = get_field_value_by_name(ps, "_PawnDataContext")
    if pawn_data == nil then pawn_data = safe_call(human, "get_PawnDataContext") end
    paso112_log_tipo_objeto("PawnDataContext", pawn_data, { __no_fields = true },
        { get_SubSkill = true, setSubSkill = true, setPersonarity = true,
          get_Personality = true, get_VoiceGender = true, setVoiceGender = true,
          get_VoiceToneType = true, setVoiceToneType = true, get_Name = true,
          setName = true, get_Nickname = true, setNickName = true })
    if pawn_data ~= nil then
        local td = safe(function() return pawn_data:get_type_definition() end)
        local methods = td and (safe(function() return td:get_methods() end) or {}) or {}
        local wanted = { get_SubSkill = true, setSubSkill = true, setPersonarity = true,
            get_Personality = true, get_VoiceGender = true, setVoiceGender = true,
            get_VoiceToneType = true, setVoiceToneType = true, get_Name = true,
            setName = true, get_Nickname = true, setNickName = true }
        for _, method in ipairs(methods) do
            local name = safe(function() return method:get_name() end)
            if wanted[name] then paso111_log_metodo(method, "[PawnResearch] PASO 112 PawnDataContext ") end
        end
    end

    local knowledge_td = safe(function() return sdk.find_type_definition("app.PawnKnowledgeContext") end)
    logp("[PawnResearch] PASO 112 PawnKnowledgeContext type="
        .. tostring(knowledge_td and safe(function() return knowledge_td:get_full_name() end) or "nil"))
    if knowledge_td ~= nil then
        local wanted = { checkQuestKnowledge = true, checkWayKnowledge = true,
            checkKeyLocationKnowledge = true, checkNRDKeyLocationKnowledge = true,
            checkContents014Knowledge = true, checkShortcutWayKnowledge = true,
            checkGimmickKnowledge = true, checkNRDGimmickKnowledge = true }
        local methods = safe(function() return knowledge_td:get_methods() end) or {}
        for _, method in ipairs(methods) do
            local name = safe(function() return method:get_name() end)
            if wanted[name] then paso111_log_metodo(method, "[PawnResearch] PASO 112 PawnKnowledgeContext ") end
        end
    end
end

paso112_auditar_appraisal_dlc = function()
    logp("[PawnResearch] PASO 112 ===== HABILIDADES ESPECIALES DE EQUIPO / APPRAISAL =====")
    paso112_enumerar_enum("app.EquipmentAbilityID", nil, nil, "equipment_ability_ids")
    paso112_enumerar_enum("app.AppraisalSetting.AppraisalAbilityID", nil, nil, "appraisal_ability_ids")
    paso112_enumerar_enum("app.GUIAppraisalDefine.AppraiseSkillRank", nil, nil, "appraisal_skill_ranks")
    paso112_enumerar_enum("app.AppraisalSetting.LevelType", nil, nil, "appraisal_level_types")

    local appraisal_manager = safe(function() return sdk.get_managed_singleton("app.ItemAppraisalManager") end)
    paso112_log_tipo_objeto("ItemAppraisalManager", appraisal_manager,
        { AppraisalLevelSettingDict = true, ItemSettingDict = true },
        { get_ItemSettingDict = true, get_AppraisalLevelSettingDict = true })
    local gui_behavior_td = safe(function() return sdk.find_type_definition("app.GuiManagerBehavior") end)
    logp("[PawnResearch] PASO 112 GuiManagerBehavior type="
        .. tostring(gui_behavior_td and safe(function() return gui_behavior_td:get_full_name() end) or "nil"))
    if gui_behavior_td ~= nil then
        local fields = safe(function() return gui_behavior_td:get_fields() end) or {}
        for _, field in ipairs(fields) do
            if safe(function() return field:get_name() end) == "EquipmentAbilityInfomationData" then
                logp("[PawnResearch] PASO 112 GuiManagerBehavior.EquipmentAbilityInfomationData tipo="
                    .. tostring(safe(function() return field:get_type():get_full_name() end)))
            end
        end
    end
    local validator_td = safe(function() return sdk.find_type_definition("app.PawnRentalValidator") end)
    if validator_td ~= nil then
        local fields = safe(function() return validator_td:get_fields() end) or {}
        for _, field in ipairs(fields) do
            local name = safe(function() return field:get_name() end)
            if name == "_MaxAbilitySlot" then
                logp("[PawnResearch] PASO 112 PawnRentalValidator._MaxAbilitySlot tipo="
                    .. tostring(safe(function() return field:get_type():get_full_name() end)))
            end
        end
    else
        logp("[PawnResearch] PASO 112 TypeDef app.PawnRentalValidator=nil")
    end
end

paso112_auditar_altura_y_color = function(character)
    logp("[PawnResearch] PASO 112 ===== FIRMAS APARIENCIA / ALTURA =====")
    local ps = get_part_swapper(character)
    local body_editor = get_field_value_by_name(ps, "_BodyEditor")
    local body_context = get_field_value_by_name(body_editor, "_BodyEditContext")
    local body_td = body_context ~= nil and safe(function() return body_context:get_type_definition() end) or nil
    if body_td ~= nil then
        local methods = safe(function() return body_td:get_methods() end) or {}
        for _, method in ipairs(methods) do
            local name = safe(function() return method:get_name() end)
            if name == "setEditValue" or name == "getEditValue" or name == "set_EditValues"
                or name == "get_EditValues" then
                paso111_log_metodo(method, "[PawnResearch] PASO 112 BodyEditContext ")
            end
        end
    end

    local body_values = get_field_value_by_name(body_context, "_EditValues")
    if body_values ~= nil then
        local size = safe_call(body_values, "get_size")
        logp("[PawnResearch] PASO 112 BodyEditContext EditValues.size=" .. tostring(size))
        if type(size) == "number" then
            for index = 0, size - 1 do
                local edit = safe_call(body_values, "get_element", index)
                local hash = safe_call(edit, "get_EditKeyHash")
                if hash == nil then hash = get_field_value_by_name(edit, "_EditKeyHash") end
                if tonumber(hash) == 1497737450 then
                    local val = safe_call(edit, "get_Value")
                    if val == nil then val = get_field_value_by_name(edit, "_Value") end
                    local edit_td = safe(function() return edit:get_type_definition() end)
                    if edit_td ~= nil then
                        local edit_methods = safe(function() return edit_td:get_methods() end) or {}
                        for _, method in ipairs(edit_methods) do
                            local name = safe(function() return method:get_name() end)
                            if name == "set_Value" or name == "get_Value" then
                                paso111_log_metodo(method, "[PawnResearch] PASO 112 EditValue ")
                            end
                        end
                    end
                    logp("[PawnResearch] PASO 112 HEIGHT EditValue index=" .. tostring(index)
                        .. " hash=" .. tostring(hash) .. " value=" .. tostring(val))
                    break
                end
            end
        end
    end
end

paso112_auditar_catalogos_dlc = function(character)
    logp("[PawnResearch] ===== PASO 112 CATALOGOS DINAMICOS POST-DLC =====")
    if character == nil then
        logp("[PawnResearch] PASO 112 character=nil")
        logp("[PawnResearch] ===== FIN PASO 112 CATALOGOS DINAMICOS POST-DLC =====")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] PASO 112 CID=" .. tostring(cid)
        .. " protegido=" .. tostring(is_character_protected(cid))
        .. " tdb=" .. tostring(safe(function() return sdk.get_tdb_version() end)))
    logp("[PawnResearch] PASO 112 REF: ThePawnController 2.2.0 dinamiza items desde ItemManager y deriva skills/core/augments desde enums.")
    logp("[PawnResearch] PASO 112 ESTADO JSON itemData=" .. tostring(type(hpo_itemData) == "table")
        .. " skillCatalog=" .. tostring(type(hpo_skill_catalog) == "table"))

    paso112_auditar_item_manager(character)
    paso112_auditar_habilidades(character)
    paso112_auditar_nombres_y_definiciones()
    paso112_auditar_appraisal_dlc()
    paso112_auditar_altura_y_color(character)
    paso112_auditar_estado_y_atributos(character)

    logp("[PawnResearch] PASO 112 NOTA: solo lectura. No se agregaron objetos al inventario, no se equiparon items, no se modificaron skills/augments ni apariencia.")
    logp("[PawnResearch] ===== FIN PASO 112 CATALOGOS DINAMICOS POST-DLC =====")
    return true, "Auditoria de catalogos DLC terminada; revisar log antes de integrar escrituras."
end

logp("[PawnResearch] ===== PASO 112 CARGADO (auditoria de catalogos dinamicos DLC) =====")

-- ============================================================
-- PASO 113: CATALOGOS VIVOS EN MEMORIA + DIAGNOSTICO REAL DE ALTURA
-- Integra las fuentes vivas observadas en Paso 112 y ThePawnController:
-- ItemManager._ItemDataDict para equipo y enums actuales para skills.
-- Lee via.vec3 por get_Item(System.Int32), firma ya confirmada en TDB 83.
-- No escribe en el juego, no equipa, no cambia skills ni apariencia.
-- ============================================================

PawnResearch_CatalogoEquipoVivo = PawnResearch_CatalogoEquipoVivo or {}
PawnResearch_CatalogoSkillsVivas = PawnResearch_CatalogoSkillsVivas or {}
PawnResearch_CatalogoCoreVivo = PawnResearch_CatalogoCoreVivo or {}
PawnResearch_CatalogoAugmentsVivos = PawnResearch_CatalogoAugmentsVivos or {}
PawnResearch_CatalogoHabilidadesEquipo = PawnResearch_CatalogoHabilidadesEquipo or {}
PawnResearch_CatalogoAppraisal = PawnResearch_CatalogoAppraisal or {}

paso113_buscar_metodo = function(obj, method_name, params_wanted, return_wanted)
    if obj == nil then return nil, nil end
    local td = safe(function() return obj:get_type_definition() end)
    local seen = {}
    while td ~= nil do
        local tn = safe(function() return td:get_full_name() end) or "<?>"
        if seen[tn] then break end
        seen[tn] = true
        for _, m in ipairs(safe(function() return td:get_methods() end) or {}) do
            if safe(function() return m:get_name() end) == method_name
                and safe(function() return m:is_static() end) ~= true then
                local pts = safe(function() return m:get_param_types() end) or {}
                local valid = params_wanted == nil or #pts == #params_wanted
                if valid and params_wanted then
                    for i, wanted in ipairs(params_wanted) do
                        if safe(function() return pts[i]:get_full_name() end) ~= wanted then valid = false break end
                    end
                end
                local ret = safe(function() return m:get_return_type():get_full_name() end)
                if valid and (return_wanted == nil or ret == return_wanted) then return m, tn end
            end
        end
        td = safe(function() return td:get_parent_type() end)
    end
    return nil, nil
end

paso113_enum = function(type_name, pattern)
    local out, td = {}, safe(function() return sdk.find_type_definition(type_name) end)
    if td == nil then
        logp("[PawnResearch] PASO 113 ENUM " .. type_name .. "=nil")
        return out
    end
    for _, f in ipairs(safe(function() return td:get_fields() end) or {}) do
        if safe(function() return f:is_static() end) == true then
            local name = safe(function() return f:get_name() end)
            local id = paso112_numero_enum(safe(function() return f:get_data(nil) end))
            if name and id ~= nil then
                local job, suffix = nil, nil
                if pattern then job, suffix = name:match(pattern) end
                if pattern == nil or job ~= nil then
                    out[#out + 1] = { id = id, name = name, job = tonumber(job), suffix = suffix }
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if (a.job or -1) ~= (b.job or -1) then return (a.job or -1) < (b.job or -1) end
        if a.id ~= b.id then return a.id < b.id end
        return a.name < b.name
    end)
    return out
end

paso113_etiqueta = function(name, pattern)
    local s = tostring(name or "")
    if pattern then s = s:gsub(pattern, "") end
    return s:gsub("_", " "):gsub("(%l)(%u)", "%1 %2"):gsub("(%u)(%u%l)", "%1 %2")
end

paso113_categoria = function(raw)
    local n = paso112_numero_enum(raw)
    local map = { [0]="Weapon", [1]="Shield", [2]="Head", [3]="Chest",
        [4]="Legs", [5]="Mantle", [6]="Jewelry", [7]="Visual" }
    return n, map[n]
end

paso113_construir_equipo = function()
    logp("[PawnResearch] PASO 113 ===== CATALOGO EQUIPO VIVO =====")
    local manager = safe(function() return sdk.get_managed_singleton("app.ItemManager") end) or ItemManager
    local dict = get_field_value_by_name(manager, "_ItemDataDict")
    if dict == nil then return false, "ItemManager._ItemDataDict no disponible" end
    local expected = safe_call(dict, "get_Count")
    local enum = safe_call(dict, "GetEnumerator")
    if enum == nil then return false, "GetEnumerator no disponible" end

    local staged = {}
    local stats = { enumerated=0, equip=0, incomplete=0, unknown=0, no_mask=0, cats={}, job_signature=nil, job_owner=nil }
    local moved = safe_call(enum, "MoveNext")
    while moved == true and stats.enumerated < 100000 do
        local pair = safe_call(enum, "get_Current")
        local param = safe_call(pair, "get_Value")
        stats.enumerated = stats.enumerated + 1
        if param ~= nil and safe_call(param, "get_IsEquip") == true then
            local id = tonumber(safe_call(param, "get_Id"))
            local name = safe_call(param, "get_Name")
            local ep = safe_call(param, "get_EquipParam")
            if id == nil or name == nil or ep == nil then
                stats.incomplete = stats.incomplete + 1
            else
                local category_id, category = paso113_categoria(safe_call(ep, "get_EquipCategory"))
                if category == nil then
                    stats.unknown = stats.unknown + 1
                else
                    stats.equip = stats.equip + 1
                    stats.cats[category] = (stats.cats[category] or 0) + 1
                    local mask, job_method, job_owner = nil, nil, nil
                    job_method, job_owner = paso113_buscar_metodo(ep, "IsJob", {"System.Int32"}, "System.Boolean")
                    if job_method ~= nil then stats.job_signature = "IsJob(System.Int32)" end
                    if job_method == nil then
                        job_method, job_owner = paso113_buscar_metodo(ep, "IsJob", {"System.UInt32"}, "System.Boolean")
                        if job_method ~= nil then stats.job_signature = "IsJob(System.UInt32)" end
                    end
                    if job_method ~= nil then
                        stats.job_owner = job_owner
                        local value, valid = 0, true
                        for job = 1, 10 do
                            local ok, allowed = pcall(function() return job_method:call(ep, 2 ^ job) end)
                            if not ok or type(allowed) ~= "boolean" then valid = false break end
                            if allowed then value = value + 2 ^ job end
                        end
                        if valid then mask = value else stats.no_mask = stats.no_mask + 1 end
                    else
                        stats.no_mask = stats.no_mask + 1
                    end
                    staged[tostring(id)] = { name=tostring(name), category=category, job=mask,
                        equip_category=category_id, source="ItemManager" }
                end
            end
        end
        moved = safe_call(enum, "MoveNext")
    end

    logp("[PawnResearch] PASO 113 ITEM enumerated=" .. tostring(stats.enumerated)
        .. " expected=" .. tostring(expected) .. " equip=" .. tostring(stats.equip)
        .. " incomplete=" .. tostring(stats.incomplete) .. " unknown=" .. tostring(stats.unknown)
        .. " without_job_mask=" .. tostring(stats.no_mask))
    logp("[PawnResearch] PASO 113 ItemEquipParam vocacion_method=" .. tostring(stats.job_signature)
        .. " owner=" .. tostring(stats.job_owner))
    for cat, n in pairs(stats.cats) do
        logp("[PawnResearch] PASO 113 ITEM CATEGORY " .. tostring(cat) .. " count=" .. tostring(n))
    end
    if type(expected) ~= "number" or stats.enumerated ~= expected or stats.equip == 0
        or stats.incomplete > 0 or stats.unknown > 0 then
        logp("[PawnResearch] PASO 113 CATALOGO NO INSTALADO: validacion incompleta")
        return false, "El catalogo no supero la validacion; itemData se conserva"
    end

    hpo_itemData = staged
    hpo_build_item_lists()
    PawnResearch_CatalogoEquipoVivo = staged
    logp("[PawnResearch] PASO 113 CATALOGO EQUIPO INSTALADO EN MEMORIA=" .. tostring(stats.equip)
        .. " con_job_mask=" .. tostring(stats.equip - stats.no_mask))
    for _, slot in ipairs(HPO_SLOTS) do
        logp("[PawnResearch] PASO 113 UI SLOT " .. slot .. " opciones="
            .. tostring(hpo_itemLists[slot] and #hpo_itemLists[slot] or 0))
    end
    if stats.no_mask > 0 then
        logp("[PawnResearch] PASO 113 AVISO: hay items sin mascara de vocacion confirmada; no se inventaron restricciones")
    end
    return true, "Catalogo de equipo instalado en memoria: " .. tostring(stats.equip)
end

paso113_construir_skills = function()
    logp("[PawnResearch] PASO 113 ===== CATALOGOS SKILLS VIVOS =====")
    local custom = paso113_enum("app.HumanCustomSkillID", "^Job(%d%d)_(.+)$")
    local core = paso113_enum("app.HumanNormalSkillID", "^Job(%d%d)_(.+)$")
    local augments = paso113_enum("app.HumanAbilityID", "^Job(%d%d)_(%d%d)$")
    local equipment = paso113_enum("app.EquipmentAbilityID", nil)
    local appraisal = paso113_enum("app.AppraisalSetting.AppraisalAbilityID", nil)

    for k in pairs(hpo_skill_ids_by_job) do hpo_skill_ids_by_job[k] = nil end
    for k in pairs(hpo_skill_names_by_id) do hpo_skill_names_by_id[k] = nil end
    for k in pairs(hpo_skill_job_names) do hpo_skill_job_names[k] = nil end

    local catalog = { source={mod="PawnResearch runtime enums", version="Paso 113 / TDB 83"},
        skills={}, vocation_skills={}, vocations={} }
    local core_map, augment_map, equipment_map, appraisal_map = {}, {}, {}, {}
    local by_job = {}
    for _, e in ipairs(custom) do
        if e.id > 0 and e.job then
            local label = paso113_etiqueta(e.name, "^Job%d%d_")
            hpo_skill_ids_by_job[e.job] = hpo_skill_ids_by_job[e.job] or {}
            hpo_skill_ids_by_job[e.job][e.id] = true
            hpo_skill_names_by_id[e.id] = label
            catalog.vocation_skills[tostring(e.job)] = catalog.vocation_skills[tostring(e.job)] or {}
            table.insert(catalog.vocation_skills[tostring(e.job)], e.id)
            table.insert(catalog.skills, { id=e.id, name=label, names={en=label}, job=e.job })
            by_job[e.job] = (by_job[e.job] or 0) + 1
        end
    end
    for _, e in ipairs(core) do
        core_map[e.id] = { id=e.id, name=paso113_etiqueta(e.name, "^Job%d%d_"), job=e.job }
    end
    for _, e in ipairs(augments) do
        augment_map[e.id] = { id=e.id, name="Augment " .. tostring((tonumber(e.suffix) or -1) + 1), enum_name=e.name, job=e.job }
    end
    for _, e in ipairs(equipment) do equipment_map[e.id] = { id=e.id, name=e.name } end
    for _, e in ipairs(appraisal) do appraisal_map[e.id] = { id=e.id, name=e.name } end

    for i = #hpo_skill_job_list, 1, -1 do table.remove(hpo_skill_job_list, i) end
    for i = #hpo_skill_job_values, 1, -1 do table.remove(hpo_skill_job_values, i) end
    for job = 1, 10 do
        local job_name = HPO_JobRealNames[job] or ("Job" .. string.format("%02d", job))
        hpo_skill_job_names[job] = job_name
        catalog.vocations[#catalog.vocations + 1] = { id=job, name=job_name }
        catalog.vocation_skills[tostring(job)] = catalog.vocation_skills[tostring(job)] or {}
        table.sort(catalog.vocation_skills[tostring(job)])
        hpo_skill_job_list[job] = job_name .. " (" .. tostring(job) .. ")"
        hpo_skill_job_values[job] = job
        logp("[PawnResearch] PASO 113 SKILLS job=" .. tostring(job) .. " custom=" .. tostring(by_job[job] or 0))
    end

    hpo_skill_catalog = catalog
    PawnResearch_CatalogoSkillsVivas = catalog
    PawnResearch_CatalogoCoreVivo = core_map
    PawnResearch_CatalogoAugmentsVivos = augment_map
    PawnResearch_CatalogoHabilidadesEquipo = equipment_map
    PawnResearch_CatalogoAppraisal = appraisal_map
    logp("[PawnResearch] PASO 113 SKILLS custom=" .. tostring(#custom)
        .. " core=" .. tostring(#core) .. " augments=" .. tostring(#augments)
        .. " equipment_ability=" .. tostring(#equipment) .. " appraisal=" .. tostring(#appraisal))
    return true, "Catalogos de skills/core/augments instalados en memoria"
end

paso113_inspeccionar_altura = function(character)
    logp("[PawnResearch] PASO 113 ===== EDITVALUES Y VEC3 =====")
    local ps = get_part_swapper(character)
    local editor = get_field_value_by_name(ps, "_BodyEditor")
    local ctx = get_field_value_by_name(editor, "_BodyEditContext")
    if editor == nil or ctx == nil then
        logp("[PawnResearch] PASO 113 BodyEditor/BodyEditContext=nil")
        return
    end
    logp("[PawnResearch] PASO 113 BodyEditor=" .. tostring(safe(function() return editor:get_type_definition():get_full_name() end)))
    local td, seen = safe(function() return ctx:get_type_definition() end), {}
    while td ~= nil do
        local tn = safe(function() return td:get_full_name() end) or "<?>"
        if seen[tn] then break end
        seen[tn] = true
        for _, m in ipairs(safe(function() return td:get_methods() end) or {}) do
            local n = safe(function() return m:get_name() end)
            if n == "setEditValue" or n == "getEditValue" then
                paso111_log_metodo(m, "[PawnResearch] PASO 113 BodyEditContext ")
            end
        end
        td = safe(function() return td:get_parent_type() end)
    end
    local height = safe(function() return ctx:call("getEditValue(System.UInt32)", 1497737450) end)
    logp("[PawnResearch] PASO 113 getEditValue(height_hash)=" .. tostring(height))

    local values = safe(function() return ctx:call("get_EditValues") end)
    if values == nil then values = get_field_value_by_name(ctx, "_EditValues") end
    paso111_log_objeto("PASO 113 EditValues", values)
    if values ~= nil then
        local size = safe(function() return values:get_size() end)
        logp("[PawnResearch] PASO 113 EditValues.get_size directo=" .. tostring(size))
        if type(size) == "number" then
            local found = false
            for i = 0, math.min(size - 1, 127) do
                local edit = safe(function() return values:get_element(i) end)
                if edit ~= nil then
                    local hash = safe_call(edit, "get_EditKeyHash") or get_field_value_by_name(edit, "_EditKeyHash")
                    if tonumber(hash) == 1497737450 then
                        local value = safe_call(edit, "get_Value") or get_field_value_by_name(edit, "_Value")
                        logp("[PawnResearch] PASO 113 HEIGHT array_index=" .. tostring(i) .. " value=" .. tostring(value))
                        found = true
                        break
                    end
                end
            end
            logp("[PawnResearch] PASO 113 HEIGHT array_found=" .. tostring(found))
        end
    end

    local setup_ok, setup_result = pcall(function() return editor:call("setupApplyEditScales") end)
    logp("[PawnResearch] PASO 113 setupApplyEditScales ok=" .. tostring(setup_ok) .. " result=" .. tostring(setup_result))
    local scales = get_field_value_by_name(editor, "_ApplyEditScales")
    logp("[PawnResearch] PASO 113 ApplyEditScales=" .. value_to_string(scales)
        .. " count=" .. tostring(safe_call(scales, "get_Count")))
    if scales == nil then return end

    local outer = safe_call(scales, "GetEnumerator")
    local moved = outer and safe_call(outer, "MoveNext") or false
    local shown = 0
    while moved == true and shown < 3 do
        local pair = safe_call(outer, "get_Current")
        local joint_hash, inner = safe_call(pair, "get_Key"), safe_call(pair, "get_Value")
        if safe_call(inner, "ContainsKey", 1497737450) == true then
            shown = shown + 1
            local joint = safe_call(inner, "get_Item", 1497737450)
            logp("[PawnResearch] PASO 113 HEIGHT MATCH #" .. tostring(shown) .. " joint_hash=" .. tostring(joint_hash))
            for _, field_name in ipairs({"_UpperScale", "_LowerScale", "_UpperTranslate", "_LowerTranslate"}) do
                local vec = get_field_value_by_name(joint, field_name)
                logp("[PawnResearch] PASO 113 VEC " .. field_name .. "=" .. tostring(vec))
                if vec ~= nil then
                    for index = 0, 2 do
                        local number = safe(function() return vec:call("get_Item(System.Int32)", index) end)
                        logp("[PawnResearch] PASO 113 VEC " .. field_name .. " GET_ITEM[" .. tostring(index) .. "]=" .. tostring(number))
                    end
                end
            end
        end
        moved = safe_call(outer, "MoveNext")
    end
    logp("[PawnResearch] PASO 113 vec3_matches_read=" .. tostring(shown))
end

paso113_construir_catalogos_y_diagnosticar = function(character)
    logp("[PawnResearch] ===== PASO 113 CATALOGOS VIVOS + ALTURA =====")
    if character == nil then return false, "character nil" end
    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] PASO 113 CID=" .. tostring(cid)
        .. " protegido=" .. tostring(is_character_protected(cid))
        .. " tdb=" .. tostring(safe(function() return sdk.get_tdb_version() end)))
    logp("[PawnResearch] PASO 113 MODO: solo lectura del juego; construccion de tablas Lua en memoria")
    local item_ok, item_msg = paso113_construir_equipo()
    logp("[PawnResearch] PASO 113 EQUIPO ok=" .. tostring(item_ok) .. " detalle=" .. tostring(item_msg))
    local skill_ok, skill_msg = paso113_construir_skills()
    logp("[PawnResearch] PASO 113 SKILLS ok=" .. tostring(skill_ok) .. " detalle=" .. tostring(skill_msg))
    paso113_inspeccionar_altura(character)
    logp("[PawnResearch] PASO 113 RESUMEN equipo=" .. tostring(type(hpo_itemData) == "table")
        .. " skills=" .. tostring(type(hpo_skill_catalog) == "table")
        .. " Main_options=" .. tostring(hpo_itemLists.Main and #hpo_itemLists.Main or 0)
        .. " Job05_skills=" .. tostring(hpo_skill_catalog and hpo_skill_catalog.vocation_skills
            and hpo_skill_catalog.vocation_skills["5"] and #hpo_skill_catalog.vocation_skills["5"] or 0))
    logp("[PawnResearch] PASO 113 NOTA: no hubo escrituras al juego; los catalogos viven solo durante esta sesion")
    logp("[PawnResearch] ===== FIN PASO 113 =====")
    return item_ok and skill_ok, "Catalogos construidos; revisar log del Paso 113"
end

logp("[PawnResearch] ===== PASO 113 CARGADO (catalogos dinamicos en memoria + lectura altura) =====")


-- ============================================================
-- PASO 114: VALIDAR CATALOGOS VIVOS, LOADOUTS Y LECTURA REAL DE VEC3
-- El Paso 113 construyo los catalogos correctamente, pero get_Item se
-- intento llamar desde el objeto Vector3f copiado y devolvio nil.
-- REFramework convierte via.vec3 a Vector3f Lua; se prueba x/y/z directos.
-- Se mantiene la auditoria: no cambia equipo, skills ni apariencia.
-- ============================================================

paso114_numero_valido = function(value)
    return type(value) == "number" and value == value and math.abs(value) < 1000000
end

paso114_leer_componentes_vec3 = function(vec, etiqueta)
    if vec == nil then
        logp("[PawnResearch] PASO 114 " .. tostring(etiqueta) .. " vector=nil")
        return nil, nil, nil, false
    end

    local ok_x, x = pcall(function() return vec.x end)
    local ok_y, y = pcall(function() return vec.y end)
    local ok_z, z = pcall(function() return vec.z end)

    if not ok_x then x = nil end
    if not ok_y then y = nil end
    if not ok_z then z = nil end

    logp("[PawnResearch] PASO 114 " .. tostring(etiqueta)
        .. " Vector3f=" .. tostring(vec)
        .. " x=" .. tostring(x) .. " (ok=" .. tostring(ok_x) .. ")"
        .. " y=" .. tostring(y) .. " (ok=" .. tostring(ok_y) .. ")"
        .. " z=" .. tostring(z) .. " (ok=" .. tostring(ok_z) .. ")")

    local valid = ok_x and ok_y and ok_z
        and paso114_numero_valido(x)
        and paso114_numero_valido(y)
        and paso114_numero_valido(z)

    -- Indices Lua se prueban solamente como lectura alternativa.
    -- No se invoca el metodo nativo get_Item desde el wrapper Vector3f.
    if not valid then
        for index = 0, 2 do
            local ok_index, value = pcall(function() return vec[index] end)
            logp("[PawnResearch] PASO 114 " .. tostring(etiqueta)
                .. " INDEX[" .. tostring(index) .. "]=" .. tostring(value)
                .. " ok=" .. tostring(ok_index))
        end
    end

    return x, y, z, valid
end

paso114_auditar_vector_definition = function()
    local td = safe(function() return sdk.find_type_definition("via.vec3") end)
    logp("[PawnResearch] PASO 114 TYPEDEF via.vec3=" .. tostring(td))
    if td == nil then return end

    logp("[PawnResearch] PASO 114 via.vec3 is_value_type="
        .. tostring(safe(function() return td:is_value_type() end))
        .. " size=" .. tostring(safe(function() return td:get_size() end))
        .. " valuetype_size=" .. tostring(safe(function() return td:get_valuetype_size() end)))

    for _, component in ipairs({"x", "y", "z"}) do
        local field = safe(function() return td:get_field(component) end)
        local field_type = field and safe(function() return field:get_type():get_full_name() end) or nil
        local offset_base = field and safe(function() return field:get_offset_from_base() end) or nil
        local offset_ptr = field and safe(function() return field:get_offset_from_fieldptr() end) or nil
        logp("[PawnResearch] PASO 114 via.vec3 FIELD " .. component
            .. " type=" .. tostring(field_type)
            .. " offset_base=" .. tostring(offset_base)
            .. " offset_fieldptr=" .. tostring(offset_ptr))
    end

    local getter = safe(function() return td:get_method("get_Item(System.Int32)") end)
    local setter = safe(function() return td:get_method("set_Item(System.Int32, System.Single)") end)
    logp("[PawnResearch] PASO 114 via.vec3 get_Item(System.Int32)=" .. tostring(getter)
        .. " set_Item(System.Int32,System.Single)=" .. tostring(setter))
    if getter ~= nil then
        logp("[PawnResearch] PASO 114 via.vec3 get_Item return="
            .. tostring(safe(function() return getter:get_return_type():get_full_name() end))
            .. " params=" .. tostring(safe(function() return getter:get_num_params() end)))
    end
end

paso114_diagnosticar_apply_scales_vec3 = function(character)
    logp("[PawnResearch] PASO 114 ===== APPLYEDITSCales / VEC3 =====")
    local ps = get_part_swapper(character)
    local editor = get_field_value_by_name(ps, "_BodyEditor")
    local ctx = get_field_value_by_name(editor, "_BodyEditContext")
    if editor == nil or ctx == nil then
        logp("[PawnResearch] PASO 114 BodyEditor o BodyEditContext=nil")
        return false, "BodyEditor/BodyEditContext no disponible"
    end

    local body_height = safe_call(editor, "get_BodyHeight")
    local context_height = safe(function() return ctx:call("getEditValue(System.UInt32)", 1497737450) end)
    logp("[PawnResearch] PASO 114 BodyHeight=" .. tostring(body_height)
        .. " context_height=" .. tostring(context_height))

    local values = safe(function() return ctx:call("get_EditValues") end)
    if values == nil then values = get_field_value_by_name(ctx, "_EditValues") end
    local value_count = safe(function() return values:get_size() end)
    logp("[PawnResearch] PASO 114 EditValues size=" .. tostring(value_count))
    if type(value_count) == "number" then
        local found = false
        for index = 0, math.min(value_count - 1, 127) do
            local item = safe(function() return values:get_element(index) end)
            if item ~= nil then
                local hash = safe_call(item, "get_EditKeyHash") or get_field_value_by_name(item, "_EditKeyHash")
                if tonumber(hash) == 1497737450 then
                    local value = safe_call(item, "get_Value") or get_field_value_by_name(item, "_Value")
                    logp("[PawnResearch] PASO 114 HEIGHT EditValues index=" .. tostring(index)
                        .. " value=" .. tostring(value))
                    found = true
                    break
                end
            end
        end
        logp("[PawnResearch] PASO 114 HEIGHT EditValues found=" .. tostring(found))
    end

    local setup_ok, setup_result = pcall(function() return editor:call("setupApplyEditScales") end)
    logp("[PawnResearch] PASO 114 setupApplyEditScales ok=" .. tostring(setup_ok)
        .. " result=" .. tostring(setup_result))

    local scales = get_field_value_by_name(editor, "_ApplyEditScales")
    local count = safe_call(scales, "get_Count")
    logp("[PawnResearch] PASO 114 _ApplyEditScales=" .. value_to_string(scales)
        .. " count=" .. tostring(count))
    if scales == nil then return false, "_ApplyEditScales no disponible" end

    local outer = safe_call(scales, "GetEnumerator")
    local moved = outer and safe_call(outer, "MoveNext") or false
    local joints_with_height, vectors_read, vectors_valid = 0, 0, 0
    local max_samples = 6

    while moved == true do
        local pair = safe_call(outer, "get_Current")
        local joint_hash = safe_call(pair, "get_Key")
        local inner = safe_call(pair, "get_Value")
        if safe_call(inner, "ContainsKey", 1497737450) == true then
            joints_with_height = joints_with_height + 1
            if joints_with_height <= max_samples then
                local joint = safe_call(inner, "get_Item", 1497737450)
                logp("[PawnResearch] PASO 114 HEIGHT MATCH #" .. tostring(joints_with_height)
                    .. " joint_hash=" .. tostring(joint_hash)
                    .. " joint_type=" .. tostring(safe(function() return joint:get_type_definition():get_full_name() end)))

                for _, field_name in ipairs({"_UpperScale", "_LowerScale", "_UpperTranslate", "_LowerTranslate"}) do
                    local vec = get_field_value_by_name(joint, field_name)
                    if vec ~= nil then
                        vectors_read = vectors_read + 1
                        local _, _, _, valid = paso114_leer_componentes_vec3(
                            vec, "MATCH#" .. tostring(joints_with_height) .. " " .. field_name)
                        if valid then vectors_valid = vectors_valid + 1 end
                    else
                        logp("[PawnResearch] PASO 114 MATCH#" .. tostring(joints_with_height)
                            .. " " .. field_name .. "=nil")
                    end
                end
            end
        end
        moved = safe_call(outer, "MoveNext")
    end

    logp("[PawnResearch] PASO 114 ESCALAS joints_with_height=" .. tostring(joints_with_height)
        .. " vectors_read=" .. tostring(vectors_read)
        .. " vectors_valid=" .. tostring(vectors_valid)
        .. " muestras=" .. tostring(math.min(joints_with_height, max_samples)))
    logp("[PawnResearch] PASO 114 NOTA: setupApplyEditScales solo calcula la tabla interna; no se escribieron valores ni se solicito refresh visual")
    return vectors_read > 0, "Diagnostico Vector3f terminado"
end

paso114_validar_catalogos_y_loadouts = function(character)
    logp("[PawnResearch] PASO 114 ===== CATALOGOS Y LOADOUTS =====")

    local item_total, list_total = 0, 0
    if type(hpo_itemData) == "table" then
        for _ in pairs(hpo_itemData) do item_total = item_total + 1 end
    end
    if type(hpo_itemLists) == "table" then
        for slot, entries in pairs(hpo_itemLists) do
            local n = type(entries) == "table" and #entries or 0
            list_total = list_total + n
            logp("[PawnResearch] PASO 114 ITEM UI slot=" .. tostring(slot)
                .. " opciones=" .. tostring(n))
        end
    end
    logp("[PawnResearch] PASO 114 ITEM catalog_count=" .. tostring(item_total)
        .. " ui_options_total=" .. tostring(list_total)
        .. " source=" .. tostring(PawnResearch_CatalogoEquipoVivo and "ItemManager" or "JSON/none"))

    local skill_total = 0
    if type(hpo_skill_catalog) == "table" and type(hpo_skill_catalog.skills) == "table" then
        skill_total = #hpo_skill_catalog.skills
    end
    logp("[PawnResearch] PASO 114 SKILL catalog_total=" .. tostring(skill_total)
        .. " core=" .. tostring(PawnResearch_CatalogoCoreVivo and "available" or "nil")
        .. " augments=" .. tostring(PawnResearch_CatalogoAugmentsVivos and "available" or "nil")
        .. " equipment_ability=" .. tostring(PawnResearch_CatalogoHabilidadesEquipo and "available" or "nil")
        .. " appraisal=" .. tostring(PawnResearch_CatalogoAppraisal and "available" or "nil"))

    for job = 1, 10 do
        local ids = hpo_skill_catalog and hpo_skill_catalog.vocation_skills
            and hpo_skill_catalog.vocation_skills[tostring(job)] or nil
        logp("[PawnResearch] PASO 114 SKILL job=" .. tostring(job)
            .. " count=" .. tostring(type(ids) == "table" and #ids or 0))
    end

    local equip_ok, equip_data, equip_err = pcall(function()
        local snapshot, err = hpo_global_loadout_system.snapshot_equipment(character)
        return snapshot, err
    end)
    if equip_ok and type(equip_data) == "table" then
        for _, slot in ipairs(HPO_SLOTS) do
            local id = tonumber(equip_data[slot]) or 0
            local item = id > 0 and hpo_itemData and hpo_itemData[tostring(id)] or nil
            logp("[PawnResearch] PASO 114 EQUIP CURRENT slot=" .. tostring(slot)
                .. " id=" .. tostring(id) .. " name=" .. tostring(item and item.name or (id == 0 and "(vacio)" or "no_en_catalogo")))
        end
    else
        logp("[PawnResearch] PASO 114 EQUIP READ failed=" .. tostring(equip_ok)
            .. " detail=" .. tostring(equip_ok and equip_err or equip_data))
    end

    local skill_call_ok, read_ok, read_err, loadout = pcall(function()
        return hpo_read_skill_loadout(character)
    end)
    if skill_call_ok and read_ok == true and type(loadout) == "table" then
        logp("[PawnResearch] PASO 114 SKILL CURRENT job=" .. tostring(loadout.current_job_num)
            .. " read_job=" .. tostring(loadout.read_job))
        for slot = 0, HPO_SKILL_SLOT_COUNT - 1 do
            local id = tonumber(loadout.slots and loadout.slots[slot]) or 0
            logp("[PawnResearch] PASO 114 SKILL CURRENT slot=" .. tostring(slot)
                .. " id=" .. tostring(id) .. " name=" .. tostring(hpo_skill_name(id))
                .. " valid_for_job=" .. tostring(hpo_skill_id_is_valid_for_job(loadout.read_job, id)))
        end
    else
        logp("[PawnResearch] PASO 114 SKILL READ failed=" .. tostring(skill_call_ok)
            .. " read_ok=" .. tostring(read_ok) .. " detail=" .. tostring(read_err))
    end
end

paso114_auditar_catalogos_y_vec3 = function(character)
    logp("[PawnResearch] ===== PASO 114 VALIDAR CATALOGOS / LOADOUTS / VEC3 =====")
    if character == nil then return false, "character nil" end
    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] PASO 114 CID=" .. tostring(cid)
        .. " protegido=" .. tostring(is_character_protected(cid))
        .. " tdb=" .. tostring(safe(function() return sdk.get_tdb_version() end)))
    logp("[PawnResearch] PASO 114 MODO: lectura del juego y tablas Lua; no aplicar equipo, skills o apariencia")

    -- Reconstruir catálogos por si el usuario no ejecuto Paso 113 en esta sesion.
    local item_ok, item_msg = paso113_construir_equipo()
    local skill_ok, skill_msg = paso113_construir_skills()
    logp("[PawnResearch] PASO 114 CATALOG BUILD item_ok=" .. tostring(item_ok)
        .. " item_msg=" .. tostring(item_msg)
        .. " skill_ok=" .. tostring(skill_ok) .. " skill_msg=" .. tostring(skill_msg))

    paso114_validar_catalogos_y_loadouts(character)
    paso114_auditar_vector_definition()
    local vec_ok, vec_msg = paso114_diagnosticar_apply_scales_vec3(character)

    logp("[PawnResearch] PASO 114 RESUMEN items=" .. tostring(type(hpo_itemData) == "table")
        .. " skills=" .. tostring(type(hpo_skill_catalog) == "table")
        .. " vector_read=" .. tostring(vec_ok)
        .. " detalle=" .. tostring(vec_msg))
    logp("[PawnResearch] PASO 114 NOTA: no se escribio en Character, Human, PartSwapper, inventario, equipo, SkillContext ni Appearance; no hubo refresh")
    logp("[PawnResearch] ===== FIN PASO 114 =====")
    return item_ok and skill_ok, "Auditoria Paso 114 terminada; revisar log"
end

logp("[PawnResearch] ===== PASO 114 CARGADO (catalogos/loadouts/Vector3f solo lectura) =====")


-- ============================================================
-- PASO 115: AUDITORIA COMPLETA DE JOINTS Y HASHES ANATOMICOS
-- Objetivo: enumerar todos los joints de _ApplyEditScales, registrar
-- _JointNameHash y las cuatro estructuras Vector3f. No se infiere anatomia
-- a partir de hashes desconocidos: el log deja los identificadores listos
-- para resolverlos con una tabla/nombre obtenido de la propia build TU4.
-- Solo lectura de datos. No modifica vectores, EditValues ni apariencia.
-- ============================================================

paso115_auditar_joints = function(character)
    logp("[PawnResearch] ===== PASO 115 AUDITORIA COMPLETA DE JOINTS =====")
    if character == nil then
        logp("[PawnResearch] PASO 115 character=nil")
        return false, "character nil"
    end

    local cid = get_field_value_by_name(character, "CharacterID")
    logp("[PawnResearch] PASO 115 CID=" .. tostring(cid)
        .. " protegido=" .. tostring(is_character_protected(cid))
        .. " tdb=" .. tostring(safe(function() return sdk.get_tdb_version() end)))
    logp("[PawnResearch] PASO 115 MODO: solo lectura; no se modifican joints ni apariencia")

    local ps = get_part_swapper(character)
    local editor = get_field_value_by_name(ps, "_BodyEditor")
    if editor == nil then
        logp("[PawnResearch] PASO 115 BodyEditor=nil")
        return false, "BodyEditor nil"
    end

    local scales = get_field_value_by_name(editor, "_ApplyEditScales")
    if scales == nil then
        logp("[PawnResearch] PASO 115 _ApplyEditScales=nil; preparando cache con setupApplyEditScales")
        local setup_ok, setup_result = pcall(function()
            return editor:call("setupApplyEditScales")
        end)
        logp("[PawnResearch] PASO 115 setupApplyEditScales ok=" .. tostring(setup_ok)
            .. " result=" .. tostring(setup_result))
        scales = get_field_value_by_name(editor, "_ApplyEditScales")
    end
    if scales == nil then
        logp("[PawnResearch] PASO 115 _ApplyEditScales continua nil")
        return false, "_ApplyEditScales nil"
    end

    local outer_count = safe_call(scales, "get_Count")
    logp("[PawnResearch] PASO 115 ApplyEditScales=" .. value_to_string(scales)
        .. " outer_count=" .. tostring(outer_count))

    local enumerator = safe_call(scales, "GetEnumerator")
    if enumerator == nil then
        logp("[PawnResearch] PASO 115 GetEnumerator=nil")
        return false, "No se pudo enumerar ApplyEditScales"
    end

    local total, with_height, missing_height, data_ok = 0, 0, 0, 0
    local unique_joint_name_hashes = {}
    local repeated_joint_name_hashes = {}
    local min_hash, max_hash = nil, nil
    local field_names = { "_UpperScale", "_LowerScale", "_UpperTranslate", "_LowerTranslate" }

    while safe_call(enumerator, "MoveNext") == true do
        local pair = safe_call(enumerator, "get_Current")
        if pair == nil then
            logp("[PawnResearch] PASO 115 enumerator Current=nil; corte seguro")
            break
        end
        total = total + 1
        local outer_hash = safe_call(pair, "get_Key")
        local inner = safe_call(pair, "get_Value")
        local inner_count = safe_call(inner, "get_Count")
        local contains_height = safe_call(inner, "ContainsKey", 1497737450) == true

        if type(outer_hash) == "number" then
            if min_hash == nil or outer_hash < min_hash then min_hash = outer_hash end
            if max_hash == nil or outer_hash > max_hash then max_hash = outer_hash end
        end

        if contains_height then
            with_height = with_height + 1
            local joint = safe_call(inner, "get_Item", 1497737450)
            if joint ~= nil then
                data_ok = data_ok + 1
                local joint_name_hash = get_field_value_by_name(joint, "_JointNameHash")
                if joint_name_hash == nil then
                    joint_name_hash = safe_call(joint, "get_JointNameHash")
                end
                if joint_name_hash ~= nil then
                    local key = tostring(joint_name_hash)
                    if unique_joint_name_hashes[key] then
                        repeated_joint_name_hashes[key] = (repeated_joint_name_hashes[key] or 1) + 1
                    else
                        unique_joint_name_hashes[key] = true
                    end
                end

                logp("[PawnResearch] PASO 115 JOINT index=" .. tostring(total)
                    .. " outer_hash=" .. tostring(outer_hash)
                    .. " joint_name_hash=" .. tostring(joint_name_hash)
                    .. " inner_count=" .. tostring(inner_count)
                    .. " type=" .. object_type_name(joint))

                for _, field_name in ipairs(field_names) do
                    local vec = get_field_value_by_name(joint, field_name)
                    if vec ~= nil then
                        local x, y, z, valid = paso114_leer_componentes_vec3(
                            vec, "JOINT#" .. tostring(total) .. " " .. field_name)
                        logp("[PawnResearch] PASO 115 VECTOR joint=" .. tostring(outer_hash)
                            .. " field=" .. field_name .. " valid=" .. tostring(valid)
                            .. " xyz=" .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z))
                    else
                        logp("[PawnResearch] PASO 115 VECTOR joint=" .. tostring(outer_hash)
                            .. " field=" .. field_name .. " nil=true")
                    end
                end
            else
                logp("[PawnResearch] PASO 115 JOINT outer_hash=" .. tostring(outer_hash)
                    .. " height_entry=true JointEditData=nil")
            end
        else
            missing_height = missing_height + 1
            logp("[PawnResearch] PASO 115 JOINT outer_hash=" .. tostring(outer_hash)
                .. " height_entry=false inner_count=" .. tostring(inner_count))
        end
    end

    local unique_count = 0
    for _ in pairs(unique_joint_name_hashes) do unique_count = unique_count + 1 end
    local repeated_count = 0
    for hash, amount in pairs(repeated_joint_name_hashes) do
        repeated_count = repeated_count + 1
        logp("[PawnResearch] PASO 115 DUPLICATE JointNameHash=" .. tostring(hash)
            .. " occurrences=" .. tostring(amount))
    end

    logp("[PawnResearch] PASO 115 SUMMARY outer_total=" .. tostring(total)
        .. " expected_outer=" .. tostring(outer_count)
        .. " with_height=" .. tostring(with_height)
        .. " missing_height=" .. tostring(missing_height)
        .. " joint_data_ok=" .. tostring(data_ok)
        .. " unique_joint_name_hashes=" .. tostring(unique_count)
        .. " repeated_hash_groups=" .. tostring(repeated_count)
        .. " outer_hash_min=" .. tostring(min_hash)
        .. " outer_hash_max=" .. tostring(max_hash))
    logp("[PawnResearch] PASO 115 ANATOMY: no se asignaron nombres anatomicos; _JointNameHash requiere resolucion contra nombres/definiciones TU4")
    logp("[PawnResearch] PASO 115 NOTA: no se escribio en JointEditData, via.vec3, EditValues, BodyEditor, Human, PartSwapper o Appearance; no hubo refresh")
    logp("[PawnResearch] ===== FIN PASO 115 =====")

    return total > 0 and data_ok > 0,
        "Auditoria de joints terminada; revisar hashes y vectores en el log"
end

logp("[PawnResearch] ===== PASO 115 CARGADO (auditoria completa de joints; solo lectura) =====")
