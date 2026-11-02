--[[
    ================================================================================
    ROBLOX — GOLDEN BLACK HOLE / DIVINE SINGULARITY VFX (OPUS 5.5 ULTRA-DETAILED)
    COMPATIBILIDADE: DELTA EXECUTOR MOBILE / CLIENT-SIDE LOCAL SCRIPT
    ARQUITETURA: PROCEDURAL MATEMÁTICA 3D • SISTEMA DE POSICIONAMENTO FRONTAL HRP
    ================================================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Limpeza preventiva de execuções anteriores no Delta Executor
if _G.DivineSingularityCleanup then
    pcall(_G.DivineSingularityCleanup)
end

-- ================================================================================
-- 1. PARÂMETROS AJUSTÁVEIS E ESTADO DO SISTEMA
-- ================================================================================
local Config = {
    -- Parâmetros Obrigatórios de Posicionamento Frontal
    FrontDistance = 28,                         -- Distância à frente do personagem
    VerticalOffset = 6.5,                       -- Altura do centro da singularidade em relação ao HRP
    FollowSpeed = 8.5,                          -- Velocidade de suavização (interpolação exponencial)
    RotationOffset = CFrame.Angles(0, 0, 0),    -- Offset angular customizável
    PositionOffset = Vector3.new(0, 0, 0),      -- Offset vetorial adicional

    -- Dimensões e Complexidade Visual
    CoreRadius = 5.2,                           -- Raio do horizonte de eventos (Buraco Negro)
    AccretionInnerRadius = 6.5,                 -- Raio interno do disco de acreção
    AccretionOuterRadius = 32.0,                -- Raio externo do disco de acreção
    ArcCount = 16,                              -- 16 arcos dourados complexos (> 12 exigidos)
    RingLayerCount = 6,                         -- 6 camadas concêntricas de anéis segmentados
    SegmentsPerRing = 20,                       -- Segmentos por camada de anel
    CosmicParticleCount = 65,                   -- Partículas individuais com física matemática própria
    GroundWaveInterval = 0.65,                  -- Intervalo de emissão de ondas no chão
    BeamHeight = 75.0,                          -- Altura total do feixe vertical atravessando o núcleo

    -- Paleta de Cores (Fiel à imagem de referência: Abismo Negro, Ouro Imperial, Branco Solar)
    VoidBlack = Color3.fromRGB(4, 3, 6),
    DeepAmber = Color3.fromRGB(185, 95, 10),
    ImperialGold = Color3.fromRGB(255, 180, 35),
    BrightGold = Color3.fromRGB(255, 220, 95),
    SolarWhite = Color3.fromRGB(255, 250, 230),
}

-- Máquina de Estados das 8 Fases de Animação Sincronizada
local Phases = {
    IDLE = 0,
    CORE_FORMATION = 1,       -- 1. Formação do núcleo
    ENERGY_CONDENSATION = 2,  -- 2. Condensação de energia
    RING_FORMATION = 3,       -- 3. Formação dos anéis
    ARC_EMERGENCE = 4,        -- 4. Surgimento dos arcos
    BEAM_ACTIVATION = 5,      -- 5. Ativação do feixe vertical
    INTENSIFICATION = 6,      -- 6. Intensificação
    MAXIMUM_STATE = 7,        -- 7. Estado máximo
    DISSIPATION = 8           -- 8. Dissipação
}

local PhaseNames = {
    [0] = "INATIVO",
    [1] = "1/8 FORMAÇÃO DO NÚCLEO",
    [2] = "2/8 CONDENSAÇÃO DE ENERGIA",
    [3] = "3/8 FORMAÇÃO DOS ANÉIS",
    [4] = "4/8 SURGIMENTO DOS ARCOS",
    [5] = "5/8 FEIXE VERTICAL",
    [6] = "6/8 INTENSIFICAÇÃO",
    [7] = "7/8 SINGULARIDADE MÁXIMA",
    [8] = "8/8 DISSIPAÇÃO QUÂNTICA"
}

local State = {
    Active = false,
    Phase = Phases.IDLE,
    PhaseTime = 0,
    TotalTime = 0,
    MasterScale = 0,
    CoreFactor = 0,
    CondenseFactor = 0,
    RingFactor = 0,
    ArcFactor = 0,
    BeamFactor = 0,
    OverdriveFactor = 0,

    CurrentCFrame = CFrame.new(0, 50, 0),
    TargetCFrame = CFrame.new(0, 50, 0),
    FollowCharacter = true,
    GroundYOffset = -6.0,
    LastWaveClock = 0,
    RepositionPulse = 0,

    Connections = {},
    CoreData = nil,
    RingsData = {},
    ArcsData = {},
    BeamData = nil,
    WavesData = {},
    ParticlesData = {},
    TrailsData = {},
    UI = {}
}

-- ================================================================================
-- 2. GERADOR DE TEXTURAS PROCEDURAIS E UTILITÁRIOS MATEMÁTICOS
-- ================================================================================
local Assets = {
    GlowBeam = "rbxassetid://446111271",
    SoftParticle = "rbxassetid://243660364",
    SparkParticle = "rbxassetid://241685484",
    RingMesh = "rbxassetid://3270017"
}

local function Clamp(val, minVal, maxVal)
    return math.max(minVal, math.min(maxVal, val))
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function SmoothStep(edge0, edge1, x)
    local t = Clamp((x - edge0) / (edge1 - edge0), 0, 1)
    return t * t * (3 - 2 * t)
end

-- Cria pasta de armazenamento segura no Workspace
local VFXFolder = Workspace:FindFirstChild("DivineSingularityVFX_Opus55")
if VFXFolder then
    VFXFolder:Destroy()
end
VFXFolder = Instance.new("Folder")
VFXFolder.Name = "DivineSingularityVFX_Opus55"
VFXFolder.Parent = Workspace

-- Construtor otimizado de BasePart para VFX
local function CreateVFXPart(name, shape, size, color, material, transparency, parent)
    local part = Instance.new("Part")
    part.Name = name
    part.Shape = shape or Enum.PartType.Ball
    part.Size = size or Vector3.new(1, 1, 1)
    part.Color = color or Config.ImperialGold
    part.Material = material or Enum.Material.Neon
    part.Transparency = transparency or 0
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent or VFXFolder
    return part
end

-- Construtor de SpecialMesh (Esferas em escala não-uniforme, Anéis Toroidais e Cilindros Finos)
local function AddMesh(part, meshType, scale, meshId)
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = meshType or Enum.MeshType.Sphere
    if meshId then
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = meshId
    end
    mesh.Scale = scale or Vector3.new(1, 1, 1)
    mesh.Parent = part
    return mesh
end

-- Sequência de Cores Dourada Divina (Branco Solar -> Ouro Imperial -> Âmbar Profundo)
local GoldenColorSequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Config.SolarWhite),
    ColorSequenceKeypoint.new(0.25, Config.BrightGold),
    ColorSequenceKeypoint.new(0.65, Config.ImperialGold),
    ColorSequenceKeypoint.new(1.0, Config.DeepAmber)
})

local CoreHaloColorSequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Config.DeepAmber),
    ColorSequenceKeypoint.new(0.5, Config.SolarWhite),
    ColorSequenceKeypoint.new(1.0, Config.DeepAmber)
})

-- ================================================================================
-- 3. CREATE ENERGY TRAIL (RASTROS LUMINOSOS DETALHADOS)
-- ================================================================================
local function CreateEnergyTrail(parentPart, widthStart, widthEnd, lifetime, offsetRadius, colorSeq)
    local att0 = Instance.new("Attachment")
    att0.Name = "TrailAtt0"
    att0.Position = Vector3.new(0, offsetRadius or 0.35, 0)
    att0.Parent = parentPart

    local att1 = Instance.new("Attachment")
    att1.Name = "TrailAtt1"
    att1.Position = Vector3.new(0, -(offsetRadius or 0.35), 0)
    att1.Parent = parentPart

    local trail = Instance.new("Trail")
    trail.Name = "GoldenEnergyTrail"
    trail.Attachment0 = att0
    trail.Attachment1 = att1
    trail.Lifetime = lifetime or 0.45
    trail.MinLength = 0.05
    trail.FaceCamera = true
    trail.LightEmission = 1
    trail.LightInfluence = 0
    trail.Brightness = 3.5
    trail.Color = colorSeq or GoldenColorSequence
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, widthStart or 1.0),
        NumberSequenceKeypoint.new(0.4, (widthStart or 1.0) * 0.7),
        NumberSequenceKeypoint.new(1.0, widthEnd or 0.0)
    })
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0.05),
        NumberSequenceKeypoint.new(0.5, 0.35),
        NumberSequenceKeypoint.new(1.0, 1.0)
    })
    trail.Parent = parentPart

    local trailRecord = {
        Trail = trail,
        Att0 = att0,
        Att1 = att1,
        BaseLifetime = lifetime or 0.45
    }
    table.insert(State.TrailsData, trailRecord)
    return trailRecord
end

