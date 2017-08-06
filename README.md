### Seafile Server Docker image ###
Seafile docker image based on Debian

[Seafile](https://www.seafile.com) is an open source storage system which can be self hosting for more privacy


## Features ##
* Auto configuration on first run, based on the manual setup described in the official  [documentation](https://manual.seafile.com/deploy/using_mysql.html)
* Auto import previous installation, including non docker installation
* Support FASTCGI mode
* Upgrade Seafile with one simple command

## Supported tags ##
Tags of this image follow Seafile version:
* latest - Development build based on the latest Seafile version
* 6.1.1 - Seafile server 6.1.1
* 6.0.7 - Seafile server 6.0.7

## Detailed Configuration ##
- #### Ports ####
  - 8000 (seafile port)
  - 8082 (seahub port)

- #### Volume ####

  - This image exposes only one volume
    * version 6.0.7 -> /home/seafile/
    * from version 6.1.1 -> /seafile

  - Directory Structure
  ``` seafile/
          ├── ccnet
          │   └── seafile.ini
          │
          ├── conf
          │   ├── ccnet.conf
          │   ├── seafdav.conf
          │   ├── seafile.conf
          │   ├── seahub_settings.py
          │   └── seahub_settings.pyc
          │
          ├── logs
          │   ├── ccnet.log
          │   ├── controller.log
          │   ├── seafile.log
          │   ├── seahub.log
          │   └── seahub_django_request.log
          │
          ├── seafile-data
          │
          ├── seahub
          │   └── media 
          │
          └── seahub-data
   ```       
    * The folder **seafile/seahub/media** must be shared with Apache/nginx when running in FASTCGI mode
              
- #### Environment variables ####
  * **SERVER_NAME** (default is *seafile*): name of the server
  
  * **SERVER_NAME** (default is *127.0.0.1*): IP or domain name of the server
  
  * **FASTCGI** (default is *false*): If true or True then run seafile in fastcgi mode

  * **MYSQL_SERVER** (required):  MySQL/Maria DB Server name or ip, could be the name of the database service in docker-compose.yml file.

  * **MYSQL_PORT** (default is *3306*): port used by the database server

  * **MYSQL_ROOT_PASSWORD** (required): root user is needed by Seafile to create its own databases

  * **MYSQL_USER** (required): MYSQL user used by Seafile

  * **MYSQL_USER_PASSWORD** (required): password for MYSQL_USER

  * **CCNET_DB** (default is *ccnet-db*): name of the database for CCNET

  * **SEAFILE_DB** (default is *seafile-db*): name of the database for Seafile

  * **SEAHUB_DB** (default is *seahub-db*): name of the database for CCNET

  * **SEAFILE_ADMIN** (required): email for the admin account

  * **SEAFILE_ADMIN_PASSWORD** (required): password for the admin account


## docker-compose.yml example ##
  ```yml
  version: '2'
  services:
    seafile:
      image: sabaitech/seafile
      container_name: seafile
      ports:
       - "8000:8000"
       - "8082:8082"
      environment:
       - SERVER_ADDRESS=my.domain.com
       - FASTCGI=true
       - MYSQL_SERVER=mariadb
       - MYSQL_USER=seafile
       - MYSQL_USER_PASSWORD=test
       - MYSQL_ROOT_PASSWORD=passw0rd!
       - SEAFILE_ADMIN=admin@domain.com
       - SEAFILE_ADMIN_PASSWORD=passw00rd
      volumes:
       - ./seafile:/home/seafile
      depends_on:
       - mariadb

    mariadb:
      image: mariadb:10.1
      container_name: mariadb
      ports:
       - "3306:3306"
      environment:
        - MYSQL_ROOT_PASSWORD=passw0rd!
        - MYSQL_USER=seafile
        - MYSQL_PASSWORD=test
      volumes:
        - ./mysql/db:/var/lib/mysql
```


and just run ```docker-compose up -d```


## Restoring a previous installation ##

 If you already have a previous installation of Seafile server (including non docker installation) and want to use this image you just have to:
   1. Put ```conf```, ```logs```, ```seafile-data``` directories in the associated volume
   2. Run ```docker-compose up -d```


## Upgrading Seafile server ##

To upgrade the current version of Seafile server, you just have to run the following command:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;docker-compose exec **seafile** upgrade **6.0.8**

where:

  - **seafile** is the name of the service defined in *docker-compose.yml* file

  - **6.0.8** is the new version

## TODO ##
* Manage SQLite
* Expose some services like Garbage Collector
