/* This code is based on StrongholdEventHandler by Ed the Bat.
 * (https://github.com/Realm667/Re-Releases/blob/master/stronghold/zscript.txt)
 */

class m8f_is_EventHandler : StaticEventHandler
{

// public: // StaticEventHandler ///////////////////////////////////////////////

  override
  void PlayerEntered(PlayerEvent e)
  {
    if (IsTitleMap()) { return; }

    settings = new("m8f_is_Settings").init();

    if (!settings.isEnabled) { return; }

    let playerPawn = PlayerPawn(players[e.PlayerNumber].mo);

    ResetHealthAndArmor(playerPawn);
    ResetInventory     (playerPawn);
    ResetWeapons       (playerPawn);
    ResetAmmo          (playerPawn);
    MaybeAddBackpack   (playerPawn);
  }

  override
  void NetworkProcess(ConsoleEvent e)
  {
    if (e.name == "keep_this_weapon")
    {
      Weapon currentWeapon = players[e.player].ReadyWeapon;
      if (currentWeapon == null)
      {
        return;
      }

      string currentWeaponClass = currentWeapon.GetClassName();

      Array<String> keepWeapons;
      GetKeepWeapons(keepWeapons);

      string message = StringTable.Localize("$M8F_IS_KEEP_MESSAGE");
      Console.Printf(message, currentWeapon.GetTag());

      if (WeaponIsInKeepList(keepWeapons, currentWeaponClass))
      {
        return;
      }

      CVar   keepWeaponsCVar = CVar.GetCVar("m8f_is_KeepWeapons");
      String keeped          = keepWeaponsCvar.GetString();

      keeped.AppendFormat("%s,", currentWeaponClass);
      keepWeaponsCVar.SetString(keeped);
    }
    else if (e.name == "clear_keep_weapons")
    {
      CVar.GetCVar("m8f_is_KeepWeapons").SetString("");
      string message = StringTable.Localize("$M8F_IS_KEEP_CLEAR");
      Console.Printf(message);
    }
  }

// private: //////////////////////////////////////////////////////////////////

  private static
  bool IsUltimateCustomDoomLoaded()
  {
    string        className = "cd_UltimateCustomDoom";
    class<Object> cls       = className;
    bool          isLoaded  = (cls != null);

    return isLoaded;
  }

  private static
  void ResetHealthAndArmor(PlayerPawn player)
  {
    if (IsUltimateCustomDoomLoaded())
    {
      // rely on Ultimate Custom Doom instead.
      return;
    }

    player.A_SetHealth(player.GetSpawnHealth());
    player.SetInventory("BasicArmor", 0);
  }

  private
  bool ShouldRemoveItem(Array<String> keepWeapons, Inventory item)
  {
    bool   droppable     = !item.bUNDROPPABLE;
    string className     = item.GetClassName();
    bool   notInKeepList = !WeaponIsInKeepList(keepWeapons, className);
    bool   notArmor      = !(item is "BasicArmor" || item is "HexenArmor");

    bool   shouldRemove  = droppable && notInKeepList && notArmor;

    return shouldRemove;
  }

  /**
   * Resets health, armor, and droppable inventory items.
   */
  private
  void ResetInventory(PlayerPawn player)
  {
    // remove everything that is droppable
    Array<String> items;
    Array<String> keepWeapons;
    GetKeepWeapons(keepWeapons);

    for (let item = player.Inv; item; item = item.Inv)
    {
      if (ShouldRemoveItem(keepWeapons, item))
      {
        items.push(item.GetClassName());
      }
    }
    int size = items.Size();
    for (int i = 0; i < size; ++i)
    {
      player.A_TakeInventory(items[i]);
    }

    // Restore default things
    DropItem drop = player.GetDropItems();
    if (drop != null)
    {
      for (DropItem di = drop; di != null; di=di.Next)
      {
        if (di.Name == "None") { continue; }

        let weapon = (class<Weapon>)(di.Name);
        if (weapon != null) { continue; }

        let ammo = (class<Ammo>)(di.Name);
        if (ammo != null) { continue; }

        let inv = (class<Inventory>)(di.Name);

        if (inv != null)
        {
          player.A_SetInventory(di.Name, di.Amount);
        }
      }
    }
  }

  private
  void GetKeepWeapons(out Array<String> keepWeapons)
  {
    keepWeapons.Clear();
    CVar.GetCVar("m8f_is_KeepWeapons").GetString().Split(keepWeapons, ",", TOK_SKIPEMPTY);
  }

  private
  bool WeaponIsInKeepList(Array<String> keepWeapons, String weaponClass)
  {
    uint index = keepWeapons.Find(weaponClass);
    return index != keepWeapons.size();
  }

  private
  bool ShouldRemoveWeapon(Array<String> keepWeapons, string weaponClass)
  {
    bool inKeepList = WeaponIsInKeepList(keepWeapons, weaponClass);
    bool holstered  = (weaponClass == "m8f_wm_Holstered");

    bool shouldRemoveWeapon = !inKeepList && !holstered;

    return shouldRemoveWeapon;
  }

  /**
   * Resets weapons, even if they are undroppable.
   * Ammo should be reset after resetting weapons.
   */
  private
  void ResetWeapons(PlayerPawn player)
  {
    DropItem drop = player.GetDropItems();

    Array<String> keepWeapons;
    GetKeepWeapons(keepWeapons);

    // remove weapons even if they are undroppable
    // removing an item invalidates the iterator, so
    // 1. remember weapon classes
    Array<String> weapons;
    for (let item = player.Inv; item; item = item.Inv)
    {
      if (item is "Weapon")
      {
        string weaponClass = item.GetClassName();
        if (ShouldRemoveWeapon(keepWeapons, weaponClass))
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
      for (DropItem di = drop; di != null; di=di.Next)
      {
        if (di.Name == "None") { continue; }

        let weptype = (class<weapon>)(di.Name);

        if (weptype != null)
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

  private
  void ResetAmmo(PlayerPawn player)
  {
    DropItem drop = player.GetDropItems();

    // Remove all ammo, except that with the UNDROPPABLE flag
    // 1. Remember ammo classes
    Array<string> ammos;
    for (let item = player.Inv; item; item = item.Inv)
    {
      if (item is "Ammo") { ammos.Push(item.GetClassName()); }
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
      for (DropItem di = drop; di != null; di = di.Next)
      {
        if (di.Name == "None") { continue; }

        let ammotype = (class<ammo>)(di.Name);
        if (ammotype != null)
        {
          player.A_SetInventory(di.Name, int(di.Amount * settings.ammoMultiplier));
        }
      }
    }
  }

  private
  void MaybeAddBackpack(PlayerPawn player)
  {
    if (!settings.startWithBackpack) { return; }

    player.GiveInventoryType("BackpackItem");
  }

  private static
  bool IsTitlemap()
  {
    bool isTitlemap = (level.mapname == "TITLEMAP");
    return isTitlemap;
  }

// private: ////////////////////////////////////////////////////////////////////

  private m8f_is_Settings settings;

} // class m8f_is_EventHandler
