# Use mise for the Node toolchain

The Developer Shell will use `mise` as its authoritative Node toolchain manager instead of Ubuntu's system `nodejs` and `npm` packages. `mise` will provide multiple Node.js runtimes with the latest LTS as the global default, honor explicit project runtime files, require an explicit install for missing runtimes, and enable Corepack so projects can select pnpm or Yarn versions through their `packageManager` metadata. This avoids conflicting Node installations while preserving project-specific reproducibility.
