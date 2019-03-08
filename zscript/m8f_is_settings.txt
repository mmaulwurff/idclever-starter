class m8f_is_Settings
{

  // public: ///////////////////////////////////////////////////////////////////

  m8f_is_Settings init(PlayerInfo player)
  {
    read(player);

    return self;
  }

  void read(PlayerInfo player)
  {
    isEnabled         = CVar.GetCVar("m8f_wm_PistolStart"       , player).GetBool();
    startWithBackpack = CVar.GetCVar("m8f_is_StartWithBackpack" , player).GetBool();
    ammoMultiplier    = CVar.GetCVar("m8f_is_StartAmmoPercent"  , player).GetInt() / 100.0;
  }

  // public: ///////////////////////////////////////////////////////////////////

  bool   isEnabled;
  bool   startWithBackpack;
  double ammoMultiplier;

} // class m8f_is_Settings
