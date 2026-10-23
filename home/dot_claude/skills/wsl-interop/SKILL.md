---
name: wsl-interop
description: Use before crossing between Windows and WSL2 - wsl.exe, powershell.exe, wsl --exec, .wslconfig, wsl --shutdown, Docker Desktop integration, /mnt/wsl.
---

# WSL interop cheatsheet

Measured on WSL 3.0.3 with kernel 6.18, Windows 11 Home build 26200 and Docker Desktop 4.96 (2026-10). Re-check anything that matters on other versions; the measuring commands are included.

## WSL → Windows

- **Call Windows binaries by full path.** Shells that don't append the Windows PATH (fish's interactive PATH, systemd units) won't find `powershell.exe` or `wsl.exe` by name:
  - `/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -Command '...'`
  - `/mnt/c/Windows/System32/wsl.exe`
- **Clean the output.** `powershell.exe` and `wsl.exe` print CRLF, and `wsl.exe -l` prints UTF-16, so pipe through `tr -d '\0' | sed 's/\r//'` before grepping.
- **Run from a Linux cwd.** From a cwd under `/home`, `wsl.exe` prints `Failed to translate '\\wsl.localhost\...'`. Use `cd /` first; the warning is harmless otherwise.
- **stdin pipes through.** For example, `cat unit | wsl.exe -d other -u root --exec tee /etc/...` writes a file into another distro without putting its contents on argv.
- **localhost:** a port bound to 127.0.0.1 inside WSL (NAT mode) is reachable from the Windows browser at `localhost:<port>`. That includes ports from `ssh -R` tunnels landing in WSL.

## Windows or another distro → a distro

- **`wsl -d <distro> --exec <cmd>` runs without a shell** (no profile, no aliases, no globbing). Use `-- <cmd>` for the distro's default shell.
- **`--exec` name lookup skips the sbin directories.** `printenv PATH` under `--exec` lists `/usr/sbin` and `/sbin`, yet `wsl --exec swapon` fails with `execvpe(swapon) failed: No such file or directory`. `/usr/local/bin` and `/usr/bin` names resolve. Give admin tools full paths: `/usr/sbin/swapon`, `/usr/sbin/sysctl`, `/usr/sbin/ip`.
  - Check with: `wsl -d Ubuntu --exec swapon --show` versus `wsl -d Ubuntu --exec /usr/sbin/swapon --show`.
- **`wsl -u root` is passwordless.** Any process that can run `wsl.exe` gets root in every distro, so sudo passwords inside WSL are not a security boundary.
- **Every distro shares one kernel and VM.** `vm.*` sysctls, page cache and memory pressure apply to all of them. Distros also share the network namespace, so 127.0.0.1 is the same across distros.
- **`/mnt/wsl` is shared by every distro.** Docker Desktop puts each integrated distro's engine socket there (`/mnt/wsl/docker-desktop-bind-mounts/<distro>/docker.sock`, root:1001, mode 660). Any distro user in GID 1001 can drive that engine. `backend.sock` under `docker-desktop/shared-sockets/host-services/` is mode 666.
- **A `docker` on PATH may be Docker Desktop's stub** (`/mnt/c/Program Files/Docker/Docker/resources/bin/docker`), which only prints "activate the WSL integration". Check that the engine answers (`docker version`, or `curl --unix-socket ... /_ping`), not just that `command -v docker` finds something.

## .wslconfig and restarts

- **Check settings by measuring the result.** Read `free -m`, `nproc` and `/usr/sbin/swapon --show` inside a distro after the restart, not the file.
- **`swapfile=` needs its folder to exist,** otherwise swap is silently 0.
- **Keep `.wslconfig` in LF line endings.** A CR at the end of a path breaks it, and Windows Notepad saves CRLF again.
- **`wsl --shutdown` ends every distro, including the session that ran it.** Write out every step, and how to resume, before running it.
- **Docker Desktop restarts the VM** and its integrated distros within about 20 s, so "all distros Stopped" never holds while Docker Desktop runs. Detect the restart by `/proc/uptime` or the swap vhdx timestamp.
- **Keepalives:** a logon scheduled task running `conhost.exe --headless wsl.exe -d <distro> --exec sleep infinity` keeps a distro (and its systemd) up without a terminal. After `wsl --shutdown`, start it again with `Start-ScheduledTask`.
- **The VM fills its `memory=` cap with page cache** within seconds of boot. A lower cap limits the VM's worst case but doesn't raise Windows' free memory under load. Linux returns free memory to Windows only in blocks of 128 KB or more (`/sys/module/page_reporting/parameters/page_reporting_order` = 5).

## Inside minimal distros

- **No D-Bus user session in minimal Debian:** `systemd-run --user` fails; `systemctl --user` works. Use an enabled user unit for long-lived test processes.
- **Linger** (`loginctl enable-linger`) plus a keepalive task starts user units at Windows logon with no terminal open.
