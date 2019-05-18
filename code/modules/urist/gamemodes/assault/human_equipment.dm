//human

/obj/item/weapon/grenade/frag/anforgrenade
	desc = "A small explosive meant for anti-personnel use."
	name = "ANFOR grenade"
	icon = 'icons/urist/items/uristweapons.dmi'
	icon_state = "large_grenade"
	item_state = "flashbang"
	origin_tech = "materials=3;magnets=3"

///obj/item/weapon/grenade/anforgrenade/detonate()
//	explosion(src.loc, 0, 0, 2, 2)
//	qdel(src)

/obj/item/weapon/storage/box/anforgrenade
	name = "box of frag grenades (WARNING)"
	desc = "<B>WARNING: These devices are extremely dangerous and can cause cause death within a short radius.</B>"
	icon_state = "flashbang"
	startswith = list(/obj/item/weapon/grenade/frag/anforgrenade = 5)

/obj/item/weapon/mine/frag
	name = "frag mine"
	desc = "A frag mine. Press the button to set it up and move the fuck away."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "uglymine" //should probably ask olly or nien for a better sprite

/obj/item/weapon/mine/attack_self(mob/user as mob)
	var/obj/effect/mine/frag/M = new /obj/effect/mine/frag(user.loc)
	M.overlays += image('icons/urist/jungle/turfs.dmi', "exclamation", layer=3.1)
	user.visible_message("<span class='warning'>[user] arms the mine! Be careful not to step on it!</span>","<span_class='warning'>You arm the mine and lay it on the floor. Be careful not to step on it!</span>")
	qdel(src)
	user.regenerate_icons()
	spawn(35)
		M.overlays -= image('icons/urist/jungle/turfs.dmi', "exclamation", layer=3.1)

/obj/item/weapon/storage/box/large/mines
	name = "box of frag mines (WARNING)"
	desc = "<B>WARNING: These devices are extremely dangerous and can cause death within a short radius.</B>"
	icon_state = "flashbang"
	startswith = list(/obj/item/weapon/mine/frag = 3)

/obj/effect/mine/proc/explode2(obj)
	/* oldcode, pre-fragification -scr
	explosion(loc, 0, 0, 2, 2)
	spawn(1)
		qdel(src)*/
	//vars stolen for fragification
	var/fragment_type = /obj/item/projectile/bullet/pellet/fragment
	var/num_fragments = 72  //total number of fragments produced by the grenade
	//The radius of the circle used to launch projectiles. Lower values mean less projectiles are used but if set too low gaps may appear in the spread pattern
	var/spread_range = 7 //leave as is, for some reason setting this higher makes the spread pattern have gaps close to the epicenter

	//blatant copypaste from frags, but those are a whole different type so vOv
	set waitfor = 0
	..()

	var/turf/O = get_turf(src)
	if(!O) return

	var/list/target_turfs = getcircle(O, spread_range)
	var/fragments_per_projectile = round(num_fragments/target_turfs.len)

	for(var/turf/T in target_turfs)
		sleep(0)
		var/obj/item/projectile/bullet/pellet/fragment/P = new fragment_type(O)

		P.pellets = fragments_per_projectile
		P.shot_from = src.name

		P.launch(T)

		//Make sure to hit any mobs in the source turf
		for(var/mob/living/M in O)
			//lying on a frag grenade while the grenade is on the ground causes you to absorb most of the shrapnel.
			//you will most likely be dead, but others nearby will be spared the fragments that hit you instead.
			if(M.lying && isturf(src.loc))
				P.attack_mob(M, 0, 0)
			else
				P.attack_mob(M, 0, 100) //otherwise, allow a decent amount of fragments to pass

	qdel(src)

/obj/effect/mine/frag
	name = "Frag Mine"
	triggerproc = "explode2"

/obj/effect/mine/frag/attack_hand(mob/user as mob)
	user.visible_message("<span class='warning'>[user] starts to disarm the mine!</span>","<span class='warning'>You start to disarm the mine. Just stay very still.</span>")
	if (do_after(user, 30, src))
		user.visible_message("<span class='warning'>[user] disarms the mine!</span>","<span class='warning'>You disarm the mine. It's safe to pick up now!</span>")
		new /obj/item/weapon/mine/frag(src.loc)
		qdel(src)

/obj/structure/assaultshieldgen
	name = "shield generator"
	desc = "The shield generator for the station. Protect it with your life. Repair it with a welding torch."
	icon = 'icons/obj/power.dmi'
	icon_state = "bbox_on"
	var/health = 300
	var/maxhealth = 300
	anchored = 1
	density = 1

/obj/structure/assaultshieldgen/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/WT = W
		if (WT.remove_fuel(0,user))
			if(health >= maxhealth)
				user << "<span class='warning'>The shield generator is fully repaired alredy!</span>"
			else
				playsound(src.loc, 'sound/items/Welder2.ogg', 50, 1)
				user.visible_message("[user.name] starts to patch some dents on the shield generator.", \
					"You start to patch some dents on the shield generator", \
					"You hear welding")
				if (do_after(user,20))
					if(!src || !WT.isOn()) return
					health += 10

		else
			user << "<span class='warning'>You need more welding fuel to complete this task.</span>"

	else
		switch(W.damtype)
			if("fire")
				src.health -= W.force * 1
			if("brute")
				src.health -= W.force * 0.50
			else
		if (src.health <= 0)
			visible_message("<span class='danger'>The shield generator is smashed apart!</span>")
			kaboom()
			return
		..()

/obj/structure/assaultshieldgen/ex_act(severity)
	switch(severity)
		if(1.0)
			kaboom()
			return
		if(2.0)
			if(prob(75))
				kaboom()
				return
			else
				health -= 150
		if(3.0)
			if(prob(5))
				kaboom()
				return
			else
				health -= 50

	if(src.health <=0)
		visible_message("<span class='danger'>The shield generator is smashed apart!</span>")
		qdel(src)

	return

/obj/structure/assaultshieldgen/bullet_act(var/obj/item/projectile/Proj)
	health -= Proj.damage

	if(health <= 0)
		kaboom()

	..()

/obj/structure/assaultshieldgen/proc/kaboom()
	remaininggens -= 1
	qdel(src)