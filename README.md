# HingeWake

**Close the lid. Keep the work running.**

HingeWake is a minimal macOS menu bar app that can disable or restore system sleep, allowing long-running work to continue when a MacBook lid is closed.

<p align="center">
  <img src="Resources/AppIcon.png" alt="HingeWake icon" width="128">
</p>

> [!WARNING]
> When sleep is disabled, a MacBook can remain awake with its lid closed. This may cause significant heat buildup and battery drain, especially inside a bag. Always restore normal sleep before carrying or storing the MacBook.

## Status

HingeWake is intended for local, informed use. It is not currently distributed as a Developer ID-signed and notarized application. This repository publishes source code only; build the app locally before use.

## Requirements

- macOS 13 Ventura or later
- A MacBook for the closed-lid use case
- An administrator account for every setting change
- Xcode Command Line Tools and Swift 6 to build from source

The build script produces a binary for the architecture of the build Mac. Builds produced on Apple Silicon are arm64-only unless the build process is explicitly changed to create a Universal Binary. Intel and older macOS configurations have not been validated by this project.

## How it works

HingeWake changes one system setting through a deliberately narrow privileged boundary:

```text
/usr/bin/pmset -a disablesleep 1
/usr/bin/pmset -a disablesleep 0
```

The executable path and arguments are fixed in source code. The app does not invoke a shell and does not accept user-controlled commands, paths, or privileged arguments.

After every change, HingeWake runs the unprivileged command below and verifies the observed `SleepDisabled` value before reporting success:

```text
/usr/bin/pmset -g
```

The app does not change power settings when it launches or quits. The setting is persistent and managed by macOS, so quitting HingeWake does not automatically restore normal sleep.

## Privacy

HingeWake:

- does not collect analytics or telemetry;
- does not make network requests;
- does not store administrator passwords or authorization credentials;
- does not read documents, browser data, contacts, or other personal files;
- does not persist application preferences or user-generated data.

## Build

```bash
git clone https://github.com/J0hnSm1thyk/HingeWake.git
cd HingeWake
./build-app.sh
```

The local build is written to:

```text
dist/HingeWake.app
dist/HingeWake.zip
```

`build-app.sh` applies an ad hoc signature with Hardened Runtime enabled. An ad hoc signature is suitable for local testing but is not a substitute for Developer ID signing and Apple notarization.

## Usage

1. Launch the locally built app:

   ```bash
   open dist/HingeWake.app
   ```

2. Click the HingeWake icon in the macOS menu bar.
3. Select **Disable Sleep...**.
4. Read the heat and battery warning, then select **Continue to Authorization**.
5. Complete the macOS administrator authorization prompt.
6. Confirm that the menu shows **Status: Sleep Disabled** and the menu-bar icon changes to a sun.

While sleep is disabled, the setting applies system-wide and remains active even if HingeWake quits. Do not place the MacBook in a bag or other enclosed space in this state.

To restore normal sleep:

1. Open the HingeWake menu.
2. Select **Restore Normal Sleep...**.
3. Complete the administrator authorization prompt.
4. Confirm that the menu shows **Status: Normal Sleep** and the icon changes to a moon.

Use **Refresh Status** to read the current macOS power setting again. **Quit HingeWake** closes only the menu-bar app; it does not change the current sleep setting.

If the app is unavailable, normal sleep can be restored manually in Terminal:

```bash
sudo /usr/bin/pmset -a disablesleep 0
```

## Menu states

- **Sun:** system sleep is disabled.
- **Moon:** normal sleep behavior is enabled.
- **Question mark:** the current state could not be determined safely.

Each enable or disable action requests macOS administrator authorization. Authorization rights are destroyed after each operation.

## Compatibility and distribution limitations

HingeWake currently uses Apple's deprecated `AuthorizationExecuteWithPrivileges` API with a fixed executable path and fixed arguments. It works on the tested macOS environment, but Apple may remove this API in a future macOS release. A production-grade long-term distribution should migrate privileged operations to a signed helper managed by `SMAppService`.

Public distribution of a prebuilt binary should also use:

1. a Developer ID Application certificate;
2. Hardened Runtime;
3. Apple notarization and stapling;
4. testing on each supported macOS and CPU architecture.

No claim is made that the current source or locally built binary works on every Mac.

## License

MIT License. See [LICENSE](LICENSE).
