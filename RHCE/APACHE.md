# **APACHE**

### <span style="color:red">Basic WebSite with SELinux & Virtual Hosting</span>

-   yum -y install httpd httpd-manual

-   systemctl enable httpd ; systemctl start httpd

-   firewall-cmd --permanent --add-service={http,https}/tcp

-   firewall-cmd --permanent --add-port=8877/tcp

-   firewall-cmd --reload

-   mkdir /srv/bacalhau

-   ll -Z /var/www
    -   drwxr-xr-x. root root system_u:object_r:httpd_sys_content_t:s0 html


-   `semanage fcontext -a -t httpd_sys_content_t "/srv/bacalhau(/.*)?"`
-   restorecon -Rv /srv
    <p>
-   man semanage-port
-   semanage port -l
-   semanage port -a -t http_port_t -p tcp 8877

-   vim /srv/bacalhau

-   vim /etc/httpd/conf.d/bacalhau.conf
    -   `Listen 8877`
    -   `<VirtualHost *:8877>`
        -   `DocumentRoot /srv/bacalhau`
        -   `ServerName srv1.rhce.local`
            <p>
        -   `<Directory /srv/bacalhau>`
            -   **escolher a opção de acordo com o que for pedido**
            -   Require all granted <!-- permite acesso de todos -->
            -   Require local <!--Apenas permite acesso local-->
            -   Require ip 192.168.122.1 <!-- Permite acesso apenas do ip indicado -->
            -   Require valid-user <!--Requerer autenticação-->
        -   `</Directory>`
            <p>
    -   `</VirtualHost>`


-   systemctl restart httpd

<br>

### <span style="color:red">Basic WebSite with SELinux, Virtual Hosting & Basic Authentication</span>

-   yum -y install httpd httpd-manual

-   firewall-cmd --permanent --add-service={http,https}
-   firewall-cmd --permanent --add-port=8787/tcp
-   firewall-cmd --reload

-   mkdir /srv/autenticacao

-   ll -Z /var/www
    -   drwxr-xr-x. root root system_u:object_r:httpd_sys_content_t:s0 html


-   `semanage fcontext -a -t httpd_sys_content_t "/srv/autenticacao(/.*)?"`
    <p>
-   man semanage-port
-   semanage port -l
-   semanage port -m -t http_port_t -p tcp 8787

-   vim /srv/autenticacao/index.html

-   vim /etc/httpd/conf.d/autenticacao.conf
    -   `Listen 8787`
    -   `<VirtualHost *:8787>`
        	 _ `ServerName srv1.rhce.local`
        	 _ `DocumentRoot /srv/autenticacao`
        <p>
    -   `<Directory /srv/autenticacao>`
        -   `AuthType Basic`
        -   `AuthName "Restricted Files"`
            <!-- (Following line optional) -->
        -   `AuthBasicProvider file`
        -   `AuthUserFile /etc/httpd/password`
        -   `Require user alice`
    -   `</Directory>`
        <p>
    -   `</VirtualHost>`

<p>

-   htpasswd -c /etc/httpd/password alice

-   systemctl restart httpd
