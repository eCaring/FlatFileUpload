# FlatFileUpload

# Configuration

Copy care_recipient_flat_file_upload.json and update the token value.

````
{
  "token"  : "Paste here the FlatFileUploadToken provided by eCaring."
}

````

The script searches for the config file in the following locations:

* At the location specified with the `--config` option.
* In the current directory.
* Where the script resides.
* In the HOME directory

# Usage

````
Usage: care_recipient_flat_file_upload.rb [options] csv_files
Options:
    -c, --config=CONFIG_FILE         Config file to use (default: care_recipient_flat_file_upload.json
    -s, --server=SERVER              Server to connect to (if not in config file). (default: https://secure.ecaring.com)
    -t, --token=TOKEN                FlatFileUploadToken provided by eCaring (if not in config file).
    -d, --debug                      Debug mode
    -v, --verbose                    Verbose
        --test_mode                  Process CSV without recording data (test mode)
    -h, --help                       Prints this help
````

