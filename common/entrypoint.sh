#!/bin/sh

# Set defaults for uid and gid to not be root
GID="${GID:-100}"
UID="${UID:-1000}"

if [ "$GID" -ne "0" ]; then
	GROUP=jdownloader
	# Group may already exist (pre-existing GID in the image, or a
	# previous run in the same container layer) - don't error out.
	getent group "$GID" >/dev/null 2>&1 || groupadd -g $GID $GROUP
else
	GROUP=root
fi

if [ "$UID" -ne "0" ]; then
    USER=jdownloader

    # Create user without home (-M) and remove login shell.
    # Skip if it already exists (e.g. a restart of the same container).
    id -u "$USER" >/dev/null 2>&1 || useradd -M -s /bin/false -g $GID -u $UID $USER
else
    USER=root
fi

# Set MyJDownloader credentials. EMAIL and PASSWORD are applied
# independently so setting one never blanks out the other.
CONFIG_FILE="/opt/JDownloader/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json"
if [ ! -z "$EMAIL" ] || [ ! -z "$PASSWORD" ]; then
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ] ; then
        echo '{}' > "$CONFIG_FILE"
    fi

    CFG=$(cat "$CONFIG_FILE")
    [ ! -z "$EMAIL" ] && CFG=$(echo "$CFG" | jq -r --arg EMAIL "$EMAIL" '.email = $EMAIL')
    [ ! -z "$PASSWORD" ] && CFG=$(echo "$CFG" | jq -r --arg PASSWORD "$PASSWORD" '.password = $PASSWORD')
    [ ! -z "$CFG" ] && echo "$CFG" > "$CONFIG_FILE"
fi

# cfg only ever holds a handful of small config files, so it's cheap to
# keep in sync on every start (covers the credentials file written above).
chown -R $UID:$GID /opt/JDownloader/cfg

# Recursively chowning the whole tree (Downloads included) on every
# restart is expensive on large libraries / network shares. Only do it
# when the target UID:GID actually changed since the last run.
CHOWN_MARKER="/opt/JDownloader/cfg/.last-chown-uidgid"
if [ "$(cat "$CHOWN_MARKER" 2>/dev/null)" != "$UID:$GID" ]; then
    chown -R $UID:$GID /opt/JDownloader
    echo "$UID:$GID" > "$CHOWN_MARKER"
fi

# Sometimes this gets deleted. Just copy it every time.
cp /opt/JDownloader/sevenzip* /opt/JDownloader/libs/

umask "${UMASK:-000}"
su-exec ${UID}:${GID} "$@"

# Keep container alive when jd2 restarts
while sleep 3600; do :; done
