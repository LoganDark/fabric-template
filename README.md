## fabric-template

My personal template for Fabric mods. Supports at least every patch Minecraft release since 1.14.

This repo is structured using one commit for each supported version. **It is constantly and aggressively rebased by Jujutsu**, so the only reliable way to refer to versions is by their branch (bookmark in Jujutsu).

There are branches for each patch version, such as 1.14.4, 1.15.2, ... 1.21.11, 26.1.0, 26.1.2, etc., which each track their respective exact versions.

There are also branches for minor versions, such as 1.14, 1.15, ... 1.21, 26.1, etc., which each track their respective latest patch version, such as 1.14.4, 1.15.2, ... 1.21.11, 26.1.2, etc.

There are even branches for major versions, such as 1, 26, etc., which each track their respective latest patch version, such as 1.21.11, etc.

There may or may not be branches for snapshots.

All versions are standardized on the exact same project structure:

- Kotlin DSL for `build.gradle.kts`;
- a simple `ModInitializer` as the mod's only source code;
- `run_server` as a separate directory;
- accepted `eula.txt`;
- customized `options.txt` and `server.properties`;
- and IntelliJ run configurations generated on IDE sync.

The purpose of the repository is to make porting and backporting my mods easier. The idea is that by making it very easy for me to test across multiple versions, it will become much easier for me to support multiple versions. Less grunt work.

Mod identity (project name, package, class name, mod ID, etc.) is defined entirely in `gradle.properties`:

- The build automatically reflects changes to those properties.
- The `TEMPLATE_PACKAGE` package is automatically resolved to `mod_group.mod_package` at build time.
- This works both for IntelliJ's run configurations as well as for `./gradlew runClient` (or `runServer`) and `./gradlew build`.

I accept issues and review pull requests.
