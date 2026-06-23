[![Build and Test](https://github.com/KrX3D/headless-jd2-docker/actions/workflows/build.yml/badge.svg)](https://github.com/KrX3D/headless-jd2-docker/actions/workflows/build.yml)

# headless-jd2-docker

Headless [JDownloader 2](https://jdownloader.org/) in Docker. Runs as a specified UID/GID so downloaded files are owned by the right user, with a configurable umask for SMB/Windows share compatibility.

# Supported tags

* [`latest`, `debian` (debian.Dockerfile)](https://github.com/KrX3D/headless-jd2-docker/blob/master/debian.Dockerfile) — Java 21 LTS on Ubuntu 22.04 (recommended)
* [`alpine` (alpine.Dockerfile)](https://github.com/KrX3D/headless-jd2-docker/blob/master/alpine.Dockerfile) — Java 21 LTS on Alpine Linux

# Running the container

1. Create folders on your host for config and downloads:

    ```sh
    mkdir -p /config/jd2 /home/user/Downloads
    ```

2. Run the container:

    ```sh
    docker run -d --name jd2 \
        -e EMAIL=my@mail.com \
        -e PASSWORD=my_secret_password \
        -v /config/jd2:/opt/JDownloader/cfg \
        -v /home/user/Downloads:/opt/JDownloader/Downloads \
        krx3d/jdownloader2-headless
    ```

If you don't want to pass credentials on the command line, omit the `-e EMAIL` and `-e PASSWORD` flags and add them manually to `<config-dir>/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json`:

```json
{ "email": "my@mail.com", "password": "my_secret_password" }
```

# Environment variables

| Variable   | Default | Description |
|------------|---------|-------------|
| `EMAIL`    | —       | MyJDownloader account e-mail. Written to the config file on startup if set. |
| `PASSWORD` | —       | MyJDownloader account password. Written to the config file on startup if set. |
| `UID`      | `1000`  | UID the JDownloader process runs as. All downloaded files are owned by this UID. |
| `GID`      | `100`   | GID for all downloaded files. |
| `UMASK`    | `000`   | umask applied before JDownloader starts. See below. |

## UMASK

The `UMASK` variable controls the permissions of files and directories created by JDownloader:

| `UMASK` | Dir permissions | File permissions | Use case |
|---------|----------------|-----------------|----------|
| `000`   | `777` (rwxrwxrwx) | `666` (rw-rw-rw-) | Default — fully writable, required for SMB/Windows access |
| `002`   | `775` (rwxrwxr-x) | `664` (rw-rw-r--) | Group-writable |
| `022`   | `755` (rwxr-xr-x) | `644` (rw-r--r--) | Standard Unix permissions |

The default `000` means downloaded files can be moved and deleted from Windows over SMB without needing a periodic `chmod` job. Tighten it with `-e UMASK=022` if you prefer standard Unix permissions.

# Unraid / SMB example

For Unraid where the SMB user is `nobody` (UID 99) in the `users` group (GID 100):

```sh
docker run -d --name jd2 \
    -e UID=99 \
    -e GID=100 \
    -e UMASK=000 \
    -v /mnt/user/appdata/jd2:/opt/JDownloader/cfg \
    -v /mnt/user/Downloads:/opt/JDownloader/Downloads \
    krx3d/jdownloader2-headless
```

Files will be owned by `nobody:users` and created with permissions `666`/`777`, making them fully manageable from Windows over SMB.

# docker-compose example

```yaml
services:
  jdownloader:
    image: krx3d/jdownloader2-headless
    container_name: jd2
    restart: unless-stopped
    environment:
      - EMAIL=my@mail.com
      - PASSWORD=my_secret_password
      - UID=99
      - GID=100
      - UMASK=000
    volumes:
      - /mnt/user/appdata/jd2:/opt/JDownloader/cfg
      - /mnt/user/Downloads:/opt/JDownloader/Downloads
```