-- ================================================================================
-- 4. CREATE SINGULARITY CORE (NÚCLEO ESCURO, CAMADAS CONCÊNTRICAS E LENTE GRAVITACIONAL)
-- ================================================================================
local function CreateSingularityCore()
    local coreFolder = Instance.new("Folder")
    coreFolder.Name = "SingularityCore"
    coreFolder.Parent = VFXFolder

    -- Âncora Principal da Singularidade
    local rootAnchor = CreateVFXPart("RootAnchor", Enum.PartType.Ball, Vector3.new(0.5, 0.5, 0.5), Config.SolarWhite, Enum.Material.Neon, 1, coreFolder)

    -- Iluminação Dinâmica de Longo Alcance
    local coreLight = Instance.new("PointLight")
    coreLight.Name = "SingularityLight"
    coreLight.Color = Color3.fromRGB(255, 200, 75)
    coreLight.Range = 60
    coreLight.Brightness = 0
    coreLight.Shadows = false
    coreLight.Parent = rootAnchor

    -- 1. Esfera Escura Absoluta (Horizonte de Eventos - Buraco Negro)
    local voidSphere = CreateVFXPart("EventHorizonVoid", Enum.PartType.Ball, Vector3.new(1, 1, 1), Config.VoidBlack, Enum.Material.SmoothPlastic, 0, coreFolder)
    voidSphere.Reflectance = 0
    local voidMesh = AddMesh(voidSphere, Enum.MeshType.Sphere, Vector3.new(1, 1, 1))

    -- 2. Abismo Interno Secundário (Absorção de luz profunda)
    local innerAbyss = CreateVFXPart("InnerAbyss", Enum.PartType.Ball, Vector3.new(1, 1, 1), Color3.fromRGB(0, 0, 0), Enum.Material.Neon, 0.05, coreFolder)
    local innerAbyssMesh = AddMesh(innerAbyss, Enum.MeshType.Sphere, Vector3.new(1, 1, 1))

    -- 3. Camadas Concêntricas da Esfera de Fótons (Contornos Dourados Intensos)
    local concentricShells = {}
    local shellConfigs = {
        { scale = 1.03, color = Config.SolarWhite, trans = 0.15, speed = 1.8, axis = Vector3.new(1, 0.3, 0.2).Unit },
        { scale = 1.08, color = Config.BrightGold, trans = 0.38, speed = -2.4, axis = Vector3.new(0.2, 1, 0.4).Unit },
        { scale = 1.15, color = Config.ImperialGold, trans = 0.58, speed = 1.2, axis = Vector3.new(0.4, 0.2, 1).Unit },
        { scale = 1.26, color = Config.DeepAmber, trans = 0.74, speed = -0.9, axis = Vector3.new(1, 1, 0.2).Unit },
        { scale = 1.40, color = Config.ImperialGold, trans = 0.85, speed = 0.6, axis = Vector3.new(0.3, 1, 1).Unit }
    }

    for i, cfg in ipairs(shellConfigs) do
        local shellPart = CreateVFXPart("PhotonShell_" .. i, Enum.PartType.Ball, Vector3.new(1, 1, 1), cfg.color, Enum.Material.Neon, 1, coreFolder)
        local mesh = AddMesh(shellPart, Enum.MeshType.Sphere, Vector3.new(1, 1, 1))
        table.insert(concentricShells, {
            Part = shellPart,
            Mesh = mesh,
            BaseScale = cfg.scale,
            BaseTrans = cfg.trans,
            Speed = cfg.speed,
            Axis = cfg.axis,
            PhaseOffset = i * 1.15
        })
    end

    -- 4. Anéis de Lente Gravitacional Relativística (O arco dourado superior e inferior da imagem!)
    -- Na imagem de referência, a gravidade curva a luz formando um domo luminoso acima e um cálice luminoso abaixo do buraco negro.
    local lensingRings = {}
    local lensConfigs = {
        -- Anel de Einstein Frontal Vertical (Contorno brilhante imediato ao redor da esfera negra)
        { radius = 1.04, thickness = 0.14, tiltX = math.rad(90), tiltZ = 0, color = Config.SolarWhite, trans = 0.05 },
        { radius = 1.10, thickness = 0.22, tiltX = math.rad(86), tiltZ = math.rad(4), color = Config.BrightGold, trans = 0.25 },
        -- Arco de Lente Superior e Inferior Inclinado (Efeito Gargantua)
        { radius = 1.22, thickness = 0.28, tiltX = math.rad(72), tiltZ = math.rad(-6), color = Config.ImperialGold, trans = 0.35 },
        { radius = 1.36, thickness = 0.35, tiltX = math.rad(108), tiltZ = math.rad(6), color = Config.ImperialGold, trans = 0.45 },
        { radius = 1.52, thickness = 0.42, tiltX = math.rad(62), tiltZ = 0, color = Config.DeepAmber, trans = 0.62 },
        { radius = 1.68, thickness = 0.50, tiltX = math.rad(118), tiltZ = 0, color = Config.DeepAmber, trans = 0.72 }
    }

    for i, lcfg in ipairs(lensConfigs) do
        local ringPart = CreateVFXPart("GravitationalLensRing_" .. i, Enum.PartType.Block, Vector3.new(1, 1, 1), lcfg.color, Enum.Material.Neon, 1, coreFolder)
        local ringMesh = AddMesh(ringPart, Enum.MeshType.FileMesh, Vector3.new(1, 1, 1), Assets.RingMesh)
        table.insert(lensingRings, {
            Part = ringPart,
            Mesh = ringMesh,
            RadiusFactor = lcfg.radius,
            ThicknessFactor = lcfg.thickness,
            TiltX = lcfg.tiltX,
            TiltZ = lcfg.tiltZ,
            BaseTrans = lcfg.trans,
            PulseOffset = i * 0.85
        })
    end

    -- 5. Partículas Orbitais de Horizonte de Eventos (18 Micro-astros dourados presos na órbita próxima)
    local coreOrbiters = {}
    for i = 1, 18 do
        local orbPart = CreateVFXPart("CoreOrbiter_" .. i, Enum.PartType.Ball, Vector3.new(0.45, 0.45, 0.45), (i % 2 == 0) and Config.SolarWhite or Config.BrightGold, Enum.Material.Neon, 1, coreFolder)
        local orbMesh = AddMesh(orbPart, Enum.MeshType.Sphere, Vector3.new(1, 1, 1))
        local trailData = CreateEnergyTrail(orbPart, 0.45, 0.0, 0.28, 0.18, CoreHaloColorSequence)

        local phi = math.acos(1 - 2 * (i / 18))
        local theta = math.pi * (1 + math.sqrt(5)) * i

        table.insert(coreOrbiters, {
            Part = orbPart,
            Mesh = orbMesh,
            Trail = trailData.Trail,
            OrbitRadius = Config.CoreRadius * (1.08 + (i % 5) * 0.09),
            Speed = (2.8 + (i % 4) * 0.75) * ((i % 2 == 0) and 1 or -1),
            Inclination = phi,
            Azimuth = theta,
            Phase = i * 0.52,
            Eccentricity = 0.12 + (i % 3) * 0.06
        })
    end

    State.CoreData = {
        Folder = coreFolder,
        RootAnchor = rootAnchor,
        Light = coreLight,
        VoidSphere = voidSphere,
        VoidMesh = voidMesh,
        InnerAbyss = innerAbyss,
        InnerAbyssMesh = innerAbyssMesh,
        ConcentricShells = concentricShells,
        LensingRings = lensingRings,
        Orbiters = coreOrbiters
    }

    return State.CoreData
end

-- ================================================================================
-- 5. CREATE ENERGY RING (ANEL DE ACREÇÃO HORIZONTAL MULTI-CAMADAS E FRAGMENTOS)
-- ================================================================================
local function CreateEnergyRing()
    local ringsFolder = Instance.new("Folder")
    ringsFolder.Name = "AccretionEnergyRings"
    ringsFolder.Parent = VFXFolder

    State.RingsData = {
        Folder = ringsFolder,
        Layers = {},
        DetachingFragments = {}
    }

    -- 6 Camadas Concêntricas do Disco de Acreção Horizontal
    for layerIdx = 1, Config.RingLayerCount do
        local layerFraction = (layerIdx - 1) / (Config.RingLayerCount - 1)
        local baseRadius = Lerp(Config.AccretionInnerRadius, Config.AccretionOuterRadius, layerFraction)
        local direction = (layerIdx % 2 == 1) and 1 or -1
        local angularSpeed = Lerp(3.2, 0.75, layerFraction) * direction
        local ringColor = (layerIdx == 1) and Config.SolarWhite
            or (layerIdx == 2) and Config.BrightGold
            or (layerIdx <= 4) and Config.ImperialGold
            or Config.DeepAmber

        -- Malha Toroidal Contínua de Base da Camada
        local torusPart = CreateVFXPart("AccretionTorus_" .. layerIdx, Enum.PartType.Block, Vector3.new(1, 1, 1), ringColor, Enum.Material.Neon, 1, ringsFolder)
        local torusMesh = AddMesh(torusPart, Enum.MeshType.FileMesh, Vector3.new(1, 1, 1), Assets.RingMesh)

        -- Segmentos Individuais com Feixes Luminosos (Beams) Conectados e Ondulação Própria
        local segments = {}
        local segCount = Config.SegmentsPerRing
        for segIdx = 1, segCount do
            local segPart = CreateVFXPart(
                string.format("RingL%d_Seg%d", layerIdx, segIdx),
                Enum.PartType.Block,
                Vector3.new(1, 1, 1),
                ringColor,
                Enum.Material.Neon,
                1,
                ringsFolder
            )
            local segMesh = AddMesh(segPart, Enum.MeshType.Sphere, Vector3.new(1, 1, 1))

            local attCenter = Instance.new("Attachment")
            attCenter.Name = "SegAtt"
            attCenter.Parent = segPart

            -- Trilha luminosa nos segmentos ímpares para criar riscas orbitais densas
            local segTrail = nil
            if (segIdx % 3 == 0) then
                local tr = CreateEnergyTrail(segPart, 0.65, 0.05, 0.35, 0.25, GoldenColorSequence)
                segTrail = tr.Trail
            end

            table.insert(segments, {
                Part = segPart,
                Mesh = segMesh,
                Attachment = attCenter,
                Trail = segTrail,
                AngleOffset = (segIdx / segCount) * math.pi * 2,
                WaveFrequency = 2.0 + (segIdx % 4),
                WaveAmplitude = 0.25 + layerFraction * 0.85,
                ThicknessSeed = segIdx * 0.73
            })
        end

        -- Conecta os segmentos em um circuito fechado de Beams de alta energia
        local ringBeams = {}
        for segIdx = 1, segCount do
            local nextIdx = (segIdx % segCount) + 1
            local beam = Instance.new("Beam")
            beam.Name = "AccretionSegmentBeam_" .. segIdx
            beam.Attachment0 = segments[segIdx].Attachment
            beam.Attachment1 = segments[nextIdx].Attachment
            beam.Texture = Assets.GlowBeam
            beam.TextureMode = Enum.TextureMode.Wrap
            beam.TextureLength = 2.5
            beam.TextureSpeed = 2.0 * direction
            beam.LightEmission = 1
            beam.LightInfluence = 0
            beam.Brightness = 4.0 - layerFraction * 1.5
            beam.Color = GoldenColorSequence
            beam.FaceCamera = true
            beam.Segments = 8
            beam.Width0 = 0
            beam.Width1 = 0
            beam.Transparency = NumberSequence.new(0.15 + layerFraction * 0.45)
            beam.Parent = segments[segIdx].Part
            table.insert(ringBeams, beam)
        end

        table.insert(State.RingsData.Layers, {
            LayerIndex = layerIdx,
            Fraction = layerFraction,
            BaseRadius = baseRadius,
            Direction = direction,
            AngularSpeed = angularSpeed,
            CurrentAngle = layerIdx * 0.9,
            Color = ringColor,
            TorusPart = torusPart,
            TorusMesh = torusMesh,
            Segments = segments,
            Beams = ringBeams
        })
    end

    -- 28 Fragmentos Incandescentes que se desprendem da borda do anel de energia
    for fragIdx = 1, 28 do
        local fragPart = CreateVFXPart(
            "DetachingRingFragment_" .. fragIdx,
            Enum.PartType.Block,
            Vector3.new(0.45, 0.22, 1.1),
            (fragIdx % 3 == 0) and Config.SolarWhite or Config.BrightGold,
            Enum.Material.Neon,
            1,
            ringsFolder
        )
        local fragMesh = AddMesh(fragPart, Enum.MeshType.Sphere, Vector3.new(1, 1, 1))
        local tr = CreateEnergyTrail(fragPart, 0.5, 0.0, 0.40, 0.2, GoldenColorSequence)

        table.insert(State.RingsData.DetachingFragments, {
            Part = fragPart,
            Mesh = fragMesh,
            Trail = tr.Trail,
            StartRadius = Lerp(Config.AccretionInnerRadius * 1.1, Config.AccretionOuterRadius * 0.9, (fragIdx % 10) / 10),
            DriftSpeed = 4.5 + (fragIdx % 6) * 1.4,
            AngularSpeed = (1.6 + (fragIdx % 5) * 0.45) * ((fragIdx % 2 == 0) and 1 or -1),
            CycleTime = (fragIdx / 28) * 3.5,
            CycleDuration = 2.4 + (fragIdx % 4) * 0.65,
            VerticalDrift = ((fragIdx % 2 == 0) and 1 or -1) * (0.4 + (fragIdx % 5) * 0.35),
            PhaseOffset = fragIdx * 1.37
        })
    end

    return State.RingsData
end

