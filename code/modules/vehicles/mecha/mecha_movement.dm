/// Sets the direction of the mecha and all of its occcupents, required for FOV. Alternatively one could make a recursive contents registration and register topmost direction changes in the fov component
/obj/vehicle/sealed/mecha/setDir(newdir)
	. = ..()
	for(var/mob/living/occupant as anything in occupants)
		occupant.setDir(newdir)

///Called when the mech moves
/obj/vehicle/sealed/mecha/proc/on_move()
	SIGNAL_HANDLER

	collect_ore()
	play_stepsound()

///Collects ore when we move, if there is an orebox and it is functional
/obj/vehicle/sealed/mecha/proc/collect_ore()
	if(isnull(ore_box) || !HAS_TRAIT(src, TRAIT_OREBOX_FUNCTIONAL))
		return
	for(var/obj/item/stack/ore/ore in range(1, src))
		//we can reach it and it's in front of us? grab it!
		if(ore.Adjacent(src) && ((get_dir(src, ore) & dir) || ore.loc == loc))
			ore.forceMove(ore_box)

///Plays the mech step sound effect. Split from movement procs so that other mechs (HONK) can override this one specific part.
/obj/vehicle/sealed/mecha/proc/play_stepsound()
	if(mecha_flags & QUIET_STEPS)
		return
	playsound(src, stepsound, 40, TRUE)

///Disconnects air tank- air port connection on mecha move
/obj/vehicle/sealed/mecha/proc/disconnect_air()
	SIGNAL_HANDLER
	if(internal_tank.disconnect()) // Something moved us and broke connection
		to_chat(occupants, "[icon2html(src, occupants)][span_warning("Air port connection has been severed!")]")
		log_message("Lost connection to gas port.", LOG_MECHA)

// Do whatever you do to mobs to these fuckers too
/obj/vehicle/sealed/mecha/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	. = ..()
	if(.)
		return TRUE

	var/atom/movable/backup = get_spacemove_backup(movement_dir, continuous_move)
	if(backup)
		if(!istype(backup) || !movement_dir || backup.anchored || continuous_move) //get_spacemove_backup() already checks if a returned turf is solid, so we can just go
			return TRUE
		last_pushoff = world.time
		if(backup.newtonian_move(turn(movement_dir, 180), instant = TRUE))
			backup.last_pushoff = world.time
			step_silent = TRUE
			if(return_drivers())
				to_chat(occupants, "[icon2html(src, occupants)][span_info("The [src] push off [backup] to propel yourself.")]")
		return TRUE

	if(active_thrusters?.thrust(movement_dir))
		step_silent = TRUE
		return TRUE
	return FALSE

///Called when the driver turns with the movement lock key
/obj/vehicle/sealed/mecha/proc/on_turn(mob/living/driver, direction)
	SIGNAL_HANDLER
	return COMSIG_IGNORE_MOVEMENT_LOCK

/obj/vehicle/sealed/mecha/relaymove(mob/living/user, direction)
	. = TRUE
	if(!canmove || !(user in return_drivers()))
		return
	if (!vehicle_move(direction))
		return
	SEND_SIGNAL(user, COMSIG_MOB_DROVE_MECH, src)

/obj/vehicle/sealed/mecha/vehicle_move(direction, forcerotate = FALSE)
	if(!COOLDOWN_FINISHED(src, cooldown_vehicle_move))
		return FALSE
	COOLDOWN_START(src, cooldown_vehicle_move, get_movedelay())
	if(completely_disabled)
		return FALSE
	if(!direction)
		return FALSE
	if(internal_tank?.connected_port)
		if(!TIMER_COOLDOWN_CHECK(src, COOLDOWN_MECHA_MESSAGE))
			to_chat(occupants, "[icon2html(src, occupants)][span_warning("Unable to move while connected to the air system port!")]")
			TIMER_COOLDOWN_START(src, COOLDOWN_MECHA_MESSAGE, 2 SECONDS)
		return FALSE
	if(construction_state)
		if(!TIMER_COOLDOWN_CHECK(src, COOLDOWN_MECHA_MESSAGE))
			to_chat(occupants, "[icon2html(src, occupants)][span_danger("Maintenance protocols in effect.")]")
			TIMER_COOLDOWN_START(src, COOLDOWN_MECHA_MESSAGE, 2 SECONDS)
		return FALSE

	if(!Process_Spacemove(direction))
		return FALSE
	if(zoom_mode)
		if(!TIMER_COOLDOWN_CHECK(src, COOLDOWN_MECHA_MESSAGE))
			to_chat(occupants, "[icon2html(src, occupants)][span_warning("Unable to move while in zoom mode!")]")
			TIMER_COOLDOWN_START(src, COOLDOWN_MECHA_MESSAGE, 2 SECONDS)
		return FALSE
	if(!cell)
		if(!TIMER_COOLDOWN_CHECK(src, COOLDOWN_MECHA_MESSAGE))
			to_chat(occupants, "[icon2html(src, occupants)][span_warning("Missing power cell.")]")
			TIMER_COOLDOWN_START(src, COOLDOWN_MECHA_MESSAGE, 2 SECONDS)
		return FALSE
	if(!scanmod || !capacitor)
		if(!TIMER_COOLDOWN_CHECK(src, COOLDOWN_MECHA_MESSAGE))
			to_chat(occupants, "[icon2html(src, occupants)][span_warning("Missing [scanmod? "capacitor" : "scanning module"].")]")
			TIMER_COOLDOWN_START(src, COOLDOWN_MECHA_MESSAGE, 2 SECONDS)
		return FALSE
	if(!use_power(step_energy_drain))
		if(!TIMER_COOLDOWN_CHECK(src, COOLDOWN_MECHA_MESSAGE))
			to_chat(occupants, "[icon2html(src, occupants)][span_warning("Insufficient power to move!")]")
			TIMER_COOLDOWN_START(src, COOLDOWN_MECHA_MESSAGE, 2 SECONDS)
		return FALSE
	if(lavaland_only && is_mining_level(z))
		if(!TIMER_COOLDOWN_CHECK(src, COOLDOWN_MECHA_MESSAGE))
			to_chat(occupants, "[icon2html(src, occupants)][span_warning("Invalid Environment.")]")
			TIMER_COOLDOWN_START(src, COOLDOWN_MECHA_MESSAGE, 2 SECONDS)
		return FALSE

	var/olddir = dir

	if(internal_damage & MECHA_INT_CONTROL_LOST)
		direction = pick(GLOB.alldirs)

	//only mechs with diagonal movement may move diagonally
	if(!allow_diagonal_movement && ISDIAGONALDIR(direction))
		return TRUE

	var/keyheld = FALSE
	if(strafe)
		for(var/mob/driver as anything in return_drivers())
			if(driver.client?.keys_held["Alt"])
				keyheld = TRUE
				break

	//if we're not facing the way we're going rotate us
	if(dir != direction && (!strafe || forcerotate || keyheld))
		if(dir != direction && !(mecha_flags & QUIET_TURNS) && !step_silent)
			playsound(src,turnsound,40,TRUE)
		setDir(direction)
		if(keyheld || !pivot_step) //If we pivot step, we don't return here so we don't just come to a stop
			return TRUE

	set_glide_size(DELAY_TO_GLIDE_SIZE(get_movedelay()))
	//Otherwise just walk normally
	. = try_step_multiz(direction)
	if(phasing)
		use_power(phasing_energy_drain)
	if(strafe)
		setDir(olddir)

