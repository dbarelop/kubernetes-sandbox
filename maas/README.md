# MAAS v2.0 command-line basic operations
["The MAAS CLI can do everything that the web UI can do, and more"](http://maas.io/docs/en/manage-cli). This is a record of the basic operations a MAAS server can perform and how to trigger them from the command line.
## Login
The first thing a user has to do is log in to the API server. For that, the API key generated upon the MAAS account creation will be needed: `$MAAS_KEY`. It is necessary to login only once, the commands following the login command will use the existing session:
```shell
$ maas login $USER http://$MAAS_SERVER/MAAS/api/2.0/ "$MAAS_KEY"
```
## Configure user's SSH keys
In order to log in to the deployed machines, a user needs to add their SSH public key to the MAAS system. This can be done using `maas` client with this command:
```shell
$ maas $USER sshkeys create "key=$(cat ~/.ssh/id_rsa.pub)"
```
## Deploy a machine
Deployment takes to steps: allocating the machine and actually deploying the system.
Allocating a given machine using a certain hostname, `$HOSTNAME` can be done with the following command:
```shell
$ maas $USER machines allocate hostname=$HOSTNAME
```
Now that the user has allocated the machine, it is ready for deployment.
To do so the user has to obtain the machine's `system_id` attribute of the machine, assigned by MAAS system and then use the command-line utility to perform the deployment:
```shell
$ system_id=$(maas $USER machines read | jq -r "map(select(.hostname == \"$HOSTNAME\")) | .[] | .system_id")
$ maas $USER machine deploy $system_id
```
After the system is deployed the user will be able to login into the newly created system using their SSH keys.
## Release (destroy) a machine
To release a machine it is also necessary to know its system_id, which can be obtained using the command above:
```shell
$ maas $USER machine release $system_id
```
## References
* [MAAS documentation](http://maas.io/docs/en/)
