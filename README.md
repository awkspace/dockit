# dockit: Overlay a Docker image onto the current directory

```text
$ touch file1 file2
$ ls
file1  file2
$ dockit alpine
Using default tag: latest
latest: Pulling from library/alpine
Digest: sha256:72c42ed48c3a2db31b7dafe17d275b634664a708d901ec9fd57b1529280f01fb
Status: Image is up to date for alpine:latest
docker.io/library/alpine:latest
/docked # ls
file1  file2
```

## Features

* Seamless but separated: Changes in the `/docked` directory stay local to the
  container, letting you install, delete, and otherwise make a mess of things
  without harming the real directory.
* Consistent permissions: `dockit` tries to set the ownership of files in the
  docked directory to a sensible user. This defaults to the `USER` specified in
  the image, if any, and `root` if not.
* Easy export: The `undock` command exports files you select back to the host.

## Caveats

* To allow for the exporting of files, the `/host` directory is mounted
  read-write. Changes inside that directory will impact the real host directory.
  Maybe don’t `rm -rf /`.
* To fix permissions, `dockit` runs a recursive `chown` on the overlay
  filesystem in `/docked`. If you `dockit` from a large directory, this could
  take a while. If your version of `overlayfs` doesn’t support the `metaonly`
  mount option, this will take even longer, and will result in a temporary copy
  of all the files in that directory inside a Docker volume.

## Installation

```bash
git clone https://github.com/awkspace/dockit
cd dockit
sudo ./install.sh
```

The included installer script will install `dockit` to `/usr/local`. If that
doesn’t meet your needs, you can also run it directly from the cloned copy as
`bin/dockit`.

## Usage

```text
dockit - Run a Docker image overlaid on the current directory

Usage: dockit [options] <image>

Options:
-h         this help text
-d         detach; run in background, useful for scripting
-n         no mount; just run the image
-m <user>  mount directory as <user> instead of default
-r <user>  run shell as <user> instead of default
```

## Exporting

If you’ve produced something inside the container that you’d like to move back
to the host, you can do so using the `undock` command from within the container.

```text
/docked # undock
Usage: undock <file1> [<file2>]...
```

## License

`dockit`, such as it is, is licensed under [MIT](LICENSE).
