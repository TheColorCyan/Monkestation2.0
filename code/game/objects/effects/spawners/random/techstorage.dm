// Tech storage circuit board spawners
/obj/effect/spawner/random/techstorage
	name = "generic circuit board spawner"
	icon_state = "circuit"
	spawn_loot_split = TRUE
	spawn_all_loot = TRUE

/obj/effect/spawner/random/techstorage/data_disk
	name = "data disk spawner"
	icon_state = "disk"
	spawn_all_loot = FALSE
	loot = list(
		/obj/item/disk/data = 49,
		/obj/item/disk/data/random = 5, // monkestation edit: add random dna data disks (this is a weighted list, it does NOT have to add up to 50 lol)
		/obj/item/disk/nuclear/fake/obvious = 1,
	)

/obj/effect/spawner/random/techstorage/arcade_boards
	name = "arcade board spawner"
	spawn_all_loot = FALSE
	spawn_loot_count = 1
	loot = list(
		/obj/item/circuitboard/computer/arcade/amputation,
		/obj/item/circuitboard/computer/arcade/battle,
		/obj/item/circuitboard/computer/arcade/orion_trail,
	)

/obj/effect/spawner/random/techstorage/service_all
	name = "service circuit board spawner"
	loot = list(
		/obj/item/circuitboard/computer/arcade/battle,
		/obj/item/circuitboard/computer/arcade/orion_trail,
		/obj/item/circuitboard/machine/autolathe,
		/obj/item/circuitboard/computer/mining,
		/obj/item/circuitboard/machine/ore_redemption,
		/obj/item/circuitboard/computer/order_console/mining,
		/obj/item/circuitboard/machine/microwave,
		/obj/item/circuitboard/machine/deep_fryer,
		/obj/item/circuitboard/machine/griddle,
		/obj/item/circuitboard/machine/reagentgrinder,
		/obj/item/circuitboard/machine/oven,
		/obj/item/circuitboard/machine/stove,
		/obj/item/circuitboard/machine/processor,
		/obj/item/circuitboard/machine/gibber,
		/obj/item/circuitboard/machine/chem_dispenser/drinks,
		/obj/item/circuitboard/machine/chem_dispenser/drinks/beer,
		/obj/item/circuitboard/computer/slot_machine,
		// monkestation start: botany stuff
		/obj/item/circuitboard/machine/composters,
		/obj/item/circuitboard/machine/plantgenes,
		/obj/item/circuitboard/machine/biogenerator,
		/obj/item/circuitboard/machine/splicer,
		/obj/item/circuitboard/machine/hydroponics,
		/obj/item/circuitboard/machine/seed_extractor,
		/obj/item/circuitboard/machine/chicken_grinder,
		/obj/item/circuitboard/machine/feed_machine,
		// monkestation end
	)

/obj/effect/spawner/random/techstorage/rnd_all
	name = "RnD circuit board spawner"
	loot = list(
		/obj/item/circuitboard/computer/aifixer,
		/obj/item/circuitboard/machine/rdserver,
		/obj/item/circuitboard/machine/mechfab,
		/obj/item/circuitboard/machine/circuit_imprinter/department,
		/obj/item/circuitboard/computer/teleporter,
		/obj/item/circuitboard/machine/destructive_analyzer,
		/obj/item/circuitboard/computer/rdconsole,
		/obj/item/circuitboard/computer/nanite_chamber_control,
		/obj/item/circuitboard/computer/nanite_cloud_controller,
		/obj/item/circuitboard/machine/nanite_chamber,
		/obj/item/circuitboard/machine/nanite_programmer,
		/obj/item/circuitboard/machine/nanite_program_hub,
		/obj/item/circuitboard/computer/dna_console,
		/obj/item/circuitboard/machine/dnascanner,
		/obj/item/circuitboard/machine/dna_infuser,
	)

/obj/effect/spawner/random/techstorage/security_all
	name = "security circuit board spawner"
	loot = list(
		/obj/item/circuitboard/computer/secure_data,
		/obj/item/circuitboard/computer/security,
		/obj/item/circuitboard/computer/prisoner,
	)

/obj/effect/spawner/random/techstorage/engineering_all
	name = "engineering circuit board spawner"
	loot = list(
		/obj/item/circuitboard/computer/atmos_alert,
		/obj/item/circuitboard/computer/stationalert,
		/obj/item/circuitboard/computer/powermonitor,
	)

/obj/effect/spawner/random/techstorage/tcomms_all
	name = "tcomms circuit board spawner"
	loot = list(
		/obj/item/circuitboard/computer/message_monitor,
		/obj/item/circuitboard/machine/telecomms/broadcaster,
		/obj/item/circuitboard/machine/telecomms/bus,
		/obj/item/circuitboard/machine/telecomms/server,
		/obj/item/circuitboard/machine/telecomms/receiver,
		/obj/item/circuitboard/machine/telecomms/processor,
		/obj/item/circuitboard/machine/announcement_system,
		/obj/item/circuitboard/computer/comm_server,
		/obj/item/circuitboard/computer/comm_monitor,
	)

/obj/effect/spawner/random/techstorage/medical_all
	name = "medical circuit board spawner"
	loot = list(
		/obj/item/circuitboard/machine/chem_dispenser,
		/obj/item/circuitboard/computer/med_data,
		/obj/item/circuitboard/machine/smoke_machine,
		/obj/item/circuitboard/machine/chem_master,
		/obj/item/circuitboard/machine/diseaseanalyser, // MONKESTATION EDIT START: FUCK THE PANDEMIC. -dexee, 4/26/24
		/obj/item/circuitboard/computer/diseasesplicer,
		/obj/item/circuitboard/machine/centrifuge,
		/obj/item/circuitboard/computer/pathology_data,
		/obj/item/circuitboard/machine/incubator,
	//	/obj/item/circuitboard/computer/pandemic, // MONKESTATION EDIT END: fuck the pandemic. we have better disease machines
	)

/obj/effect/spawner/random/techstorage/ai_all
	name = "secure AI circuit board spawner"
	loot = list(
		/obj/item/circuitboard/computer/aiupload,
		/obj/item/circuitboard/computer/borgupload,
		/obj/item/circuitboard/aicore,
	)

/obj/effect/spawner/random/techstorage/command_all
	name = "secure command circuit board spawner"
	loot = list(
		/obj/item/circuitboard/computer/crew,
		/obj/item/circuitboard/computer/communications,
	)

/obj/effect/spawner/random/techstorage/rnd_secure_all
	name = "secure RnD circuit board spawner"
	loot = list(
		/obj/item/circuitboard/computer/mecha_control,
		/obj/item/circuitboard/computer/apc_control,
		/obj/item/circuitboard/computer/robotics,
	)
