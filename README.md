# dockit: Jump into a container

Sometimes you need a clean workspace, fast. `dockit` mounts the current
directory into a Docker image of your choosing.

```text
$ touch file1 file2
$ ls -l
total 0
-rw-r--r-- 1 myuser myuser 0 Jan  1 00:00 file1
-rw-r--r-- 1 myuser myuser 0 Jan  1 00:00 file2
$ dockit alpine
Using default tag: latest
latest: Pulling from library/alpine
Digest: sha256:72c42ed48c3a2db31b7dafe17d275b634664a708d901ec9fd57b1529280f01fb
Status: Image is up to date for alpine:latest
docker.io/library/alpine:latest
/docked # ls -l
total 0
-rw-r--r--    1 root     root             0 Jan  1 00:00 file1
-rw-r--r--    1 root     root             0 Jan  1 00:00 file2
```

## Features

* Consistent permissions. By default, files in the `/docked` directory will be
  owned by the user running inside Docker.
* Changes in the `/docked` directory stay inside the container, letting you
  install, delete, and otherwise break stuff without impacting the real
  directory.
* Works with Docker images with a default `USER` specified.
* Easily export files and directories back to the host.

## Installation

```bash
git clone https://github.com/awkspace/dockit
cd dockit
sudo ./install.sh
```

The included installer script will install `dockit` to `/usr/local`.
Alternatively, you can add the `bin/` directory from your cloned copy of this
repository to your `$PATH` in your shell’s profile.

## Usage

Change directory to the location you want to mount into a Docker container and
run `dockit <image>`, e.g. `docker alpine` or `docker python:3.6`.

```text
# print usage here
```

## Exporting

If you’ve produced something inside your docked container that you’d like to
move back to the host, you can do so using the `undock` command.