-- ================================================================================
-- 6. CREATE GOLDEN ARC (16 ARCOS DOURADOS 3D COM BEAMS E PONTOS DE CONTROLE)
-- ================================================================================
local function CreateGoldenArc(arcIndex, totalArcs)
    local arcsFolder = VFXFolder:FindFirstChild("GoldenEnergyArcs")
    if not arcsFolder then
        arcsFolder = Instance.new("Folder")
        arcsFolder.Name = "GoldenEnergyArcs"
        arcsFolder.Parent = VFXFolder
    end

    -- Cada arco possui 7 pontos de controle (Attachments) formando uma trajetória curva tridimensional
    -- que passa pela frente, por trás, por cima ou por baixo do núcleo escuro
    local controlPointCount = 7
    local nodes = {}
    local beams = {}

    local seed = arcIndex * 13.37
    local baseElevation = Lerp(-math.rad(78), math.rad(78), ((arcIndex - 1) / (totalArcs - 1)))
    local baseTilt = math.rad((arcIndex % 5 - 2) * 28)
    local baseRadius = Config.CoreRadius * (1.28 + (arcIndex % 6) * 0.42)
    local arcSpan = math.rad(135 + (arcIndex % 5) * 22) -- Comprimento angular individual
    local heightStretch = 0.85 + (arcIndex % 4) * 0.38
    local orbitSpeed = (0.55 + (arcIndex % 5) * 0.32) * ((arcIndex % 2 == 0) and 1 or -1)
    local pulseSpeed = 2.2 + (arcIndex % 4) * 0.85
    local maxThickness = 0.55 + (arcIndex % 4) * 0.35

    for pt = 1, controlPointCount do
        local nodePart = CreateVFXPart(
            string.format("Arc%d_Node%d", arcIndex, pt),
            Enum.PartType.Ball,
            Vector3.new(0.25, 0.25, 0.25),
            Config.BrightGold,
            Enum.Material.Neon,
            1,
            arcsFolder
        )
        local att = Instance.new("Attachment")
        att.Name = "ArcControlAtt"
        att.Parent = nodePart

        table.insert(nodes, {
            Part = nodePart,
            Attachment = att,
            Alpha = (pt - 1) / (controlPointCount - 1) -- De 0.0 a 1.0 ao longo do arco
        })
    end

    -- Cria os Beams encadeados entre os 7 pontos de controle para uma curvatura suave perfeita
    for pt = 1, controlPointCount - 1 do
        local segAlpha0 = (pt - 1) / (controlPointCount - 1)
        local segAlpha1 = pt / (controlPointCount - 1)
        -- Perfil de espessura fusiforme (fino nas pontas, intenso no centro do arco)
        local env0 = math.sin(segAlpha0 * math.pi)
        local env1 = math.sin(segAlpha1 * math.pi)

        local beam = Instance.new("Beam")
        beam.Name = string.format("GoldenArcBeam_%d_%d", arcIndex, pt)
        beam.Attachment0 = nodes[pt].Attachment
        beam.Attachment1 = nodes[pt + 1].Attachment
        beam.Texture = Assets.GlowBeam
        beam.TextureMode = Enum.TextureMode.Stretch
        beam.TextureSpeed = 1.8 * ((arcIndex % 2 == 0) and 1 or -1)
        beam.LightEmission = 1
        beam.LightInfluence = 0
        beam.Brightness = 4.5
        beam.Color = GoldenColorSequence
        beam.FaceCamera = true
        beam.Segments = 12
        beam.CurveSize0 = 1.8
        beam.CurveSize1 = 1.8
        beam.Parent = nodes[pt].Part

        table.insert(beams, {
            Beam = beam,
            Env0 = env0,
            Env1 = env1
        })
    end

    -- Partícula Viajante de Plasma que percorre o arco deixando um rastro dourado
    local travelerPart = CreateVFXPart(
        "ArcTravelerParticle_" .. arcIndex,
        Enum.PartType.Ball,
        Vector3.new(0.42, 0.42, 0.42),
        Config.SolarWhite,
        Enum.Material.Neon,
        1,
        arcsFolder
    )
    local travelerMesh = AddMesh(travelerPart, Enum.MeshType.Sphere, Vector3.new(1, 1, 1))
    local travelerTrail = CreateEnergyTrail(travelerPart, 0.48, 0.0, 0.32, 0.2, CoreHaloColorSequence)

    local arcRecord = {
        Index = arcIndex,
        Nodes = nodes,
        Beams = beams,
        TravelerPart = travelerPart,
        TravelerMesh = travelerMesh,
        TravelerTrail = travelerTrail.Trail,
        TravelProgress = (arcIndex / totalArcs),
        TravelSpeed = 0.65 + (arcIndex % 5) * 0.22,
        BaseRadius = baseRadius,
        ArcSpan = arcSpan,
        HeightStretch = heightStretch,
        Elevation = baseElevation,
        Tilt = baseTilt,
        Azimuth = (arcIndex / totalArcs) * math.pi * 2,
        OrbitSpeed = orbitSpeed,
        PulseSpeed = pulseSpeed,
        MaxThickness = maxThickness,
        Seed = seed
    }

    table.insert(State.ArcsData, arcRecord)
    return arcRecord
end

-- ================================================================================
-- 7. CREATE VERTICAL BEAM (FEIXE POLAR RELATIVÍSTICO VERTICAL COMPLETO)
-- ================================================================================
local function CreateVerticalBeam()
    local beamFolder = Instance.new("Folder")
    beamFolder.Name = "VerticalRelativisticBeam"
    beamFolder.Parent = VFXFolder

    -- 1. Núcleo Central Branco-Dourado Intenso (Cilindro fino vertical)
    local innerCorePillar = CreateVFXPart("BeamInnerCore", Enum.PartType.Cylinder, Vector3.new(1, 1, 1), Config.SolarWhite, Enum.Material.Neon, 1, beamFolder)
    local innerCoreMesh = AddMesh(innerCorePillar, Enum.MeshType.Cylinder, Vector3.new(1, 1, 1))

    -- 2. Camada Externa Dourada Pulsante
    local outerGoldShroud = CreateVFXPart("BeamOuterShroud", Enum.PartType.Cylinder, Vector3.new(1, 1, 1), Config.ImperialGold, Enum.Material.Neon, 1, beamFolder)
    local outerGoldMesh = AddMesh(outerGoldShroud, Enum.MeshType.Cylinder, Vector3.new(1, 1, 1))

    -- 3. Flare de Ignição Polar Superior e Inferior (Brilho na saída dos polos do buraco negro)
    local topPolarFlare = CreateVFXPart("TopPolarFlare", Enum.PartType.Ball, Vector3.new(1, 1, 1), Config.SolarWhite, Enum.Material.Neon, 1, beamFolder)
    local topFlareMesh = AddMesh(topPolarFlare, Enum.MeshType.Sphere, Vector3.new(1, 1, 1))

    local bottomPolarFlare = CreateVFXPart("BottomPolarFlare", Enum.PartType.Ball, Vector3.new(1, 1, 1), Config.SolarWhite, Enum.Material.Neon, 1, beamFolder)
    local bottomFlareMesh = AddMesh(bottomPolarFlare, Enum.MeshType.Sphere, Vector3.new(1, 1, 1))

    -- 4. Feixes Secundários (6 Filamentos Helicoidais / Secundários envolvendo o pilar vertical)
    local secondaryFilaments = {}
    for i = 1, 6 do
        local botNode = CreateVFXPart("SecBeamBot_" .. i, Enum.PartType.Ball, Vector3.new(0.2, 0.2, 0.2), Config.BrightGold, Enum.Material.Neon, 1, beamFolder)
        local topNode = CreateVFXPart("SecBeamTop_" .. i, Enum.PartType.Ball, Vector3.new(0.2, 0.2, 0.2), Config.BrightGold, Enum.Material.Neon, 1, beamFolder)

        local att0 = Instance.new("Attachment", botNode)
        local att1 = Instance.new("Attachment", topNode)

        local secBeam = Instance.new("Beam")
        secBeam.Name = "SecondaryVerticalBeam_" .. i
        secBeam.Attachment0 = att0
        secBeam.Attachment1 = att1
        secBeam.Texture = Assets.GlowBeam
        secBeam.TextureMode = Enum.TextureMode.Wrap
        secBeam.TextureLength = 4
        secBeam.TextureSpeed = (i % 2 == 0) and 3.5 or -3.5
        secBeam.LightEmission = 1
        secBeam.LightInfluence = 0
        secBeam.Brightness = 4.0
        secBeam.Color = GoldenColorSequence
        secBeam.FaceCamera = true
        secBeam.Segments = 16
        secBeam.Width0 = 0
        secBeam.Width1 = 0
        secBeam.Parent = botNode

        table.insert(secondaryFilaments, {
            BotNode = botNode,
            TopNode = topNode,
            Beam = secBeam,
            AngleOffset = (i / 6) * math.pi * 2,
            RadiusOffset = 0.8 + (i % 3) * 0.65,
            TwistFactor = ((i % 2 == 0) and 1 or -1) * 1.4
        })
    end

    -- 5. Partículas Ascendentes e Fragmentos Descendentes ao longo do Feixe Vertical
    local verticalParticles = {}
    for i = 1, 20 do
        local isAscending = (i <= 12)
        local vpPart = CreateVFXPart(
            (isAscending and "AscendingBeamSpark_" or "DescendingBeamShard_") .. i,
            Enum.PartType.Ball,
            Vector3.new(0.4, 1.4, 0.4),
            isAscending and Config.SolarWhite or Config.ImperialGold,
            Enum.Material.Neon,
            1,
            beamFolder
        )
        local vpMesh = AddMesh(vpPart, Enum.MeshType.Sphere, Vector3.new(1, 1, 1))
        local vpTrail = CreateEnergyTrail(vpPart, 0.4, 0.0, 0.25, 0.3, GoldenColorSequence)

        table.insert(verticalParticles, {
            Part = vpPart,
            Mesh = vpMesh,
            Trail = vpTrail.Trail,
            Ascending = isAscending,
            Progress = (i / 20),
            Speed = (isAscending and 1 or -1) * (0.55 + (i % 5) * 0.18),
            SpiralRadius = 0.35 + (i % 4) * 0.45,
            SpiralSpeed = (3.5 + (i % 3) * 1.2) * (isAscending and 1 or -1),
            Phase = i * 0.9
        })
    end

    State.BeamData = {
        Folder = beamFolder,
        InnerPillar = innerCorePillar,
        InnerMesh = innerCoreMesh,
        OuterShroud = outerGoldShroud,
        OuterMesh = outerGoldMesh,
        TopFlare = topPolarFlare,
        TopFlareMesh = topFlareMesh,
        BottomFlare = bottomPolarFlare,
        BottomFlareMesh = bottomFlareMesh,
        SecondaryFilaments = secondaryFilaments,
        VerticalParticles = verticalParticles
    }

    return State.BeamData
end

