class m8f_is_Settings
{

  // public: ///////////////////////////////////////////////////////////////////

  m8f_is_Settings init()
  {
    read();

    return self;
  }

  void read()
  {
    isEnabled         = m8f_wm_PistolStart;
    startWithBackpack = m8f_is_StartWithBackpack;
    ammoMultiplier    = m8f_is_StartAmmoPercent / 100.0;
  }

  // public: ///////////////////////////////////////////////////////////////////

  bool   isEnabled;
  bool   startWithBackpack;
  double ammoMultiplier;

} // class m8f_is_Settings
