# Core: Memory management and swap configuration
_: {
  # Optimize for interactive desktop usage
  # Lower swappiness prevents system lag during memory pressure
  boot.kernel.sysctl = {
    # Reduce swap usage (default: 60)
    # Only swap when memory is critically low
    "vm.swappiness" = 80;

    # Reduce inode/dentry cache pressure (default: 100)
    # Keeps application memory prioritized over filesystem caches
    "vm.vfs_cache_pressure" = 50;
  };
}