-- ================================================================================
-- 8. CREATE GROUND WAVE (ONDAS DE ENERGIA EXPANSIVAS NO CHÃO + FRAGMENTOS)
-- ================================================================================
local function CreateGroundWave(originPosition, intensityMultiplier)
    local wavesFolder = VFXFolder:FindFirstChild("GroundShockwaves")
    if not wavesFolder then
        wavesFolder = Instance.new("Folder")
        wavesFolder.Name = "GroundShockwaves"
        wavesFolder.Parent = VFXFolder
    end

    local intensity = intensityMultiplier or 1.0

    -- Camada 1: Onda Principal Dourada Brilhante
    local outerWavePart = CreateVFXPart("GroundWaveOuter", Enum.PartType.Block, Vector3.new(1, 1, 1), Config.BrightGold, Enum.Material.Neon, 0.15, wavesFolder)
    local outerWaveMesh = AddMesh(outerWavePart, Enum.MeshType.FileMesh, Vector3.new(1, 1, 1), Assets.RingMesh)

    -- Camada 2: Sub-Onda Interna Branca-Dourada
    local innerWavePart = CreateVFXPart("GroundWaveInner", Enum.PartType.Block, Vector3.new(1, 1, 1), Config.SolarWhite, Enum.Material.Neon, 0.1, wavesFolder)
    local innerWaveMesh = AddMesh(innerWavePart, Enum.MeshType.FileMesh, Vector3.new(1, 1, 1), Assets.RingMesh)

    -- Camada 3: Disco de Reflexo Dourado Rasante no Chão (Fiel ao brilho intenso no chão da imagem!)
    local groundGlowDisc = CreateVFXPart("GroundReflectionDisc", Enum.PartType.Cylinder, Vector3.new(0.1, 1, 1), Config.ImperialGold, Enum.Material.Neon, 0.45, wavesFolder)
    local discMesh = AddMesh(groundGlowDisc, Enum.MeshType.Cylinder, Vector3.new(1, 1, 1))

    -- 8 Fragmentos de Energia que saltam radialmente junto com a onda no solo
    local waveShards = {}
    for i = 1, 8 do
        local shard = CreateVFXPart("GroundWaveShard_" .. i, Enum.PartType.Block, Vector3.new(0.35, 0.35, 0.9), Config.SolarWhite, Enum.Material.Neon, 0.1, wavesFolder)
        local shardMesh = AddMesh(shard, Enum.MeshType.Sphere, Vector3.new(1, 1, 1))
        table.insert(waveShards, {
            Part = shard,
            Mesh = shardMesh,
            Angle = (i / 8) * math.pi * 2 + math.random() * 0.35,
            HeightMod = 0.5 + (i % 3) * 0.45
        })
    end

    local waveRecord = {
        Origin = originPosition,
        Age = 0,
        Lifetime = 2.1,
        MaxRadius = (Config.AccretionOuterRadius * 1.45) * (0.85 + intensity * 0.3),
        Intensity = intensity,
        OuterPart = outerWavePart,
        OuterMesh = outerWaveMesh,
        InnerPart = innerWavePart,
        InnerMesh = innerWaveMesh,
        GlowDisc = groundGlowDisc,
        DiscMesh = discMesh,
        Shards = waveShards
    }

    table.insert(State.WavesData, waveRecord)
    return waveRecord
end

-- ================================================================================
-- 9. CREATE COSMIC PARTICLE (8 TRAJETÓRIAS MATEMÁTICAS INDIVIDUALIZADAS)
-- ================================================================================
local TrajectoryTypes = {
    "SPIRAL",       -- 1. Espirais
    "ARC",          -- 2. Arcos
    "DIAGONAL",     -- 3. Diagonais
    "ASCENDING",    -- 4. Ascendentes
    "DESCENDING",   -- 5. Descendentes
    "ORBITAL",      -- 6. Orbitais
    "RADIAL",       -- 7. Radiais
    "LISSAJOUS"     -- 8. Curvas complexas (3D Lissajous Harmônico)
}

