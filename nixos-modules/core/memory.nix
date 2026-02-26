# Core: Memory management and swap configuration
_: {
  # Optimize for interactive desktop usage
  # Lower swappiness prevents system lag during memory pressure
  boot.kernel.sysctl = {
    # High swappiness with zram: prefer compressed RAM swap over disk I/O (default: 60)
    # With zram enabled, this reduces disk writes and improves interactive responsiveness
    "vm.swappiness" = 80;

    # Reduce inode/dentry cache pressure (default: 100)
    # Keeps application memory prioritized over filesystem caches
    "vm.vfs_cache_pressure" = 50;
  };
}
