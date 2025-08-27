/datum/action/cooldown/arcfiend/wire_travel
	name = "Wire travel"
	desc = "Transforms your body into electricity to travel in the wires"
	button_icon = 'icons/mob/actions/arcfiend_actions.dmi'
	button_icon_state = "drain_power"

	cooldown_time = 20 SECOND
	var/is_travelling = FALSE

	power_cost = 2000
	active_power_cost = 35

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
	var/obj/structure/cable/cable = locate() in get_turf(owner)
	if (!cable)
		return
	if (!check_can_travel(cable))
		return
	if (!do_after(owner, 1 SECOND, cable))
		return
	owner.forceMove(cable)
	is_travelling = TRUE
	active = TRUE
	START_PROCESSING(SSprocessing, src)
	build_all_button_icons()

/datum/action/cooldown/arcfiend/wire_travel/process()
	. = ..()
	if (!is_travelling)
		return
	var/current_location = owner.loc
	if (!istype(current_location, /obj/structure/cable))
		DeactivatePower()
	var/obj/structure/cable/cable = current_location
	if (QDELETED(cable))
		owner.forceMove(get_turf(owner))

/datum/action/cooldown/arcfiend/wire_travel/DeactivatePower(trigger_flags)
	. = ..()
	// Move the person out
	owner.forceMove(get_turf(owner))
	is_travelling = FALSE
