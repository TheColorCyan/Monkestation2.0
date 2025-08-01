//Preferences stuff
	//Hairstyles
GLOBAL_LIST_EMPTY(roundstart_hairstyles_list)
GLOBAL_LIST_EMPTY(hairstyles_list) //stores /datum/sprite_accessory/hair indexed by name
GLOBAL_LIST_EMPTY(hairstyles_male_list) //stores only hair names
GLOBAL_LIST_EMPTY(hairstyles_female_list) //stores only hair names
GLOBAL_LIST_EMPTY(facial_hairstyles_list) //stores /datum/sprite_accessory/facial_hair indexed by name
GLOBAL_LIST_EMPTY(facial_hairstyles_male_list) //stores only hair names
GLOBAL_LIST_EMPTY(facial_hairstyles_female_list) //stores only hair names
GLOBAL_LIST_EMPTY(hair_gradients_list) //stores /datum/sprite_accessory/hair_gradient indexed by name
GLOBAL_LIST_EMPTY(facial_hair_gradients_list) //stores /datum/sprite_accessory/facial_hair_gradient indexed by name
	//Underwear
GLOBAL_LIST_EMPTY(underwear_list) //stores /datum/sprite_accessory/underwear indexed by name
GLOBAL_LIST_EMPTY(underwear_m) //stores only underwear name
GLOBAL_LIST_EMPTY(underwear_f) //stores only underwear name
	//Undershirts
GLOBAL_LIST_EMPTY(undershirt_list) //stores /datum/sprite_accessory/undershirt indexed by name
GLOBAL_LIST_EMPTY(undershirt_m)  //stores only undershirt name
GLOBAL_LIST_EMPTY(undershirt_f)  //stores only undershirt name
	//Socks
GLOBAL_LIST_EMPTY(socks_list) //stores /datum/sprite_accessory/socks indexed by name
	//Lizard Bits (all datum lists indexed by name)
GLOBAL_LIST_EMPTY(body_markings_list)
GLOBAL_LIST_EMPTY(snouts_list)
GLOBAL_LIST_EMPTY(horns_list)
GLOBAL_LIST_EMPTY(frills_list)
GLOBAL_LIST_EMPTY(spines_list)
GLOBAL_LIST_EMPTY(legs_list)
GLOBAL_LIST_EMPTY(animated_spines_list)

	//Mutant Human bits
