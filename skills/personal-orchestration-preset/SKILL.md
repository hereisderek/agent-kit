---
name: personal-orchestration-preset
description: Derek's personal multi-agent orchestration preset and configuration hooks for agent-orchestration. Covers local Proxmox LXC 2026 paths, StageDroid Central Smart ADB Proxy (port 50370), hardware device pool leasing, flock /tmp/dtm-gradle.lock, and host memory discipline.
---

# Personal Orchestration Preset (`personal-orchestration-preset`)

Host- and environment-specific configuration hooks for [`agent-orchestration`](file:///Volumes/private/workspace/my-skills/android-skill-derek/agent-orchestration/SKILL.md) tailored to Derek's development machines (Mac & LXC 2026).

## Environment Variables & Verification Hooks

When orchestrating on Derek's machines, set the following environment variables or add them to your session environment:

```bash
# 1. Multi-Agent Gradle Daemon Lock (prevents daemon contention & OOM)
export VALIDATION_TEST_CMD="cd mobile && flock /tmp/dtm-gradle.lock ./gradlew :<module>:allTests"

# 2. Build Debug Artifact
export VALIDATION_DEPLOY_CMD="cd mobile && ./gradlew :androidApp:assembleDebug"

# 3. On-Device Smoke & Verification Command
export VALIDATION_SMOKE_CMD="adb -s \"\${TEST_DEVICE:-\$ANDROID_SERIAL}\" install -r <path_to_apk> && adb shell am start -n <package>/<activity>"

# 4. Host Daemon Discipline (stops daemon after merge to free host RAM)
export POST_MERGE_CLEANUP_CMD="cd mobile && ./gradlew --stop"

# 5. Shared Device Lock Release
export VALIDATION_LOCK_RELEASE_CMD="bash \"\$HOME/.agents/agent-kit/skills/state-droid-remote-device/scripts/device-pool.sh\" release --owner \"<validation-worker>\""
```

## Host Specifics

- **Mac (`mac.md`)**: Local Android SDK, USB/wireless ADB, shared debug keystore at `~/.android/debug.keystore`, `/tmp/dtm-gradle.lock`.
- **Agent LXC (`agent-lxc.md`)**: Headless Debian 13, StageDroid Smart ADB proxy on `172.16.2.26:50370`, remote hardware testing via Tailscale.
