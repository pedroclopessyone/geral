# **SAMBA**
### <span style="color:red">Public Share</span>

#### Server:

`yum -y install samba samba-client cifs-utils`

`systemctl start smb nmb ; systemctl enable smb nmb`

`mkdir /mnt/public`

`chmod 0777 /mnt/public`

`setsebool -P smbd_anon_write on`

`semanage fcontext -a -t public_content_rw_t "/mnt/public(/.*)?"`

`restorecon -Rv /mnt`

`ll -Z /mnt` <!-- Confirmar aplicação da label "samba_share_t" -->

`vim /etc/samba/smb.conf`

    [public]
    path = /mnt/public
    writable = yes
    browseable = yes
    guest ok = yes

##### Add below parameters to 'global' section:
<p>
`vim /etc/samba/smb.conf`

    [global]
    hostname lookups = yes
    map to guest = bad user
    guest account = nobody


`systemctl restart smb nmb`

`testparm -S`

`smbclient //localhost/public -U guest%`


#### Client:

`yum -y install samba-client cifs-utils`

`mkdir /mnt/public`

`smbclient //srv1.rhce.local/public -U guest%``

`mount -t cifs //srv1.rhce.local/public /mnt/publica/ --verbose -o username=guest`

`vim /etc/fstab`
* `//srv1.rhce.local/public        /mnt/publica    cifs    _netdev,username=guest,password=        0 0`

`mount -va`

### <span style="color:red">Share with Write permissions for one User and only Read permissions to another</span>

<!--- This share allows write for the user 'alice' and read permission for the user 'vince'-->

`yum -y install samba samba-client cifs-utils`

`systemctl start smb nmb ; systemctl enable smb nmb`

`mkdir /mnt/cenas`

`semanage fcontext -a -t samba_share_t "/mnt/cenas(/.*)?"`

`restorecon -Rv /mnt`

`ll -Z /mnt`

    [cenas]
    path = /mnt/cenas
    write list = alice
    read list = vince

### <span style="color:red">Multiuser Share</span>

#### Server:

`yum install -y samba samba-client cifs-utils`

`systemctl enable smb nmb ; systemctl start smb nmb`

`firewall-cmd --permanent --add-service=samba ; firewall-cmd --reload`

`vim /etc/samba/smb.conf`

    [multi]
    path = /srv/smb_multi_user
    browseable = yes
    printable = no
    writable = no
    write list = vince
    read list = dev
    valid user = vince, dev

`useradd -s /sbin/nologin dev`

`smbpasswd -a dev`    

`systemctl restart smb nmb`

#### Client:

`yum -y install samba-client cifs-utils`

`mkdir /mnt/multi`

`useradd -s /sbin/nologin dev`

`vim /etc/fstab`
* `//srv1.rhce.local/multi		/mnt/multi	cifs	credentials=/etc/samba/credentials,multiuser,sec=ntlmssp,_netdev	0 0`

`mount -va`

`su - vince`
  * `ll /mnt`
  * `cifscreds -a srv1.rhce.local`
  * `ll /mnt`
  * `touch /mnt/multi/vince.txt`
