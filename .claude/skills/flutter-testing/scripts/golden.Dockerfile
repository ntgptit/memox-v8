# The Linux renderer that writes this repo's goldens (spec §8.2, owner decision
# 2026-09-25), for regenerating them from a Windows or macOS checkout. The
# `goldens` job of `.github/workflows/ci.yml`
# compares the pictures on `ubuntu-latest`, as described below; this image is
# where they are written.
#
# **Why this file exists.** Goldens have exactly one authoring platform, Linux
# (`dart_test.yaml` carries the reasoning). A Windows checkout that runs
# `--update-goldens` writes PNGs CI rejects, and it does it silently — the local
# run reports every test passing, because a platform always agrees with itself.
# This image is the reproducible way to write them from any machine.
#
# **The base is Ubuntu plus the official SDK tarball, not a vendor image.** The
# CI job is `runs-on: ubuntu-latest` with `subosito/flutter-action` reading
# `.fvmrc`, and that action downloads exactly this archive. A vendor image is a
# different font stack and a different libc, which is another way of saying a
# different rasteriser — and the whole contract of a golden is that one platform
# wrote it.
#
# **Validate before trusting it.** Run the golden suite on unmodified `master`
# content first; it must be green. A container that disagrees with the committed
# PNGs will not agree with CI either, and regenerating from it would replace 300
# correct pictures with 300 wrong ones.
#
#   docker build -f .claude/skills/flutter-testing/scripts/golden.Dockerfile \
#     -t memox-golden:3.47.5 .claude/skills/flutter-testing/scripts
#
#   # 1. validate — must print "All tests passed!"
#   git worktree add /tmp/mainref origin/master
#   docker run --rm -v /tmp/mainref:/src memox-golden:3.47.5 bash -lc '
#     cp -a /src /w2 && cd /w2 && flutter pub get &&
#     dart run build_runner build --delete-conflicting-outputs &&
#     bash .claude/skills/flutter-workflow/scripts/run_goldens.sh'
#
#   # 2. regenerate — writes back into the mounted checkout
#   docker run --rm -v "$PWD":/w memox-golden:3.47.5 bash -lc '
#     flutter pub get &&
#     dart run build_runner build --delete-conflicting-outputs &&
#     bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update'
#
# **On Docker Desktop for Windows** (Git Bash, a WSL2 VM with capped memory),
# three things decide whether a run takes a few minutes or half an hour:
# - Copy the tree in with `docker cp`. A bind mount of `D:\...` is slow across
#   the VM boundary, and in the SP2a run of 2026-10-03 the container died once
#   the tests started.
# - Keep packages in a named volume (`memox-pub-cache`), so `pub get` does not
#   download everything again for every new container.
# - Cap processes to the VM's memory with `MEMOX_TEST_BUNDLES=<n>`. It caps the
#   bundles of a comparison and the files of `--update`. Use run_goldens.sh
#   rather than `flutter test -j 1 <files>`: that ran the 40 golden files one by
#   one, twice, and still crawled.
#
#   git ls-files | tar -cf src.tar -T -
#   MSYS_NO_PATHCONV=1 docker create --name memox-golden \
#     -v memox-pub-cache:/root/.pub-cache -e MEMOX_TEST_BUNDLES=2 \
#     memox-golden:3.47.5 bash -lc '
#       mkdir /w && cd /w && tar -xf /src.tar && git init -q && git add -A &&
#       git -c user.email=g@x -c user.name=g commit -qm snap &&
#       flutter pub get && dart run build_runner build --delete-conflicting-outputs &&
#       bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update; rc=$?
#       git status --porcelain --untracked-files=all -- "test/**/goldens/*.png" |
#         cut -c4- | tar -cf /pngs.tar -T -; exit $rc'
#   MSYS_NO_PATHCONV=1 docker cp src.tar memox-golden:/src.tar
#   docker start -a memox-golden     # streams progress; exits with the run's code
#   MSYS_NO_PATHCONV=1 docker cp memox-golden:/pngs.tar - | tar -xOf - | tar -xf -
#   docker rm memox-golden
#
# `docker start -a` blocks until the run ends and shows it as it goes, so no
# `sleep`/`docker inspect` polling loop is needed. Drop `--update` to compare.
#
# `TZ=UTC` is not optional: `card_detail` renders review timestamps through
# `toLocal()`, so without it the PNGs carry the machine's timezone. The image
# sets it as a default, and the command restates it so a reader of either does
# not have to check the other.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl xz-utils git unzip zip ca-certificates \
      libglu1-mesa python3 \
    && rm -rf /var/lib/apt/lists/*

# Keep in step with `.fvmrc`, which is what the CI job reads.
ARG FLUTTER_VERSION=3.47.5
RUN curl -fsSL -o /tmp/flutter.tar.xz \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz

ENV FLUTTER_ROOT=/opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
ENV TZ=UTC

RUN git config --global --add safe.directory /opt/flutter \
    && git config --global --add safe.directory '*' \
    && flutter --version \
    && flutter precache --force --universal

# `prepare_test_fonts.sh`, baked in. Flutter's Linux test runner asks for
# lowercase material-font paths while the SDK artifact ships mixed case; without
# the symlinks every glyph falls back to the box font and all 300 goldens
# disagree at once. The CI job runs the script as a step; doing it here means
# every container run starts from the font state that step produces.
RUN cd "$FLUTTER_ROOT/bin/cache/artifacts/material_fonts" \
    && for f in *; do \
         l="$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')"; \
         [ "$f" = "$l" ] && continue; \
         [ -e "$l" ] && continue; \
         ln -s "$f" "$l"; \
       done \
    && test -f "$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/roboto-regular.ttf"

WORKDIR /w
