"""start-docker.sh: starts the Docker daemon in cloud sessions, never fails them.

Each case runs the hook with a PATH that holds only fake `docker` and
`dockerd` scripts plus the few tools the hook uses, so a real Docker install
on the machine is never seen or touched.
"""

import shutil
import stat
import subprocess
from pathlib import Path

import pytest

HOOK = Path(__file__).resolve().parents[1] / "start-docker.sh"
BASH = shutil.which("bash") or "/bin/bash"
# The hook's own tools; docker and dockerd are left out on purpose.
TOOLS = ("bash", "seq", "sleep", "setsid", "nohup", "touch", "test")


def _fake(bin_dir: Path, name: str, body: str) -> None:
    path = bin_dir / name
    path.write_text("#!/usr/bin/env bash\n" + body + "\n", encoding="utf-8")
    path.chmod(path.stat().st_mode | stat.S_IXUSR)


def _run(bin_dir: Path, remote: bool = True, **extra_env: str):
    env = {
        "PATH": str(bin_dir),
        "TMPDIR": str(bin_dir),
        "START_DOCKER_WAIT": "1",
        **extra_env,
    }
    if remote:
        env["CLAUDE_CODE_REMOTE"] = "true"
    return subprocess.run(
        [BASH, str(HOOK)], env=env, capture_output=True, text=True, timeout=30
    )


@pytest.fixture
def bin_dir(tmp_path: Path) -> Path:
    path = tmp_path / "bin"
    path.mkdir()
    for tool in TOOLS:
        found = shutil.which(tool)
        if found is None:
            pytest.skip(f"{tool} is not installed")
        (path / tool).symlink_to(found)
    return path


def test_outside_the_cloud_it_does_nothing(bin_dir: Path) -> None:
    _fake(bin_dir, "docker", "echo touched > \"$TMPDIR/touched\"; exit 1")
    result = _run(bin_dir, remote=False)
    assert result.returncode == 0
    assert result.stdout == "" and result.stderr == ""
    assert not (bin_dir / "touched").exists()


def test_a_running_daemon_is_left_alone(bin_dir: Path) -> None:
    _fake(bin_dir, "docker", 'test "$1" = info && exit 0; exit 1')
    _fake(bin_dir, "dockerd", "echo started > \"$TMPDIR/dockerd-ran\"; exit 0")
    result = _run(bin_dir)
    assert result.returncode == 0
    assert "already running" in result.stdout
    assert not (bin_dir / "dockerd-ran").exists()


def test_without_dockerd_it_skips_quietly(bin_dir: Path) -> None:
    _fake(bin_dir, "docker", "exit 1")
    result = _run(bin_dir)
    assert result.returncode == 0
    assert "no dockerd" in result.stdout


def test_it_starts_the_daemon_and_waits_for_it(bin_dir: Path) -> None:
    # The fake daemon writes a marker; the fake client answers once it exists.
    _fake(bin_dir, "dockerd", 'touch "$TMPDIR/up"; sleep 5')
    _fake(bin_dir, "docker", 'test "$1" = info && test -f "$TMPDIR/up"')
    result = _run(bin_dir, START_DOCKER_WAIT="5")
    assert result.returncode == 0
    assert "Docker daemon started" in result.stdout


def test_a_daemon_that_never_answers_does_not_fail_the_session(bin_dir: Path) -> None:
    _fake(bin_dir, "dockerd", "exit 1")
    _fake(bin_dir, "docker", "exit 1")
    result = _run(bin_dir)
    assert result.returncode == 0
    assert "did not answer" in result.stderr
