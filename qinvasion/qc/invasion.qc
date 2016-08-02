/*

  QInvasion
  By KaadmY

  Invasion-specific entities and game logic

*/

/**** CVars ****/

float autocvar_invasion; // 0 disables invasion, 1 enables invasion
float autocvar_invasion_multiplier; // monster multiplier. 1 is normal, 2 is double

/**** Entity fields ****/

.float wave;
.float monster_count;
.float spawned_monsters;

/**** Global variables ****/
entity inv_conductor_ent;

/**** Temp stuff for the compiler ****/

void() NextLevel;

void(vector org) spawn_tfog;

void() monster_ogre;
void() monster_demon1;
void() monster_shambler;
void() monster_knight;
void() monster_army;
void() monster_wizard;
void() monster_dog;
void() monster_zombie;

void() inv_conductor_endwave;

/**** Helper functions****/

void(string s) centerprintall =
{
  entity e = find(world, classname, "player");
  do {
    centerprint(e, s);
    e = find(e, classname, "player");
  } while(e != world);
};

void(string s) printall =
{
  entity e = find(world, classname, "player");
  do {
    sprint(e, s);
    e = find(e, classname, "player");
  } while(e != world);
};

/**** Entity helper functions****/

void() monster_multi_trigger =
{
  if(self.nextthink > time) // already been triggered
    return;

  // don't trigger again until reset
  self.takedamage = DAMAGE_NO;

  activator = self.enemy;

  SUB_UseTargets();

  if(self.wait > 0)	
    {
      self.think = SUB_Null;
      self.nextthink = time + self.wait;
    }
  else
    {// we can't just remove (self) here, because this is a touch function
      // called while C code is looping through area links...
      self.touch = SUB_Null;
      self.nextthink = time + 0.1;
      self.think = SUB_Remove;
    }
};

void() monster_multi_use =
{
  self.enemy = activator;
  monster_multi_trigger();
};

void() monster_multi_touch =
{
  if( !(other.flags & FL_MONSTER))
    return;
	
  self.enemy = other;
  monster_multi_trigger ();
};

/**** Entities ****/

/** Invasion deadline **/

void() inv_deadline_use =
{
  self.cnt += 1;

  if(self.cnt >= self.monster_count) {
    if(self.message)
      centerprintall(self.message);
    
    SUB_UseTargets();

    self.think = NextLevel;
    self.nextthink = time + 5.0;
  }
};

void() inv_deadline =
{
  self.cnt = 0; // number of times this has been triggered
  self.use = inv_deadline_use;
};

/** Wave trigger **/

void() inv_wave_think =
{
  SUB_UseTargets();

  remove(self);
};

void() inv_wave =
{
};

/** Monster spawn **/

void() inv_spawn_makesolid =
{
  self.touch = SUB_Null;

  inv_conductor_ent.spawned_monsters += 1;

  if(self.netname == "monster_ogre")
    monster_ogre();
  else if(self.netname == "monster_demon1")
    monster_demon1();
  else if(self.netname == "monster_shambler")
    monster_shambler();
  else if(self.netname == "monster_knight")
    monster_knight();
  else if(self.netname == "monster_army")
    monster_army();
  else if(self.netname == "monster_wizard")
    monster_wizard();
  else if(self.netname == "monster_dog")
    monster_dog();
  else if(self.netname == "monster_zombie")
    monster_zombie();
  
  spawn_tfog(self.origin);
};

void() inv_spawn_fling =
{
  setsize(self, '-16 -16 -24', '16 16 40');
  self.origin_z += 30; // move up a bit

  self.velocity_x = (random() * 400) + 200;
  self.velocity_y = (random() * 400) + 200;
  self.velocity_z = 80;
	
  self.solid = SOLID_BBOX;
  self.movetype = MOVETYPE_TOSS;

  self.touch = inv_spawn_makesolid;
};

void() inv_spawn_think =
{
  if(self.spawned_monsters >= self.monster_count) {
    remove(self);
    return;
  }

  /* Copy self into a temp variable */
  local entity spawner = self;

  /* Spawn the monster */
  self = spawn();

  self.netname = spawner.netname; // monster type

  if(spawner.target) // monsters target path_corner
    self.target = spawner.target;

  self.origin = spawner.origin;
  self.angles = spawner.angles;

  inv_spawn_fling(); // fling in a random direction and spawn when it collides

  /* Revert self back to the original entity */
  self = spawner;

  self.spawned_monsters += 1;

  self.nextthink = time + self.delay;
};