local function CreateCosmicParticle(index)
    local particlesFolder = VFXFolder:FindFirstChild("CosmicParticles")
    if not particlesFolder then
        particlesFolder = Instance.new("Folder")
        particlesFolder.Name = "CosmicParticles"
        particlesFolder.Parent = VFXFolder
    end

    local trajType = TrajectoryTypes[((index - 1) % #TrajectoryTypes) + 1]
    local isBright = (index % 3 == 0)
    local partColor = isBright and Config.SolarWhite or ((index % 2 == 0) and Config.BrightGold or Config.ImperialGold)
    local baseSize = 0.28 + (index % 5) * 0.11

    local pPart = CreateVFXPart(
        string.format("CosmicParticle_%s_%d", trajType, index),
        Enum.PartType.Ball,
        Vector3.new(baseSize, baseSize, baseSize),
        partColor,
        Enum.Material.Neon,
        1,
        particlesFolder
    )
    local pMesh = AddMesh(pPart, Enum.MeshType.Sphere, Vector3.new(1, 1, 1))

    -- Todas as partículas possuem rastros detalhados individuais
    local trailRecord = CreateEnergyTrail(pPart, baseSize * 1.15, 0.0, 0.32 + (index % 4) * 0.08, baseSize * 0.45, GoldenColorSequence)

    local particleRecord = {
        Index = index,
        Behavior = trajType,
        Part = pPart,
        Mesh = pMesh,
        Trail = trailRecord.Trail,
        BaseSize = baseSize,
        Phase = (index / Config.CosmicParticleCount) * math.pi * 2,
        Timer = (index * 0.17) % 1.0,
        Speed = 0.45 + (index % 7) * 0.14,
        Radius = Config.CoreRadius * (1.5 + (index % 9) * 0.62),
        Height = 4.0 + (index % 8) * 2.5,
        Inclination = math.rad((index * 29) % 160 - 80),
        Azimuth = math.rad((index * 53) % 360),
        FreqA = 1 + (index % 3),
        FreqB = 2 + (index % 4),
        FreqC = 3 + (index % 2)
    }

    table.insert(State.ParticlesData, particleRecord)
    return particleRecord
end

-- ================================================================================
-- 10. SISTEMA DE POSICIONAMENTO FRONTAL (UPDATEFRONTPOSITION & MOVESINGULARITYINFRONT)
-- ================================================================================
local function GetCharacterRootPart()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

-- Detecta a altura exata do chão abaixo da singularidade para alinhar as ondas terrestres
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function ComputeTargetFrontCFrame()
    local hrp = GetCharacterRootPart()
    if not hrp then
        return State.CurrentCFrame
    end

    -- Utiliza exclusivamente a posição e direção frontal do HumanoidRootPart (NUNCA a câmera!)
    local hrpPosition = hrp.Position
    local rawLookVector = hrp.CFrame.LookVector

    -- Projeta a direção frontal no plano horizontal para manter a singularidade nivelada e estável
    local flatForward = Vector3.new(rawLookVector.X, 0, rawLookVector.Z)
    if flatForward.Magnitude < 0.001 then
        flatForward = Vector3.new(0, 0, -1)
    else
        flatForward = flatForward.Unit
    end

    local upVector = Vector3.new(0, 1, 0)
    local rightVector = flatForward:Cross(upVector).Unit

    -- Posição frontal calculada com FrontDistance, VerticalOffset e PositionOffset
    local targetPosition = hrpPosition
        + (flatForward * Config.FrontDistance)
        + (upVector * Config.VerticalOffset)
        + (rightVector * Config.PositionOffset.X)
        + (upVector * Config.PositionOffset.Y)
        + (flatForward * Config.PositionOffset.Z)

    -- A orientação acompanha a direção para onde o personagem está olhando + RotationOffset
    local baseCFrame = CFrame.lookAt(targetPosition, targetPosition + flatForward, upVector)
    return baseCFrame * Config.RotationOffset
end

-- Reposicionamento imediato ou suave acionado pelo BOTÃO 2 ("COLOCAR À FRENTE")
local function MoveSingularityInFront(instantSnap)
    local hrp = GetCharacterRootPart()
    if not hrp then return end

    State.FollowCharacter = true
    local computedCF = ComputeTargetFrontCFrame()
    State.TargetCFrame = computedCF

    if instantSnap then
        State.CurrentCFrame = computedCF
    else
        -- Impulso cinemático suave para reposicionar prontamente na frente do personagem
        State.CurrentCFrame = State.CurrentCFrame:Lerp(computedCF, 0.38)
    end

    -- Pulso visual e emissão de onda de choque no chão ao reposicionar
    State.RepositionPulse = 1.0
    if State.Active then
        local groundPos = Vector3.new(computedCF.Position.X, computedCF.Position.Y + State.GroundYOffset, computedCF.Position.Z)
        CreateGroundWave(groundPos, 1.35)
    end
end

-- Atualização centralizada da posição frontal a cada frame
local function UpdateFrontPosition(dt)
    local hrp = GetCharacterRootPart()
    if hrp and State.FollowCharacter then
        State.TargetCFrame = ComputeTargetFrontCFrame()
    end

    -- Interpolação exponencial suave (sem movimentos bruscos e independente de FPS)
    local alpha = 1 - math.exp(-Config.FollowSpeed * dt)
    State.CurrentCFrame = State.CurrentCFrame:Lerp(State.TargetCFrame, Clamp(alpha, 0, 1))

    -- Raycast vertical para encontrar a superfície do chão sob a singularidade
    local char = LocalPlayer.Character
    if char then
        raycastParams.FilterDescendantsInstances = { VFXFolder, char }
    else
        raycastParams.FilterDescendantsInstances = { VFXFolder }
    end

    local origin = State.CurrentCFrame.Position
    local rayResult = Workspace:Raycast(origin, Vector3.new(0, -60, 0), raycastParams)
    if rayResult then
        State.GroundYOffset = (rayResult.Position.Y - origin.Y) + 0.15
    else
        State.GroundYOffset = -Config.VerticalOffset - 2.8
    end

    if State.RepositionPulse > 0 then
        State.RepositionPulse = math.max(0, State.RepositionPulse - dt * 2.5)
    end
end

-- ================================================================================
-- 11. UPDATE SINGULARITY (CONTROLADOR CENTRAL MATEMÁTICO E SINCRONIA DE 8 FASES)
-- ================================================================================
local function UpdateSingularity(dt)
    if not State.Active and State.Phase == Phases.IDLE then
        return
    end

    State.TotalTime = State.TotalTime + dt
    State.PhaseTime = State.PhaseTime + dt
    local t = State.TotalTime

    -- 1. Atualização da Posição Frontal do Personagem
    UpdateFrontPosition(dt)
    local centerCF = State.CurrentCFrame
    local centerPos = centerCF.Position
    local groundCenterPos = Vector3.new(centerPos.X, centerPos.Y + State.GroundYOffset, centerPos.Z)

    -- 2. Máquina de Estados Sincronizada (8 Fases da Animação)
    if State.Phase ~= Phases.DISSIPATION then
        if t < 0.75 then
            State.Phase = Phases.CORE_FORMATION
        elseif t < 1.55 then
            State.Phase = Phases.ENERGY_CONDENSATION
        elseif t < 2.50 then
            State.Phase = Phases.RING_FORMATION
        elseif t < 3.45 then
            State.Phase = Phases.ARC_EMERGENCE
        elseif t < 4.30 then
            State.Phase = Phases.BEAM_ACTIVATION
        elseif t < 5.30 then
            State.Phase = Phases.INTENSIFICATION
        else
            State.Phase = Phases.MAXIMUM_STATE
        end

        State.CoreFactor      = SmoothStep(0.0, 0.85, t)
        State.CondenseFactor  = SmoothStep(0.65, 1.65, t)
        State.RingFactor      = SmoothStep(1.40, 2.65, t)
        State.ArcFactor       = SmoothStep(2.35, 3.60, t)
        State.BeamFactor      = SmoothStep(3.30, 4.40, t)
        State.OverdriveFactor = SmoothStep(4.25, 5.35, t)
        State.MasterScale     = State.CoreFactor + (State.RepositionPulse * 0.14)
    else
        -- Fase 8: Dissipação Quântica Suave
        local dissipateProgress = Clamp(State.PhaseTime / 1.35, 0, 1)
        local inv = 1 - SmoothStep(0.0, 1.0, dissipateProgress)
        State.CoreFactor      = inv
        State.CondenseFactor  = inv
        State.RingFactor      = inv
        State.ArcFactor       = inv
        State.BeamFactor      = inv
        State.OverdriveFactor = inv
        State.MasterScale     = inv

        if dissipateProgress >= 1.0 then
            State.Active = false
            State.Phase = Phases.IDLE
            if State.UI.UpdateStatusUI then
                State.UI.UpdateStatusUI()
            end
            -- Oculta todas as partes ao finalizar a dissipação
            for _, desc in ipairs(VFXFolder:GetDescendants()) do
                if desc:IsA("BasePart") then
                    desc.Transparency = 1
                elseif desc:IsA("Beam") or desc:IsA("Trail") then
                    desc.Enabled = false
                elseif desc:IsA("PointLight") then
                    desc.Brightness = 0
                end
            end
            return
        end
    end

    if State.UI.UpdatePhaseLabel then
        State.UI.UpdatePhaseLabel(PhaseNames[State.Phase] or "ATIVO")
    end

    local pulseHarmonic = 1 + math.sin(t * 4.2) * 0.055 + math.cos(t * 9.7) * 0.025 + State.RepositionPulse * 0.18
    local overdriveBoost = 1 + State.OverdriveFactor * 0.25

    -- ============================================================================
    -- A. ATUALIZAÇÃO DO NÚCLEO E LENTE GRAVITACIONAL
    -- ============================================================================
    local core = State.CoreData
    if core then
        core.RootAnchor.CFrame = centerCF
        core.Light.Brightness = (3.5 + State.OverdriveFactor * 3.5 + math.sin(t * 7) * 0.6) * State.CoreFactor
        core.Light.Range = (42 + State.OverdriveFactor * 28) * State.CoreFactor

        local coreDiam = (Config.CoreRadius * 2) * State.CoreFactor * pulseHarmonic
        local oscOffset = Vector3.new(
            math.sin(t * 3.1) * 0.12,
            math.cos(t * 2.7) * 0.16,
            math.sin(t * 3.7) * 0.12
        )
        local coreCenterCF = centerCF * CFrame.new(oscOffset)

        core.VoidSphere.CFrame = coreCenterCF
        core.VoidSphere.Transparency = 1 - State.CoreFactor
        core.VoidMesh.Scale = Vector3.new(coreDiam, coreDiam, coreDiam)

        core.InnerAbyss.CFrame = coreCenterCF
        core.InnerAbyss.Transparency = 1 - (State.CoreFactor * 0.96)
        core.InnerAbyssMesh.Scale = Vector3.new(coreDiam * 0.96, coreDiam * 0.96, coreDiam * 0.96)

        -- Camadas Concêntricas da Esfera de Fótons
        for _, shell in ipairs(core.ConcentricShells) do
            local shellPulse = 1 + math.sin(t * 5.5 + shell.PhaseOffset) * 0.06
            local sScale = coreDiam * shell.BaseScale * shellPulse * overdriveBoost
            shell.Part.CFrame = coreCenterCF * CFrame.fromAxisAngle(shell.Axis, t * shell.Speed)
            shell.Mesh.Scale = Vector3.new(sScale, sScale * 0.96, sScale)
            shell.Part.Transparency = Lerp(1, shell.BaseTrans, State.CoreFactor)
        end

        -- Anéis de Lente Gravitacional (Curvatura da luz superior e inferior fiel à imagem)
        for idx, lens in ipairs(core.LensingRings) do
            local lensPulse = 1 + math.sin(t * 4.8 + lens.PulseOffset) * 0.07
            local rSize = (Config.CoreRadius * 2.15) * lens.RadiusFactor * State.CoreFactor * lensPulse * overdriveBoost
            local zThick = rSize * lens.ThicknessFactor
            local wobbleX = math.sin(t * 1.9 + idx) * math.rad(4)
            local wobbleZ = math.cos(t * 2.3 + idx) * math.rad(4)

            lens.Part.CFrame = coreCenterCF * CFrame.Angles(lens.TiltX + wobbleX, t * (idx % 2 == 0 and 0.45 or -0.45), lens.TiltZ + wobbleZ)
            lens.Mesh.Scale = Vector3.new(rSize, rSize, zThick)
            lens.Part.Transparency = Lerp(1, lens.BaseTrans, State.CoreFactor * (0.65 + State.CondenseFactor * 0.35))
        end

        -- Partículas Orbitais do Núcleo
        for _, orb in ipairs(core.Orbiters) do
            orb.Trail.Enabled = (State.CondenseFactor > 0.08)
            local angle = t * orb.Speed + orb.Phase
            local r = orb.OrbitRadius * State.CondenseFactor * (1 + orb.Eccentricity * math.sin(angle * 2))
            local localPos = Vector3.new(
                r * math.cos(angle),
                r * math.sin(angle) * math.sin(orb.Inclination),
                r * math.sin(angle) * math.cos(orb.Inclination)
            )
            local worldPos = (coreCenterCF * CFrame.Angles(0, orb.Azimuth, 0)):PointToWorldSpace(localPos)
            orb.Part.CFrame = CFrame.new(worldPos)
            orb.Part.Transparency = 1 - State.CondenseFactor
            local oScale = (0.8 + math.sin(t * 8 + orb.Phase) * 0.3) * State.CondenseFactor
            orb.Mesh.Scale = Vector3.new(oScale, oScale, oScale)
        end
    end

    -- ============================================================================
    -- B. ATUALIZAÇÃO DO ANEL DE ENERGIA (DISCO DE ACREÇÃO MULTI-CAMADAS)
    -- ============================================================================
    if State.RingsData and State.RingsData.Layers then
        for _, layer in ipairs(State.RingsData.Layers) do
            layer.CurrentAngle = layer.CurrentAngle + layer.AngularSpeed * dt * (1 + State.OverdriveFactor * 0.45)

            -- Expansão e contração respiratória da camada
            local breath = 1 + math.sin(t * 2.6 - layer.LayerIndex * 0.65) * 0.065
            local currentRadius = layer.BaseRadius * State.RingFactor * breath * overdriveBoost

            -- Inclinação sutil de ondulação do disco
            local discTiltX = math.sin(t * 1.4 + layer.LayerIndex) * math.rad(2.2)
            local discTiltZ = math.cos(t * 1.7 + layer.LayerIndex) * math.rad(2.2)
            local layerCenterCF = centerCF * CFrame.Angles(discTiltX, layer.CurrentAngle, discTiltZ)

            -- Atualiza o Torus base da camada
            layer.TorusPart.CFrame = layerCenterCF * CFrame.Angles(math.rad(90), 0, 0)
            local torusScale = currentRadius * 2.02
            local torusThick = (1.5 + math.sin(t * 5 + layer.LayerIndex) * 0.45) * (1 - layer.Fraction * 0.35) * State.RingFactor
            layer.TorusMesh.Scale = Vector3.new(torusScale, torusScale, torusThick)
            layer.TorusPart.Transparency = Lerp(1, 0.25 + layer.Fraction * 0.45, State.RingFactor)

            -- Atualiza cada Segmento individual do Anel
            for segIdx, seg in ipairs(layer.Segments) do
                local totalAngle = seg.AngleOffset
                local waveY = math.sin(t * 3.8 + totalAngle * seg.WaveFrequency + layer.LayerIndex) * seg.WaveAmplitude * State.RingFactor
                local radialMod = currentRadius + math.cos(t * 4.2 + segIdx) * (0.45 * State.RingFactor)

                local localSegPos = Vector3.new(
                    math.cos(totalAngle) * radialMod,
                    waveY,
                    math.sin(totalAngle) * radialMod
                )
                local tangentDir = Vector3.new(-math.sin(totalAngle) * layer.Direction, 0, math.cos(totalAngle) * layer.Direction)

                local worldSegPos = layerCenterCF:PointToWorldSpace(localSegPos)
                local worldTangent = layerCenterCF:VectorToWorldSpace(tangentDir)

                seg.Part.CFrame = CFrame.lookAt(worldSegPos, worldSegPos + worldTangent)
                local segWidth = (0.35 + math.sin(t * 6 + seg.ThicknessSeed) * 0.15) * (1.2 - layer.Fraction * 0.5) * State.RingFactor
                local segLen = ((2 * math.pi * radialMod) / #layer.Segments) * 0.85
                seg.Mesh.Scale = Vector3.new(segWidth, segWidth * 0.55, segLen)
                seg.Part.Transparency = Lerp(1, 0.12 + layer.Fraction * 0.5, State.RingFactor)

                if seg.Trail then
                    seg.Trail.Enabled = (State.RingFactor > 0.15)
                end

                local beam = layer.Beams[segIdx]
                if beam then
                    beam.Enabled = (State.RingFactor > 0.08)
                    local bWidth = (0.85 + math.sin(t * 5.2 + segIdx) * 0.3) * (1.3 - layer.Fraction * 0.55) * State.RingFactor * overdriveBoost
                    beam.Width0 = bWidth
                    beam.Width1 = bWidth
                end
            end
        end

        -- Fragmentos que se desprendem do anel
        for _, frag in ipairs(State.RingsData.DetachingFragments) do
            frag.CycleTime = (frag.CycleTime + dt) % frag.CycleDuration
            local progress = frag.CycleTime / frag.CycleDuration -- 0 a 1
            local fade = math.sin(progress * math.pi) * State.RingFactor

            local r = (frag.StartRadius + progress * frag.DriftSpeed * 2.8) * State.RingFactor
            local angle = t * frag.AngularSpeed + frag.PhaseOffset
            local y = (progress * frag.VerticalDrift * 3.2) + math.sin(t * 4 + frag.PhaseOffset) * 0.4

            local worldPos = centerCF:PointToWorldSpace(Vector3.new(math.cos(angle) * r, y, math.sin(angle) * r))
            frag.Part.CFrame = CFrame.new(worldPos) * CFrame.Angles(t * 3, angle, t * 2)
            frag.Part.Transparency = 1 - (fade * 0.9)
            local fScale = fade * (0.7 + State.OverdriveFactor * 0.4)
            frag.Mesh.Scale = Vector3.new(fScale, fScale, fScale * 1.8)
            frag.Trail.Enabled = (fade > 0.15)
        end
    end

    -- ============================================================================
    -- C. ATUALIZAÇÃO DOS 16 ARCOS DOURADOS TRIDIMENSIONAIS
    -- ============================================================================
    for _, arc in ipairs(State.ArcsData) do
        arc.Azimuth = arc.Azimuth + arc.OrbitSpeed * dt * (1 + State.OverdriveFactor * 0.4)
        local arcPulse = 0.75 + 0.25 * math.sin(t * arc.PulseSpeed + arc.Seed)
        local arcRadius = arc.BaseRadius * State.ArcFactor * (1 + math.sin(t * 2.1 + arc.Index) * 0.08) * overdriveBoost

        local arcOrientation = centerCF
            * CFrame.Angles(0, arc.Azimuth, 0)
            * CFrame.Angles(arc.Elevation + math.sin(t * 1.3 + arc.Index) * 0.15, 0, arc.Tilt + math.cos(t * 1.1 + arc.Index) * 0.15)

        -- Posiciona os 7 pontos de controle ao longo da trajetória 3D passando pela frente e trás do núcleo
        for _, node in ipairs(arc.Nodes) do
            local theta = (node.Alpha - 0.5) * arc.ArcSpan
            local ripple = math.sin(theta * 4 + t * 5.5 + arc.Seed) * 0.38 * math.sin(node.Alpha * math.pi)
            local r = arcRadius + ripple

            local localPos = Vector3.new(
                r * math.sin(theta),
                r * math.cos(theta) * arc.HeightStretch - (arcRadius * 0.32),
                math.sin(theta * 2 + arc.Seed) * (arcRadius * 0.35)
            )
            node.Part.CFrame = arcOrientation * CFrame.new(localPos)
        end

        -- Atualiza a espessura e intensidade variável dos Beams do arco
        for _, bData in ipairs(arc.Beams) do
            bData.Beam.Enabled = (State.ArcFactor > 0.05)
            local wFactor = arc.MaxThickness * arcPulse * State.ArcFactor * overdriveBoost
            bData.Beam.Width0 = bData.Env0 * wFactor
            bData.Beam.Width1 = bData.Env1 * wFactor
            bData.Beam.Brightness = 3.5 + arcPulse * 2.5 + State.OverdriveFactor * 2.0
        end

        -- Atualiza a partícula que acompanha e viaja pelo arco
        arc.TravelProgress = (arc.TravelProgress + dt * arc.TravelSpeed) % 1.0
        local tTheta = (arc.TravelProgress - 0.5) * arc.ArcSpan
        local tRipple = math.sin(tTheta * 4 + t * 5.5 + arc.Seed) * 0.38 * math.sin(arc.TravelProgress * math.pi)
        local tr = arcRadius + tRipple
        local travelerLocal = Vector3.new(
            tr * math.sin(tTheta),
            tr * math.cos(tTheta) * arc.HeightStretch - (arcRadius * 0.32),
            math.sin(tTheta * 2 + arc.Seed) * (arcRadius * 0.35)
        )
        arc.TravelerPart.CFrame = arcOrientation * CFrame.new(travelerLocal)
        local envTraveler = math.sin(arc.TravelProgress * math.pi) * State.ArcFactor
        arc.TravelerPart.Transparency = 1 - envTraveler
        arc.TravelerMesh.Scale = Vector3.new(envTraveler * 1.3, envTraveler * 1.3, envTraveler * 1.3)
        arc.TravelerTrail.Enabled = (envTraveler > 0.15)
    end

    -- ============================================================================
    -- D. ATUALIZAÇÃO DO FEIXE VERTICAL (PILAR POLAR E FEIXES SECUNDÁRIOS)
    -- ============================================================================
    local beamData = State.BeamData
    if beamData then
        local bFactor = State.BeamFactor
        local bHeight = Config.BeamHeight * bFactor * overdriveBoost
        local bPulse = 1 + math.sin(t * 11.5) * 0.14 + math.cos(t * 19.0) * 0.08
        local swayX = math.sin(t * 2.4) * math.rad(1.2)
        local swayZ = math.cos(t * 2.8) * math.rad(1.2)

        local beamCenterCF = centerCF * CFrame.Angles(swayX, 0, swayZ)
        -- Cilindros no Roblox têm o eixo de comprimento no eixo X local; rotacionamos 90 graus em Z para ficar vertical
        local cylCF = beamCenterCF * CFrame.Angles(0, 0, math.rad(90))

        local innerThick = (0.85 * bPulse * bFactor * overdriveBoost)
        beamData.InnerPillar.CFrame = cylCF
        beamData.InnerMesh.Scale = Vector3.new(bHeight, innerThick, innerThick)
        beamData.InnerPillar.Transparency = Lerp(1, 0.02, bFactor)

        local outerThick = (2.35 * bPulse * bFactor * overdriveBoost)
        beamData.OuterShroud.CFrame = cylCF
        beamData.OuterMesh.Scale = Vector3.new(bHeight * 0.98, outerThick, outerThick)
        beamData.OuterShroud.Transparency = Lerp(1, 0.42, bFactor)

        -- Flares Polares (Acima e abaixo do núcleo onde o jato emerge)
        local polarDist = Config.CoreRadius * 1.05 * State.CoreFactor
        local flareSize = (2.6 * bPulse * bFactor * overdriveBoost)
        beamData.TopFlare.CFrame = beamCenterCF * CFrame.new(0, polarDist, 0)
        beamData.TopFlareMesh.Scale = Vector3.new(flareSize, flareSize * 1.8, flareSize)
        beamData.TopFlare.Transparency = Lerp(1, 0.08, bFactor)

        beamData.BottomFlare.CFrame = beamCenterCF * CFrame.new(0, -polarDist, 0)
        beamData.BottomFlareMesh.Scale = Vector3.new(flareSize, flareSize * 1.8, flareSize)
        beamData.BottomFlare.Transparency = Lerp(1, 0.08, bFactor)

        -- Feixes Secundários Verticais
        for idx, sec in ipairs(beamData.SecondaryFilaments) do
            local ang = sec.AngleOffset + t * 2.2 * sec.TwistFactor
            local r = sec.RadiusOffset * bFactor * bPulse
            local topAng = ang + sec.TwistFactor * math.pi

            local botPos = beamCenterCF:PointToWorldSpace(Vector3.new(math.cos(ang) * r, -bHeight * 0.45, math.sin(ang) * r))
            local topPos = beamCenterCF:PointToWorldSpace(Vector3.new(math.cos(topAng) * r, bHeight * 0.45, math.sin(topAng) * r))

            sec.BotNode.CFrame = CFrame.new(botPos)
            sec.TopNode.CFrame = CFrame.new(topPos)
            sec.Beam.Enabled = (bFactor > 0.06)
            local secW = (0.45 + (idx % 2) * 0.25) * bFactor * bPulse * overdriveBoost
            sec.Beam.Width0 = secW
            sec.Beam.Width1 = secW * 0.4
        end

        -- Partículas Ascendentes e Fragmentos Descendentes do Feixe Vertical
        for _, vp in ipairs(beamData.VerticalParticles) do
            vp.Progress = (vp.Progress + dt * vp.Speed) % 1.0
            if vp.Progress < 0 then vp.Progress = vp.Progress + 1.0 end

            local ySpan = bHeight * 0.48
            local localY = Lerp(-ySpan, ySpan, vp.Progress)
            local spAngle = t * vp.SpiralSpeed + vp.Phase
            local spRadius = vp.SpiralRadius * bFactor * (1 - math.abs(vp.Progress - 0.5) * 1.2)

            local worldPos = beamCenterCF:PointToWorldSpace(Vector3.new(math.cos(spAngle) * spRadius, localY, math.sin(spAngle) * spRadius))
            vp.Part.CFrame = CFrame.new(worldPos)
            local vpVis = math.sin(vp.Progress * math.pi) * bFactor
            vp.Part.Transparency = 1 - vpVis
            vp.Trail.Enabled = (vpVis > 0.15)
        end
    end

    -- ============================================================================
    -- E. ATUALIZAÇÃO E EMISSÃO CONTÍNUA DAS ONDAS DE ENERGIA NO CHÃO
    -- ============================================================================
    local effectiveWaveInterval = Config.GroundWaveInterval / (1 + State.OverdriveFactor * 0.65)
    if State.RingFactor > 0.25 and State.Phase ~= Phases.DISSIPATION then
        if (t - State.LastWaveClock) >= effectiveWaveInterval then
            State.LastWaveClock = t
            CreateGroundWave(groundCenterPos, 0.8 + State.OverdriveFactor * 0.5)
        end
    end

    for i = #State.WavesData, 1, -1 do
        local wave = State.WavesData[i]
        wave.Age = wave.Age + dt
        local progress = wave.Age / wave.Lifetime

        if progress >= 1.0 then
            wave.OuterPart:Destroy()
            wave.InnerPart:Destroy()
            wave.GlowDisc:Destroy()
            for _, sh in ipairs(wave.Shards) do
                sh.Part:Destroy()
            end
            table.remove(State.WavesData, i)
        else
            -- Acompanha suavemente o X/Z atual da singularidade mantendo expansão radial
            local waveOrigin = Vector3.new(
                Lerp(wave.Origin.X, groundCenterPos.X, 0.15),
                groundCenterPos.Y,
                Lerp(wave.Origin.Z, groundCenterPos.Z, 0.15)
            )
            local easeOut = 1 - (1 - progress) ^ 2.4
            local fadeOut = (1 - progress) ^ 1.6 * State.MasterScale

            local currentRadius = wave.MaxRadius * easeOut
            local ringThickness = (2.4 * (1 - progress * 0.7)) * wave.Intensity

            wave.OuterPart.CFrame = CFrame.new(waveOrigin) * CFrame.Angles(math.rad(90), t * 0.8, 0)
            wave.OuterMesh.Scale = Vector3.new(currentRadius * 2, currentRadius * 2, ringThickness)
            wave.OuterPart.Transparency = Clamp(1 - fadeOut * 0.85, 0, 1)

            local innerR = currentRadius * 0.72
            wave.InnerPart.CFrame = CFrame.new(waveOrigin) * CFrame.Angles(math.rad(90), -t * 1.1, 0)
            wave.InnerMesh.Scale = Vector3.new(innerR * 2, innerR * 2, ringThickness * 0.75)
            wave.InnerPart.Transparency = Clamp(1 - fadeOut * 0.75, 0, 1)

            -- Disco de reflexo luminoso dourado no chão
            local discDiam = currentRadius * 1.65
            wave.GlowDisc.CFrame = CFrame.new(waveOrigin - Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
            wave.DiscMesh.Scale = Vector3.new(0.08, discDiam, discDiam)
            wave.GlowDisc.Transparency = Clamp(1 - fadeOut * 0.32, 0, 1)

            -- Fragmentos acompanhando a frente da onda terrestre
            for _, sh in ipairs(wave.Shards) do
                local shR = currentRadius * 0.5
                local shY = math.sin(progress * math.pi) * (2.2 * sh.HeightMod)
                local shPos = waveOrigin + Vector3.new(math.cos(sh.Angle + progress * 1.2) * shR, shY, math.sin(sh.Angle + progress * 1.2) * shR)
                sh.Part.CFrame = CFrame.new(shPos) * CFrame.Angles(t * 4, sh.Angle, t * 3)
                sh.Part.Transparency = Clamp(1 - fadeOut * 0.9, 0, 1)
                sh.Mesh.Scale = Vector3.new(fadeOut, fadeOut, fadeOut * 1.6)
            end
        end
    end

    -- ============================================================================
    -- F. ATUALIZAÇÃO DAS PARTÍCULAS E RASTROS (8 TRAJETÓRIAS MATEMÁTICAS)
    -- ============================================================================
    local pFactor = State.CondenseFactor
    for _, p in ipairs(State.ParticlesData) do
        p.Timer = (p.Timer + dt * p.Speed * (1 + State.OverdriveFactor * 0.35)) % 1.0
        local prog = p.Timer
        local lifeEnvelope = math.sin(prog * math.pi) * pFactor

        local localVec = Vector3.zero
        local ang = t * (p.Speed * 3.2) + p.Phase
        local rMax = p.Radius * State.MasterScale

        if p.Behavior == "SPIRAL" then
            -- 1. Espiral convergente/divergente ao redor do núcleo
            local spR = Lerp(rMax, Config.CoreRadius * 1.15, prog)
            local spY = math.sin(prog * math.pi * 2 + p.Phase) * (p.Height * 0.35)
            localVec = Vector3.new(math.cos(ang * 2.2) * spR, spY, math.sin(ang * 2.2) * spR)

        elseif p.Behavior == "ARC" then
            -- 2. Trajetória parabólica em arco sobre o horizonte de eventos
            local arcTheta = (prog - 0.5) * math.pi * 1.35
            local aR = rMax * 0.75
            localVec = CFrame.Angles(p.Inclination, p.Azimuth, 0):PointToWorldSpace(
                Vector3.new(math.sin(arcTheta) * aR, math.cos(arcTheta) * aR * 0.85, 0)
            )

        elseif p.Behavior == "DIAGONAL" then
            -- 3. Corte diagonal veloz cruzando os planos da singularidade
            local span = (prog - 0.5) * rMax * 1.7
            local diagDir = CFrame.Angles(p.Inclination, p.Azimuth + t * 0.3, 0).LookVector
            local curveOffset = Vector3.new(0, math.sin(prog * math.pi) * 3.0, 0)
            localVec = (diagDir * span) + curveOffset

        elseif p.Behavior == "ASCENDING" then
            -- 4. Corrente gravitacional ascendente com leve torção
            local ascR = (Config.CoreRadius * 0.85) + (p.Index % 5) * 2.2
            local ascY = Lerp(-p.Height * 0.6, p.Height * 1.25, prog)
            localVec = Vector3.new(math.cos(ang) * ascR, ascY, math.sin(ang) * ascR)

        elseif p.Behavior == "DESCENDING" then
            -- 5. Precipitação cósmica descendente em direção ao disco
            local descR = Lerp(rMax * 0.4, rMax * 0.95, prog)
            local descY = Lerp(p.Height * 1.2, -p.Height * 0.45, prog)
            localVec = Vector3.new(math.cos(-ang) * descR, descY, math.sin(-ang) * descR)

        elseif p.Behavior == "ORBITAL" then
            -- 6. Órbita kepleriana inclinada ao redor do buraco negro
            local orbLocal = Vector3.new(math.cos(ang) * rMax * 0.8, 0, math.sin(ang) * rMax * 0.65)
            localVec = CFrame.Angles(p.Inclination, p.Azimuth, 0):PointToWorldSpace(orbLocal)

        elseif p.Behavior == "RADIAL" then
            -- 7. Ejeção radial explosiva a partir da esfera de fótons
            local radDist = Lerp(Config.CoreRadius * 1.05, rMax * 1.25, prog ^ 0.75)
            local radDir = CFrame.Angles(p.Inclination * 0.5, p.Azimuth + t * 0.2, 0).LookVector
            localVec = radDir * radDist

        else -- "LISSAJOUS"
            -- 8. Curva Harmônica Complexa 3D (Nó de Lissajous)
            local lR = rMax * 0.72
            localVec = Vector3.new(
                lR * math.sin(p.FreqA * ang + p.Phase),
                (p.Height * 0.65) * math.sin(p.FreqB * ang),
                lR * math.cos(p.FreqC * ang)
            )
        end

        local worldPos = centerCF:PointToWorldSpace(localVec)
        p.Part.CFrame = CFrame.new(worldPos)
        p.Part.Transparency = 1 - (lifeEnvelope * 0.95)
        local s = lifeEnvelope * (1 + State.OverdriveFactor * 0.35)
        p.Mesh.Scale = Vector3.new(s, s, s)
        p.Trail.Enabled = (lifeEnvelope > 0.12)
    end
end

-- ================================================================================
-- 12. CONTROLE DE ATIVAÇÃO E DESATIVAÇÃO (ACTIVATESINGULARITY / DEACTIVATESINGULARITY)
-- ================================================================================
local function InitializeAllVFXElements()
    if State.CoreData then return end

    CreateSingularityCore()
    CreateEnergyRing()

    for arcIdx = 1, Config.ArcCount do
        CreateGoldenArc(arcIdx, Config.ArcCount)
    end

    CreateVerticalBeam()

    for pIdx = 1, Config.CosmicParticleCount do
        CreateCosmicParticle(pIdx)
    end
end

local function ActivateSingularity()
    InitializeAllVFXElements()

    State.Active = true
    State.Phase = Phases.CORE_FORMATION
    State.PhaseTime = 0
    State.TotalTime = 0

    -- Posiciona imediatamente à frente do personagem ao ativar
    MoveSingularityInFront(true)

    local groundPos = Vector3.new(
        State.CurrentCFrame.Position.X,
        State.CurrentCFrame.Position.Y + State.GroundYOffset,
        State.CurrentCFrame.Position.Z
    )
    CreateGroundWave(groundPos, 1.2)

    if State.UI.UpdateStatusUI then
        State.UI.UpdateStatusUI()
    end
end

local function DeactivateSingularity()
    if not State.Active then return end
    -- Inicia a Fase 8 (Dissipação sincronizada suave)
    State.Phase = Phases.DISSIPATION
    State.PhaseTime = 0

    if State.UI.UpdateStatusUI then
        State.UI.UpdateStatusUI()
    end
end

-- ================================================================================
-- 13. CREATE MOBILE UI (INTERFACE TOUCH MINIMALISTA, ARRASTÁVEL E DOURADA)
-- ================================================================================
local function CreateMobileUI()
    -- Seleciona container compatível com Delta Executor Mobile
    local parentGui = nil
    pcall(function()
        if gethui then
            parentGui = gethui()
        end
    end)
    if not parentGui then
        pcall(function()
            parentGui = game:GetService("CoreGui")
        end)
    end
    if not parentGui then
        parentGui = LocalPlayer:WaitForChild("PlayerGui")
    end

    local oldGui = parentGui:FindFirstChild("DivineSingularityMobileUI")
    if oldGui then
        oldGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DivineSingularityMobileUI"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parentGui

    -- Container Principal Arrastável (Posicionado à direita para não bloquear o analógico mobile)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainTouchPanel"
    mainFrame.Size = UDim2.new(0, 236, 0, 290)
    mainFrame.Position = UDim2.new(1, -254, 0.5, -145)
    mainFrame.BackgroundColor3 = Color3.fromRGB(12, 11, 16)
    mainFrame.BackgroundTransparency = 0.12
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 14)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Config.ImperialGold
    mainStroke.Thickness = 1.8
    mainStroke.Transparency = 0.15
    mainStroke.Parent = mainFrame

    -- Barra de Título Arrastável (Touch Drag Handle)
    local headerBar = Instance.new("Frame")
    headerBar.Name = "DragHeader"
    headerBar.Size = UDim2.new(1, 0, 0, 38)
    headerBar.BackgroundColor3 = Color3.fromRGB(22, 19, 28)
    headerBar.BorderSizePixel = 0
    headerBar.Active = true
    headerBar.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 14)
    headerCorner.Parent = headerBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -44, 0, 20)
    titleLabel.Position = UDim2.new(0, 12, 0, 4)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "✦ DIVINE SINGULARITY"
    titleLabel.TextColor3 = Config.BrightGold
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = headerBar

    local phaseStatusLabel = Instance.new("TextLabel")
    phaseStatusLabel.Size = UDim2.new(1, -44, 0, 14)
    phaseStatusLabel.Position = UDim2.new(0, 12, 0, 21)
    phaseStatusLabel.BackgroundTransparency = 1
    phaseStatusLabel.Font = Enum.Font.GothamMedium
    phaseStatusLabel.Text = "STATUS: INATIVO"
    phaseStatusLabel.TextColor3 = Color3.fromRGB(185, 175, 155)
    phaseStatusLabel.TextSize = 10
    phaseStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    phaseStatusLabel.Parent = headerBar

    -- Botão Minimizar/Expandir Painel
    local collapseBtn = Instance.new("TextButton")
    collapseBtn.Size = UDim2.new(0, 28, 0, 28)
    collapseBtn.Position = UDim2.new(1, -34, 0, 5)
    collapseBtn.BackgroundColor3 = Color3.fromRGB(32, 27, 40)
    collapseBtn.Font = Enum.Font.GothamBold
    collapseBtn.Text = "–"
    collapseBtn.TextColor3 = Config.BrightGold
    collapseBtn.TextSize = 16
    collapseBtn.Parent = headerBar
    Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(0, 8)

    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -20, 1, -46)
    contentContainer.Position = UDim2.new(0, 10, 0, 42)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame

    -- ============================================================================
    -- BOTÃO 1 — ATIVAR VFX (GRANDE, OTIMIZADO PARA CELULAR, COM ÍCONE E FEEDBACK)
    -- ============================================================================
    local btnActivate = Instance.new("TextButton")
    btnActivate.Name = "BtnActivateVFX"
    btnActivate.Size = UDim2.new(1, 0, 0, 62)
    btnActivate.Position = UDim2.new(0, 0, 0, 2)
    btnActivate.BackgroundColor3 = Color3.fromRGB(26, 22, 32)
    btnActivate.AutoButtonColor = false
    btnActivate.Text = ""
    btnActivate.Parent = contentContainer

    local actCorner = Instance.new("UICorner")
    actCorner.CornerRadius = UDim.new(0, 12)
    actCorner.Parent = btnActivate

    local actStroke = Instance.new("UIStroke")
    actStroke.Color = Config.ImperialGold
    actStroke.Thickness = 1.6
    actStroke.Parent = btnActivate

    -- Ícone Personalizado da Singularidade no Botão 1
    local actIconBg = Instance.new("Frame")
    actIconBg.Size = UDim2.new(0, 42, 0, 42)
    actIconBg.Position = UDim2.new(0, 10, 0.5, -21)
    actIconBg.BackgroundColor3 = Color3.fromRGB(8, 7, 12)
    actIconBg.Parent = btnActivate
    Instance.new("UICorner", actIconBg).CornerRadius = UDim.new(1, 0)

    local actIconStroke = Instance.new("UIStroke")
    actIconStroke.Color = Config.BrightGold
    actIconStroke.Thickness = 2.2
    actIconStroke.Parent = actIconBg

    local actIconSymbol = Instance.new("TextLabel")
    actIconSymbol.Size = UDim2.new(1, 0, 1, 0)
    actIconSymbol.BackgroundTransparency = 1
    actIconSymbol.Font = Enum.Font.GothamBold
    actIconSymbol.Text = "◉"
    actIconSymbol.TextColor3 = Config.SolarWhite
    actIconSymbol.TextSize = 22
    actIconSymbol.Parent = actIconBg

    local actTitle = Instance.new("TextLabel")
    actTitle.Size = UDim2.new(1, -64, 0, 24)
    actTitle.Position = UDim2.new(0, 60, 0, 10)
    actTitle.BackgroundTransparency = 1
    actTitle.Font = Enum.Font.GothamBlack
    actTitle.Text = "ATIVAR VFX"
    actTitle.TextColor3 = Config.SolarWhite
    actTitle.TextSize = 15
    actTitle.TextXAlignment = Enum.TextXAlignment.Left
    actTitle.Parent = btnActivate

    local actSub = Instance.new("TextLabel")
    actSub.Size = UDim2.new(1, -64, 0, 16)
    actSub.Position = UDim2.new(0, 60, 0, 33)
    actSub.BackgroundTransparency = 1
    actSub.Font = Enum.Font.Gotham
    actSub.Text = "Singularidade Dourada: OFF"
    actSub.TextColor3 = Color3.fromRGB(190, 175, 140)
    actSub.TextSize = 11
    actSub.TextXAlignment = Enum.TextXAlignment.Left
    actSub.Parent = btnActivate

    -- ============================================================================
    -- BOTÃO 2 — COLOCAR À FRENTE (POSICIONAMENTO FRONTAL HRP COM COOLDOWN VISUAL)
    -- ============================================================================
    local btnPlaceFront = Instance.new("TextButton")
    btnPlaceFront.Name = "BtnPlaceInFront"
    btnPlaceFront.Size = UDim2.new(1, 0, 0, 62)
    btnPlaceFront.Position = UDim2.new(0, 0, 0, 72)
    btnPlaceFront.BackgroundColor3 = Color3.fromRGB(26, 22, 32)
    btnPlaceFront.AutoButtonColor = false
    btnPlaceFront.Text = ""
    btnPlaceFront.ClipsDescendants = true
    btnPlaceFront.Parent = contentContainer

    local frontCorner = Instance.new("UICorner")
    frontCorner.CornerRadius = UDim.new(0, 12)
    frontCorner.Parent = btnPlaceFront

    local frontStroke = Instance.new("UIStroke")
    frontStroke.Color = Config.BrightGold
    frontStroke.Thickness = 1.6
    frontStroke.Parent = btnPlaceFront

    -- Barra de Cooldown Visual Opcional integrada ao Botão 2
    local cooldownFill = Instance.new("Frame")
    cooldownFill.Name = "CooldownVisualBar"
    cooldownFill.Size = UDim2.new(0, 0, 1, 0)
    cooldownFill.Position = UDim2.new(0, 0, 0, 0)
    cooldownFill.BackgroundColor3 = Config.ImperialGold
    cooldownFill.BackgroundTransparency = 0.72
    cooldownFill.BorderSizePixel = 0
    cooldownFill.Parent = btnPlaceFront

    local frontIconBg = Instance.new("Frame")
    frontIconBg.Size = UDim2.new(0, 42, 0, 42)
    frontIconBg.Position = UDim2.new(0, 10, 0.5, -21)
    frontIconBg.BackgroundColor3 = Color3.fromRGB(38, 28, 12)
    frontIconBg.Parent = btnPlaceFront
    Instance.new("UICorner", frontIconBg).CornerRadius = UDim.new(1, 0)

    local frontIconStroke = Instance.new("UIStroke")
    frontIconStroke.Color = Config.SolarWhite
    frontIconStroke.Thickness = 1.8
    frontIconStroke.Parent = frontIconBg

    local frontIconSymbol = Instance.new("TextLabel")
    frontIconSymbol.Size = UDim2.new(1, 0, 1, 0)
    frontIconSymbol.BackgroundTransparency = 1
    frontIconSymbol.Font = Enum.Font.GothamBold
    frontIconSymbol.Text = "⌖"
    frontIconSymbol.TextColor3 = Config.BrightGold
    frontIconSymbol.TextSize = 24
    frontIconSymbol.Parent = frontIconBg

    local frontTitle = Instance.new("TextLabel")
    frontTitle.Size = UDim2.new(1, -64, 0, 24)
    frontTitle.Position = UDim2.new(0, 60, 0, 10)
    frontTitle.BackgroundTransparency = 1
    frontTitle.Font = Enum.Font.GothamBlack
    frontTitle.Text = "COLOCAR À FRENTE"
    frontTitle.TextColor3 = Config.BrightGold
    frontTitle.TextSize = 14
    frontTitle.TextXAlignment = Enum.TextXAlignment.Left
    frontTitle.Parent = btnPlaceFront

    local frontSub = Instance.new("TextLabel")
    frontSub.Size = UDim2.new(1, -64, 0, 16)
    frontSub.Position = UDim2.new(0, 60, 0, 33)
    frontSub.BackgroundTransparency = 1
    frontSub.Font = Enum.Font.Gotham
    frontSub.Text = "Alinhar à direção do personagem"
    frontSub.TextColor3 = Color3.fromRGB(205, 190, 155)
    frontSub.TextSize = 10
    frontSub.TextXAlignment = Enum.TextXAlignment.Left
    frontSub.Parent = btnPlaceFront

    -- ============================================================================
    -- CONTROLES TOUCH DE PARÂMETROS EM TEMPO REAL (DISTÂNCIA, ALTURA, VELOCIDADE)
    -- ============================================================================
    local function CreateParameterStepper(labelText, yPos, getVal, setVal, step)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.Position = UDim2.new(0, 0, 0, yPos)
        row.BackgroundColor3 = Color3.fromRGB(18, 16, 24)
        row.BorderSizePixel = 0
        row.Parent = contentContainer
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -86, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextColor3 = Color3.fromRGB(235, 220, 185)
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = string.format("%s: %.1f", labelText, getVal())
        lbl.Parent = row

        local btnMinus = Instance.new("TextButton")
        btnMinus.Size = UDim2.new(0, 34, 0, 24)
        btnMinus.Position = UDim2.new(1, -76, 0.5, -12)
        btnMinus.BackgroundColor3 = Color3.fromRGB(35, 28, 18)
        btnMinus.Font = Enum.Font.GothamBold
        btnMinus.Text = "-"
        btnMinus.TextColor3 = Config.BrightGold
        btnMinus.TextSize = 15
        btnMinus.Parent = row
        Instance.new("UICorner", btnMinus).CornerRadius = UDim.new(0, 6)

        local btnPlus = Instance.new("TextButton")
        btnPlus.Size = UDim2.new(0, 34, 0, 24)
        btnPlus.Position = UDim2.new(1, -38, 0.5, -12)
        btnPlus.BackgroundColor3 = Color3.fromRGB(35, 28, 18)
        btnPlus.Font = Enum.Font.GothamBold
        btnPlus.Text = "+"
        btnPlus.TextColor3 = Config.BrightGold
        btnPlus.TextSize = 15
        btnPlus.Parent = row
        Instance.new("UICorner", btnPlus).CornerRadius = UDim.new(0, 6)

        btnMinus.Activated:Connect(function()
            setVal(getVal() - step)
            lbl.Text = string.format("%s: %.1f", labelText, getVal())
        end)

        btnPlus.Activated:Connect(function()
            setVal(getVal() + step)
            lbl.Text = string.format("%s: %.1f", labelText, getVal())
        end)
    end

    CreateParameterStepper("Distância Frontal", 142,
        function() return Config.FrontDistance end,
        function(v) Config.FrontDistance = Clamp(v, 8, 85) end,
        2.0
    )

    CreateParameterStepper("Altura (Offset Y)", 176,
        function() return Config.VerticalOffset end,
        function(v) Config.VerticalOffset = Clamp(v, -5, 45) end,
        1.0
    )

    CreateParameterStepper("Velocidade Follow", 210,
        function() return Config.FollowSpeed end,
        function(v) Config.FollowSpeed = Clamp(v, 1.0, 25.0) end,
        1.0
    )

    -- Funções de Feedback Visual Touch
    local function PlayTouchFeedback(button, highlightColor)
        TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = highlightColor or Color3.fromRGB(65, 48, 18)
        }):Play()
        task.delay(0.12, function()
            if button and button.Parent then
                local restColor = (button == btnActivate and State.Active)
                    and Color3.fromRGB(52, 38, 12)
                    or Color3.fromRGB(26, 22, 32)
                TweenService:Create(button, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = restColor
                }):Play()
            end
        end)
    end

    local function UpdateStatusUI()
        if State.Active and State.Phase ~= Phases.DISSIPATION then
            btnActivate.BackgroundColor3 = Color3.fromRGB(52, 38, 12)
            actStroke.Color = Config.SolarWhite
            actTitle.Text = "DESATIVAR VFX"
            actSub.Text = "Singularidade Dourada: ATIVA"
            actSub.TextColor3 = Config.BrightGold
        else
            btnActivate.BackgroundColor3 = Color3.fromRGB(26, 22, 32)
            actStroke.Color = Config.ImperialGold
            actTitle.Text = "ATIVAR VFX"
            actSub.Text = "Singularidade Dourada: OFF"
            actSub.TextColor3 = Color3.fromRGB(190, 175, 140)
        end
    end

    -- Conecta BOTÃO 1 — ATIVAR / DESATIVAR VFX
    btnActivate.Activated:Connect(function()
        PlayTouchFeedback(btnActivate, Color3.fromRGB(95, 70, 20))
        if not State.Active or State.Phase == Phases.DISSIPATION then
            ActivateSingularity()
        else
            DeactivateSingularity()
        end
    end)

    -- Conecta BOTÃO 2 — COLOCAR À FRENTE (Reposiciona na direção do personagem)
    btnPlaceFront.Activated:Connect(function()
        PlayTouchFeedback(btnPlaceFront, Color3.fromRGB(110, 82, 24))

        -- Cooldown visual suave no botão
        cooldownFill.Size = UDim2.new(1, 0, 1, 0)
        TweenService:Create(cooldownFill, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 0, 1, 0)
        }):Play()

        if not State.Active or State.Phase == Phases.DISSIPATION then
            ActivateSingularity()
        else
            MoveSingularityInFront(false)
        end
    end)

    -- Minimizar / Expandir Painel
    local isCollapsed = false
    collapseBtn.Activated:Connect(function()
        isCollapsed = not isCollapsed
        contentContainer.Visible = not isCollapsed
        collapseBtn.Text = isCollapsed and "+" or "–"
        TweenService:Create(mainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = isCollapsed and UDim2.new(0, 236, 0, 38) or UDim2.new(0, 236, 0, 290)
        }):Play()
    end)

    -- Sistema Touch Drag (Arrastar o painel pela tela no celular sem travar a movimentação)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    headerBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    headerBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    local dragConn = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    table.insert(State.Connections, dragConn)

    State.UI = {
        ScreenGui = screenGui,
        UpdateStatusUI = UpdateStatusUI,
        UpdatePhaseLabel = function(txt)
            phaseStatusLabel.Text = txt
        end
    }

    return screenGui
