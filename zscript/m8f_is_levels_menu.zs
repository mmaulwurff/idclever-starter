class m8f_is_LevelsMenu : OptionMenu
{

  // public: ///////////////////////////////////////////////////////////////////

  override void Init(Menu parent, OptionMenuDescriptor desc)
  {
    reset(desc);

    string currentMapName = level.mapName;
    currentMapName.toUpper();
    setup(desc, currentMapName);

    bool isInGame = (gamestate == GS_LEVEL);
    if (isInGame) { addInGameOptions(desc); }

    super.Init(parent, desc);
  }

  override bool MenuEvent (int mkey, bool fromcontroller)
  {
    if (mkey == MKEY_ENTER)
    {
      if (mDesc.mSelectedItem >= 0 && mDesc.mItems[mDesc.mSelectedItem].Activate())
      {
        let commandItem = OptionMenuItemCommand(mDesc.mItems[mDesc.mSelectedItem]);
        if (commandItem)
        {
          reset(mDesc);

          string label        = commandItem.mLabel;
          string restartLabel = StringTable.Localize("$M8F_IS_RESTART");
          string nextLabel    = StringTable.Localize("$M8F_IS_NEXT");
          string mapName;

          if (label == restartLabel)
          {
            mapName = level.mapName;
          }
          else if (label == nextLabel)
          {
            if (level.nextMap.IndexOf("enDSeQ") == -1)
            {
              mapName = level.nextMap;
            }
            else
            {
              mapName = level.mapName;
            }
          }
          else
          {
            int leftP  = label.RightIndexOf("(");
            int rightP = label.RightIndexOf(")");

            mapName = label.Mid(leftP + 1, rightP - leftP - 1);
          }

          setup(mDesc, mapName);

          addInGameOptions(mDesc);

          if (isKeepInventory())
          {
            let inhibitCVar = CVar.GetCVar("m8f_is_inhibit");
            inhibitCVar.SetBool(true);
          }
        }
        return true;
      }
    }

    return Super.MenuEvent(mkey, fromcontroller);
  }

  // private: //////////////////////////////////////////////////////////////////

  private void addEmptyLine(OptionMenuDescriptor desc)
  {
    int nItems = desc.mItems.size();
    if (nItems > 0)
    {
      let staticText = OptionMenuItemStaticText(desc.mItems[nItems - 1]);
      if (staticText != null && staticText.mLabel == "") { return; }
    }

    let item = new("OptionMenuItemStaticText").Init("");
    desc.mItems.push(item);
  }

  private void addStaticText(OptionMenuDescriptor desc, string label)
  {
    let item = new("OptionMenuItemStaticText").Init(label);
    desc.mItems.push(item);
  }

  private bool addGoToMapItemIfFound( string mapLumpName
                                    , string fullName
                                    , string mapName
                                    , string currentMap
                                    , OptionMenuDescriptor desc
                                    )
  {
    bool found = (Wads.CheckNumForFullName(fullName) != -1)
              || (Wads.FindLump(mapLumpName) != -1);

    if (found)
    {
      let item = makeGoToMapItem(mapLumpName, mapName, currentMap);
      desc.mItems.push(item);
    }

    return found;
  }

  private OptionMenuItem makeGoToMapItem(string mapLumpName, string mapName, string currentMap)
  {
    string label;

    if (mapName.CharAt(0) == "$")
    {
      string localized = StringTable.Localize(mapName);

      if (mapName.indexOf(localized) == -1) // localized properly
      {
        label = String.Format("%s (%s)", localized, mapLumpName);
      }
      else // string not found
      {
        label = String.Format("(%s)", mapLumpName);
      }
    }
    else
    {
      label = String.Format("%s (%s)", mapName, mapLumpName);
    }

    if (currentMap.length() > 0 && isEqualIgnoreCase(currentMap, mapLumpName))
    {
      label.AppendFormat(" *");
    }
    else
    {
      label.AppendFormat("  ");
    }

    bool   isInGame = (gamestate == GS_LEVEL);
    string command  = (isKeepInventory() && isInGame)
                    ? String.Format("changemap %s", mapLumpName)
                    : String.Format("map %s"      , mapLumpName);

    OptionMenuItem item;
    if (isSafe())
    {
      string warning = StringTable.Localize("$M8F_IS_WARNING");
      item = new("OptionMenuItemSafeCommand").Init(label, command, warning);
    }
    else
    {
      item = new("OptionMenuItemCommand").Init(label, command);
    }

    return item;
  }

  private void reset(OptionMenuDescriptor desc)
  {
    desc.mItems.clear();
  }

  private void addInGameOptions(OptionMenuDescriptor desc)
  {
    string backLabel = StringTable.Localize("$M8F_IS_BACK");
    desc.mItems.push(new("OptionMenuItemCommand").Init(backLabel, "closemenu"));
    addEmptyLine(desc);

    string nextLabel = StringTable.Localize("$M8F_IS_NEXT");
    if (isSafe())
    {
      string warning = StringTable.Localize("$M8F_IS_WARNING");
      desc.mItems.push(new("OptionMenuItemSafeCommand").Init(nextLabel , "nextmap", warning));
    }
    else
    {
      desc.mItems.push(new("OptionMenuItemCommand").Init(nextLabel, "nextmap"));
    }
    if (isKeepInventory())
    {
      string keepNote = StringTable.Localize("$M8F_IS_INV_KEEP_NOTE");
      addStaticText(desc, keepNote);
      addEmptyLine(desc);
    }

    string command  = isKeepInventory()
                    ? String.Format("changemap *")
                    : String.Format("map *");

    string restartLabel = StringTable.Localize("$M8F_IS_RESTART");
    string warning      = StringTable.Localize("$M8F_IS_WARNING");
    if (isSafe())
    {
      desc.mItems.push(new("OptionMenuItemSafeCommand").Init(restartLabel, command , warning));
    }
    else
    {
      desc.mItems.push(new("OptionMenuItemCommand").Init(restartLabel, command));
    }

    addEmptyLine(desc);
  }

  private void setup(OptionMenuDescriptor desc, string currentMap)
  {
    // Special maps
    { // Test map
      string mapName     = "Test Map";
      string mapLumpName = "TEST";
      bool   isFound     = addGoToMapItemIfFound(mapLumpName, "", mapName, currentMap, desc);
    }

    string game = StringTable.Localize("$M8F_IS_GAME");

    addSquareMaps(desc, currentMap);

    if (isHarmony())
    {
      bool   replacementFound = isDoom2MapsReplaced();
      string episodeCode      = "$HUSTR_%d";
      addDoom2Maps(desc, currentMap, replacementFound, episodeCode);
    }

    else if (game == "DOOM1")
    {
      addEmptyLine(desc);
      addDoom1Maps(desc, currentMap);
    }

    else if (game == "DOOM2")
    {
      bool   replacementFound = isDoom2MapsReplaced();
      string episodeCode      = StringTable.Localize("$M8F_IS_EPISODE_CODE");
      addDoom2Maps(desc, currentMap, replacementFound, episodeCode);
    }

    addEmptyLine(desc);
  }

  private void addSquareMaps(OptionMenuDescriptor desc, string currentMap)
  {
    string nameCode     = "$SQHUSTR_E%dA%d";
    string lumpCode     = "e%da%d";
    string fullNameCode = "maps/e%da%d.wad";

    addEpisodicMaps(desc, currentMap, nameCode, fullNameCode, lumpCode);

    addEmptyLine(desc);
    { // Time attack
      string mapName     = StringTable.Localize("$M8F_IS_AS_TIME_MODE");
      string mapLumpName = "dm01";
      string fullName    = "maps/dm01.wad";
      bool   isFound     = addGoToMapItemIfFound(mapLumpName, fullName, mapName, currentMap, desc);
    }
  }

  private void addDoom1Maps(OptionMenuDescriptor desc, string currentMap)
  {
    string nameCode = StringTable.Localize("$M8F_IS_EPISODE_CODE");
    string lumpCode = "E%dM%d";

    addEpisodicMaps(desc, currentMap, nameCode, nameCode, lumpCode);
  }

  private void addEpisodicMaps( OptionMenuDescriptor desc
                              , string currentMap
                              , string nameCode
                              , string fullNameCode
                              , string lumpCode
                              )
  {
    for (int e = 0; e < 10; ++e)
    {
      bool found = false;

      for (int i = 0; i < 99; ++i)
      {
        string mapName     = String.Format(nameCode,     e, i);
        string mapLumpName = String.Format(lumpCode,     e, i);
        string fullName    = String.Format(fullNameCode, e, i);

        found |= addGoToMapItemIfFound(mapLumpName, fullName, mapName, currentMap, desc);
      }

      if (found) { addEmptyLine(desc); }
    }
  }

  private void addDoom2Maps( OptionMenuDescriptor desc
                           , string currentMap
                           , bool   replacementFound
                           , string episodeCode
                           )
  {
    int maxNum = StringTable.Localize("$M8F_IS_ORIG_MAPS_END").ToInt();

    for (int i = 0; i < 100; ++i)
    {
      string mapLumpName = String.Format("MAP%02d", i);

      if (replacementFound)
      {
        int num = Wads.CheckNumForName(mapLumpName, Wads.ns_global);
        if (num <= maxNum) { continue; }
      }

      if (i % 10 == 1) { addEmptyLine(desc); }

      string mapName = String.Format(episodeCode, i);
      addGoToMapItemIfFound(mapLumpName, mapLumpName, mapName, currentMap, desc);
    }
  }

  private bool isDoom2MapsReplaced()
  {
    int maxNum = StringTable.Localize("$M8F_IS_ORIG_MAPS_END").ToInt();

    for (int i = 0; i < 100; ++i)
    {
      string mapLumpName = String.Format("MAP%02d", i);
      int    num         = Wads.CheckNumForName(mapLumpName, Wads.ns_global);

      if (num > maxNum) { return true; }
    }

    return false;
  }

  private bool isHarmony()
  {
    string map03Name = StringTable.Localize("$HUSTR_3");
    map03Name.toUpper();
    bool   isHarmony = (map03Name == "03: OWT MOOD");

    return isHarmony;
  }

  private bool isKeepInventory()
  {
    bool isKeepInventory = CVar.GetCvar("m8f_is_level_menu_keep").GetBool();

    return isKeepInventory;
  }

  private bool isEqualIgnoreCase(string str1, string str2)
  {
    str1.toUpper();
    str2.toUpper();

    bool isEqual = (str1 == str2);

    return isEqual;
  }

  private bool isSafe()
  {
    bool isSafe = CVar.GetCVar("m8f_is_safe_level_menu_commands").GetBool();

    return isSafe;
  }

} // class m8f_is_LevelsMenu