void() inv_spawn_use =
{
  self.think = inv_spawn_think;
  self.nextthink = time + self.wait;
};

void() inv_spawn =
{
  self.use = inv_spawn_use;

  self.monster_count *= autocvar_invasion_multiplier; // use monster multiplier
  self.spawned_monsters = 0;
};

/** Wave conductor **/

void() inv_conductor_success =
{
  if(self.message)
    centerprintall(self.message);

  SUB_UseTargets();

  self.think = NextLevel;
  self.nextthink = time + 5.0;
};

void() inv_conductor_idle =
{
  self.nextthink = time + 0.2; // check for next wave condition

  if(total_monsters - killed_monsters <= 0 && self.spawned_monsters >= self.monster_count) {
    if(self.wave == self.health) { // final wave
      centerprintall("Final wave complete");

      self.think = inv_conductor_endwave;
      self.nextthink = time + 0.1; // skip ASAP
    } else {
      if(self.wave == 1)
	centerprintall("First wave complete");
      else if(self.wave == 2)
	centerprintall("Second wave complete");
      else if(self.wave == 3)
	centerprintall("Third wave complete");
      else if(self.wave == 4)
	centerprintall("Fourth wave complete");
      else if(self.wave == 5)
	centerprintall("Fifth wave complete");
      else if(self.wave == 6)
	centerprintall("Sixth wave complete");
      else if(self.wave == 7)
	centerprintall("Seventh wave complete");
      else if(self.wave == 8)
	centerprintall("Eighth wave complete");
      else if(self.wave == 9)
	centerprintall("Ninth wave complete");
      else if(self.wave == 10)
	centerprintall("Tenth wave complete");

      self.think = inv_conductor_endwave;
      self.nextthink = time + self.delay; // between wave delay
    }
  }
};

void() inv_conductor_beginwave =
{
  self.wave += 1; // increase wave

  self.think = inv_conductor_idle;
  self.nextthink = time + 1.0; // check for next wave condition every second

  self.spawned_monsters = 0;
  self.monster_count = 0;

  entity ent_wave = find(world, classname, "inv_wave");
  entity ent_spawn;

  do {
    if(ent_wave.wave == self.wave) {
      ent_spawn = find(world, targetname, ent_wave.target);
      
      do {
	if(ent_spawn.classname == "inv_spawn")
	  self.monster_count += ent_spawn.monster_count;

	ent_spawn = find(ent_spawn, targetname, ent_wave.target);
      } while(ent_spawn != world);

      ent_wave.think = inv_wave_think;
      ent_wave.nextthink = time + random() * 0.5;
    }

    ent_wave = find(ent_wave, classname, "inv_wave");
  } while(ent_wave != world);

  if(self.wave == self.health) { // final wave
    centerprintall("Final wave");
  } else {
    if(self.wave == 1)
      centerprintall("First wave");
    else if(self.wave == 2)
      centerprintall("Second wave");
    else if(self.wave == 3)
      centerprintall("Third wave");
    else if(self.wave == 4)
      centerprintall("Fourth wave");
    else if(self.wave == 5)
      centerprintall("Fifth wave");
    else if(self.wave == 6)
      centerprintall("Sixth wave");
    else if(self.wave == 7)
      centerprintall("Seventh wave");
    else if(self.wave == 8)
      centerprintall("Eighth wave");
    else if(self.wave == 9)
      centerprintall("Ninth wave");
    else if(self.wave == 10)
      centerprintall("Tenth wave");
  }
};

void() inv_conductor_endwave =
{
  if(self.wave >= self.health) { // final wave
    self.think = inv_conductor_success;
    self.nextthink = time + 3.0; // print success message
  } else {
    self.think = inv_conductor_beginwave;
    self.nextthink = time + 0.1; // start the next wave
  }
};

void() inv_conductor =
{
  self.wave = 0;

  self.think = inv_conductor_beginwave;
  self.nextthink = time + self.wait;

  inv_conductor_ent = self;
};

/** Monster triggers **/
void() inv_monstertrigger_multiple =
{
  if(!self.wait)
    self.wait = 0.2;

  self.use = monster_multi_use;

  InitTrigger ();

  self.touch = monster_multi_touch;
};

void() inv_monstertrigger_once =
{
  self.wait = -1;
  inv_monstertrigger_multiple();
};

