import glob
import json
import os
import shutil
import stat
import sys
import tempfile
from datetime import datetime, timezone


def read_json_object(
    path,
    *,
    symlink_label,
    read_context,
    object_error,
    default=None,
    default_mode=0o600,
):
    if os.path.lexists(path) and os.path.islink(path):
        raise SystemExit(f"error: {symlink_label} is a symlink: {path}")

    if not os.path.exists(path):
        return ({} if default is None else default), default_mode

    try:
        with open(path, encoding="utf-8") as state_file:
            state = json.load(state_file)
    except (OSError, json.JSONDecodeError) as error:
        raise SystemExit(f"error: cannot read {read_context}: {error}") from error

    if not isinstance(state, dict):
        raise SystemExit(object_error)

    return state, stat.S_IMODE(os.stat(path).st_mode)


def write_json_object(
    path,
    state,
    *,
    mode,
    prefix,
    update_context,
    indent=None,
    separators=None,
    backup_limit=3,
):
    directory = os.path.dirname(path)
    os.makedirs(directory, mode=0o755, exist_ok=True)

    if os.path.exists(path):
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
        backup_path = f"{path}.chezmoi-backup.{timestamp}"
        suffix = 1
        while os.path.exists(backup_path):
            backup_path = f"{path}.chezmoi-backup.{timestamp}-{suffix}"
            suffix += 1
        shutil.copyfile(path, backup_path)
        os.chmod(backup_path, mode)

    temporary_path = None
    try:
        descriptor, temporary_path = tempfile.mkstemp(prefix=prefix, dir=directory)
        with os.fdopen(descriptor, "w", encoding="utf-8") as state_file:
            json.dump(state, state_file, indent=indent, separators=separators, ensure_ascii=False)
            state_file.write("\n")
            state_file.flush()
            os.fsync(state_file.fileno())
        os.chmod(temporary_path, mode)
        os.replace(temporary_path, path)
    except OSError as error:
        if temporary_path is not None:
            try:
                os.unlink(temporary_path)
            except FileNotFoundError:
                pass
        raise SystemExit(f"error: cannot update {update_context}: {error}") from error

    backups = sorted(
        glob.glob(f"{path}.chezmoi-backup.*"),
        key=os.path.getmtime,
        reverse=True,
    )
    for old_backup in backups[backup_limit:]:
        os.unlink(old_backup)
