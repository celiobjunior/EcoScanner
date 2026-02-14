import Foundation

// MARK: - Code-Based Localization

/// Since .swiftpm doesn't support .lproj, we use a dictionary-based approach
/// that detects the system locale and returns the appropriate string.

public extension String {

    var localized: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        let key = self

        if lang.hasPrefix("pt"),
           let ptString = LocalizationStore.ptBR[key] {
            return ptString
        }

        return LocalizationStore.en[key] ?? key
    }

    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
}

// MARK: - Localization Store

enum LocalizationStore {

    // MARK: English

    static let en: [String: String] = [
        // Navigation
        "app.name": "Eco Scanner",
        "navigation.scanner": "Scanner",
        "navigation.history": "History",
        "navigation.profile": "Profile",

        // Common formats
        "common.xp_total": "%d XP",
        "common.xp_gain": "+%d XP",
        "common.percent": "%d%%",
        "common.co2_mass": "−%.3f kg CO₂",

        // Camera errors
        "camera.error.unavailable": "Camera is unavailable",
        "camera.error.cannot_add_output": "Cannot add video output",
        "camera.error.access_denied": "Camera access denied",
        "camera.error.access_restricted": "Camera access restricted",
        "camera.error.unknown_authorization": "Unknown camera authorization",

        // Categories
        "category.plastic": "Plastic",
        "category.glass": "Glass",
        "category.metal": "Metal",
        "category.paper": "Paper",
        "category.cardboard": "Cardboard",
        "category.electronic": "Electronic",
        "category.biodegradable": "Biodegradable",
        "category.textile": "Textile",

        // Disposal
        "category.disposal.plastic": "Wash and dry before discarding. Remove labels when possible. Dispose in the yellow bin.",
        "category.disposal.glass": "Rinse the container. Separate lids. Dispose in the green bin. Careful with broken glass.",
        "category.disposal.metal": "Rinse cans and containers. Flatten when possible. Dispose in the yellow bin.",
        "category.disposal.paper": "Keep dry and clean. Remove clips and staples. Dispose in the blue bin.",
        "category.disposal.cardboard": "Flatten boxes. Remove tape and labels. Keep dry. Dispose in the blue bin.",
        "category.disposal.electronic": "Never dispose in regular trash. Take to e-waste collection points or authorized stores.",
        "category.disposal.biodegradable": "Can be composted. Separate from other waste. Use in home composting or organic bins.",
        "category.disposal.textile": "Donate if in good condition. For damaged items, take to textile recycling collection points.",

        // Levels
        "level.eco_iniciante": "Eco Beginner",
        "level.eco_aprendiz": "Eco Apprentice",
        "level.eco_coletor": "Eco Collector",
        "level.eco_guardiao": "Eco Guardian",
        "level.eco_warrior": "Eco Warrior",
        "level.eco_heroi": "Eco Hero",
        "level.eco_champion": "Eco Champion",
        "level.eco_lenda": "Eco Legend",

        // Achievements
        "achievement.first_collection.title": "First Collection",
        "achievement.first_collection.desc": "Collect your first recyclable item",
        "achievement.collector_10.title": "Dedicated Collector",
        "achievement.collector_10.desc": "Collect 10 items",
        "achievement.collector_50.title": "Super Collector",
        "achievement.collector_50.desc": "Collect 50 items",
        "achievement.collector_100.title": "Master Recycler",
        "achievement.collector_100.desc": "Collect 100 items",
        "achievement.streak_3.title": "Consistent",
        "achievement.streak_3.desc": "Maintain a 3-day streak",
        "achievement.streak_7.title": "On Fire",
        "achievement.streak_7.desc": "Maintain a 7-day streak",
        "achievement.streak_30.title": "Unstoppable",
        "achievement.streak_30.desc": "Maintain a 30-day streak",
        "achievement.plastic_25.title": "Plastic Hunter",
        "achievement.plastic_25.desc": "Collect 25 plastic items",
        "achievement.paper_25.title": "Paper Pro",
        "achievement.paper_25.desc": "Collect 25 paper items",
        "achievement.glass_25.title": "Glass Collector",
        "achievement.glass_25.desc": "Collect 25 glass items",
        "achievement.metal_25.title": "Metal Scrapper",
        "achievement.metal_25.desc": "Collect 25 metal items",
        "achievement.cardboard_50.title": "Cardboard King",
        "achievement.cardboard_50.desc": "Collect 50 cardboard items",
        "achievement.electronic_25.title": "E-Waste Ranger",
        "achievement.electronic_25.desc": "Collect 25 electronic items",
        "achievement.biodegradable_25.title": "Compost Champion",
        "achievement.biodegradable_25.desc": "Collect 25 biodegradable items",
        "achievement.textile_25.title": "Textile Keeper",
        "achievement.textile_25.desc": "Collect 25 textile items",
        "achievement.co2_1kg.title": "Planet Thanks You",
        "achievement.co2_1kg.desc": "Save 1 kg of CO₂",
        "achievement.co2_10kg.title": "Planet Protector",
        "achievement.co2_10kg.desc": "Save 10 kg of CO₂",
        "achievement.level_warrior.title": "Eco Warrior",
        "achievement.level_warrior.desc": "Reach Eco Warrior level",
        "achievement.level_legend.title": "Living Legend",
        "achievement.level_legend.desc": "Reach Eco Legend level",

        // Achievement requirements
        "achievement.req.total_collections": "%d total collections",
        "achievement.req.category_collections": "%d %@ collections",
        "achievement.req.streak_days": "%d day streak",
        "achievement.req.co2_saved": "%.1f kg CO₂ saved",
        "achievement.req.level_reached": "Reach level %d",
        "notification.level_up.title": "Level Up!",
        "notification.level_up.body": "You reached %@",
        "notification.achievement.title": "Achievement Unlocked",
        "profile.levels_title": "All Levels",
        "profile.levels_subtitle": "Tap a level to understand your progression.",
        "profile.level_current": "Current level",
        "profile.level_locked": "Locked",
        "profile.levels_button": "See all levels",
        "profile.level_progress": "%d / %d XP in this level",
        "profile.progress_label": "Progress",
        "profile.progress_fraction": "%d / %d",
        "profile.progress_decimal": "%.1f / %.1f",

        // Onboarding
        "onboarding.page1.title": "Recycling Builds\nStrong Communities",
        "onboarding.page1.subtitle": "Your daily choices improve neighborhoods, schools, and public spaces.",
        "onboarding.page1.card1.title": "Social Impact in Every Item",
        "onboarding.page1.card1.body": "Correct disposal keeps streets cleaner and helps prevent health risks in the community.",
        "onboarding.page1.card2.title": "More Resilient Cities",
        "onboarding.page1.card2.body": "Less landfill waste means fewer emissions and better environmental quality for everyone.",
        "onboarding.page2.title": "Scan Fast,\nLearn Clearly",
        "onboarding.page2.subtitle": "Use your camera to identify materials and act with confidence.",
        "onboarding.page2.card1.title": "Instant Recognition",
        "onboarding.page2.card1.body": "The model classifies common recyclable materials in seconds.",
        "onboarding.page2.card2.title": "Practical Guidance",
        "onboarding.page2.card2.body": "Receive clear instructions for sorting and proper disposal of each item.",
        "onboarding.page3.title": "Turn Habits into\nCollective Change",
        "onboarding.page3.subtitle": "Build routines that inspire your family, friends, and local community.",
        "onboarding.page3.card1.title": "Visible Progress",
        "onboarding.page3.card1.body": "Track your collections, XP growth, and avoided CO₂ over time.",
        "onboarding.page3.card2.title": "Community Engagement",
        "onboarding.page3.card2.body": "Use streaks and goals to keep everyone motivated in daily recycling actions.",
        "onboarding.page4.title": "Ready for Your\nNext Scan?",
        "onboarding.page4.subtitle": "EcoScanner transforms environmental awareness into practical impact.",
        "onboarding.page4.card1.title": "From School to Neighborhood",
        "onboarding.page4.card1.body": "Apply the app in classroom projects, events, and community initiatives.",
        "onboarding.page4.card2.title": "Built for Real Utility",
        "onboarding.page4.card2.body": "Designed for fast decisions that improve disposal quality every day.",
        "onboarding.start_button": "Start Saving the Planet",
        "onboarding.next": "Next",
        "onboarding.skip": "Skip",

        // Scanner
        "scanner.title": "EcoScanner",
        "scanner.hint": "Point at a recyclable material",
        "scanner.detecting": "Analyzing...",
        "scanner.no_detection": "No material detected",
        "scanner.confidence": "%d%% confidence",
        "scanner.continue": "Continue Scanning",
        "home.title": "Recycle with purpose",
        "home.subtitle": "Detect materials in seconds and track your real environmental impact.",
        "home.scan_button": "Start Scanning",
        "home.streak": "%d day streak",

        // Feedback
        "feedback.material_detected": "MATERIAL DETECTED",
        "feedback.confidence_label": "%d%% confidence",
        "feedback.did_you_know": "Did you know?",
        "feedback.watch_out": "Watch out!",
        "feedback.source": "Source: %@",
        "feedback.this_collection_impact": "This collection:",
        "feedback.co2_saved_format": "−%.3f kg CO₂",
        "feedback.total_accumulated": "Total accumulated:",
        "feedback.co2_total_format": "−%.3f kg CO₂",
        "feedback.correct_disposal": "CORRECT DISPOSAL",
        "feedback.streak_days": "%d days on fire!",

        // Profile
        "profile.title": "Profile",
        "profile.default_name": "Eco User",
        "profile.level_label": "Level %d",
        "profile.xp_to_next": "%d XP to next level",
        "profile.max_level": "Max level!",
        "profile.carbon_footprint": "Carbon Footprint",
        "profile.co2_format": "−%.3f kg",
        "profile.co2_subtitle": "CO₂ avoided with your collections",
        "profile.items_collected": "Items",
        "profile.streak_days": "Streak",
        "profile.total_xp": "Total XP",
        "profile.achievements_label": "Awards",
        "profile.achievements_title": "Achievements",
        "profile.requirement": "Requirement:",
        "profile.unlocked": "Unlocked",
        "profile.locked": "Locked",

        // History
        "history.title": "History",
        "history.all_filter": "All",
        "history.collections_count": "%d collections",
        "history.co2_avoided": "−%.3f kg CO₂ avoided",
        "history.empty.title": "No collections yet",
        "history.empty.description": "Scan your first recyclable item to start building your history.",

        // Facts
        "fact.default": "Recycling helps protect the environment.",
        "fact.plastic_1": "Plastic can take up to 450 years to decompose in nature.",
        "fact.plastic_2": "Recycling 1 ton of plastic saves 5,774 kWh of energy.",
        "fact.plastic_3": "8 million tons of plastic are dumped into oceans every year.",
        "fact.plastic_4": "By recycling plastic, you help reduce oil extraction, the main raw material for plastic.",
        "fact.glass_1": "Glass is 100% recyclable and can be recycled indefinitely without losing quality.",
        "fact.glass_2": "A glass bottle can take up to 1 million years to decompose in nature.",
        "fact.glass_3": "Recycling glass can reduce air pollution by 20% and water pollution by 50%.",
        "fact.glass_4": "For each 10% of cullet used, around 2.5% of energy is saved in production.",
        "fact.metal_1": "Recycling one aluminum can saves 95% of the energy needed to produce a new one.",
        "fact.metal_2": "Aluminum can be recycled infinitely without losing its properties.",
        "fact.metal_3": "A recycled aluminum can can return to store shelves in as little as 60 days.",
        "fact.metal_4": "Brazil is a global leader in aluminum can recycling, with rates above 98%.",
        "fact.paper_1": "Each ton of recycled paper can save 17 trees.",
        "fact.paper_2": "Recycling paper saves around 70% of the energy compared to virgin production.",
        "fact.paper_3": "Paper can be recycled 5 to 7 times before fibers become too short.",
        "fact.cardboard_1": "Recycled cardboard uses up to 46% less energy than producing new cardboard.",
        "fact.cardboard_2": "Cardboard is one of the most recycled materials worldwide, with over 80% recovery.",
        "fact.cardboard_3": "Wet or greasy cardboard loses recycling value. Keep it dry.",
        "fact.biodegradable_1": "Organic waste in landfills produces methane, a gas about 25 times stronger than CO₂.",
        "fact.biodegradable_2": "Composting organic waste can reduce household trash volume by up to 50%.",
        "fact.biodegradable_3": "Compost produced from organic waste is an excellent natural fertilizer for plants.",
        "fact.electronic_1": "Only about 17% of global e-waste is recycled properly.",
        "fact.electronic_2": "A smartphone contains more than 40 chemical elements, many of them recyclable.",
        "fact.electronic_3": "E-waste is the fastest-growing waste stream in the world.",
    ]

