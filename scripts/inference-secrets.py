import argparse
import fcntl
import getpass
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


FIELDS = ("openrouter", "vercel", "cloudflare", "cloudflare-account", "cloudflare-gateway")
COMMON_ENV = {
    "openrouter": "OPENROUTER_API_KEY",
    "vercel": "AI_GATEWAY_API_KEY",
    "cloudflare-account": "CLOUDFLARE_ACCOUNT_ID",
    "cloudflare-gateway": "CLOUDFLARE_GATEWAY_ID",
}
CLOUDFLARE_ENV = {
    "pi": "CLOUDFLARE_API_KEY",
    "omp": "CLOUDFLARE_AI_GATEWAY_API_KEY",
    "opencode": "CLOUDFLARE_API_TOKEN",
}

directory = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config") / "inference-secrets"
identity = directory / "identity.txt"
inventory = directory / "inference.sops.yaml"


def checked(command, *, data=None, stdout=subprocess.PIPE):
    env = os.environ | {"SOPS_AGE_KEY_FILE": str(identity)}
    result = subprocess.run(command, input=data, stdout=stdout, stderr=subprocess.DEVNULL, env=env)
    if result.returncode:
        raise ValueError(f"{command[0]} {command[1]} failed (exit {result.returncode})")
    return result.stdout


def load():
    if not inventory.exists():
        return {}
    secrets = json.loads(checked(["sops", "decrypt", "--output-type", "json", inventory]))
    if not isinstance(secrets, dict) or any(
        field in secrets and not isinstance(secrets[field], str) for field in FIELDS
    ):
        raise ValueError("expected an inventory of string fields")
    return secrets


def set_field(field, value):
    if not value or any(char.isspace() or not char.isprintable() for char in value):
        raise ValueError("expected a nonempty single value without whitespace")

    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (directory / ".lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if not identity.exists():
            if inventory.exists():
                raise ValueError("restore the age identity before editing the existing inventory")
            checked(["age-keygen", "-o", identity])

        with tempfile.TemporaryDirectory(dir=directory) as scratch:
            encrypted = Path(scratch) / inventory.name
            if inventory.exists():
                shutil.copyfile(inventory, encrypted)
                checked(
                    ["sops", "set", "--value-stdin", encrypted, f"[{json.dumps(field)}]"],
                    data=json.dumps(value).encode(),
                )
            else:
                recipient = checked(["age-keygen", "-y", identity]).decode().strip()
                with encrypted.open("wb") as output:
                    checked(
                        [
                            "sops", "encrypt", "--age", recipient,
                            "--input-type", "json", "--output-type", "yaml", "/dev/stdin",
                        ],
                        data=json.dumps({field: value}).encode(),
                        stdout=output,
                    )
            encrypted.replace(inventory)


def main():
    parser = argparse.ArgumentParser(description="Manage user-wide SOPS credentials for coding agents.")
    commands = parser.add_subparsers(dest="action", required=True)
    setter = commands.add_parser("set", help="encrypt a value read from a hidden prompt or stdin")
    setter.add_argument("field", choices=FIELDS)
    commands.add_parser("status", help="show which fields are available without printing values")
    runner = commands.add_parser("run", help="launch an agent with its provider environment")
    runner.add_argument("agent", choices=CLOUDFLARE_ENV)
    runner.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()

    if args.action == "set":
        if sys.stdin.isatty():
            value = getpass.getpass(f"{args.field}: ")
        else:
            value = sys.stdin.read().rstrip("\r\n")
        set_field(args.field, value)
        print(f"Stored {args.field} in {inventory}")
        return

    if args.action == "run" and not args.command:
        parser.error("run requires an executable")

    secrets = load()
    if args.action == "status":
        for field in FIELDS:
            print(f"{field}: {'configured' if secrets.get(field) else 'missing'}")
        return

    env = os.environ.copy()
    for field, variable in (COMMON_ENV | {"cloudflare": CLOUDFLARE_ENV[args.agent]}).items():
        if secrets.get(field):
            env[variable] = secrets[field]
    os.execvpe(args.command[0], args.command, env)


if __name__ == "__main__":
    os.umask(0o077)
    try:
        main()
    except (ValueError, OSError, EOFError) as error:
        print(f"inference-secrets: {error}", file=sys.stderr)
        sys.exit(1)
