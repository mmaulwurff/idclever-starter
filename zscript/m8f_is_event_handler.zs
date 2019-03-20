/* This code is based on StrongholdEventHandler by Ed the Bat.
 * (https://github.com/Realm667/Re-Releases/blob/master/stronghold/zscript.txt)
 */

class m8f_is_EventHandler : StaticEventHandler
{

  override void PlayerEntered(PlayerEvent e)
  {
    if (IsTitleMap()) { return; }

    PlayerInfo player = players[e.playerNumber];
    settings = new("m8f_is_Settings").init(player);

    if (!settings.isEnabled) { return; }

    let inhibitCVar = CVar.GetCVar("m8f_is_inhibit");
    if (inhibitCVar.GetBool())
    {
      inhibitCVar.SetBool(false);
      return;
    }

    let playerPawn = PlayerPawn(players[e.PlayerNumber].mo);
    ResetInventory  (playerPawn);
    ResetWeapons    (playerPawn);
    ResetAmmo       (playerPawn);
    MaybeAddBackpack(playerPawn);
  }

  override Void NetworkProcess(ConsoleEvent e)
  {
    if(e.name == "keep_this_weapon")
    {
      Weapon currentWeapon = players[e.player].ReadyWeapon;
      if (currentWeapon == null) { return; }
      string currentWeaponClass = currentWeapon.GetClassName();

      PlayerInfo player          = players[consolePlayer];
      CVar       keepWeaponsCVar = CVar.GetCVar("m8f_is_KeepWeapons", player);
      string     keeped          = keepWeaponsCVar.GetString();

      keeped.AppendFormat("%s,", currentWeaponClass);
      keepWeaponsCVar.SetString(keeped);

      string message = StringTable.Localize("$M8F_IS_KEEP_MESSAGE");
      Console.Printf(message, currentWeapon.GetTag());
    }
    else if (e.name == "clear_keep_weapons")
    {
      PlayerInfo player = players[consolePlayer];
      CVar.GetCVar("m8f_is_KeepWeapons", player).SetString("");
      string message = StringTable.Localize("$M8F_IS_KEEP_CLEAR");
      Console.Printf(message);
    }
  }

  // private: //////////////////////////////////////////////////////////////////

  /** resets health, armor, and droppable inventory items
   */
  private void ResetInventory(PlayerPawn player)
  {
    // reset health and armor
    player.A_SetHealth(player.GetSpawnHealth());
    player.SetInventory("BasicArmor", 0);
    player.SetInventory("HexenArmor", 1);

    // remove everything that is droppable
    Array<string> items;
    Array<int>    itemAmounts;

    GetKeepWeapons(player.player);

    for (let item = player.Inv; item; item = item.Inv)
    {
      if(!item.bUNDROPPABLE && !WeaponIsInKeepList(item.GetClassName()))
      {
        items.push(item.GetClassName());
        itemAmounts.push(item.amount);
      }
    }
    int size = items.Size();
    for (int i = 0; i < size; ++i)
    {
      player.A_TakeInventory(items[i], itemAmounts[i]);
    }

    // Restore default things
    DropItem drop = player.GetDropItems();
    if (drop != null)
    {
      for(DropItem di = drop; di != null; di=di.Next)
      {
        if(di.Name == "None") { continue; }

        let weapon = (class<Weapon>)(di.Name);
        if (weapon != null) { continue; }

        let ammo = (class<Ammo>)(di.Name);
        if (ammo != null) { continue; }

        let inv = (class<Inventory>)(di.Name);

        if(inv != null)
        {
          player.A_SetInventory(di.Name, di.Amount);
        }
      }
    }
  }

  private void GetKeepWeapons(PlayerInfo player)
  {
    keepWeapons.Clear();

    string weaponsSerialized = CVar.GetCVar("m8f_is_KeepWeapons", player).GetString();
    int    size              = weaponsSerialized.length();
    string currentWeapon     = "";

    for (int i = 0; i < size; ++i)
    {
      currentWeapon = "";
      while (weaponsSerialized.CharAt(i) != ',' && i < size)
      {
        currentWeapon.AppendFormat("%c", weaponsSerialized.CharCodeAt(i));
        ++i;
      }
      keepWeapons.Push(currentWeapon);
    }
  }

  private bool WeaponIsInKeepList(string weaponClass)
  {
    int size = keepWeapons.size();
    for (int i = 0; i < size; ++i)
    {
      if (weaponClass == keepWeapons[i]) { return true; }
    }
    return false;
  }

  /** resets weapons, even if they are undroppable
   * ammo should be reset after resetting weapons.
   */
  private void ResetWeapons(PlayerPawn player)
  {
    DropItem drop = player.GetDropItems();

    GetKeepWeapons(player.player);

    // remove weapons even if they are undroppable
    // removing an item invalidates the iterator, so
    // 1. remember weapon classes
    Array<string> weapons;
    for (let item = player.Inv; item; item = item.Inv)
    {
      if (item is "Weapon")
      {
        string weaponClass = item.GetClassName();
        if (!WeaponIsInKeepList(weaponClass))
        {
          weapons.push(weaponClass);
        }
      }
    }

    // 2. Remove remembered weapon classes
    int size = weapons.Size();
    for (int i = 0; i < size; ++i)
    {
      player.A_TakeInventory(weapons[i]);
    }

    // If the player has any weapons in StartItem, set them here
    string lastStartWeapon = ""; // to set default weapon
    if (drop != null)
    {
      for(DropItem di = drop; di != null; di=di.Next)
      {
        if(di.Name == "None") { continue; }

        let weptype = (class<weapon>)(di.Name);

        if(weptype != null)
        {
          lastStartWeapon = di.Name;
          player.A_SetInventory(di.Name, di.Amount);
        }
      }
    }
    if (lastStartWeapon != "")
    {
      let weaponInInv = player.FindInventory(lastStartWeapon);
      player.UseInventory(weaponInInv);
    }
  }

  private void ResetAmmo(PlayerPawn player)
  {
    DropItem drop = player.GetDropItems();

    // Remove all ammo, except that with the UNDROPPABLE flag
    // 1. Remember ammo classes
    Array<string> ammos;
    for (let item = player.Inv; item; item = item.Inv)
    {
      if(item is "Ammo") { ammos.Push(item.GetClassName()); }
    }
    // 2. Remove
    int size = ammos.Size();
    for (int i = 0; i < size; ++i)
    {
      player.A_TakeInventory(ammos[i]);
    }

    //If the player has any ammo in StartItem, set it here
    if (drop != null)
    {
      for(DropItem di = drop; di != null; di = di.Next)
      {
        if (di.Name == "None") { continue; }

        let ammotype = (class<ammo>)(di.Name);
        if (ammotype != null)
        {
          player.A_SetInventory(di.Name, di.Amount * settings.ammoMultiplier);
        }
      }
    }
  }

  private void MaybeAddBackpack(PlayerPawn player)
  {
    if (!settings.startWithBackpack) { return; }

    player.GiveInventoryType("BackpackItem");
  }

  private static bool IsTitlemap()
  {
    bool isTitlemap = (level.mapname == "TITLEMAP");
    return isTitlemap;
  }

  // private: //////////////////////////////////////////////////////////////////

  private Array<string> keepWeapons;

  private m8f_is_Settings settings;

} // class m8f_is_EventHandler