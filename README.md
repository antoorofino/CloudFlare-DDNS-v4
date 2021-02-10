# CloudFlare DDNS api-v4

Do you manage your DNS in CloudFlare but you don't have a static IP? The solution is `CF-DDNS-update.sh` !

<img src="./img/DDNS.png" alt="drawing" width="100"/>

The script will allow you to automatically update an existing DNS record (type A or AAAA) in your CloudFlare account.
It works using CloudFlare API-v4 (see documentation [here](https://api.cloudflare.com/)).

## Usage

In order to use the script you will need an API Token. You can simply run the script for a single-run update.
If you want to maintain your DNS record up to date you have to schedule the execution of the script: you can just add a line in your *crontab* file.\
For further details see the sections below.

### API Token

These are the steps to follow to generate the **API token**:
1. Go [here](https://dash.cloudflare.com/profile/api-tokens) and then in *Create Token*
2. Create Custom Token -> *Get Started*
3. Give a name to the Token
4. In *Permissions*:
	- Zone | Zone | Read
	- Zone | DNS | Write
5. In *Zone Resources*:
	- Include | Specific zone | ***your_dns _name_goes_here***

<img src="./img/Token_settings.png" alt="drawing" width="80%"/>

### Settings

The configuration must be held in a separate file or passed via command options.

#### Command options

This is the mandatory option (with the config file):
- `-c config_file_path`

These are the mandatory options (without the config file):
- `-s security_token`
- `-r record_name`
- `-z zone_name` 

These options can be omitted:
- `-t record_type` (*A* for IPv4 or *AAAA* for IPv6 - Default *A*)
- `-T record_ttl` (in seconds - Default *120*)
- `-p boolean` (*true* if proxied, *false* otherwise - Default *false*)
- `-f boolean` (*true* if you want to force the update even if the IP isn't changed - Default *false*)

#### Configuration file

See `cf_ddns_config_sample.sh` for an example.

### Automatic updates

You can set a crontab entry to schedule the execution of the script.
\
For example, this entry will execute the script every 10 minutes:
```
*/10 * * * * /*path_to_the_script*/CF-DDNS-update.sh -c *config_file_path* >> /dev/null 2>&1
```
You must add the entry at the end of the cron file. To open the cron file run `crontab -e`.

#### Log file

If you want the script to log the updates in a file, you can add a file as output:

```
*/10 * * * * /*path_to_the_script*/CF-DDNS-update.sh -c *config_file_path* >> /var/log/*log_file.log* 2>&1
```

where `/var/log/*log_file.log*` must be the full path of your file.

## IMPORTANT

In order to execute the script you must set the the right execution permissions to the file.\
You can simply run:
```
chmod +x /*path_to_the_script*/CF-DDNS-update.sh
```

### Dependencies

You'll need `jq` command-line JSON processor.