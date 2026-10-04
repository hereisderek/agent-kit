---
name: docker-hosts
description: How to run Docker or Podman workloads through Derek's two container LXCs, docker-lxc (LXC 2028, 172.16.2.28, Docker) and podman-lxc (LXC 2029, 172.16.2.29, Podman). Use when a task needs docker, docker compose, podman, or a container image build/run and the current machine has no docker (for example the agent LXC 2026), or whenever the user names docker-lxc, podman-lxc, 2028, or 2029. Covers reaching them, the shared /workspace, publishing ports and learning the reachable address (portbridge), where app data and caches live, and exposing a service through Caddy under a path (apps must support a base path). Skip it when the current machine has native docker and the user did not ask for these hosts.
---

# Docker and Podman hosts (LXC 2028 / 2029)

Full write-up and current state: `services/2026-agent/docker-hosts.md` in the proxmox-services repo. Which machines have native docker: see the machine notes (`~/.agents/rules/99-machine.md`).

| LXC | Hostname | IP | Engine | Use for |
|-----|----------|----|--------|---------|
| 2028 | `docker-lxc` | `172.16.2.28` | Docker + Compose | anything Docker. Default when the user does not say. |
| 2029 | `podman-lxc` | `172.16.2.29` | Podman (rootless) | when the user says Podman, rootless, or quadlet |

Use them when the current machine has no docker, or when the user names them. If the machine has native docker and the user did not ask for these hosts, use the local engine.

## Reaching them

- `ssh derek@172.16.2.28` (or `.29`). Key-only; `derek` is uid/gid 1000. Run the engine over SSH instead of installing docker locally:
  ```bash
  ssh derek@172.16.2.28 'cd /workspace/<project> && docker compose up -d'
  ```
- `derek` runs `docker` (2028) and rootless `podman` (2029) directly, no sudo (fixed 2026-10-04). If that fails (permission denied on the docker socket, `newuidmap` errors), the fix was lost: tell the user and point them at `docker-hosts.md`; do not work around it with `sudo` silently.
- `/workspace` is the same dataset, same path, on LXCs 2026, 2028, 2029, and 2011 (timemachine), open to derek (1000:1000). Build contexts and bind mounts must be paths that exist on the engine host. From a machine where the workspace path differs (the Mac), copy or sync what you need under `/workspace` first.
- A local docker CLI can target a host with `docker context create docker-lxc --docker host=ssh://derek@172.16.2.28`, but bind-mount paths still resolve on the remote host.
- Podman networking is rootless slirp4netns (pasta is broken on that LXC). Outbound access and published ports work.

## Ports

The containers sit on the LXC's own IP, not on the caller's localhost.

- Publish on all interfaces when you can: `-p 8080:8080` or `"8080:8080"` in compose. Reach it at `http://172.16.2.28:8080`. No tool involved.
- A port published on **loopback only** (`127.0.0.1:8080:80`, common in upstream compose files) is unreachable from other machines. **portbridge runs on both hosts and bridges those automatically**: it listens on the host's LAN address at the same port and forwards to `127.0.0.1`. Often you change nothing.
- **The port may differ.** If the container's port is already taken on the LAN address, portbridge uses another one (`+10000`, else 20000-29999). **After starting a container, find out where to connect; do not assume the container's port:**
  - `ssh derek@172.16.2.28 portbridge where <container-name|port>` prints `host:port`, one per line;
  - `ssh derek@172.16.2.28 portbridge list [--json]` shows every port: `CONNECT TO`, `same port` or `remapped: <why>`, status, traffic;
  - no ssh needed: read `/workspace/.portbridge/docker-lxc.json` (2029: `podman-lxc.json`). Use each forward's `reach` (host:port). If `same_port` is false, `listen` is the port to use, not `port`.
- Tell the user (and put in docs and tests) the address you actually used, especially when it was remapped.
- `mode: direct` means the port is already published on all interfaces: connect to `<host>:<port>`. UDP is bridged too.
- Opt a container out with the label `portbridge.enable=false`. Bridge a loopback service that has no container with `portbridge add <port>`. A bridge follows its container: gone after the container is stopped or removed, kept across a restart.
- `allow` limits sources to private networks by default. Anything bridged is exposed to the LAN, so do not bridge databases or admin UIs that must stay local.
- If a published port is unreachable, check the Proxmox firewall (`net0` has `firewall=1` on both LXCs) and `portbridge list` before blaming the container.
- Docs and operations: `services/2026-agent/portbridge/README.md`.

## Where things live

- Hosted apps (anything left running) live in `/mnt/data/<app>/`, with the compose file, config, data, and cache in subdirectories. `/mnt/data` is a separate ssd-zfs dataset per LXC (backed up), owned by `derek`, 10G. `/workspace` is for source and build contexts shared with other machines.
- Caches go in `/mnt/data/<app>/cache/<cache-name>`, bind-mounted into the container's own cache directory (compose: `./cache/<cache-name>:/path/in/container`).
- There is no dedicated cache mount on these LXCs yet. If the user adds one later, move caches there. Do not create mounts yourself; that is a host-side change, so ask.
- Image and layer storage (`/var/lib/docker`; for rootless Podman `/var/lib/containers/derek/storage`) is on a separate 50G cache dataset and is regenerable.

## Exposing a service (only when asked)

Never expose a service by default. When the user asks, do it through the Caddy LXC 2006 (needs root on the Proxmox host: `ssh root@pve.local`, then `pct exec 2006 -- ...`; if this machine cannot, give the user the exact change). Propose the change and wait for approval before touching Caddy.

**Every exposed app gets its own config file, imported into the main Caddy config. Never paste an app into the main `Caddyfile` body.**

- **Default: a path under the bare main domain, `https://hereisderek.dpdns.org/sites/<app>/`.** One file per app, `/etc/caddy/paths/<app>.caddy`, imported by `import ../paths/*.caddy` in `sites/root.caddy` (an `import` is relative to the file that contains it: a plain `paths/*.caddy` there matches nothing and only logs a warning). Template and steps: `services/2006-caddy/README.md` ("Path-based apps"). **Check that README's status first:** until Caddy terminates TLS for the bare domain (trialled and rolled back on 2026-10-04; it waits for the user's go-ahead), `/sites/<app>` does not work there. Say so instead of adding the file. After the cutover, Cloudflare's pooled connections can keep some requests on the old route for a few minutes.
- **A subdomain** only for the bigger services or when the user asks: file `/etc/caddy/sites/<name>.caddy` (`import service_http <name> 172.16.2.28:<port>`), imported by `import sites/*.caddy`, plus the two list entries in the main Caddyfile (see "Adding a new service to Caddy" there).
- **Apps must support a base path.** Choose and configure apps so they serve under `/sites/<app>` themselves (their base-URL / base-path / root-URL setting, usually an env var such as `BASE_PATH`, `BASE_URL`, `ROOT_URL`, or a `--base-path` flag), and have Caddy proxy the path unchanged. Only if an app has no such setting, strip the prefix in Caddy (`handle_path`) and check that its pages and assets still load. An app that breaks under a path (absolute asset URLs, no base-path option) needs a subdomain: say so and ask.
- Back up the Caddyfile, validate, then reload, as that README says.
