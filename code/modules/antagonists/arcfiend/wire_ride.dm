/datum/action/cooldown/arcfiend/wire_travel
	name = "Wire travel"
	desc = "Transforms your body into electricity to travel in the wires"
	button_icon = 'icons/mob/actions/arcfiend_actions.dmi'
	button_icon_state = "drain_power"

	cooldown_time = 20 SECOND
	var/is_travelling = FALSE

	power_cost = 2000
	active_power_cost = 35

	var/list/wires_shown

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
	if (!isliving(owner))
		return
	var/mob/living/living_owner = owner
	var/obj/structure/cable/cable = locate() in get_turf(living_owner)
	if (!cable)
		return
	if (!check_can_travel(cable))
		return
	if (!do_after(living_owner, 1 SECOND, cable))
		return
	living_owner.forceMove(cable)
	is_travelling = TRUE
	active = TRUE
	START_PROCESSING(SSprocessing, src)
	living_owner.update_cable_vision()
	build_all_button_icons()

/datum/action/cooldown/arcfiend/wire_travel/process()
	. = ..()
	if (!is_travelling)
		return
	var/current_location = owner.loc
	if (!istype(current_location, /obj/structure/cable))
		DeactivatePower()

/datum/action/cooldown/arcfiend/wire_travel/DeactivatePower(trigger_flags)
	. = ..()
	// Move the person out
	owner.forceMove(get_turf(owner))
	is_travelling = FALSE

/mob/living/proc/update_cable_vision(full_refresh = FALSE)
	if(!isnull(ai_controller) && isnull(client))
		return

	if(isnull(client) || !istype(loc, /obj/structure/cable))
		for(var/image/current_image in cables_shown)
			client.images -= current_image
		cables_shown.len = 0
		cable_tracker = null
		for(var/atom/movable/screen/plane_master/lighting as anything in hud_used.get_true_plane_masters(LIGHTING_PLANE))
			lighting.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#4cffe7")
		for(var/atom/movable/screen/plane_master/cable_movement as anything in hud_used.get_true_plane_masters(CABLE_MOVE_IMAGES_PLANE))
			cable_movement.hide_plane(src)
		return

	for(var/atom/movable/screen/plane_master/lighting as anything in hud_used.get_true_plane_masters(LIGHTING_PLANE))
		lighting.add_atom_colour("#4cffe7", TEMPORARY_COLOUR_PRIORITY)

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
	var/list/cables_gained = entered_exited_cables[1]
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

