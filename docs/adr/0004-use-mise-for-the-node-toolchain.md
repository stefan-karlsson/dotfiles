# mise for the Node toolchain

The Developer Shell takes its Node toolchain from `mise`. Ubuntu's `nodejs` and `npm` packages are not installed.

`mise` provides multiple Node.js runtimes with the latest LTS as the global default, honors `mise.toml`, `.nvmrc`, and `.node-version`, and installs a missing runtime only when asked. Corepack is enabled, so a project selects its pnpm or Yarn version through the `packageManager` field in `package.json`.
