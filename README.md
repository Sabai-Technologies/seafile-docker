### Seafile Server Docker image ###
Seafile docker image based on Debian

[Seafile](https://www.seafile.com) is an open source storage system which can be self hosting for more privacy


## Features ##
* Auto configuration on first run, based on the manual setup described in the official  [documentation](https://manual.seafile.com/deploy/using_mysql.html)
* Auto import previous installation, including non docker installation
* Support FASTCGI mode
* Upgrade Seafile with one simple command
* Support LDAP configuration
* Support reverse proxy configuration
* Support MySQL and Sqlite

## Supported tags ##
Tags, based on Semantic Versioning, follow the schema _**x.y.z-a**_ where _**x.y.z**_ is the version of Seafile
 and _**a**_ is an increment to follow features and bug fix of this image

* **latest** Development version, may be unstable
* **6.3.1-1** Added Sqlite support<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Complete rewrite to easily add more configuration<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Fixed issue when upgrading (empty cache)
* **6.3.1** Updated Seafile version
* **6.2.5** Updated Seafile version
* **6.1.2-2**  Added reverse proxy configuration
* **6.1.2-1**  Added LDAP configuration (thanks to [zsoerenm](https://github.com/zsoerenm))
* **6.1.2** Updated Seafile version
* **6.1.1** Updated Seafile version
* **6.0.7** This version is no more maintained

## Detailed Configuration ##
- ### Ports ###
  - 8000 (seafile port)
  - 8082 (seahub port)

- ### Volume ###

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
          ├── seahub-data
          │
          └── sqlite
              └── seahub.db
          
   ```       
    * The folder **seafile/seahub/media** must be shared with Apache/Nginx when running behind a reverse proxy

- ### Environment variables ###
    - #### Seafile #####
      * **SERVER_NAME** (default is *seafile*): name of the server
      * **SERVER_ADDRESS** (default is *127.0.0.1*): IP or domain name of the server
      * **FASTCGI** (default is *false*): If true or True then run seafile in fastcgi mode
      * **SEAFILE_ADMIN** (required): email for the admin account
      * **SEAFILE_ADMIN_PASSWORD** (required): password for the admin account
    
    - #### MySQL/Sqlite ##### 
       By default Seafile is configured to use Sqlite unless **MYSQL_SERVER** is set
      * **MYSQL_SERVER**:  MySQL/Maria DB Server name or ip
      * **MYSQL_PORT** (default is *3306*): port used by the database server
      * **MYSQL_ROOT_PASSWORD** (required if **MYSQL_SERVER** is set): root user is needed by Seafile to create its own databases
      * **MYSQL_USER** (required if  **MYSQL_SERVER** is set): MYSQL user used by Seafile
      * **MYSQL_USER_PASSWORD** (required i **MYSQL_SERVER** is set): password for MYSQL_USER
      * **MYSQL_CCNET_DB** (default is *ccnet-db*): name of CCNET database
      * **MYSQL_SEAFILE_DB** (default is *seafile-db*): name of SEAFILE database
      * **MYSQL_SEAHUB_DB** (default is *seahub-db*): name of SEAHUB database

    - #### LDAP #####
      * **LDAP_URL** : LDAP URL (e.g. ldap://openldap)
      * **LDAP_BASE** (required if **LDAP_URL** is set): LDAP BASE (e.g. ou=people,dc=example,dc=org)
      * **LDAP_LOGIN_ATTR** (required if **LDAP_URL** is set): LDAP Login attribute (e.g. mail)
      * **LDAP_USER_DN** (optional): LDAP user DN (e.g. cn=admin,dc=example,dc=org)
      * **LDAP_PASSWORD** (optional): LDAP user password
    
    - #### Reverse proxy #####
      * **REVERSE_PROXY_MODE** (value=**HTTP** or **HTTPS**): configure Seafile to run behind a reverse proxy.

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
       - REVERSE_PROXY_MODE=HTTPS
       - FASTCGI=true
       - MYSQL_SERVER=mariadb
       - MYSQL_USER=seafile
       - MYSQL_USER_PASSWORD=test
       - MYSQL_ROOT_PASSWORD=passw0rd!
       - SEAFILE_ADMIN=admin@domain.com
       - SEAFILE_ADMIN_PASSWORD=passw00rd
       - LDAP_URL=ldap://openldap
       - LDAP_BASE=ou=people,dc=example,dc=org
       - LDAP_LOGIN_ATTR=mail
       - LDAP_USER_DN=cn=admin,dc=example,dc=org
       - LDAP_PASSWORD=ldap_passw0rd
      volumes:
       - ./seafile:/seafile
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


## Supported commands ##

  You can **start**, **stop**, **restart** seafile and seahub with a command like :

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;docker-compose exec **seafile** **server** **command**

where:

  - **seafile** is the name of the service defined in *docker-compose.yml* file

  - **server** is ***seafile*** or ***seahub***

  - **command** is ***start***, ***stop***, ***restart***



## Upgrading Seafile server ##

To upgrade the current version of Seafile server, you just have to run the following command:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;```docker-compose exec seafile upgrade 6.0.8```

where:

  - **seafile** is the name of the service defined in *docker-compose.yml* file

  - **6.0.8** is the new version
  
Once you have upgraded the server, you can change the version of the image in the `docker-compose.yml` file to keep the change permanently.

## TODO ##
* Expose some services like Garbage Collector
