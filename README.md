A Vagrant setup that uses Ansible to manage and provision the DigitalOcean droplet.

## Requirements & setup

* [Vagrant](https://www.vagrantup.com/downloads.html) v2.1.1+
* DigitalOcean Vagrant Integration Plugin: `vagrant plugin install vagrant-digitalocean`
* DigitalOcean box: `vagrant box add digital_ocean https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box`
* Place your public ssh keys inside the folder `ansible/roles/common/files/ssh_keys/` and add it to the `config-custom.yml` under `digitalocean.public_keys`. Note: this will remove all other non-specified keys from the authorized_keys file.
* Optional: In order to keep your secrets in sync when using multiple machines using fore example, your Google Drive... Symlink the `config-custom.yml` you have in Google drive via a symlink ex: `ln -s ~/Google\ Drive/DO/config-custom.yml config-custom.yml`

### Customize the machine config
 
Every parameter you find under config.yml can be overwritten in your personal config-custom.yml.

Customize the configuration file by making a copy of `config-custom.yml.dist`

```
cp config-custom.yml.dist config-custom.yml
```

### Usage

* Create a new Droplet with the following command: `vagrant up --provider=digital_ocean MACHINE_NAME_HERE`
* To provision all of the machines use: `vagrant provision`
* To provision a spcefic machine like `example-com` use: `vagrant provision example-com`
* To ssh onto one of the machines like `example-com` use: `vagrant ssh example-com`
* Switch to a root user like `su foo`

## Migrating to a secured vagrant user
This is important!. Many aspects of Vagrant expect the default SSH user to have passwordless sudo configured. This lets Vagrant configure networks, mount synced folders, install software, and more.

* Ssh to the newly created machine (using root user): `ssh root@MACHINE_IP_HERE`
* ssh to the server with root password and run: `visudo`. Make sure at the end of file you have something like:
```bash
# Vagrant requires that password is empty for sudo
# This is important!. Many aspects of Vagrant expect the default SSH user to have passwordless sudo configured.
vagrant ALL=(ALL) NOPASSWD: ALL
```
* In local machine run:
```
cat ~/.ssh/abdel.pub | ssh root@MACHINE_IP_HERE "mkdir -p /home/vagrant/.ssh && chmod 700 /home/vagrant/.ssh && chown vagrant:vagrant -R /home/vagrant && chmod g+w -R /etc/apache2/ && cat >> /home/vagrant/.ssh/authorized_keys"
```
* Now run the provision: `vagrant provision MACHINE_NAME`

## Digital Ocean 

All the droplets are created in Digital Ocean.

### images

List all regions:
```bash
vagrant digitalocean-list regions TOKEN_HERE
``` 

List all sizes:
```bash
vagrant digitalocean-list sizes TOKEN_HERE
``` 

### Domains

Change domain settings [here](https://cloud.digitalocean.com/networking/domains). Add a new entry to the `A` record pointing to the machine IP or droplet of choise: without that the provision will faill on generating an SSL.

Create a subdomain in digitalocean: go to networking and choose the main domain you want to create a subdomain for, then, add an `A` record using the desired subdomain.

You can check the propagation of the domain [here](https://www.whatsmydns.net/#A/mydomain.com)

## Important notes

NEVER USE VAGRANT DESTROY AS IT CREATES A NEW IP ADRESS!!

MYSQL PASSWORD IN VAGRANT MUST USE "" ELSE THAT PASSWORD IS FALS IF IT CONTAINS BAD CHARACTERS

todo: https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04
We cannot prevent root from ssh access because then vagrant/Ansible will stop provisioning!

### Supported Commands
The DigitalOcean provider supports the following Vagrant sub-commands:

vagrant ssh: Logs into the droplet instance using the configured user account.
vagrant halt: Powers off the droplet instance.
vagrant provision: Runs the configured provisioners and rsyncs any specified config.vm.synced_folder.
vagrant reload: Reboots the droplet instance.
vagrant rebuild: Destroys the droplet instance and recreates it with the same IP address is was assigned to previously.
vagrant status: Outputs the status (active, off, not created) for the droplet instance.
vagrant destroy: Destroys the droplet instance: WARNING! NEW IP WILL BE GENERATED!.


## FAQ & commands

### Validate apache config
```
apachectl configtest
```


### Create user and group

`useradd -m -s /bin/bash -U vagrant -G sudo,root`

### WHICH GROUP APACHE IS USING? 
`cat /etc/apache2/envvars | grep GROUP`

See Which Groups Your Linux User Belongs To: `groups user`

### Set group and owner for www folder

`/var/www` folder should have owner and group identical to Apache user (`export APACHE_RUN_GROUP=GROUP_NAME_HERE`):
```bash
chown foo:bar -R /var/www/
```

Next step, for general practice, you should change permission to 755 (rwxr-xr-x), not recommend changing permission to 777 for security reason: 
`sudo chmod u=rwX,g=srX,o=rX -R /var/www`
Related to specific permission for wordpress or laravel or another framework, then you can read the documentation respectively.

```
sudo chmod u=rwX,g=srX,o=rX -R /var/www
```
'S' = The directory's setgid bit is set, but the execute bit isn't set.
's' = The directory's setgid bit is set, and the execute bit is set.
SetGID = When another user creates a file or directory under such a setgid directory, the new file or directory will have its group set as the group of the directory's owner, instead of the group of the user who creates it.
To remove the setGID bit:
```
chmod g-s eclipse/
```

### Clear MySQL data

SELECT User FROM mysql.user;

```
sudo apt purge mysql-*
sudo rm -rvf /var/lib/mysql
sudo rm -rvf /usr/local/mysql
sudo rm -rvf /var/run/mysqld
sudo rm -rvf /etc/mysql/
sudo userdel mysql

# service mysql stop
# mysqld_safe --skip-grant-tables &
$ mysql -u root

mysql> use mysql;
mysql> update user set authentication_string=PASSWORD("YOUR-NEW-ROOT-PASSWORD") where User='root';
mysql> flush privileges;
mysql> quit

# service mysql stop
# service mysql start
$ mysql -u root -p

```

*********

### User roles and permissions

* To list all local users you can use: `cut -d: -f1 /etc/passwd`
* Display the groups to which you (or the optionally specified user) belong, use: `id -Gn tp`

### Debug vagrant
`vagrant up --debug &> vagrant.log`

### SSL certbot
Automating renewal
The Certbot packages on your system come with a cron job that will renew your certificates automatically before they expire. Since Let's Encrypt certificates last for 90 days, it's highly advisable to take advantage of this feature. You can test automatic renewal for your certificates by running this command:

`$ sudo certbot renew --dry-run --apache`

If that appears to be working correctly, you can arrange for automatic renewal by adding a cron or systemd job which runs the following:
`certbot renew --apache`


IMPORTANT NOTES:
 - Your account credentials have been saved in your Certbot
   configuration directory at /etc/letsencrypt. You should make a
   secure backup of this folder now. This configuration directory will
   also contain certificates and private keys obtained by Certbot so
   making regular backups of this folder is ideal.
   
### Force SSL redirect on HTTP
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule (.*) https://%{SERVER_NAME}/$1 [R,L]

### Display the real-time memory usage
`watch -d free -m`

## Debug roles

```ansible

- name: Display variable
  debug:
    msg: "{{ lookup('file', 'ssh_keys/' + item ) }}"
  with_items: "{{ config.digitalocean.public_keys }}"
```
## Issues & Fixes

### Issues with publick keys

Check if your key has a comment which uses an apostrophe! or strange characters as comment:
`ssh-rsa ABCD...XYZ Bob's key!
`

### Failed upgrade APT to the latest packages

```bash
sudo apt-get upgrade
```

### Missing PPA & GPG

Missing public keys
```bash
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys <PUBKEY>
```
### Generate ssl certificate
```
sudo certbot --apache
```

## WP CLI

Install:
```bash
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && php wp-cli.phar --info && chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp
```

Switch php version: 
```bash
sudo update-alternatives --set php /usr/bin/php7.1
```

Create new user:
```bash
wp user create gyshido info@example.com --role=administrator
```
## TODO
* SSL grade B issue: https://blog.qualys.com/ssllabs/2018/02/02/forward-secrecy-authenticated-encryption-and-robot-grading-update
* Add wp cli: https://wp-cli.org/
* update default php cli to php 7.1: https://wordpress.stackexchange.com/questions/244164/wp-cli-selecting-php-version
