//BASKETBALL

/obj/item/basketball
	name = "basketball"
	desc = "If you can't slam with the best, then jam with the rest."
	icon = 'icons/obj/items.dmi'
	icon_state = "bball"
	item_state = "bball"
	w_class = 3.0
	force = 0
	throw_range = 10
	throwforce = 0
	var/obj/item/plutonium_core/payload = null
	stamina_damage = 5
	stamina_cost = 5
	stamina_crit_chance = 5

/obj/item/basketball/attack_hand(mob/user as mob)
	..()
	if(user)
		src.icon_state = "bball"

/obj/item/basketball/throw_impact(atom/hit_atom)
	..(hit_atom)
	src.icon_state = "bball"
	if(hit_atom)
		playsound(src.loc, "sound/items/bball_bounce.ogg", 65, 1)
		if(ismob(hit_atom))
			var/mob/M = hit_atom
			if(ishuman(M))
				if((prob(50) && M.bioHolder.HasEffect("clumsy")) || M.equipped() || get_dir(M, src) == M.dir)
					src.visible_message("<span class='combat'>[M] gets beaned with the [src.name].</span>")
					M.stunned = max(2, M.stunned)
					return
				// catch the ball!
				src.attack_hand(M)
				M.visible_message("<span class='combat'>[M] catches the [src.name]!</span>", "<span class='combat'>You catch the [src.name]!</span>")
				logTheThing("combat", M, null, "catches [src]")
				return
			src.visible_message("<span class='combat'>[M] gets beaned with the [src.name].</span>")
			logTheThing("combat", M, null, "is struck by [src]")
			M.stunned = max(2, M.stunned)
			return

/obj/item/basketball/throw_at(atom/target, range, speed)
	src.icon_state = "bball_spin"
	..(target, range, speed)

/obj/item/basketball/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/plutonium_core))
		boutput(user, "<span style=\"color:blue\">You insert the [W.name] into the [src.name].</span>")
		user.u_equip(W)
		W.dropped(user)
		W.layer = initial(W.layer)
		W.set_loc(src)
		src.payload = W
		if(src.loc == user)
			user.verbs += /proc/chaos_dunk
		return
	..(W, user)
	return

/obj/item/basketball/attack_hand(mob/user as mob)
	..()
	var/mob/living/carbon/human/H = user
	if(istype(H) && payload && istype(payload))
		H.verbs += /proc/chaos_dunk
	return

/obj/item/basketball/unequipped(var/mob/user)
	if(payload && istype(payload))
		user.verbs -= /proc/chaos_dunk
	..()

// hoop

