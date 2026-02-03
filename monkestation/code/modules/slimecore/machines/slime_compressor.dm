#define CROSSBREED_BASE_PATHS list(\
/datum/crossbreed_recipe/burning,\
/datum/crossbreed_recipe/charged,\
/datum/crossbreed_recipe/chilling,\
/datum/crossbreed_recipe/consuming,\
/datum/crossbreed_recipe/industrial,\
/datum/crossbreed_recipe/prismatic,\
/datum/crossbreed_recipe/regenerative,\
/datum/crossbreed_recipe/reproductive,\
/datum/crossbreed_recipe/selfsustaining,\
/datum/crossbreed_recipe/stabilized,\
)

/obj/machinery/slime_compressor
	name = "slime compressor"
	desc = "Machine used to compress slimes into bases for crossbreed extracts."

	icon = 'monkestation/code/modules/slimecore/icons/slime_compressor.dmi'
	icon_state = "base"
	base_icon_state = "base"

	use_power = IDLE_POWER_USE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION
	anchored = TRUE
	density = TRUE

	/// amount of time it takes to compress, scales with manipulator tier
	var/compress_time = 15 SECONDS
	///list of all the slimes we have
	var/list/mobs_inside = list()
	///are we grinding some slimes
	var/active = FALSE
	/// What mobs can go inside the compressor. Initially only slimes
	var/list/mob_whitelist = list(/mob/living/basic/slime)
	/// Recipes we can choose from - base of crossbreed
	var/static/list/base_choices = list()
	/// Recipes we can choose from - subtype of base crossbreed
	var/static/list/cross_breed_choices = list()
	/// Recipe we have currently set
	var/datum/crossbreed_recipe/current_recipe

	/// Base slime required for the recipe (e.g. regenerative has purple as base)
	var/datum/slime_color/base_slime_required
	/// Cross slime required to make the crossbreed
	var/datum/slime_color/cross_slime_required

	var/base_complete = FALSE
	var/cross_complete = FALSE

	var/static/list/choice_to_datum = list()

/obj/machinery/slime_compressor/Initialize(mapload)
	. = ..()
	if(length(cross_breed_choices))
		return
	for(var/datum/compressor_recipe/listed as anything in CROSSBREED_BASE_PATHS)
		var/datum/compressor_recipe/stored_recipe = new listed
		var/obj/item/slimecross/crossbreed = stored_recipe.output_item
		var/image/new_image = image(icon = initial(stored_recipe.output_item.icon), icon_state = initial(stored_recipe.output_item.icon_state))
		new_image.color = return_color_from_string(initial(crossbreed.colour))
		if(initial(crossbreed.colour) == "rainbow")
			new_image.rainbow_effect()
		base_choices |= list("[initial(stored_recipe.output_item.name)]" = new_image)
		cross_breed_choices |= list("[initial(stored_recipe.output_item.name)]" = list())

		for(var/datum/compressor_recipe/subtype as anything in subtypesof(listed))
			var/datum/compressor_recipe/subtype_stored = new subtype
			var/obj/item/slimecross/subtype_breed = subtype_stored.output_item
			var/image/subtype_image = image(icon = initial(subtype_stored.output_item.icon), icon_state = initial(subtype_stored.output_item.icon_state))
			subtype_image.color = return_color_from_string(initial(subtype_breed.colour))
			if(initial(subtype_breed.colour) == "rainbow")
				subtype_image.rainbow_effect()

			cross_breed_choices["[initial(stored_recipe.output_item.name)]"] |= list("[initial(subtype_breed.colour)] [initial(subtype_stored.output_item.name)]" = subtype_image)
			choice_to_datum |= list("[initial(subtype_breed.colour)] [initial(subtype_stored.output_item.name)]" = subtype_stored)

	register_context()

