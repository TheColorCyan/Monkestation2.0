#define CROSSBREED_BASE_PATHS_1 list(\
/datum/compressor_recipe/crossbreed/burning,\
/datum/compressor_recipe/crossbreed/charged,\
/datum/compressor_recipe/crossbreed/chilling,\
/datum/compressor_recipe/crossbreed/consuming,\
/datum/compressor_recipe/crossbreed/industrial,\
/datum/compressor_recipe/crossbreed/prismatic,\
/datum/compressor_recipe/crossbreed/regenerative,\
/datum/compressor_recipe/crossbreed/reproductive,\
/datum/compressor_recipe/crossbreed/selfsustaining,\
/datum/compressor_recipe/crossbreed/stabilized,\
)

/obj/machinery/slime_compressor
	name = "slime compressor"
	desc = "Machine used to compress slimes into bases for crossbreed extracts."

	icon = 'monkestation/code/modules/slimecore/icons/slime_grinder.dmi'
	icon_state = "slime_grinder_backdrop"
	base_icon_state = "slime_grinder_backdrop"

	use_power = IDLE_POWER_USE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION
	anchored = TRUE
	density = TRUE

	var/grind_time = 5 SECONDS
	///list of all the slimes we have
	var/list/mobs_inside = list()
	///are we grinding some slimes
	var/active = FALSE
	/// What mobs can go inside the compressor. Initially only slimes
	var/list/mob_whitelist = list(/mob/living/basic/slime)
	/// Recipes we can choose from
	var/static/list/base_choices = list()
	var/static/list/cross_breed_choices = list()
	/// Recipe we have currently set
	var/datum/compressor_recipe/crossbreed/current_recipe
	/// What slimes we need for the recipe
	var/list/slimes_for_recipe = list()
	var/static/list/choice_to_datum = list()

/obj/machinery/slime_compressor/Initialize(mapload)
	. = ..()
	if(length(cross_breed_choices))
		return
	for(var/datum/compressor_recipe/listed as anything in CROSSBREED_BASE_PATHS_1)
		var/datum/compressor_recipe/stored_recipe = new listed
		var/obj/item/slimecross/crossbreed = stored_recipe.output_item
		var/image/new_image = image(icon = initial(stored_recipe.output_item.icon), icon_state = initial(stored_recipe.output_item.icon_state))
		if(initial(crossbreed.colour) == "rainbow")
			new_image.rainbow_effect()
		base_choices |= list("[initial(stored_recipe.output_item.name)]" = new_image)
		cross_breed_choices |= list("[initial(stored_recipe.output_item.name)]" = list())

		for(var/datum/compressor_recipe/subtype as anything in subtypesof(listed))
			var/datum/compressor_recipe/subtype_stored = new subtype
			var/obj/item/slimecross/subtype_breed = subtype_stored.output_item
			var/image/subtype_image = image(icon = initial(subtype_stored.output_item.icon), icon_state = initial(subtype_stored.output_item.icon_state))
			if(initial(subtype_breed.colour) == "rainbow")
				subtype_image.rainbow_effect()

			cross_breed_choices["[initial(stored_recipe.output_item.name)]"] |= list("[initial(subtype_breed.colour)] [initial(subtype_stored.output_item.name)]" = subtype_image)
			choice_to_datum |= list("[initial(subtype_breed.colour)] [initial(subtype_stored.output_item.name)]" = subtype_stored)

	register_context()

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
		if(change_recipe(user))
			return TRUE
	// Check if we have all slimes needed to make the extract
	// If we need one more of the components, break
	var/component_check = TRUE
	for(var/needed_color in slimes_for_recipe)
		if(slimes_for_recipe[needed_color] > 0)
			component_check = FALSE
			break
	if(component_check)
		compress_recipe()

/obj/machinery/slime_compressor/proc/change_recipe(mob/user, cross_breed = FALSE)
	var/choice
	var/base_choice = show_radial_menu(user, src, base_choices, require_near = TRUE, tooltips = TRUE)
	if(!base_choice)
		return
	choice = show_radial_menu(user, src, cross_breed_choices[base_choice], require_near = TRUE, tooltips = TRUE)

	if(active || !(choice in choice_to_datum))
		return

	current_recipe = choice_to_datum[choice]
	slimes_for_recipe = current_recipe.required_slimes.Copy()
	balloon_alert_to_viewers("set extract recipe")

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
	return ..() // If it is anything else handle being hit normally.

/obj/machinery/slime_compressor/proc/check_recipe(var/mob/living/basic/slime/slime)
	for(var/needed_color in slimes_for_recipe)
		var/datum/slime_color/color = slime.current_color
		if (istype(color, needed_color))
			slimes_for_recipe[needed_color]--
			return TRUE
		else
			continue
	return FALSE

/obj/machinery/slime_compressor/proc/compress_recipe()
	active = TRUE
	Shake(6, 6, 3 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(finish_compressing)), 3 SECONDS)

/obj/machinery/slime_compressor/proc/finish_compressing()
	for(var/i in 1 to current_recipe.created_amount)
		new current_recipe.output_item(drop_location())
	active = FALSE
	mobs_inside = list()
	current_recipe = null
