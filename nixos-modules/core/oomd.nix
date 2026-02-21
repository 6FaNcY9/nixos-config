_:

{
  # Enable systemd-oomd for PSI-based OOM killing
  # This prevents system freeze by killing memory-hungry processes before total RAM exhaustion
  systemd = {
    oomd = {
      enable = true;

      # Monitor user slices (desktop applications) for memory pressure
      enableUserSlices = true;

      # Optional: monitor system and root slices
      # enableSystemSlice = true;
      # enableRootSlice = true;
    };

    # Configure slice-level oomd policies
    # Kill user applications when memory pressure is high, protecting system services
    slices."user-.slice" = {
      sliceConfig = {
        # Kill processes when sustained memory pressure exceeds 60% for 30 seconds
        ManagedOOMMemoryPressure = "kill";
        ManagedOOMMemoryPressureLimit = "60%";

        # Kill processes when swap usage exceeds 90%
        ManagedOOMSwap = "kill";
      };
    };

    # Protect system services from oomd kills
    slices."system.slice" = {
      sliceConfig = {
        # Don't kill system services automatically
        ManagedOOMMemoryPressure = "auto";
        ManagedOOMSwap = "auto";
      };
    };
  };
}