/obj/machinery/slime_compressor/examine(mob/living/user)
	. = ..()
	if (!current_recipe)
		return
	if (base_complete && cross_complete)
		. += span_notice("The extract is ready to be made!")
		return
	. += span_notice("The recipe requires:")
	if (!base_complete)
		. += span_notice("[base_slime_required.name] slime as base.")
	if (!cross_complete)
		. += span_notice("[cross_slime_required.name] slime for cross.")

/obj/machinery/slime_compressor/proc/clear_recipe()
	current_recipe = null
	base_complete = FALSE
	cross_complete = FALSE

/obj/machinery/slime_compressor/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	if(current_recipe)
		context[SCREENTIP_CONTEXT_RMB] = "Cancel current recipe"
	else
		context[SCREENTIP_CONTEXT_LMB] = "Select a crossbreed to make"
	return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/slime_compressor/attack_hand(mob/living/user, list/modifiers)
	if(. || !can_interact(user))
		return
	if(!anchored)
		balloon_alert(user, "unanchored!")
		return TRUE
	if(!current_recipe)
		if (change_recipe(user))
			return TRUE
	if (!base_complete || !cross_complete)
		return TRUE
	compress_recipe()

/obj/machinery/slime_compressor/attack_hand_secondary(mob/living/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN || !can_interact(user))
		return
	. = SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(!current_recipe)
		return
	if(active)
		return

	clear_recipe()

	balloon_alert_to_viewers("cancelled recipe")
	remove_mobs_inside()

// Changing the recipe
/obj/machinery/slime_compressor/proc/change_recipe(mob/user)
	var/choice
	var/base_choice = show_radial_menu(user, src, base_choices, require_near = TRUE, tooltips = TRUE)
	if(!base_choice)
		return
	choice = show_radial_menu(user, src, cross_breed_choices[base_choice], require_near = TRUE, tooltips = TRUE)

	if(active || !(choice in choice_to_datum))
		return

	current_recipe = choice_to_datum[choice]
	base_slime_required = current_recipe.base_slime_color
	cross_slime_required = current_recipe.cross_slime_color

	base_complete = FALSE
	cross_complete = FALSE

	balloon_alert_to_viewers("set extract recipe")
	remove_mobs_inside()

/obj/machinery/slime_compressor/proc/remove_mobs_inside()
	for (var/victim in mobs_inside)
		var/mob/living/slime = victim
		slime.forceMove(get_turf(src))

// On hit we check if mob is a slime
// Then we do check_recipe(), and if it passes, complete part of the recipe
// After, we move the mob inside
/obj/machinery/slime_compressor/hitby(atom/movable/hit_by, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	if (active)
		return
	var/mob/living/victim = hit_by
	if (isslime(victim))
		if (!current_recipe)
			return ..()
		var/mob/living/basic/slime/slime = victim
		if(!check_recipe(slime))
			return
		mobs_inside |= slime
		slime.forceMove(src)
		return
	return ..()

// Check if the slime fits the recipe we have set
/obj/machinery/slime_compressor/proc/check_recipe(mob/living/basic/slime/slime)
	// Cleaner slimes split very fast so it would make it...too easy
	for(var/datum/slime_trait/trait in slime.slime_traits)
		if (istype(trait,/datum/slime_trait/cleaner))
			return FALSE
	var/datum/slime_color/color = slime.current_color
	if(istype(color, base_slime_required) && !base_complete)
		base_complete = TRUE
		return TRUE
	else if (istype (color, cross_slime_required) && !cross_complete)
		cross_complete = TRUE
		return TRUE
	return FALSE

// Set machine to active and start compressing process
/obj/machinery/slime_compressor/proc/compress_recipe()
	active = TRUE
	Shake(6, 6, compress_time)
	addtimer(CALLBACK(src, PROC_REF(finish_compressing)), compress_time)

// Finish compressing
// Deactivates machine, removes everything inside and produces the extracts
/obj/machinery/slime_compressor/proc/finish_compressing()
	new current_recipe.output_item(drop_location())
	active = FALSE
	mobs_inside = list()

	clear_recipe()

	for (var/victim in mobs_inside)
		qdel(victim)

#undef CROSSBREED_BASE_PATHS