GLOBAL_LIST_EMPTY(tails_list)
GLOBAL_LIST_EMPTY(tails_list_human) //Only exists for preference choices. Use "tails_list" otherwise.
GLOBAL_LIST_EMPTY(tails_list_lizard) //See above!
GLOBAL_LIST_EMPTY(ears_list)
GLOBAL_LIST_EMPTY(wings_list)
GLOBAL_LIST_EMPTY(wings_open_list)
GLOBAL_LIST_EMPTY(moth_wings_list)
GLOBAL_LIST_EMPTY(moth_antennae_list)
GLOBAL_LIST_EMPTY(moth_markings_list)
GLOBAL_LIST_EMPTY(apid_antenna_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(ipc_screens_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(ipc_antennas_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(ipc_chassis_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(apid_wings_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(caps_list)
GLOBAL_LIST_EMPTY(pod_hair_list)
GLOBAL_LIST_EMPTY(ethereal_horns_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(ethereal_tail_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(tails_list_monkey)
GLOBAL_LIST_EMPTY(anime_top_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(anime_middle_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(anime_bottom_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(arachnid_appendages_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(arachnid_chelicerae_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(goblin_ears_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(goblin_nose_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(floran_leaves_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(satyr_fluff_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(satyr_tail_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(satyr_horns_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(oni_tail_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(oni_wings_list) //Monkestation Addition
GLOBAL_LIST_EMPTY(oni_horns_list) //Monkestation Addition

GLOBAL_LIST_INIT(color_list_ethereal, list(
	"Blue" = "#3399ff",
	"Bright Yellow" = "#ffff99",
	"Burnt Orange" = "#cc4400",
	"Cyan Blue" = "#00ffff",
	"Dark Blue" = "#6666ff",
	"Dark Fuschia" = "#C70064", //Monkestation Edit: #CC0066 TO #C70064
	"Dark Green" = "#37835b",
	"Dark Red" = "#9c3030",
	"Dull Yellow" = "#fbdf56",
	"Faint Blue" = "#b3d9ff",
	"Faint Green" = "#ddff99",
	"Faint Red" = "#ffb3b3",
	"Green" = "#97ee63",
	"Orange" = "#ffa64d",
	"Pink" = "#ff99cc",
	"Purple" = "#ee82ee",
	"Red" = "#ff4d4d",
	"Seafoam Green" = "#00fa9a",
	"White" = "#f2f2f2",
	"Fuschia" = "#FF0066", //Monkestation Addition
	"Dark Purple" = "#502A77", //Monkestation Addition
	"Gray" = "#505050", //Monkestation Addition
))

GLOBAL_LIST_INIT(color_list_lustrous, list(
	"Cyan Blue" = "#00ffff",
	"Sky Blue" = "#37c0ff",
	"Blue" = "#3374ff",
	"Dark Blue" = "#5b5beb",
	"Bright Red" = "#fa2d2d",
))

GLOBAL_LIST_INIT(ghost_forms_with_directions_list, list(
	"catghost",
	"ghost_black",
	"ghost_blazeit",
	"ghost_blue",
	"ghost_camo",
	"ghost_cyan",
	"ghost_dblue",
	"ghost_dcyan",
	"ghost_dgreen",
	"ghost_dpink",
	"ghost_dred",
	"ghost_dyellow",
	"ghost_fire",
	"ghost_funkypurp",
	"ghost_green",
	"ghost_grey",
	"ghost_mellow",
	"ghost_pink",
	"ghost_pinksherbert",
	"ghost_purpleswirl",
	"ghost_rainbow",
	"ghost_red",
	"ghost_yellow",
	"ghost",
	"ghostian",
	"ghostian2",
	"ghostking",
	"skeleghost",
))
//stores the ghost forms that support directional sprites

GLOBAL_LIST_INIT(ghost_forms_with_accessories_list, list(
	"ghost_black",
	"ghost_blazeit",
	"ghost_blue",
	"ghost_camo",
	"ghost_cyan",
	"ghost_dblue",
	"ghost_dcyan",
	"ghost_dgreen",
	"ghost_dpink",
	"ghost_dred",
	"ghost_dyellow",
	"ghost_fire",
	"ghost_funkypurp",
	"ghost_green",
	"ghost_grey",
	"ghost_mellow",
	"ghost_pink",
	"ghost_pinksherbert",
	"ghost_purpleswirl",
	"ghost_rainbow",
	"ghost_red",
	"ghost_yellow",
	"ghost",
	"skeleghost",
))
//stores the ghost forms that support hair and other such things

GLOBAL_LIST_INIT(security_depts_prefs, sort_list(list(
	SEC_DEPT_ENGINEERING,
	SEC_DEPT_MEDICAL,
	SEC_DEPT_NONE,
	SEC_DEPT_SCIENCE,
	SEC_DEPT_SUPPLY,
)))

	//Backpacks
#define DBACKPACK "Department Backpack"
#define DDUFFELBAG "Department Duffel Bag"
#define DSATCHEL "Department Satchel"
#define GBACKPACK "Grey Backpack"
#define GDUFFELBAG "Grey Duffel Bag"
#define GSATCHEL "Grey Satchel"
#define LSATCHEL "Leather Satchel"
#define BSATCHEL "Black Leather Satchel" //MONKESTATION
#define RSATCHEL "Retro Satchel" //MONKESTATION
GLOBAL_LIST_INIT(backpacklist, list(
	DBACKPACK,
	DDUFFELBAG,
	DSATCHEL,
	GBACKPACK,
	GDUFFELBAG,
	GSATCHEL,
	LSATCHEL,
	BSATCHEL, //MONKESTATION
	RSATCHEL, //MONKESTATION
))

	//Suit/Skirt
#define PREF_SUIT "Jumpsuit"
#define PREF_SKIRT "Jumpskirt"

//Uplink spawn loc
#define UPLINK_PDA "PDA"
#define UPLINK_RADIO "Radio"
#define UPLINK_PEN "Pen" //like a real spy!
#define UPLINK_IMPLANT "Implant"

	//Female Uniforms
GLOBAL_LIST_EMPTY(female_clothing_icons)
	//Auto-generated 'fallback' clothing icons
GLOBAL_LIST_EMPTY(fallback_clothing_icons)

GLOBAL_LIST_INIT(scarySounds, list(
	'sound/effects/footstep/clownstep1.ogg',
	'sound/effects/footstep/clownstep2.ogg',
	'sound/effects/glassbr1.ogg',
	'sound/effects/glassbr2.ogg',
	'sound/effects/glassbr3.ogg',
	'sound/items/welder.ogg',
	'sound/items/welder2.ogg',
	'sound/machines/airlock.ogg',
	'sound/voice/hiss1.ogg',
	'sound/voice/hiss2.ogg',
	'sound/voice/hiss3.ogg',
	'sound/voice/hiss4.ogg',
	'sound/voice/hiss5.ogg',
	'sound/voice/hiss6.ogg',
	'sound/weapons/armbomb.ogg',
	'sound/weapons/taser.ogg',
	'sound/weapons/thudswoosh.ogg',
))


// Reference list for disposal sort junctions. Set the sortType variable on disposal sort junctions to
// the index of the sort department that you want. For example, sortType set to 2 will reroute all packages
// tagged for the Cargo Bay.

/* List of sortType codes for mapping reference
0 Waste
1 Disposals - All unwrapped items and untagged parcels get picked up by a junction with this sortType. Usually leads to the recycler.
2 Cargo Bay
3 QM Office
4 Engineering
5 CE Office
6 Atmospherics
7 Security
8 HoS Office
9 Medbay
10 CMO Office
11 Chemistry
12 Research
13 RD Office
14 Robotics
15 HoP Office
16 Library
17 Chapel
18 Theatre
19 Bar
20 Kitchen
21 Hydroponics
22 Janitor
23 Genetics
24 Experimentor Lab
25 Ordnance
26 Dormitories
27 Virology
28 Xenobiology
29 Law Office
30 Detective's Office
*/

//The whole system for the sorttype var is determined based on the order of this list,
//disposals must always be 1, since anything that's untagged will automatically go to disposals, or sorttype = 1 --Superxpdude

//If you don't want to fuck up disposals, add to this list, and don't change the order.
//If you insist on changing the order, you'll have to change every sort junction to reflect the new order. --Pete

GLOBAL_LIST_INIT(TAGGERLOCATIONS, list("Disposals",
	"Cargo Bay", "QM Office", "Engineering", "CE Office",
	"Atmospherics", "Security", "HoS Office", "Medbay",
	"CMO Office", "Chemistry", "Research", "RD Office",
	"Robotics", "HoP Office", "Library", "Chapel", "Theatre",
	"Bar", "Kitchen", "Hydroponics", "Janitor Closet","Genetics",
	"Experimentor Lab", "Ordnance", "Dormitories", "Pathology",
	"Xenobiology", "Law Office","Detective's Office"))

GLOBAL_LIST_INIT(station_prefixes, world.file2list("strings/station_prefixes.txt"))

GLOBAL_LIST_INIT(station_names, world.file2list("strings/station_names.txt"))

GLOBAL_LIST_INIT(station_suffixes, world.file2list("strings/station_suffixes.txt"))

GLOBAL_LIST_INIT(greek_letters, world.file2list("strings/greek_letters.txt"))

GLOBAL_LIST_INIT(phonetic_alphabet, world.file2list("strings/phonetic_alphabet.txt"))

GLOBAL_LIST_INIT(numbers_as_words, world.file2list("strings/numbers_as_words.txt"))

GLOBAL_LIST_INIT(wisdoms, world.file2list("strings/wisdoms.txt"))

/proc/generate_number_strings()
	var/list/L[198]
	for(var/i in 1 to 99)
		L += "[i]"
		L += "\Roman[i]"
	return L

GLOBAL_LIST_INIT(station_numerals, greek_letters + phonetic_alphabet + numbers_as_words + generate_number_strings())

GLOBAL_LIST_INIT(admiral_messages, list(
	"<i>Error: No comment given.</i>",
	"<i>null</i>",
	"Do you know how expensive these stations are?",
	"I was sleeping, thanks a lot.",
	"It's a good day to die!",
	"No.",
	"Stand and fight you cowards!",
	"Stop being paranoid.",
	"Stop wasting my time.",
	"Whatever's broken just build a new one.",
	"You knew the risks coming in.",
))

GLOBAL_LIST_INIT(junkmail_messages, world.file2list("strings/junkmail.txt"))

// All valid inputs to status display post_status
GLOBAL_LIST_INIT(status_display_approved_pictures, list(
	"blank",
	"shuttle",
	"default",
	"biohazard",
	"lockdown",
	"greenalert",
	"bluealert",
	"redalert",
	"deltaalert",
	"amberalert",
	"yellowalert",
	"lambdaalert",
	"gammaalert",
	"epsilonalert",
	"radiation",
	"currentalert", //For automatic set of status display on current level
))

// All possible alert level displays
GLOBAL_LIST_INIT(status_display_alert_level_pictures, list(
	"greenalert",
	"bluealert",
	"redalert",
	"deltaalert",
	"amberalert",
	"yellowalert",
	"lambdaalert",
	"gammaalert",
	"epsilonalert",
))

// Alert level names on the same level
GLOBAL_LIST_INIT(same_level_alert_levels, list(
	"blue",
	"yellow",
	"amber",
))

// Members of status_display_approved_pictures that are actually states and not alert values
GLOBAL_LIST_INIT(status_display_state_pictures, list(
	"blank",
	"shuttle",
))
