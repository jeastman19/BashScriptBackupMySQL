# BashScriptBackupMySQL

![logo-mysql](images/MySQL.png)

Script base for the backup of the MySQL databases of our system, based on the [repository][db_backup] of [Nihad Abbasov][narkoz]

**Important**: sending mail has only been tested with mailgun


## Instalation

1. Clone this repository to server


In this case, we have created a new folder within / opt called ***/opt/db-backup*** in which we have cloned the repository

inside this, make

``` bash
$ cd /opt
$ mkdir db-backup
$ git clone git@github.com:jeastman19/BashScriptBackupMySQL.git .
$ chmod +x backup.sh
```

2. Copy o rename variables file ***example.backup.env*** to ***backup.env***

``` bash
$ cp example.backup.env backup.env
```

3. Edit variables file ***backup.env*** and set real values

[db_backup]: https://gist.github.com/NARKOZ/642511
[narkoz]:https://gist.github.com/NARKOZ