/obj/item/bballbasket
	name = "basketball hoop" // it's a hoop you nerd, not a basket
	desc = "Can be mounted on walls."
	opacity = 0
	density = 0
	anchored = 0
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "bbasket0"
	var/mounted = 0
	var/active = 0
	var/probability = 40

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W,/obj/item/wrench) && mounted)
			src.visible_message("<span style=\"color:blue\"><b>[user] removes [src].</b></span>")
			src.pixel_y = 0
			src.pixel_x = 0
			src.anchored = 0
			src.mounted = 0
		else if (src.mounted && !istype(W, /obj/item/bballbasket))
			if (W.cant_drop) return
			src.visible_message("<span style=\"color:blue\"><b>[user]</b> jumps up and tries to dunk [W] into [src]!</span>")
			user.u_equip(W)
			if (user.bioHolder.HasEffect("clumsy") && prob(50)) // clowns are not good at basketball I guess
				user.visible_message("<span class='combat'><b>[user] knocks their head into the rim of [src]!</b></span>")
				user.weakened = max(5, user.weakened)
			if (!src.shoot(W, user))
				spawn(10)
					src.visible_message("<span style=\"color:red\">[user] whiffs the dunk.</span>")
		return

	attack_hand(mob/user as mob)
		if (mounted)
			return
		else
			return ..(user)

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob)
		if (!mounted && get_dist(src, target) == 1)
			if (isturf(target) && target.density)
				//if (get_dir(src,target) == NORTH || get_dir(src,target) == EAST || get_dir(src,target) == SOUTH || get_dir(src,target) == WEST)
				if (get_dir(src,target) in cardinal)
					src.visible_message("<span style=\"color:blue\"><b>[user] mounts [src] on [target].</b></span>")
					user.drop_item()
					src.loc = get_turf(user)
					src.mounted = 1
					src.anchored = 1
					src.dir = get_dir(src, target)
					switch (src.dir)
						if (NORTH)
							src.pixel_y = 20
						if (SOUTH)
							src.pixel_y = -20
						if (EAST)
							src.pixel_x = 20
						if (WEST)
							src.pixel_x = -20
		return

	HasEntered(atom/A)
		if (src.active)
			return
		if (istype(A, /obj/item/bballbasket)) // oh for FUCK'S SAKE
			return // NO
		if (istype(A, /obj/item))
			src.shoot(A)

	proc/shoot(var/obj/O as obj, var/mob/user as mob)
		if (!O)
			return 0
		if (istype(O, /obj/item/bballbasket))
			return
		src.active = 1
		if (user)
			user.u_equip(O)
		O.set_loc(get_turf(src))
		if (prob(src.probability)) // It might land!
			if (prob(30)) // It landed cleanly!
				src.visible_message("<span style=\"color:blue\">[O] lands cleanly in [src]!</span>")
				src.basket(O)
			else // Aaaa the tension!
				src.visible_message("<span style=\"color:red\">[O] teeters on the edge of [src]!</span>")
				var/delay = rand(5, 15)
				animate_horizontal_wiggle(O, delay, 5, 1, -1) // target, number of animation loops, speed, positive x variation, negative x variation
				spawn(delay)
					if (O && O.loc == src.loc)
						if (prob(40)) // It goes in!
							src.visible_message("<span style=\"color:blue\">[O] slips into [src]!</span>")
							src.basket(O)
						else
							src.visible_message("<span style=\"color:red\">[O] slips off of the edge of [src]!</span>")
							src.active = 0
					else
						src.active = 0
			src.active = 0
			return 1
		else
			src.active = 0
			return 0

	proc/basket(var/atom/A as obj|mob)
		if (!A || isarea(A) || isturf(A))
			return
		src.active = 1
		playsound(get_turf(src), "rustle", 75, 1)
		A.invisibility = 100
		flick("bbasket1", src)
		spawn(15)
			A.invisibility = 0
			src.active = 0

/obj/item/bballbasket/testing
	probability = 100

//PLUTONIUM CORE

/obj/item/plutonium_core
	name = "plutonium core"
	desc = "A payload from a nuclear warhead. Comprised of weapons-grade plutonium."
	icon = 'icons/obj/items.dmi'
	icon_state = "plutonium"
	item_state = "egg3"
	w_class = 3.0
	force = 0
	throwforce = 10

/obj/item/plutonium_core/attack_hand(mob/user as mob)
	..()
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(!H.gloves)
			boutput(H, "<span class='combat'>Your hand burns from grabbing the [src.name].</span>")
			var/obj/item/affecting = H.organs["r_arm"]
			if(H.hand)
				affecting = H.organs["l_arm"]
			if(affecting)
				affecting.take_damage(0, 15)
				H.UpdateDamageIcon()
				H.updatehealth()


//BLOOD BOWL BALL

/obj/item/bloodbowlball
	name = "spiked ball"
	desc = "An american football studded with sharp spikes and serrated blades. Looks dangerous."
	icon = 'icons/obj/items.dmi'
	icon_state = "bloodbowlball"
	item_state = "bloodbowlball"
	w_class = 3.0
	force = 10
	throw_range = 10
	throwforce = 2

