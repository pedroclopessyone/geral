# <span style="color:red">**Pacemaker + GFS2**</span>

<span style="color:black">**Tipo de Subscrição:**</span> Resilient Storage ( já inclui o HA )

* Resilient Storage --> GFS2 packages
* High Availability --> Pacemaker packages

<span style="color:black">**Repositórios:**</span>

* rhel-ha-for-rhel-7-server-rpms
* rhel-rs-for-rhel-7-server-rpms


## <span style="color:blue">**Pacemaker Steps:**</span>

* **Cluster Software Installation:**
	* yum install pcs pacemaker fence-agents-all
	* passwd hacluster <!-- password convem ser igual em todos os nós-->
	* systemctl start pcsd.service
	* systemctl enable pcsd.service
	* pcs cluster auth server1.redhat.com server2.redhat.com
	* pcs cluster setup --start --name my_cluster server1.redhat.com server2.redhat.com
	* pcs cluster enable --all
	* pcs cluster status

<br>

* **Fencing Configuration:**

***

	* Garantir que user p/ VMware (fencing) está criado:

		* https://access.redhat.com/solutions/82333

	* Configurar o fencing device ( VMware [fence_vmware_soap] ):

		* https://access.redhat.com/solutions/917813

***


* **Exemplo de configuração:**

***
	* Considerações:

		* Nome das máquinas: [node1.syone.com] e [node2.syone.com]
		* Máquinas no hypervisor(ESXi/vCenter): [node1-vm] e [node2-vm]
		* [ESXi/vCenter IP address] é o IP do hypervisor VMware que está a gerir as VMs

***

* fence_vmware_soap -a [ESXi/vCenter IP address] -l [esxi_username] -p [esxi_password] --ssl -z -v -o list |egrep "(node1-vm|node2-vm)"
* fence_vmware_soap -a [ESXi/vCenter IP address] -l [esxi_username] -p [esxi_password] --ssl -z -o list |egrep "(node1-vm|node2-vm)"
* pcs stonith create vmfence fence_vmware_soap pcmk_host_map="node1:node1-vm;node2:node2-vm" ipaddr=[ESXi/vCenter IP address] ssl=1 login=[esxi_username] passwd=[esxi_password]
* pcs stonith show
* pcs stonith show vmfence --full


## <span style="color:blue">**GFS2 Steps:**</span>

* **Configure a GFS2 FileSystem in a Cluster:**

	* yum install lvm2-cluster gfs2-utils
	* pcs property set no-quorum-policy=freeze <Set the global Pacemaker parameter no_quorum_policy to freeze.>
	* pcs resource create dlm ocf:pacemaker:controld op monitor interval=30s on-fail=fence clone interleave=true ordered=true
	* /sbin/lvmconf --enable-cluster
	* pcs resource create clvmd ocf:heartbeat:clvm op monitor interval=30s on-fail=fence clone interleave=true ordered=true
	* pcs constraint order start dlm-clone then clvmd-clone
	* pcs constraint colocation add clvmd-clone with dlm-clone
	* pvcreate /dev/vdb
	* vgcreate -Ay -cy cluster_vg /dev/vdb
	* lvcreate -L5G -n cluster_lv cluster_vg
	* mkfs.gfs2 -j2 -p lock_dlm -t rhel7-demo:gfs2-demo /dev/cluster_vg/cluster_lv
	* pcs resource create clusterfs Filesystem device="/dev/cluster_vg/cluster_lv" directory="/var/mountpoint" fstype="gfs2" "options=noatime" op monitor interval=10s on-fail=fence clone interleave=true
	* pcs constraint order start clvmd-clone then clusterfs-clone
	* pcs constraint colocation add clusterfs-clone with clvmd-clone
	* mount |grep /mnt/gfs2-demo
