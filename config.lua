Config = {
  Debug = true, --DEV TOOL

  -- Lockpick Config
  LockpickItem = "lockpick",                               --Item required to lockpick
  LockpickDestroyChance = 20,                              --% chance to destroy item on fail
  LockpickDifficulty = { 'easy', 'easy', 'easy', 'easy' }, --Difficulty of lockpick
  LockpickAnim = {
    Dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",     --Animation dictionary
    Name = "machinic_loop_mechandplayer",                  --Animation name
    Flags = 16,                                            --Animation flags
  },

  -- Hotwire Config
  HotwireTime = math.random(2500, 5000),               --milliseconds to hotwire
  HotwireDifficulty = { 'easy', 'easy', 'easy' },      --Difficulty of hotwire
  HotwireAnim = {
    Dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", --Animation dictionary
    Name = "machinic_loop_mechandplayer",              --Animation name
    Flags = 16,                                        --Animation flags
  },
}
