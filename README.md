# Snapscatter

This script creates snapshots from EBS volumes and copies them across regions for disaster recovery.
If your volume is used for database storage, this script can make sure your backup is consistent by
flushing and stopping writes until the snapshot is complete.

This script also purges old snapshots according to a simple retention policy specified by you, to keep
your Amazon AWS bills under control.

## Installation

Just use the gem command to install:

    $ gem install snapscatter

## Usage

You can have a look at the commands and options by just typing the name of the executable:

    Snapscatter commands:
      snapscatter create          # Create snapshots, optionally copying them to an alternate region
      snapscatter help [COMMAND]  # Describe available commands or one specific command
      snapscatter list            # Show available snapshots
      snapscatter purge           # purge snapshots older than the specified number of days
      snapscatter targets         # Show volumes tagged for backup
      snapscatter version         # Shows current version of the program

The best way to use this script is to make a shell wrapper for it that exports your AWS credentials
as environment variables and then put it under the control of the cron demon.

### Specifying volumes to backup

You should use the AWS console to mark the volumes you want to be backed up using the tag `Backup` with a
value of `true`. You can then check the list of these volumes using the command `targets`.

### Taking snapshots

Use the command `create` to take snapshots of all the tagged volumes. Snapshots will be taken to your default
AWS region, but you can optionally supply the `--alternate` flag to create a copy onto another
region for disaster recovery.

Every snapshot taken will have the `PurgeAllow` tag set with the value of `true`. If for some reason you want
a snapshot not to be purged indefinitely, you can set this tag to any other value, or even remove the tag
 altogether.

### Purging snapshots

You can call the `purge` command to delete any snapshots older than 30 days. This is the default retention policy
but you can change it by using the optional `-d` flag (for `--days`).

Snapshots will be deleted from your default AWS region. If you supply the `--alternate` flag, snapshots will also
be purged from the alternate region.

You can also run this command with the `-n` (for `--noaction`) to only list the snapshots that would be purged
under the specified retention policy, no snapshot will be purged.

### Listing snapshots

The `list` command will show all the snapshots subject to be purged, that is, all snapshots with the `PurgAllow`
tag set to `true`. The `-f` option for this command gives more information on every snapshot: snapshot id, volume id
and date of creation. Using the `-r` or `--region` flag you can change the target region.

### Consistent backups

If the volumes your attempting to snapshot are being used by a database, then you want to force a flush to disk and
stop writing so you can have a consistent backup. This script can do that for you (currently it only supports MongoDB).

To use this feature, you can tag the volume with the `Consistent` tag. The value of this tag contains the connection
information, as key-value pairs separated by commas, so that the script can have access to the database, flush and
stop writes until the snapshot has been taken. Here's an example:

    strategy: mongo, host: 127.0.0.1, port: 27017, usr: admin, pwd: 12345

## Example

Create a shell file like the following and put it under cron's control:

    #!/bin/sh

    export AWS_ACCESS_KEY_ID="YOURACCESSKEY"
    export AWS_SECRET_ACCESS_KEY="YOURSECRETACCESSKEY"

    snapscatter purge -d 20
    snapscatter create --alternate="us-west-1"

You have to make two calls because the script won't purge and create snapshots on a single call.

## TODO

* Take consistency specification out of the volume and put it in a configuration file
* More database connectors

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
