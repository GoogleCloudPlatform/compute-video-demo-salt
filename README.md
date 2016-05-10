## compute-video-demo-salt

This is the supporting documentation for **Using SaltStack with Google
Compute Engine**, one of the topics covered in the
*video-shorts series*, https://www.youtube.com/watch?v=0dOXbhenFl0

The goal of this repository is to provide the extra detail necessary for
you to completely replicate the recorded demo. The video's main goal
is to show a quick, fully working demo without bogging you down with all
of the required details so you can easily see the "Good Stuff".

At the end of the demo, you will have used SaltStack to automate:
* Creating 4 Compute Engine instances
* Install the Apache web server on each
* Enable Apache's `mod_headers` module
* Use a SaltStack `grain` and jinja2 template to create a custom site page
* Allow HTTP traffic to the instances with a custom firewall rule
* Create a Compute Engine Load-balancer to distribute traffic over the 4 instances
* Do a live test of the full configuration

This is intended to be a fairly trival example. The video and repo show off
the integration between SalStack and Google Compute Engine.  And, this can be
the foundational tools for building more real-world configurations.

## Google Cloud Platform Project

1. You will need to create a Google Cloud Platform Project as a first step.
Make sure you are logged in to your Google Account (gmail, Google+, etc) and
point your browser to https://console.cloud.google.com/projectselector/compute/instances. You should see a
page asking you to create your first Project.

1. When creating a Project, you will see a pop-up dialog box. You can specify
custom names but the *Project ID* is globally unique across all Google Cloud
Platform customers.

1. It's OK to create a Project first, but you will need to set up billing
before you can create any virtual machines with Compute Engine. Find the menu icon at the top left, 
then look for the *Billing* link in the navigation bar.

