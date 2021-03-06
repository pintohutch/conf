#!/usr/bin/env bash

set -ex
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

usage() {
  cat >&2 <<EOF

usage: $(basename "$0") <args>
  $(basename "$0") backs up documents to the desired SMB remote path.

args:
  --remotedir, -r <remotedir>  Remote directory path to mount.
  --localdir, -l <localdir>  Local directory to mount to.
  --user, -u <user>  Username to mount as.
  --password, -p <password>  Password for specified user to mount drive.
  --backupdir, -b [backupdir]  Local directory to backup. Default is $HOME directory.

example:
  smb_backup.sh --remotedir 192.168.1.188/backup \
                --localdir ~/Desktop/backup \
                --user admin \
                --password password1234 \
                --backupdir $HOME
EOF
}

parse_args() {
  BACKUPDIR="$HOME"
  while :; do
    case $1 in
      -h|--help)
        usage
        exit
        ;;
      -b|--backupdir)
        if [ -n "$2" ]; then
          BACKUPDIR=$2
          shift
          shift
        else
          echo -e "ERROR: '--backupdir' requires a non-empty string argument" >&2
          usage
          exit 1
        fi
        ;;
      -r|--remotedir)
        if [ -n "$2" ]; then
          REMOTEDIR=$2
          shift
          shift
        else
          echo -e "ERROR: '--remotedir' requires a non-empty string argument" >&2
          usage
          exit 1
        fi
        ;;
      -l|--localdir)
        if [ -n "$2" ]; then
          LOCALDIR=$2
          shift
          shift
        else
          echo -e "ERROR: '--localdir' requires a non-empty string argument" >&2
          usage
          exit 1
        fi
        ;;
      -u|--user)
        if [ -n "$2" ]; then
          USER=$2
          shift
          shift
        else
          echo -e "ERROR: '--user' requires a non-empty string argument" >&2
          usage
          exit 1
        fi
        ;;
      -p|--password)
        if [ -n "$2" ]; then
          PASSWORD=$2
          shift
          shift
        else
          echo -e "ERROR: '--password' requires a non-empty string argument" >&2
          usage
          exit 1
        fi
        ;;
      *)
        if [ -n "$REMOTEDIR" ] && [ -n "$LOCALDIR" ] && [ -n "$USER" ] && [ -n "$PASSWORD" ]; then
          break
        else
          echo -e "ERROR: specify '--remotedir', '--localdir', '--user', and '--password' args" >&2
          usage
          exit 1
        fi
        ;;
    esac
  done
}

main() {
  # Parse input arguments.
  parse_args "$@"

  # Make local directory if it does not exist.
  if [ ! -d "$LOCALDIR" ]; then
    mkdir -p "$LOCALDIR"
  fi

  # If the drive already is not mounted, mount it.
  if mount | grep $REMOTEDIR > /dev/null; then
    echo "$REMOTEDIR already mounted."
  else
    echo "Mounting remote..."
    mount -t smbfs //"$USER":"$PASSWORD"@"$REMOTEDIR" "$LOCALDIR"
  fi

  # Do rsync copy over.
  echo "Running rsync backup..."
  rsync -ahzP "$BACKUPDIR" "$LOCALDIR" \
      --exclude 'Library' \
      --exclude '.*' \
      --exclude 'Dropbox' \
      --exclude 'Applications' \
      --size-only \
      --delete-during
}

main "$@"
