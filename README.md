## compute-video-demo-salt

This is the supporting documentation for **Using SaltStack with Google
Compute Engine**, one of the topics covered in the
*video-shorts series* [TODO: link].

The goal of this repository is to provide the extra detail necessary for
you to completely replicate the recorded demo. The video's main goal
is to show a quick, fully working demo without bogging you down with all
of the required details so you can easily see the "Good Stuff".

So for interested viewers wanting to replicate the demo on their own, this
repository contains all those necessary details.

## Google Cloud Platform Project

1. You will need to create a Google Cloud Platform Project as a first step.
Make sure you are logged in to your Google Account (gmail, Google+, etc) and
point your browser to https://cloud.google.com/console.  You should see a
page asking you to create your first Project.

1. When creating a Project, you will see a pop-up dialog box. You can specify
custom names but the *Project ID* is globally unique across all Google Cloud
Platform customers.

1. It's OK to create a Project first, but you will need to set up billing
before you can create any virtual machines with Compute Engine. Look for the
*Billing* link in the left-hand navigation bar.

1. In order for `salt-cloud` to create Compute Engine instances, you'll need a
[Service Account](https://developers.google.com/console/help/#service_accounts)
created for the appropriate authorization. Navigate to
*APIs &amp; auth -&gt; Credentials* and then *Create New Client ID*. Make sure
to select *Service Account*. Google will generate a new private key and prompt
you to save the file and let you know that it was created with the *notasecret*
passphrase. Once you save the key file, make sure to record the
*Email address* that ends with `@developer.gserviceaccount.com` since this
will be required in the Salt configuration files.

1. Next you will want to install the [Cloud SDK](https://developers.google.com/cloud/sdk/)
and make sure you've successfully authenticated and set your default project
as instructed.

## Create the Salt Master Compute Engine instance

Next you will create a Virtual Machine for your Salt Master named `salt` so
that your managed nodes (or minions) will be able to automatcially find the
master.

You can create the master in the
[Developers Console](https://cloud.google.com/console)  under the
*Compute Engine -&gt; VM Instances* section and then click the *NEW INSTANCE*
button.

Or, you can create the Salt master either with the `gcutil` command-line
utility (part of the Cloud SDK) with the following command:

```
# Make sure to use a Debian-7-wheezy image for this demo
gcutil addinstance salt --image=debian-7 --zone=us-central1-b --machine_type=n1-standard-1
```

## Software

1. SSH to your Salt master and then become root
    ```
    gcutil ssh salt
    sudo -i
    ```

1. Update packages and install dependencies
    ```
    apt-get update
    apt-get install python-pip git -y
    ```

1. Install libcloud (v0.14.1 or greater)
    ```
    pip install apache-libcloud
    ```

1. Install salt (Hydrogen, v2014.1.0)
    ```
    curl -o salt_install.sh -L http://bootstrap.saltstack.org
    sh salt_install.sh -M -N git v2014.1.0

    # sigh... gce is broken in 2014.1.0
    wget https://raw.github.com/saltstack/salt/develop/salt/cloud/clouds/gce.py
    cp gce.py /usr/lib/python2.7/dist-packages/salt/cloud/clouds/gce.py
    ```

1. Create a Compute Engine SSH key and upload it to the metadata server.
The easist way to do this is to use the gcutil command-line utility and
try to SSH from the machine back into itself.  Since you are using the root
account, you need an additional flag.

    Cut/paste the generated URL into a browser that is authenticated with your
Google account. Accept the OAuth permissions and cut/paste the verification
code into your terminal.

    When prompted, use an Empty Passphrase for the demo. Once logged in through
this gcutil ssh command, go ahead and log back out. The full output will look
similar to,
    ```
    root@salt:~# gcutil ssh --ssh_key_push_wait_time=30 --permit_root_ssh $(hostname -s)
    Service account scopes are not enabled for default on this instance. Using manual authentication.
    Go to the following link in your browser:

        https://accounts.google.com/o/oauth2/auth?scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcompute+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fdevstorage.full_control+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&response_type=code&client_id=1111111111111.apps.googleusercontent.com&access_type=offline

    Enter verification code: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    Authentication successful.
    INFO: Zone for salt detected as us-central1-b.
    WARNING: You don't have an ssh key for Google Compute Engine. Creating one now...
    Enter passphrase (empty for no passphrase): 
    Enter same passphrase again: 
    INFO: Updated project with new ssh key. It can take several minutes for the instance to pick up the key.
    INFO: Waiting 30 seconds before attempting to connect.
    INFO: Running command line: ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no -i /root/.ssh/google_compute_engine -A -p 22 root@123.45.67.89 --
    Warning: Permanently added '123.45.67.89' (ECDSA) to the list of known hosts.
    Linux salt 3.2.0-4-amd64 #1 SMP Debian 3.2.51-1 x86_64

    The programs included with the Debian GNU/Linux system are free software;
    the exact distribution terms for each program are described in the
    individual files in /usr/share/doc/*/copyright.

    Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
    permitted by applicable law.
    root@salt:~# exit
    logout
    Connection to 123.48.67.89 closed.
    WARNING: There is a new version of gcutil available. Go to: https://developers.google.com/compute/docs/gcutil
    WARNING: Your version of gcutil is 1.12.0, the latest version is 1.13.0.
    root@salt:~# 
    ```

## Salt-Cloud setup

1. Check out this repositroy so that you can use pre-canned configuration
and demo files.
    ```
    cd $HOME
    git clone https://github.com/GoogleCloudPlatform/compute-video-demo-salt
    ```

1. The `salt-cloud` utility has its own set of configuration files. This repo
contains the sample configuration files needed for the demo, but you will need
to customize them with your credentials.
    ```
    cp -R ~/compute-video-demo-salt/etc/* /etc
    ```

1. You will need to convert the Service Account private key file from the
PKCS12 format to the RSA/PEM file format.  You can do that with the `openssl`
utility,
    ```
    openssl pkcs12 -in /path/to/original/key.p12 -passin pass:notasecret -nodes -nocerts | openssl rsa -out /etc/salt/pkey.pem
    ```

1. Edit the `/etc/salt/cloud` file and specify set your Project ID in the
`project` parameter and also set your `service_account_email_address`. Note
that if you used an alternate location for your converted Service Account key,
make sure to also adjust the `service_account_private_key` variable.

1. Now that `salt-cloud` is configured, you'll need to copy over the demo
state files that configure each minion.
    ```
    cp -R ~/compute-video-demo-salt/srv/* /srv
    ```

# Demo time!

You've now completed all of the necessary setup to replicate the demo as
shown on the video. Now, you'll use `salt-cloud` to create and bootstrap
the minions, install Apache, and set up a Compute Engine load-balancer.

## Create Minions

Use the `salt-cloud` command to create the Salt minions based on the
attributes in the configuration files. For the four instances, this
should take roughly 2 minutes to create the new Compute Engine
instances and bootstrap them with the Salt agent software.  Note that we're
specifying the parallel-mode (`-P`) to create all of the minions
simultaneously.

```
salt-cloud -P -y -m /etc/salt/demo.map --out=pprint
```

## A quick test and demo of remote execution

Now that the minions have been created and bootstrapped. You can make sure
that everything was set up correctly by using Salt's remote execution
framework.  Try the following to execute a command on each instance and
see the resulting output,

```
salt '*' cmd.run "uname -a"
```

You should see something very similar to,

```
myinstance1:
    Linux myinstance1 3.2.0-4-amd64 #1 SMP Debian 3.2.51-1 x86_64 GNU/Linux
myinstance2:
    Linux myinstance2 3.2.0-4-amd64 #1 SMP Debian 3.2.51-1 x86_64 GNU/Linux
myinstance4:
    Linux myinstance4 3.2.0-4-amd64 #1 SMP Debian 3.2.51-1 x86_64 GNU/Linux
myinstance3:
    Linux myinstance3 3.2.0-4-amd64 #1 SMP Debian 3.2.51-1 x86_64 GNU/Linux
```

## Minion configuration

Ok, now that you have your minions up and running, you can proceed with the
demo and use the state files to install Apache, enable `mod_headers`, and set
a custom landing page for the site by running triggering `highstate`. This
should take around 15-20 seconds to complete.

```
salt '*' state.highstate
```

## Firewall rule

1. Great, now you have salt minions serving a custom site page via Apache!
But if you've tried to view one of your instance's site via it's public IP,
you'll notice that it's not working. The reason is that, by default, no
external network traffic is allowed to reach your Compute Engine instances
(except for SSH on port 22). In order to allow HTTP (port 80) traffice to 
your instances, you must first create a firewall rule on your `default`
network.

    Fortunately, `salt-cloud` has this capability. If you're not used to the
syntax below, you are calling the `create_fwrule` function (`-f`) and
specifying the privider (`gce` in this case). Next, you are providing the
minimum required parameters to create the rule. This command should take around
5-10 seconds to complete.
    ```
    salt-cloud -f create_fwrule gce name=allow-http network=default allow=tcp:80 --out=pprint
    ```

1. Now, if you like, you can put the public IP address of one of your instances
into your browser and you should be able to see a simple web page with the
instance name.

## Load-balancer

1. Now that you've created the minions, each serving a custom site page via
Apache, you'll want to set up a Compute Engine
[Load Balancer](https://developers.google.com/compute/docs/load-balancing/).
You can use `salt-cloud` with a command similar to the one below. Make sure
you specify the correct `region` where your instances reside (this is likely
`us-central1` if you've used all of the default files in this repository.
This command should take around 10-15 seconds to complete.
    ```
    salt-cloud -f create_lb gce name=lb region=us-central1 ports=80 members=myinstance1,myinstance2,myinstance3,myinstance4 --out=pprint
    ```

1. The output from this command will display the public IP address associated
with your new load-balancer. You can also look in the Developers Console
under the Load-Balancer section and look at your Forwarding Rules.

1. Ok, let's test it out! Put the public IP address of your load-balancer into
your browser and take a look at the result. Within a few seconds you should
start to see a flicker of pages that will randomly bounce across each of your
instances.

    For the demo, a javascript function is set to fire when the page loads
that pauses for a half-second, and then reloads itself. Since we installed
a modified Apache configuraiton file to disable client-side caching *and* we
enabled Apache's `mod_headers`, each "reload" results in a new HTTP request
to the page. This is just a fancy hands-free way of asking you to do a
"hard refresh" of the load-balancer IP address in order to see the cycling
between instances.

# All done!

That's it for the demo. There is a lot of other functionality for
Compute Engine in the `salt-cloud` utility. Please take a look at the
[docs](http://docs.saltstack.com/topics/cloud/gce.html) for a full set of
instructions and sample commands.

## Cleaning up

When you're done with the demo, make sure to tear down all of your
instances and clean-up. You will get charged for this usage and you will
accumulate additional charges if you leave do not remove these resources.

Fortunately, `salt-cloud` also provides commands for destroying Compute
Engine resources. The following commands can be used to destroy all of the
resources created for this demo.

```
salt-cloud -d -m /etc/salt/demo.map
salt-cloud -f delete_fwrule gce name=allow-http
salt-cloud -f delete_lb gce name=lb
```

## Troubleshooting

* Make sure you have the latest libcloud (the `pip` install is probably best) and
  [`gce.py`](https://github.com/saltstack/salt/blob/develop/salt/cloud/clouds/gce.py)
  provider installed.

* Minions not updating: In some rare cases, the bootstrapped minions may not
  come up in a clean state. You can usually verify this if you try the ping
  test and see missing or extra minions (e.g. `salt '*' test.ping`). If this
  happens, the easiest thing to do is to fully restart the salt-minion service
  on each node. You can use a shell script like this to ensure that all
  salt-minion process are fully terminated and restarted cleanly,

    ```
    for m in myinstance{1..4}
    do
        gcutil ssh --permit_root_ssh $m /etc/init.d/salt-minion stop
        gcutil ssh --permit_root_ssh $m pkill salt-minion
        gcutil ssh --permit_root_ssh $m /etc/init.d/salt-minion start
    done
    ```

## Contributing

Have a patch that will benefit this project? Awesome! Follow these steps to have it accepted.

1. Please sign our [Contributor License Agreement](CONTRIB.md).
1. Fork this Git repository and make your changes.
1. Run the unit tests. (gcimagebundle only)
1. Create a Pull Request
1. Incorporate review feedback to your changes.
1. Accepted!

## License
All files in this repository are under the
[Apache License, Version 2.0](LICENSE) unless noted otherwise.