    // MARK: Portuguese (BR)

    static let ptBR: [String: String] = [
        // Navigation
        "app.name": "Eco Scanner",
        "navigation.scanner": "Scanner",
        "navigation.history": "Histórico",
        "navigation.profile": "Perfil",

        // Common formats
        "common.xp_total": "%d XP",
        "common.xp_gain": "+%d XP",
        "common.percent": "%d%%",
        "common.co2_mass": "−%.3f kg CO₂",

        // Camera errors
        "camera.error.unavailable": "Câmera indisponível",
        "camera.error.cannot_add_output": "Não foi possível adicionar saída de vídeo",
        "camera.error.access_denied": "Acesso à câmera negado",
        "camera.error.access_restricted": "Acesso à câmera restrito",
        "camera.error.unknown_authorization": "Autorização de câmera desconhecida",

        // Categories
        "category.plastic": "Plástico",
        "category.glass": "Vidro",
        "category.metal": "Metal",
        "category.paper": "Papel",
        "category.cardboard": "Papelão",
        "category.electronic": "Eletrônico",
        "category.biodegradable": "Biodegradável",
        "category.textile": "Têxtil",

        // Disposal
        "category.disposal.plastic": "Lave e seque antes de descartar. Remova rótulos quando possível. Descarte na lixeira amarela.",
        "category.disposal.glass": "Enxágue o recipiente. Separe tampas. Descarte na lixeira verde. Cuidado com vidro quebrado.",
        "category.disposal.metal": "Enxágue latas e recipientes. Amasse quando possível. Descarte na lixeira amarela.",
        "category.disposal.paper": "Mantenha seco e limpo. Remova clipes e grampos. Descarte na lixeira azul.",
        "category.disposal.cardboard": "Desmonte caixas. Remova fitas e etiquetas. Mantenha seco. Descarte na lixeira azul.",
        "category.disposal.electronic": "Nunca descarte no lixo comum. Leve a pontos de coleta de lixo eletrônico ou lojas autorizadas.",
        "category.disposal.biodegradable": "Pode ser compostado. Separe dos demais resíduos. Use em composteira doméstica ou lixeira orgânica.",
        "category.disposal.textile": "Doe se estiver em boas condições. Para itens danificados, leve a pontos de coleta de reciclagem têxtil.",

        // Levels
        "level.eco_iniciante": "Eco Iniciante",
        "level.eco_aprendiz": "Eco Aprendiz",
        "level.eco_coletor": "Eco Coletor",
        "level.eco_guardiao": "Eco Guardião",
        "level.eco_warrior": "Eco Guerreiro",
        "level.eco_heroi": "Eco Herói",
        "level.eco_champion": "Eco Campeão",
        "level.eco_lenda": "Eco Lenda",

        // Achievements
        "achievement.first_collection.title": "Primeira Coleta",
        "achievement.first_collection.desc": "Colete seu primeiro item reciclável",
        "achievement.collector_10.title": "Coletor Dedicado",
        "achievement.collector_10.desc": "Colete 10 itens",
        "achievement.collector_50.title": "Super Coletor",
        "achievement.collector_50.desc": "Colete 50 itens",
        "achievement.collector_100.title": "Mestre da Reciclagem",
        "achievement.collector_100.desc": "Colete 100 itens",
        "achievement.streak_3.title": "Constante",
        "achievement.streak_3.desc": "Mantenha uma sequência de 3 dias",
        "achievement.streak_7.title": "Em Chamas",
        "achievement.streak_7.desc": "Mantenha uma sequência de 7 dias",
        "achievement.streak_30.title": "Imparável",
        "achievement.streak_30.desc": "Mantenha uma sequência de 30 dias",
        "achievement.plastic_25.title": "Caçador de Plástico",
        "achievement.plastic_25.desc": "Colete 25 itens de plástico",
        "achievement.paper_25.title": "Mestre do Papel",
        "achievement.paper_25.desc": "Colete 25 itens de papel",
        "achievement.glass_25.title": "Coletor de Vidro",
        "achievement.glass_25.desc": "Colete 25 itens de vidro",
        "achievement.metal_25.title": "Catador de Metal",
        "achievement.metal_25.desc": "Colete 25 itens de metal",
        "achievement.cardboard_50.title": "Rei do Papelão",
        "achievement.cardboard_50.desc": "Colete 50 itens de papelão",
        "achievement.electronic_25.title": "Guardião do E-lixo",
        "achievement.electronic_25.desc": "Colete 25 itens eletrônicos",
        "achievement.biodegradable_25.title": "Campeão da Compostagem",
        "achievement.biodegradable_25.desc": "Colete 25 itens biodegradáveis",
        "achievement.textile_25.title": "Guardião Têxtil",
        "achievement.textile_25.desc": "Colete 25 itens têxteis",
        "achievement.co2_1kg.title": "Planeta Agradece",
        "achievement.co2_1kg.desc": "Economize 1 kg de CO₂",
        "achievement.co2_10kg.title": "Protetor do Planeta",
        "achievement.co2_10kg.desc": "Economize 10 kg de CO₂",
        "achievement.level_warrior.title": "Eco Guerreiro",
        "achievement.level_warrior.desc": "Alcance o nível Eco Guerreiro",
        "achievement.level_legend.title": "Lenda Viva",
        "achievement.level_legend.desc": "Alcance o nível Eco Lenda",

        // Achievement requirements
        "achievement.req.total_collections": "%d coletas no total",
        "achievement.req.category_collections": "%d coletas de %@",
        "achievement.req.streak_days": "Sequência de %d dias",
        "achievement.req.co2_saved": "%.1f kg de CO₂ economizados",
        "achievement.req.level_reached": "Alcançar nível %d",
        "notification.level_up.title": "Subiu de Nível!",
        "notification.level_up.body": "Você alcançou %@",
        "notification.achievement.title": "Conquista Desbloqueada",
        "profile.levels_title": "Todos os Níveis",
        "profile.levels_subtitle": "Toque em um nível para acompanhar sua evolução.",
        "profile.level_current": "Nível atual",
        "profile.level_locked": "Bloqueado",
        "profile.levels_button": "Ver todos os níveis",
        "profile.level_progress": "%d / %d XP neste nível",
        "profile.progress_label": "Progresso",
        "profile.progress_fraction": "%d / %d",
        "profile.progress_decimal": "%.1f / %.1f",

        // Onboarding
        "onboarding.page1.title": "Reciclagem fortalece\ncomunidades",
        "onboarding.page1.subtitle": "Suas escolhas diárias melhoram bairros, escolas e espaços públicos.",
        "onboarding.page1.card1.title": "Impacto social em cada item",
        "onboarding.page1.card1.body": "O descarte correto mantém ruas mais limpas e ajuda a prevenir riscos à saúde.",
        "onboarding.page1.card2.title": "Cidades mais resilientes",
        "onboarding.page1.card2.body": "Menos resíduos em aterros significa menos emissões e melhor qualidade ambiental para todos.",
        "onboarding.page2.title": "Escaneie rápido,\naprenda com clareza",
        "onboarding.page2.subtitle": "Use a câmera para identificar materiais e agir com confiança.",
        "onboarding.page2.card1.title": "Reconhecimento instantâneo",
        "onboarding.page2.card1.body": "O modelo classifica materiais recicláveis comuns em segundos.",
        "onboarding.page2.card2.title": "Orientação prática",
        "onboarding.page2.card2.body": "Receba instruções claras para separar e descartar cada item corretamente.",
        "onboarding.page3.title": "Transforme hábitos em\nmudança coletiva",
        "onboarding.page3.subtitle": "Construa rotinas que inspiram sua família, amigos e comunidade local.",
        "onboarding.page3.card1.title": "Progresso visível",
        "onboarding.page3.card1.body": "Acompanhe suas coletas, crescimento de XP e CO₂ evitado ao longo do tempo.",
        "onboarding.page3.card2.title": "Engajamento comunitário",
        "onboarding.page3.card2.body": "Use sequências e metas para manter todos motivados em ações diárias de reciclagem.",
        "onboarding.page4.title": "Pronto para seu\npróximo scan?",
        "onboarding.page4.subtitle": "O EcoScanner transforma consciência ambiental em impacto prático.",
        "onboarding.page4.card1.title": "Da escola para o bairro",
        "onboarding.page4.card1.body": "Aplique o app em projetos de aula, eventos e iniciativas comunitárias.",
        "onboarding.page4.card2.title": "Feito para utilidade real",
        "onboarding.page4.card2.body": "Projetado para decisões rápidas que melhoram a qualidade do descarte todos os dias.",
        "onboarding.start_button": "Comece a Salvar o Planeta",
        "onboarding.next": "Próximo",
        "onboarding.skip": "Pular",

        // Scanner
        "scanner.title": "EcoScanner",
        "scanner.hint": "Aponte para um material reciclável",
        "scanner.detecting": "Analisando...",
        "scanner.no_detection": "Nenhum material detectado",
        "scanner.confidence": "%d%% de confiança",
        "scanner.continue": "Continuar Escaneando",
        "home.title": "Recicle com propósito",
        "home.subtitle": "Detecte materiais em segundos e acompanhe seu impacto ambiental real.",
        "home.scan_button": "Iniciar Escaneamento",
        "home.streak": "Sequência de %d dias",

        // Feedback
        "feedback.material_detected": "MATERIAL DETECTADO",
        "feedback.confidence_label": "%d%% de confiança",
        "feedback.did_you_know": "Você sabia?",
        "feedback.watch_out": "Atenção!",
        "feedback.source": "Fonte: %@",
        "feedback.this_collection_impact": "Esta coleta:",
        "feedback.co2_saved_format": "−%.3f kg CO₂",
        "feedback.total_accumulated": "Total acumulado:",
        "feedback.co2_total_format": "−%.3f kg CO₂",
        "feedback.correct_disposal": "DESCARTE CORRETO",
        "feedback.streak_days": "%d dias em chamas!",

        // Profile
        "profile.title": "Perfil",
        "profile.default_name": "Usuário Eco",
        "profile.level_label": "Nível %d",
        "profile.xp_to_next": "%d XP para o próximo nível",
        "profile.max_level": "Nível máximo!",
        "profile.carbon_footprint": "Pegada de Carbono",
        "profile.co2_format": "−%.3f kg",
        "profile.co2_subtitle": "CO₂ evitado com suas coletas",
        "profile.items_collected": "Itens",
        "profile.streak_days": "Sequência",
        "profile.total_xp": "XP Total",
        "profile.achievements_label": "Prêmios",
        "profile.achievements_title": "Conquistas",
        "profile.requirement": "Requisito:",
        "profile.unlocked": "Desbloqueada",
        "profile.locked": "Bloqueada",

        // History
        "history.title": "Histórico",
        "history.all_filter": "Todos",
        "history.collections_count": "%d coletas",
        "history.co2_avoided": "−%.3f kg CO₂ evitados",
        "history.empty.title": "Nenhuma coleta ainda",
        "history.empty.description": "Escaneie seu primeiro item reciclável para começar a construir seu histórico.",

        // Facts
        "fact.default": "Reciclar ajuda a proteger o meio ambiente.",
        "fact.plastic_1": "O plástico leva até 450 anos para se decompor na natureza.",
        "fact.plastic_2": "Reciclar 1 tonelada de plástico economiza 5.774 kWh de energia.",
        "fact.plastic_3": "8 milhões de toneladas de plástico são despejadas nos oceanos todos os anos.",
        "fact.plastic_4": "Ao reciclar plástico, você ajuda a reduzir a extração de petróleo, matéria-prima do plástico.",
        "fact.glass_1": "O vidro é 100% reciclável e pode ser reciclado infinitas vezes sem perder qualidade.",
        "fact.glass_2": "Uma garrafa de vidro pode levar 1 milhão de anos para se decompor na natureza.",
        "fact.glass_3": "Reciclar vidro pode reduzir em 20% a poluição do ar e em 50% a poluição da água.",
        "fact.glass_4": "Para cada 10% de caco de vidro utilizado, economiza-se cerca de 2,5% de energia na produção.",
        "fact.metal_1": "Reciclar uma lata de alumínio economiza 95% da energia necessária para produzir uma nova.",
        "fact.metal_2": "O alumínio pode ser reciclado infinitas vezes sem perder suas propriedades.",
        "fact.metal_3": "Uma lata de alumínio reciclada pode voltar às prateleiras em apenas 60 dias.",
        "fact.metal_4": "O Brasil é líder mundial em reciclagem de latas de alumínio, com taxas acima de 98%.",
        "fact.paper_1": "Cada tonelada de papel reciclado pode salvar 17 árvores.",
        "fact.paper_2": "Reciclar papel economiza cerca de 70% de energia em relação à produção com matéria-prima virgem.",
        "fact.paper_3": "O papel pode ser reciclado de 5 a 7 vezes antes que as fibras fiquem curtas demais.",
        "fact.cardboard_1": "O papelão reciclado usa até 46% menos energia do que produzir papelão novo.",
        "fact.cardboard_2": "O papelão é um dos materiais mais reciclados do mundo, com mais de 80% de recuperação.",
        "fact.cardboard_3": "Papelão molhado ou com gordura perde valor na reciclagem. Mantenha-o seco.",
        "fact.biodegradable_1": "Resíduos orgânicos em aterros produzem metano, um gás cerca de 25 vezes mais potente que o CO₂.",
        "fact.biodegradable_2": "A compostagem de orgânicos pode reduzir em até 50% o volume do lixo doméstico.",
        "fact.biodegradable_3": "O composto gerado pela compostagem é um excelente fertilizante natural para plantas.",
        "fact.electronic_1": "Apenas cerca de 17% do lixo eletrônico global é reciclado corretamente.",
        "fact.electronic_2": "Um smartphone contém mais de 40 elementos químicos, muitos deles recicláveis.",
        "fact.electronic_3": "O lixo eletrônico é a categoria de resíduos que mais cresce no mundo.",
    ]
}
