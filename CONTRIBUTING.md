# Contributing

Thanks for helping improve `omarchy-bb-theme-sync`.

## Development

The project is a Bash integration with no package manager or build step.

```sh
./tests/verify.sh
```

The verification script uses temporary directories and fake `bb`/`omarchy`
commands. It does not modify the live Omarchy or BB configuration.

## Before opening a pull request

- Keep the implementation POSIX-shell friendly where practical.
- Preserve atomic theme writes and safe symlink behaviour.
- Add or update a verification case for behavioural changes.
- Update `README.md` when commands, requirements, or safety guarantees change.
- Do not add credentials, machine-specific paths, or live theme data.

## Commit and pull-request guidance

Use focused commits with a clear problem and outcome. Explain the user-visible
behaviour in the pull request, and include the exact verification command you
ran.