/obj/vehicle/sealed/mecha/Bump(atom/obstacle)
	. = ..()
	if(phasing) //Theres only one cause for phasing canpass fails
		to_chat(occupants, "[icon2html(src, occupants)][span_warning("A dull, universal force is preventing you from [phasing] here!")]")
		spark_system.start()
		return
	if(.) //mech was thrown/door/whatever
		return
	if(bumpsmash) //Need a pilot to push the PUNCH button.
		if(COOLDOWN_FINISHED(src, mecha_bump_smash))
			var/list/mob/mobster = return_drivers()
			obstacle.mech_melee_attack(src, mobster[1])
			COOLDOWN_START(src, mecha_bump_smash, smashcooldown)
			if(!obstacle || obstacle.CanPass(src, get_dir(obstacle, src) || dir)) // The else is in case the obstacle is in the same turf.
				step(src,dir)
	if(isobj(obstacle))
		var/obj/obj_obstacle = obstacle
		if(!obj_obstacle.anchored && obj_obstacle.move_resist <= move_force)
			step(obstacle, dir)
	else if(ismob(obstacle))
		var/mob/mob_obstacle = obstacle
		if(mob_obstacle.move_resist <= move_force)
			step(obstacle, dir)

//Following procs are camera static update related and are basically ripped off of code\modules\mob\living\silicon\silicon_movement.dm

//We only call a camera static update if we have successfully moved and have a camera installed
/obj/vehicle/sealed/mecha/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	if(chassis_camera)
		update_camera_location(old_loc)

/obj/vehicle/sealed/mecha/proc/update_camera_location(oldLoc)
	oldLoc = get_turf(oldLoc)
	if(!updating && oldLoc != get_turf(src))
		updating = TRUE
		do_camera_update(oldLoc)

///The static update delay on movement of the camera in a mech we use
#define MECH_CAMERA_BUFFER 0.5 SECONDS

/**
 * The actual update - also passes our unique update buffer. This makes our static update faster than stationary cameras,
 * helping us to avoid running out of the camera's FoV. An EMPd mecha with a lowered view_range on its camera can still
 * sometimes run out into static before updating, however.
*/
/obj/vehicle/sealed/mecha/proc/do_camera_update(oldLoc)
	if(oldLoc != get_turf(src))
		GLOB.cameranet.updatePortableCamera(chassis_camera, MECH_CAMERA_BUFFER)
	updating = FALSE
#undef MECH_CAMERA_BUFFER

/obj/vehicle/sealed/mecha/proc/get_movedelay()
	var/tally = 0

	if(LAZYLEN(flat_equipment))
		for(var/obj/item/mecha_parts/mecha_equipment/ME in flat_equipment)
			if(ME.get_movedelay())
				tally += ME.get_movedelay()

		if(tally <= encumbrance_gap)	// If the total is less than our encumbrance gap, ignore equipment weight.
			tally = 0
		else	// Otherwise, start the tally after cutting that gap out.
			tally -= encumbrance_gap

	if(leg_overload_mode)	// At the end, because this would normally just make the mech *slower* since tally wasn't starting at 0.
		tally = min(1, round(tally/2))

//	return max(1, round(tally, 0.1))	// Round the total to the nearest 10th. Can't go lower than 1 tick. Even humans have a delay longer than that.
	return movedelay + round(tally, 0.1)
