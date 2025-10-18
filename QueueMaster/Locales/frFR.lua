-- ======= Locales/frFR.lua =======
-- French localisation for QueueMaster
local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Only load if French locale
if GetLocale() ~= "frFR" then return end

local L = QueueMaster.L
if not L then return end

-- French translations
L["QueueMaster"] = "QueueMaster"
L["Enabled"] = "Activé"
L["Disabled"] = "Désactivé"

-- Queue states
L["Joined Queue"] = "File d'attente rejointe"
L["Left Queue"] = "File d'attente quittée"
L["Queue Ready"] = "File d'attente prête"
L["In Queue"] = "En file d'attente"

-- Queue types
L["Dungeon Finder"] = "Recherche de donjon"
L["Raid Finder"] = "Recherche de raid"
L["LFR"] = "RdR"
L["Scenarios"] = "Scénarios"
L["Flexible Raid"] = "Raid flexible"
L["PvP"] = "JcJ"
L["Battleground"] = "Champ de bataille"
L["Arena"] = "Arène"
L["Unknown Queue"] = "File d'attente inconnue"

-- Roles
L["Tank"] = "Tank"
L["Healer"] = "Soigneur"
L["DPS"] = "DPS"
L["Tanks"] = "Tanks"
L["Healers"] = "Soigneurs"

-- Time
L["Elapsed"] = "Écoulé"
L["Wait"] = "Attente"
L["Average Wait"] = "Attente moyenne"
L["Estimated Wait"] = "Attente estimée"

-- Configuration sections
L["GENERAL"] = "GÉNÉRAL"
L["DISPLAY"] = "AFFICHAGE"
L["APPEARANCE"] = "APPARENCE"
L["CONTROLS"] = "CONTRÔLES"
L["Notifications"] = "Notifications"
L["Advanced"] = "Avancé"

-- Configuration options
L["Show Alert Messages"] = "Afficher les messages d'alerte"
L["Enable Sound Notifications"] = "Activer les notifications sonores"
L["Enable Screen Flash"] = "Activer le flash d'écran"
L["Enable Debug Mode"] = "Activer le mode débogage"
L["Bar Layout Mode"] = "Mode de disposition des barres"
L["Compact Mode"] = "Mode compact"
L["Lock Bar Positions"] = "Verrouiller les positions des barres"
L["Group Movement Mode"] = "Mode de déplacement groupé"
L["Use Movable Anchor"] = "Utiliser l'ancre mobile"
L["Reset Bar Positions"] = "Réinitialiser les positions des barres"
L["UI Scale"] = "Échelle de l'interface"
L["Bar Height"] = "Hauteur de la barre"
L["Bar Width"] = "Largeur de la barre"
L["Bar Spacing"] = "Espacement des barres"
L["Frame Transparency"] = "Transparence du cadre"
L["Edge Opacity"] = "Opacité des bords"
L["Font Style"] = "Style de police"
L["Show Instance Name"] = "Afficher le nom de l'instance"
L["Show Timer"] = "Afficher le minuteur"
L["Show Role Composition"] = "Afficher la composition des rôles"
L["Color Theme"] = "Thème de couleur"

-- Layout modes
L["Vertical"] = "Vertical"
L["Horizontal"] = "Horizontal"
L["Text-only"] = "Texte seulement"

-- Colour themes
L["Default"] = "Par défaut"
L["Class Colors"] = "Couleurs de classe"
L["Custom"] = "Personnalisé"

-- Descriptions
L["Display popup alert messages for queue events"] = "Afficher des messages d'alerte pour les événements de file d'attente"
L["Play sound effects for queue events"] = "Jouer des effets sonores pour les événements de file d'attente"
L["Flash the screen for important events"] = "Flasher l'écran pour les événements importants"
L["Show debug messages in chat"] = "Afficher les messages de débogage dans le chat"
L["Choose how queue timer bars are arranged"] = "Choisir comment les barres de minuteur sont disposées"
L["Use smaller fonts for narrow bars"] = "Utiliser des polices plus petites pour les barres étroites"
L["Prevent bars from being moved"] = "Empêcher le déplacement des barres"
L["Move all bars together or individually"] = "Déplacer toutes les barres ensemble ou individuellement"
L["Show movable anchor point"] = "Afficher le point d'ancrage mobile"
L["Reset all positions to default"] = "Réinitialiser toutes les positions par défaut"

-- Chat messages
L["QueueMaster is now active!"] = "QueueMaster est maintenant actif !"
L["Blizzard queue UI hidden."] = "Interface de file d'attente Blizzard masquée."
L["QueueMaster is handling your queues."] = "QueueMaster gère vos files d'attente."
L["No active queues detected."] = "Aucune file d'attente active détectée."
L["Tip:"] = "Conseil :"
L["Open LFR/LFD and queue for something!"] = "Ouvrez RdR/RdD et rejoignez une file d'attente !"

-- Alert messages
L["Joined:"] = "Rejoint :"
L["Left queue:"] = "Quitté la file d'attente :"
L["Invite declined. You're still in queue."] = "Invitation refusée. Vous êtes toujours en file d'attente."

-- Tooltip headers
L["Queue Information"] = "Informations sur la file d'attente"
L["Role Breakdown"] = "Répartition des rôles"
L["Click to configure"] = "Cliquer pour configurer"
L["Drag to move"] = "Glisser pour déplacer"
