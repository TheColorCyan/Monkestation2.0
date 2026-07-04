GAME_VERB_DESC(/client, open_character_preferences, "Open Character Preferences", "Open Character Preferences", "OOC")

	usr?.client?.prefs?.open_window(PREFERENCE_PAGE_CHARACTERS)

GAME_VERB_DESC(/client, open_game_preferences, "Open Game Preferences", "Open Game Preferences", "OOC")

	usr?.client?.prefs?.open_window(PREFERENCE_PAGE_SETTINGS)

/datum/verbs/menu/Preferences/verb/open_volume_mixer()
	set category = "OOC"
	set name = "Volume Mixer"
	set desc = "Open Volume Mixer"

	usr?.client?.prefs?.open_window(PREFERENCE_PAGE_PREFERENCES_VOLUME)