/obj/item/bloodbowlball/attack_hand(mob/user as mob)
	..()
	if(user)
		src.icon_state = "bloodbowlball"

/obj/item/bloodbowlball/throw_impact(atom/hit_atom)
	..(hit_atom)
	src.icon_state = "bloodbowlball"
	if(hit_atom)
		playsound(src.loc, "sound/items/bball_bounce.ogg", 65, 1)
		if(ismob(hit_atom))
			var/mob/M = hit_atom
			if(ishuman(M))
				var/mob/living/carbon/T = M
				if(prob(20) || T.equipped() || get_dir(T, src) == T.dir)
					for(var/mob/V in AIviewers(src, null))
						if(V.client)
							V.show_message("<span class='combat'>[T] gets stabbed by one of the [src.name]'s spikes.</span>", 1)
							playsound(src.loc, "sound/effects/bloody_stabOLD.ogg", 65, 1)
					T.stunned = max(5, T.stunned)
					T.TakeDamage("chest", 30, 0)
					take_bleeding_damage(T, null, 15, DAMAGE_STAB)
					return
				else if (prob(50))
					src.visible_message("<span class='combat'>[T] catches the [src.name] but gets cut.</span>")
					T.TakeDamage(T.hand == 1 ? "l_arm" : "r_arm", 15, 0)
					take_bleeding_damage(T, null, 10, DAMAGE_CUT)
					src.attack_hand(T)
					return
				// catch the ball!
				else
					src.attack_hand(T)
					T.visible_message("<span class='combat'>[M] catches the [src.name]!</span>")
					return
	return

/obj/item/bloodbowlball/throw_at(atom/target, range, speed)
	src.icon_state = "bloodbowlball_air"
	..(target, range, speed)

/obj/item/bloodbowlball/attack(target as mob, mob/user as mob)
	playsound(target, "sound/effects/bloody_stab.ogg", 60, 1)
	if(iscarbon(target))
		if(target:stat != 2)
			var/mob/living/carbon/targMob = target
			targMob.visible_message("<span class='combat'><B>[user] attacks [target] with the [src]!</B></span>")
			take_bleeding_damage(target, user, 5, DAMAGE_STAB)
	if(prob(30))
		if(prob(30))
			boutput(user, "<span class='combat'>You accidentally cut your hand badly!</span>")
			user.TakeDamage(user.hand == 1 ? "l_arm" : "r_arm", 10, 0)
			take_bleeding_damage(user, user, 5, DAMAGE_CUT)
		else
			boutput(user, "<span class='combat'>You accidentally cut your hand!</span>")
			user.TakeDamage(user.hand == 1 ? "l_arm" : "r_arm", 5, 0)
			take_bleeding_damage(user, null, 1, DAMAGE_CUT, 0)

// MADDEN NFL FOOTBALL 2051

/obj/item/football
	name = "football"
	desc = "A pigskin. An oblate leather spheroid. For tossing around."
	icon = 'icons/obj/items.dmi'
	icon_state = "football"
	item_state = "football"
	w_class = 3.0
	force = 0
	throw_range = 10
	throwforce = 0

/obj/item/football/throw_at(atom/target, range, speed)
	src.icon_state = "football_air"
	..(target, range, speed)

/obj/item/football/throw_impact(atom/hit_atom)
	..(hit_atom)
	src.icon_state = "football"
	if(hit_atom)
		playsound(src.loc, "sound/items/bball_bounce.ogg", 65, 1)

/obj/item/football/suicide(var/mob/user as mob)
	user.visible_message("<span style=\"color:red\"><b>[user] spikes the [src.name]. It bounces back up and hits \him square in the forehead!</b></span>")
	user.TakeDamage("head", 150, 0)
	playsound(src.loc, "sound/items/bball_bounce.ogg", 50, 1)
	user.updatehealth()
	spawn(100)
		if (user)
			user.suiciding = 0
	return 1