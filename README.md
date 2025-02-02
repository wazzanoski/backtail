# backtail
A secure, minimal and lightweight container providing a backup destination (via SFTP) through Tailscale.

## Component Composition
- OS: alpine (https://hub.docker.com/_/alpine)
- OpenSSH (https://www.openssh.com)
- Tailscale (https://tailscale.com)

## Requirements & Layout

- Source Server
  - ssh-keygen
  - Tailscale connected Host or Container
- Destination Server
  - backtail Container
  - Backup Location

## Initual Setup on Unraid

### SFTP Authentication
On the Source Server that will be sending the files,
create a ssh key.
Example:
```
ssh-keygen -t ed25519 -f "/root/.ssh/id_backtail" -N ""
```
The generated file `id_backtail.pub` will need to be copied
to a new file `.ssh/authorized_keys` inside the Backup Location 
on the Destination Server.

An example approach to achieve this is to have an external USD drive initially attached 
to the Source Server (using Unassigned Devices)
and copy `id_backtail.pub` to `.ssh/authorized_keys` on the drive.
Additionally the drive can be initially
_seeded_ wih the backup files.
Once setup, the external USB drive can be disconnected from 
the Source Server and attched to the Destination Server.

### Backup Location 
On the Destination Server where the backtail container is installed,
create a location for the backup location.
This could be a Share or
an Unassigned Device Mount Point (such as using an external USB drive described above).
Set this Path as the 'Backups' Path in the backtail Container.
Example
```
/mnt/disks/BACKTAIL01
```

### Tailscale Authentication
Start the container and check the logs for the Tailscale authentication URL.
Example:
```
To authenticate, visit:

        https://login.tailscale.com/a/XXXXXXXXXXXXXX
```
After the machine is added to your tailnet, restart the container.

## SFTP Connection
Ontain an address for the machine from the Tailscale admin console (https://login.tailscale.com/admin/machines)
Initiate a SFTP connection from the Source Server.
When connecting, provide the private key created on initial setup.
The user is `backtail`.
Example:
```
sftp -i id_backtail backtail@XXX.XXX.XXX.XXX
```
On successful connection, you should see the following output:
```
   __            __   __       _ __
  / /  ___ _____/ /__/ /____ _(_) /
 / _ \/ _ `/ __/  '_/ __/ _ `/ / /
/_.__/\_,_/\__/_/\_\\__/\_,_/_/_/

Connected to XXX.XXX.XXX.XXX.
sftp>
```

## Sending Files
Manually send files using SFTP commands or use a tool 
such as Rclone (https://rclone.org) or Duplicati (https://duplicati.com) for a fully featured solution.
Specifics on the use of these tools is beyond the scope of this documentation 
- please conduct your own research to find the right approach for you.

## Banner Customisation
You can customise the banner text that is displayed when connected via sftp by editing the file 'banner.txt' in the Docker Config Path. 
