/obj/machinery/slime_compressor
	name = "slime compressor"
	desc = "Machine used to compress slimes into bases for crossbreed extracts."

	icon = 'monkestation/code/modules/slimecore/icons/slime_grinder.dmi'
	icon_state = "slime_grinder_backdrop"
	base_icon_state = "slime_grinder_backdrop"

	use_power = IDLE_POWER_USE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION

	var/grind_time = 5 SECONDS
	///this is the face you see when you start grinding the poor slime up
	var/mob/living/basic/slime/poster_boy
	///list of all the slimes we have
	var/list/mobs_inside = list()
	///are we grinding some slimes
	var/active = FALSE
	/// What mobs can go inside the compressor. Initially only slimes
	var/list/mob_whitelist = list(/mob/living/basic/slime)

/obj/machinery/slime_compressor/attack_hand(mob/living/user, list/modifiers)
	Shake(6, 6, 10 SECONDS)
	do_compress()

/obj/machinery/slime_compressor/hitby(atom/movable/hit_by, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	if (active)
		return
	for(hit_by as anything in mob_whitelist)
		if(!poster_boy)
			poster_boy = hit_by
			poster_boy.layer = layer
			poster_boy.plane = plane
		hit_by.update_appearance()
		mobs_inside |= hit_by
		hit_by.forceMove(src)
		update_appearance()
		return // Stops slime from actually hitting the machine
	return ..() // If it is anything else handle being hit normally.

/obj/machinery/slime_compressor/update_overlays()
	. = ..()
	if(poster_boy)
		var/mutable_appearance/slime = poster_boy.appearance
		. += slime
	. += mutable_appearance(icon, "slime_grinder_overlay", layer + 0.1, src)

/obj/machinery/slime_compressor/proc/do_compress()
	poster_boy = null
	update_appearance()
	for(var/mob/living/victim as anything in mobs_inside)
		if (isslime(victim))
			var/mob/living/basic/slime/slime = victim
			var/datum/slime_color/current_color = slime.current_color
			mobs_inside -= slime
			qdel(slime)
	mobs_inside = list()
