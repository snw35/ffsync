# ffsync

Firefox Sync Server Docker Container.

This container image dramatically simplifies the deployment of a self-hosted Firefox Sync Server. It includes built-in MySQL/MariaDB and Postgres database support and runs with a default sqlite configuration out of the box.


## How to Use

### Run the container

The container exposes the Firefox sync server on tcp port 5000. You can start it like this:
```
docker run -dit --name ffsync -p 5000:5000 --mount source=ffsync,target=/data snw35/ffsync:latest
```
Browsing to http://localhost:5000/token/1.0/sync/1.5 should give you "It works!".

### Configure the sync server

The ffsync volume mounted at /data contains the configuration file (syncserver.ini) and default sqlite database (syncserver.db). You will need to edit the "public_url" option to reflect your connection address, and it would be a good idea to set a secret value as described here:

https://mozilla-services.readthedocs.io/en/latest/howtos/run-sync-1.5.html

```
docker exec -it ffsync sh
vi /data/syncserver.ini
```

The file itself has good documentation on what each option does, so it is a good idea to read through it and set as appropriate.

If you want to use a different database such as Postgres, you will need to edit the "sqluri" option. As an example, connecting to Postgres or MariaDB would look like:
```
sqluri = "postgres://username:password@hostname:5432/databasename"
or
sqlurl = "mysql://username:password@hostname:3306/databasename"
```

So you would create a database and user for this (probably called 'ffsync' or similar) and set that option. Also note that the ffsync and database containers will need to be on the same Docker network together for that to work.

Once you have finished configuring, stop and start the container to have your changes picked up by the sync server.

### Make it available

You can expose port 5000 on the container directly to the internet if you want, though Mozilla's documentation advises proxying through nginx or apache instead, and provides some examples on the documentation page:

https://mozilla-services.readthedocs.io/en/latest/howtos/run-sync-1.5.html

I serve this through my [le-docker](https://github.com/snw35/le-docker) frontend proxy system to have working SSL with letsencrypt certificates automatically generated and renewed for me. This gives you free HTTP->HTTPS redirection too.

### Configure your devices

Once you've made it available on the internet, you can then configure your devices to use it:

 1. If you already have a Firefox account and are signed in with it, then sign out on all of your devices first.

 1. Go to the first machine that you use Firefox on. Enter `about:config` into the address bar, accept the warning, then enter `identity.sync.tokenserver.uri` in the search bar.

 1. Change the `identity.sync.tokenserver.uri` setting to `https://your.domain/token/1.0/sync/1.5`. Note the `/token/` after the domain name. This is _not_ present in the default URL that Mozilla use, but is _required_ for your own sync server to work.

 1. Now you can create a Firefox account or login again using your existing one.

 1. When it asks you to enter the phone number of your mobile device, don't do it just yet.

 1. Open firefox on your phone and repeat steps 1 to 3 above, so your own sync server is specified before any data is sent.

 1. Now you can enter your number, hit send, then follow the link sent to your phone and log in to your Firefox account there. NOTE: syncing doesn't always look like it's working straight away, even when it is. A full restart of Firefox is usually required to force the interface to refresh and show it correctly syncing.

 1. Repeat the above steps until all of your devices are logged in.

 1. Enjoying being able to to sync your passwords, bookmarks and history in Firefox in complete privacy.

NOTE: You may have noticed that we still use Mozilla's servers to sign up and authenticate the Firefox account. This is actually fine as no browser data is sent to the authentication servers; they are just used to verify that your device should have access to the sync server in question (which is your own one in this case). Self-hosting the Firefox authentication services necessary avoid this is undocumented and likely very difficult.

### Make it permanent

If the "identity.sync.tokenserver.uri" setting is ever reset while you are signed in to your Firefox account, e.g if you do a 'refresh' in Firefox when it prompts you to, then Mozilla's server will be re-inserted there and all of your data will silently sync in the background to them, defeating the whole exercise.

To ensure that doesn't happen, you can (in Linux) create the file `/etc/firefox/pref/prefs.js` with the following content:
```
user_pref("identity.sync.tokenserver.uri", "https://your.domain/token/1.0/sync/1.5");
```

This will auto-apply the sync server setting to all instances of Firefox started on that machine. It's also possible to do this on Windows by placing the same file in the user profile, or the Firefox profile.


## Why Use This?

Firefox's sync feature is very useful if you use Firefox on more than one device. Simply create a Firefox account and away you go: all of your open tabs, history, bookmarks, saved passwords, etc will be synced between devices, and they will be restored if you ever wipe/lose your pc/laptop/phone.

__However:__ these are all stored on Mozilla's servers by default. (Or, more accurately, whichever cloud hosting provider Mozilla uses). This includes your saved passwords and, potentially, the history of every website you've ever visited through Firefox. This could be read by anyone with access to those machines e.g. an intern hired by the cloud hosting company.

I trust Mozilla more than most organizations, but this data is (very likely) highly personal and confidential, and I believe it should be hosted on a machine _you_ control. Whether this is your own Amazon EC2 instance, a VPS, or the old PC in the corner of your bedroom, as long as only _you_ have the passwords to it, then your privacy will be far more intact with this solution.

### Grandparents / Relatives...

I find this to be an excellent solution for relatives with low technical knowledge/patience. If you set them up with this, then they can save passwords for logins in Firefox so they don't need to remember them, and you can tell them to choose better passwords than they would otherwise (e.g misspell two words and stick them together). When they inevitably get a new device, wipe/sell/destroy the old one, and forget every password they've ever set, you can point their Firefox back to your sync server and all of their saved passwords, bookmarks, and history will be back, ready for them to click 'login' again without thinking about it.