end

-- ================================================================================
-- 14. CLEANUP SINGULARITY (LIMPEZA COMPLETA DE CONEXÕES E INSTÂNCIAS)
-- ================================================================================
local function CleanupSingularity()
    State.Active = false
    State.Phase = Phases.IDLE

    for _, conn in ipairs(State.Connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    State.Connections = {}

    if State.UI and State.UI.ScreenGui then
        State.UI.ScreenGui:Destroy()
    end

    if VFXFolder and VFXFolder.Parent then
        VFXFolder:Destroy()
    end
end

_G.DivineSingularityCleanup = CleanupSingularity

-- ================================================================================
-- 15. INICIALIZAÇÃO DO SISTEMA E LOOP CENTRAL ÚNICO (RENDERSTEPPED)
-- ================================================================================
CreateMobileUI()
InitializeAllVFXElements()

-- Quando o personagem renascer, realinha automaticamente à frente do novo HumanoidRootPart
local charAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.35)
    if State.Active then
        MoveSingularityInFront(true)
    end
end)
table.insert(State.Connections, charAddedConn)

-- Controlador Central de Atualização (Único loop RenderStepped de alta precisão)
local renderConn = RunService.RenderStepped:Connect(function(dt)
    local safeDt = math.min(dt, 0.1)
    UpdateSingularity(safeDt)
end)
table.insert(State.Connections, renderConn)
