# Smart Proxy Shell Hooks

Provides an endpoint for foreman_webhooks plugin executing binaries (shell scripts, python scripts, anything).

## Running tests

Install the test dependencies and run the suite:

    bundle install
    bundle exec rake test

`bundle exec rake` also runs the tests. The test bundle uses Smart Proxy's
`develop` branch by default; set `SMART_PROXY_BRANCH` to test against another
branch. CI uses Foreman's shared Smart Proxy plugin workflow.

## Installation

Install the plugin using the foreman-installer. Never enable this service via HTTP endpoint, only HTTPS with authentication using client certificate and with trusted hosts should be used.

Open up `/var/lib/foreman-proxy/shellhooks` to see some examples, these are harmless stubs that do nothing as a starting point.

## Writing scripts

Script must be placed in `/var/lib/foreman-proxy/shellhooks` having a name consisting of alphanums, dash or underscore. The file must be executable. To see list of availble and valid scripts matching the requirements, perform:

    $ curl -s https://localhost:9090/shellhook/ | jq
    {
    "valid": [
        "print_args",
        "print_body",
        "my_script"
    ],
    "invalid": [
        "README"
    ]
    }

To execute an example script which prints input back to output (smart-proxy log):

    $ curl -sX POST -H 'Content-Type: text/plain' \
        --data "This is a test" \
        https://localhost:9090/shellhook/print_body

### Logging

To find out if the script was executed, open up smart-proxy log:

    2020-08-27T12:23:37 eabe1a74 [I] Started POST /shellhook/print_body
    2020-08-27T12:23:37 eabe1a74 [D] Headers: {"HTTP_HOST"=>"localhost:9090", "HTTP_USER_AGENT"=>"curl/7.69.1", "HTTP_ACCEPT"=>"*/*", "HTTP_VERSION"=>"HTTP/1.1"}
    2020-08-27T12:23:37 eabe1a74 [D] Body: This is a test
    2020-08-27T12:23:37 eabe1a74 [I] Finished POST /shellhook/print_body with 200 (0.68 ms)
    2020-08-27T12:23:37 eabe1a74 [I] [146347] Started task /home/lzap/work/smart_proxy_shellhooks/examples/print_body
    2020-08-27T12:23:37 eabe1a74 [D] [146347] This is a test

It is recommended to switch logging level to DEBUG when writing or editing scripts. Logging level is as follows:

* "Started task" initial message: INFO level
* Standard output: DEBUG level
* Standard error: WARNING level

### Arguments

Use X-Shellhook-Arg-1 to N HTTP header to send command arguments:

    curl -sX POST -H 'Content-Type: text/plain' \
        -H "X-Shellhook-Arg-1: Hello" \
        -H "X-Shellhook-Arg-2: World!" \
        --data "" https://localhost:9090/shellhook/print_args

This can be useful for passing database ID or other simple fields so standard JSON input does not need to be parsed. Use hammer command or python/ruby API to fetch relevant data.

### The contract

* The payload from foreman_webhook (rendered template) is connected to standard input of the script.
* Standard output and error are redirected into smart-proxy logger with an unique integer for each job.
* The script is executed asynchronously in a Ruby (green) thread, no return payload possible.
* The return (exit) value is only logged into the smart-proxy logger.
* Optionally HTTP headers X-Shellhook-Arg-1 to N are passed as arguments.
* HTTP return code is 200 when script was executed (not output) or non-200 when the plugin failed (not script).
* Keep in mind all the input is unsafe, clean every individual data element or argument to prevent security vulnerability.
* Example templates are shipped with foreman_webhooks plugin and few scripts with this plugin.
