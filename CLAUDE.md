# CLAUDE.md — echo.duv0-x.cloud

Fork personal de [GoToSocial](https://codeberg.org/superseriousbusiness/gotosocial) que corre la instancia `echo.duv0-x.cloud` (handle `@root@duv0-x.cloud`) en la Raspberry Pi `alfred` (3B+, 1 GB, `alfred@192.168.1.15`).

- **Remotes**: `origin` = `github.com/duv0-x/echo.duv0-x.cloud` (público por la AGPL-3.0: el link "Source" del footer apunta acá). `upstream` = Codeberg. `main` parte de `v0.22.2` y lleva nuestros commits encima; se commitea directo a `main`, sin PRs.
- **Traer upstream**: `git fetch upstream --tags`, `git merge vX.Y.Z` (un tag de release, no `upstream/main`), y `git push origin main --tags` (el workflow saca la versión base del último tag upstream).
- **Proponer algo a upstream**: rama desde el tag upstream, `cherry-pick` del commit y PR en Codeberg. Upstream pide en su `CLAUDE.md`/`AGENTS.md` que los agentes LLM no toquen su código: lo que se proponga allá debe escribirlo una persona.
- **Release**: cada push a `main` corre `.github/workflows/release.yml` (swagger + `yarn build` de `web/source` + `scripts/bundle_licenses.sh` + `scripts/build.sh` para linux/arm64) y publica la release `vX.Y.Z-echo.N` con el tarball y `checksums.txt`, con la misma estructura que el oficial.
- **Deploy**: la Pi no es alcanzable desde GitHub; hace pull. `deploy/update.sh` (instalado como `/usr/local/bin/gotosocial-update`, timer cada 5 min) baja la última release, verifica el checksum, respalda binario + `web/` + `sqlite.db` en `/gotosocial/.previous`, reemplaza, y si `/readyz` no responde en 10 min hace rollback. La release instalada queda en `/gotosocial/.release`. Logs: `journalctl -u gotosocial-update`.
- **En la Pi**: todo en `/gotosocial` (usuario `gotosocial`, servicio `gotosocial`), escucha en `127.0.0.1:8080`. SQLite en `/gotosocial/storage/sqlite.db`. `host` y `account-domain` no se pueden cambiar nunca más.
- **Exposición**: Cloudflare Tunnel `alfred` → `localhost:8080`. El apex `duv0-x.cloud` (repo `duv0-x.cloud`) redirige `/.well-known/{webfinger,host-meta,nodeinfo}` a `echo.`.
- **Admin CLI**: `sudo -u gotosocial /gotosocial/gotosocial --config-path /gotosocial/config.yaml admin ...` desde `/gotosocial`, con el servidor ya arriba (si corre durante las migraciones del arranque, falla). Tras `promote`, reiniciar el servicio.
- Desarrollo local y tests: `CONTRIBUTING.md` de upstream.
