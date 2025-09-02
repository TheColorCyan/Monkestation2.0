/**
 * Wire travel ability for Arcfiends
 * Movement in cables itself is handled in relaymovement() on /obj/structure/cable
 */
/datum/action/cooldown/arcfiend/wire_travel
	name = "Wire travel"
	desc = "Transforms your body into electricity to travel in the wires"
	button_icon = 'icons/mob/actions/arcfiend_actions.dmi'
	button_icon_state = "drain_power"

	cooldown_time = 20 SECOND
	power_cost = 2000
	active_power_cost = 35

	/// Effect for entering the cable
	var/obj/effect/enter_effect = /obj/effect/temp_visual/wire_travel
	/// Effect for exiting the cable
	var/obj/effect/exit_effect = /obj/effect/temp_visual/wire_travel/end

/datum/action/cooldown/arcfiend/wire_travel/proc/check_can_travel(/obj/structure/cable/target)
	if(owner.stat)
		to_chat(owner, span_warning("You must be conscious to do this!"))
		return FALSE
	if(owner.has_buckled_mobs())
		to_chat(owner, span_warning("You can't wire travel with other creatures on you!"))
		return FALSE
	if(owner.buckled)
		to_chat(owner, span_warning("You can't wire travel while buckled!"))
		return FALSE

	return TRUE

/datum/action/cooldown/arcfiend/wire_travel/ActivatePower(trigger_flags)
	// Check if our owner is living for the sake of updating cable vision
	if (!isliving(owner))
		return
	var/mob/living/living_owner = owner

	var/obj/structure/cable/cable = locate() in get_turf(living_owner)
	if (!cable)
		return
	if (!check_can_travel(cable))
		return
	// We do a do_after
	// Failing the do_after doesn't put our ability on cooldown
	if (!do_after(living_owner, 1 SECOND, cable))
		return
	living_owner.forceMove(cable)
	active = TRUE
	START_PROCESSING(SSprocessing, src)
	living_owner.update_cable_vision()
	start_wire_travel()
	build_all_button_icons()

/datum/action/cooldown/arcfiend/wire_travel/process()
	. = ..()
	var/current_location = owner.loc
	if (!istype(current_location, /obj/structure/cable || !HAS_TRAIT(owner, TRAIT_MOVE_CABLE)))
		DeactivatePower()

/datum/action/cooldown/arcfiend/wire_travel/proc/start_wire_travel()
	// Handle effects
	var/turf/enter_turf = get_turf(owner)
	new enter_effect(enter_turf)
	ADD_TRAIT(owner, TRAIT_MOVE_CABLE, CABLE_MOVEMENT_TRAIT)

/datum/action/cooldown/arcfiend/wire_travel/proc/end_wire_travel()
	// Handle effects
	var/turf/exit_turf = get_turf(owner)
	new exit_effect(exit_turf, owner.dir)
	REMOVE_TRAIT(owner, TRAIT_MOVE_CABLE, CABLE_MOVEMENT_TRAIT)

/datum/action/cooldown/arcfiend/wire_travel/DeactivatePower(trigger_flags)
	. = ..()
	// Move the person out after a do_after, so they have time to react
	end_wire_travel()
	owner.forceMove(get_turf(owner))

/**
 * Proc related to cable vision while moving inside of cable
 * Similar proc to one used in ventcrawling
 */
/mob/living/proc/update_cable_vision(full_refresh = FALSE)
	if(!isnull(ai_controller) && isnull(client))
		return

	// Hide the plane if we aren't moving in the cables
	if(isnull(client) || !istype(loc, /obj/structure/cable || !HAS_TRAIT(src, TRAIT_MOVE_CABLE)))
		for(var/image/current_image in cables_shown)
			client.images -= current_image
		cables_shown.len = 0
		cable_tracker = null
		for(var/atom/movable/screen/plane_master/lighting as anything in hud_used.get_true_plane_masters(LIGHTING_PLANE))
			lighting.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#ffdc40")
		for(var/atom/movable/screen/plane_master/cable_movement as anything in hud_used.get_true_plane_masters(CABLE_MOVE_IMAGES_PLANE))
			cable_movement.hide_plane(src)
		return

	// Cool yellow color
	for(var/atom/movable/screen/plane_master/lighting as anything in hud_used.get_true_plane_masters(LIGHTING_PLANE))
		lighting.add_atom_colour("#ffdc40", TEMPORARY_COLOUR_PRIORITY)

	for(var/atom/movable/screen/plane_master/cable_movement as anything in hud_used.get_true_plane_masters(CABLE_MOVE_IMAGES_PLANE))
		cable_movement.unhide_plane(src)

	if(full_refresh)
		for(var/image/current_image in cables_shown)
			client.images -= current_image
		cables_shown.len = 0
		cable_tracker = null

	if(!cable_tracker)
		cable_tracker = new()

	var/turf/our_turf = get_turf(src)

	var/list/view_range = getviewsize(client.view)
	cable_tracker.set_bounds(view_range[1] + 1, view_range[2] + 1)

	var/list/entered_exited_cables = cable_tracker.recalculate_type_members(our_turf, SPATIAL_GRID_CONTENTS_TYPE_CABLE)
	// All cables that entered our view
	var/list/cables_gained = entered_exited_cables[1]
	// All cables that went out of our sight
	var/list/cables_lost = entered_exited_cables[2]

	for(var/obj/structure/cable/cable as anything in cables_lost)
		if(!cable.cable_vision_img)
			continue
		client.images -= cable.cable_vision_img
		cables_shown -= cable.cable_vision_img

	for(var/obj/structure/cable/cable as anything in cables_gained)
		if(!cable.cable_vision_img)
			var/turf/their_turf = get_turf(cable)
			cable.cable_vision_img = image(cable, cable.loc, dir = cable.dir)
			SET_PLANE(cable.cable_vision_img, CABLE_MOVE_IMAGES_PLANE, their_turf)
		client.images += cable.cable_vision_img
		cables_shown += cable.cable_vision_img

