Vytvorenie IIS website s podporou PHP
===
- vytvoriť konto v AD pre AppPool (napr. svc-www-test)
- vytvoriť skupinu používateľov, kt. budú mať prístup (napr. Test Users)
- vytvoriť AppPool s nastaveniami:
    - Name: **test**
    - .NET CLR version: **No Managed Code**
    - Managed pipeline mode: **Integrated**
    - Start application pool immediately [×]
- v Advanced Settings nastaviť:
    - Identity: **DOMENA\svc-www-test**
- vytvoriť Web Site:
    - Site name
    - vybrať správny Application pool
    - Physical path: D:\data\test\webroot\www
    - Connect as...: **Application user (pass-through authentication)**
    - Binding:
        - Type: https
        - Host name: test.website.com
        - Require SNI [×]
        - SSL certificate
        - Start Website immediately [×]

- Website:
    - Authenthication:
        - Anonymous: Disabled
        - Windows: Enabled
            - Advanced Settings -> Extended Protection: **Accept**
    - Handler Mappings:
        - PHP 8.3 FastCGI
            - Request path: ***.php**
            - Module: **FastCgiModule**
            - Executable (optional): **D:\php83\php-cgi.exe|-c D:\www\dp-dev\config\php**
    - URL Rewrite `D:\data\test\webroot\www\web.config`: 
    ```
    <?xml version="1.0" encoding="UTF-8"?>
    <configuration>
        <system.webServer>
            <rewrite>
                <rules>
                    <rule name="Rewrite pravidlo pre Nette" stopProcessing="true">
                        <match url="\.(pdf|js|ico|gif|jpg|png|css|rar|zip|tar\.gz)$" negate="true" />
                        <conditions>
                            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
                            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
                        </conditions>
                        <action type="Rewrite" url="index.php" />
                    </rule>
                </rules>
            </rewrite>
        </system.webServer>
    </configuration>

- DNS:
    - test.website.com CNAME webserver.firma.local

alebo nastavť DNS A záznam a pridať SPN:
`setspn -S HTTP/test.website.com DOMENA\svc-www-test`

- Kerberos Constrained Delegation - ak je nastavený A DNS záznam (nie CNAME):
    - v dsa.msc:
        - pre konto svc-www-test nastaviť Kerberos delegation:
            - Trust this user for delegation to specified services only
            - Use Kerberos only
            - Service Type: MSSQLSvc, User or Computer: DBSERVER.firma.local
    - vo Configuration Editor nastaviť: `System.webServer/security/authentication/windowsAuthentication - **useAppPoolCredentials: True**
    - ak je nastavený CNAME, tak delegáciu je treba nastaviť rovnako, ale namiesto na svc-www-test sa nastaví na počítači DOMENA\WEBSERVER$

- Permissions:
    - D:\data\test\webroot
        - svc-www-test: Read & Execute
        - Test Users: Modify
    - D:\data\test\temp
    - D:\data\test\sessions
        - svc-www-test: Modify
    - D:\php83
        - svc-www-test: Read & Execute

- php.ini:
    - open_basedir: **D:\data\test**
    - error_log: **D:\data\test\log\php_error.log**
    - sys_temp_dir: **D:\data\test\temp**
    - upload_tmp_dir: **D:\data\test\temp**
    - session.save_path: **D:\data\test\sessions**
    - fastcgi.impersonate: **1**
    - cgi.force_redirect = **0**

- Restart Application Pool
- Restart Web Site