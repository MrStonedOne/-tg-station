/obj/effect/proc_holder/spell/targeted/shapeshift
	name = "Shapechange"
	desc = "Take on the shape of another for a time to use their natural abilities. Once you've made your choice it cannot be changed."
	clothes_req = 0
	human_req = 0
	charge_max = 200
	cooldown_min = 50
	range = -1
	include_user = 1
	invocation = "RAC'WA NO!"
	invocation_type = "shout"
	action_icon_state = "shapeshift"

	var/revert_on_death = TRUE
	var/die_with_shapeshifted_form = TRUE

	var/shapeshift_type
	var/list/possible_shapes = list(/mob/living/simple_animal/mouse,\
		/mob/living/simple_animal/pet/dog/corgi,\
		/mob/living/simple_animal/hostile/carp/ranged/chaos,\
		/mob/living/simple_animal/bot/ed209,\
		/mob/living/simple_animal/hostile/poison/giant_spider/hunter/viper,\
		/mob/living/simple_animal/hostile/construct/armored)

/obj/effect/proc_holder/spell/targeted/shapeshift/cast(list/targets,mob/user = usr)
	procstart = null
	src.procstart = null
	if(src in user.mob_spell_list)
		user.mob_spell_list.Remove(src)
		user.mind.AddSpell(src)
	if(user.buckled)
		user.buckled.unbuckle_mob(src,force=TRUE)
	for(var/mob/living/M in targets)
		if(!shapeshift_type)
			var/list/animal_list = list()
			for(var/path in possible_shapes)
				var/mob/living/simple_animal/A = path
				animal_list[initial(A.name)] = path
			var/new_shapeshift_type = input(M, "Choose Your Animal Form!", "It's Morphing Time!", null) as null|anything in animal_list
			if(shapeshift_type)
				return
			shapeshift_type = new_shapeshift_type
			if(!shapeshift_type) //If you aren't gonna decide I am!
				shapeshift_type = pick(animal_list)
			shapeshift_type = animal_list[shapeshift_type]
		
		var/obj/shapeshift_holder/S = locate() in M
		if(S)
			Restore(M)
		else
			Shapeshift(M)


/obj/effect/proc_holder/spell/targeted/shapeshift/proc/Shapeshift(mob/living/caster)
	procstart = null
	src.procstart = null
	var/obj/shapeshift_holder/H = locate() in caster
	if(H)
		to_chat(caster, "<span class='warning'>You're already shapeshifted!</span>")
		return

	var/mob/living/shape = new shapeshift_type(caster.loc)
	H = new(shape,src,caster)

	clothes_req = 0
	human_req = 0

/obj/effect/proc_holder/spell/targeted/shapeshift/proc/Restore(mob/living/shape)
	procstart = null
	src.procstart = null
	var/obj/shapeshift_holder/H = locate() in shape
	if(!H)
		return
	
	H.restore()

	clothes_req = initial(clothes_req)
	human_req = initial(human_req)

/obj/effect/proc_holder/spell/targeted/shapeshift/dragon
	name = "Dragon Form"
	desc = "Take on the shape a lesser ash drake."
	invocation = "RAAAAAAAAWR!"

	shapeshift_type = /mob/living/simple_animal/hostile/megafauna/dragon/lesser


/obj/shapeshift_holder
	name = "Shapeshift holder"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ON_FIRE | UNACIDABLE | ACID_PROOF
	var/mob/living/stored
	var/mob/living/shape
	var/restoring = FALSE
	var/datum/soullink/shapeshift/slink
	var/obj/effect/proc_holder/spell/targeted/shapeshift/source

/obj/shapeshift_holder/Initialize(mapload,obj/effect/proc_holder/spell/targeted/shapeshift/source,mob/living/caster)
	procstart = null
	src.procstart = null
	. = ..()
	src.source = source
	shape = loc
	if(!istype(shape))
		CRASH("shapeshift holder created outside mob/living")
	stored = caster
	if(stored.mind)
		stored.mind.transfer_to(shape)
	stored.forceMove(src)
	stored.notransform = TRUE
	slink = soullink(/datum/soullink/shapeshift, stored , shape)
	slink.source = src

/obj/shapeshift_holder/Destroy()
	procstart = null
	src.procstart = null
	if(!restoring)
		restore()
	stored = null
	shape = null
	. = ..()

/obj/shapeshift_holder/Moved()
	procstart = null
	src.procstart = null
	. = ..()
	if(!restoring || QDELETED(src))
		restore()

/obj/shapeshift_holder/handle_atom_del(atom/A)
	procstart = null
	src.procstart = null
	if(A == stored && !restoring)
		restore()

/obj/shapeshift_holder/Exited(atom/movable/AM)
	procstart = null
	src.procstart = null
	if(AM == stored && !restoring)
		restore()

/obj/shapeshift_holder/proc/casterDeath()
	procstart = null
	src.procstart = null
	//Something kills the stored caster through direct damage.
	if(source.revert_on_death)
		restore(death=TRUE)
	else
		shape.death()

/obj/shapeshift_holder/proc/shapeDeath()
	procstart = null
	src.procstart = null
	//Shape dies.
	if(source.die_with_shapeshifted_form)
		if(source.revert_on_death)
			restore(death=TRUE)
	else
		restore()

/obj/shapeshift_holder/proc/restore(death=FALSE)
	procstart = null
	src.procstart = null
	restoring = TRUE
	qdel(slink)
	stored.forceMove(get_turf(src))
	stored.notransform = FALSE
	if(shape.mind)
		shape.mind.transfer_to(stored)
	if(death)
		stored.death()
	qdel(shape)
	qdel(src)

/datum/soullink/shapeshift
	var/obj/shapeshift_holder/source

/datum/soullink/shapeshift/ownerDies(gibbed, mob/living/owner)
	procstart = null
	src.procstart = null
	if(source)
		source.casterDeath(gibbed)

/datum/soullink/shapeshift/sharerDies(gibbed, mob/living/sharer)
	procstart = null
	src.procstart = null
	if(source)
		source.shapeDeath(gibbed)