1. In order for `salt-cloud` to create Compute Engine instances, you'll need a
[Service Account](https://cloud.google.com/compute/docs/access/service-accounts#serviceaccount)
Make sure to download (or generate a new) P12 formatted private key file
for your Service Account. Also, make sure to record the *Email address* that
ends with `@developer.gserviceaccount.com` since this will be required in the
Salt configuration files.

1. Next you will want to install the
[Cloud SDK](https://cloud.google.com/sdk/) and make sure you've
successfully authenticated and set your default project as instructed.

## Create the Salt Master Compute Engine instance

Next you will create a Virtual Machine for your Salt Master named `salt` so
that your managed nodes (or minions) will be able to automatcially find the
master. When creating your Master, make sure to enable the `compute` scope
for *read/write* authorization.

You can create the master in the
[Developers Console](https://console.developers.google.com/)  under the
*Compute Engine -&gt; VM Instances* section and then click the *New instance*
button. You may explore around the form to find the appropriate section for
setting the `compute` *read/write* scope for your new Master.

Or, you can create the Salt master with the `gcloud` command-line utility
(part of the Cloud SDK) from your local workstation with the following
commands:

```
# Create the instance with the proper scope
gcloud compute instances create salt --scopes https://www.googleapis.com/auth/compute --image debian-7 --zone us-central1-b --machine-type n1-standard-1
Created [https://www.googleapis.com/compute/v1/projects/YOUR-PROJECT/zones/us-central1-b/instances/salt].
NAME ZONE          MACHINE_TYPE  INTERNAL_IP    EXTERNAL_IP     STATUS
salt us-central1-b n1-standard-1 10.240.136.204 123.45.67.89    RUNNING
```

## Software

1. SSH to your Salt master and then become root
    ```
    gcloud compute ssh salt --zone us-central1-b
    sudo -i
    ```
  1. Create a Compute Engine SSH key.
  
  If you do not have an existing key, you will be prompted to create one.  Use an Empty Passphrase for the purposes of this demo.  The key will be generated and you will then be logged into the Salt master.  The full output will look similar to:
    ```
    you@your-host:~$ gcloud compute ssh salt --zone us-central1-b
    WARNING: The private SSH key file for Google Compute Engine does not exist.
    WARNING: You do not have an SSH key for Google Compute Engine.
    WARNING: [/usr/bin/ssh-keygen] will be executed to generate a key.
    Generating public/private rsa key pair.
    Enter passphrase (empty for no passphrase):
    Enter same passphrase again:
    Your identification has been saved in /home/user/you/.ssh/google_compute_engine.
    Your public key has been saved in /home/user/you/.ssh/google_compute_engine.pub.
    The key fingerprint is:
    SHA256:OUWq8Hbg5PcFhkG2iSDJJItBZJ0rIOrzbf9BSlwNXo4 you@your-host
    The key's randomart image is:
    +---[RSA 2048]----+
    |=*+.o  .+...     |
    |=+o+ . o.B*      |
    |*   o + =E+o     |
    |.. . *.o.+ .     |
    |. .   *oS.  .    |
    | o   ..ooo .     |
    |  o .  . ..      |
    |   . o    .      |
    |    . ....       |
    +----[SHA256]-----+
    Updated [https://www.googleapis.com/compute/v1/projects/your-project-id].
    Warning: Permanently added '104.197.232.237' (ECDSA) to the list of known hosts.
    Warning: Permanently added '104.197.232.237' (ECDSA) to the list of known hosts.
    Linux salt 3.2.0-4-amd64 #1 SMP Debian 3.2.78-1 x86_64
    
    The programs included with the Debian GNU/Linux system are free software;
    the exact distribution terms for each program are described in the
    individual files in /usr/share/doc/*/copyright.
    
    Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
    permitted by applicable law.
    you@salt:~$
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

1. Install salt (v2014.1.4 or greater)
    ```
    curl -o salt_install.sh -L http://bootstrap.saltstack.org
    sh salt_install.sh -M -N git v2014.1.10

    # v2014.1.x is missing some GCE capabilities so let's copy a version
    # from 'develop' known to work with v2014.1.10 and replace the module
    wget https://github.com/saltstack/salt/raw/d99e639411d85fd26f3f120b3266106d61026ea4/salt/cloud/clouds/gce.py
    cp gce.py /usr/lib/python2.7/dist-packages/salt/cloud/clouds/gce.py
    ```

## Salt-Cloud and Demo Setup

1. For the Demo, check out this repository so that you can use pre-canned
configuration and demo files.
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

1. Now copy over the demo state files that configure each minion.
    ```
    cp -R ~/compute-video-demo-salt/srv/* /srv
    ```

1. Now you will need to get a copy of your private Service Account key
uploaded to your `salt` master in the proper format.  Once uploaded, you can
convert the Service Account private key file from the PKCS12 format to the
RSA/PEM file format.  You can do that with the `openssl` utility,
    ```
    openssl pkcs12 -in /path/to/original/key.p12 -passin pass:notasecret -nodes -nocerts | openssl rsa -out /etc/salt/pkey.pem

    # Since this is your private key, you should set appropriate permissions
    chmod 600 /etc/salt/pkey.pem
    ```

1. Lastly, edit the `/etc/salt/cloud` file and specify set your Project ID in
the `project` parameter and also set your `service_account_email_address`. Note
that if you used an alternate location for your converted Service Account key,
make sure to also adjust the `service_account_private_key` variable.

1. You can verify that everything is working by using a standard `salt-cloud`
command to list Compute Engine zones (e.g. locations) with,
    ```
    salt-cloud --list-locations gce
    ```

# Demo time!

You've now completed all of the necessary setup to replicate the demo as
shown on the video. Now, you'll use `salt-cloud` to create and bootstrap
the minions, install Apache, and set up a Compute Engine load-balancer.

You can also watch a replay of this terminal session at
http://asciinema.org/a/10422

## Create Minions

Use the `salt-cloud` command to create the Salt minions based on the
attributes in the configuration files. For the four instances, this
should take roughly 2 minutes to create the new Compute Engine
instances and bootstrap them with the Salt agent software.  Note that we're
specifying the parallel-mode (`-P`) to create all of the minions
simultaneously.

```
salt-cloud -P -y -m /etc/salt/demo.map
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
minion-1:
    Linux minion-1 3.2.0-4-amd64 #1 SMP Debian 3.2.51-1 x86_64 GNU/Linux
minion-2:
    Linux minion-2 3.2.0-4-amd64 #1 SMP Debian 3.2.51-1 x86_64 GNU/Linux
minion-4:
    Linux minion-4 3.2.0-4-amd64 #1 SMP Debian 3.2.51-1 x86_64 GNU/Linux
minion-3:
    Linux minion-3 3.2.0-4-amd64 #1 SMP Debian 3.2.51-1 x86_64 GNU/Linux
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
    salt-cloud -f create_fwrule gce name=allow-http network=default allow=tcp:80
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
    salt-cloud -f create_lb gce name=lb region=us-central1 ports=80 members=minion-1,minion-2,minion-3,minion-4
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
accumulate additional charges if you do not remove these resources.

Fortunately, `salt-cloud` also provides commands for destroying Compute
Engine resources. The following commands can be used to destroy all of the
resources created by salt-cloud for this demo.

```
salt-cloud -d -m /etc/salt/demo.map
salt-cloud -f delete_fwrule gce name=allow-http
salt-cloud -f delete_lb gce name=lb
```

If you'd like to destroy the Salt master as well, please do so via the
[Developers Console](https://console.developers.google.com/) under the 
*Compute Engine -&gt; VM Instances* section or by running this command from where you created the instance:

```
gcloud compute instances delete salt --zone us-central1-b
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

