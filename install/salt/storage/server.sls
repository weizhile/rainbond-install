nfs_server:
  pkg.installed:
   {% if grains['os_family']|lower == 'redhat' %}
    - name: nfs-utils
    - unless: rpm -qa | grep nfs-utils
   {% else %}
    - name: nfs-kernel-server
    - unless: dpkg -l | grep nfs-kernel-server
   {% endif %}

{% if pillar.storage.get('type','nfs') == 'nfs' %}
nfs_server_running:
  service.running:
    - name: nfs-server
    - enable: True
    - require:
      - pkg: nfs_server
    - watch:
      - file: server_exports

server_exports:
  file.managed:
    - name: /etc/exports
    - source: salt://install/files/storage/exports
    - user: root
    - group: root
    - mode: 644

update_exports:
  cmd.run:
    - name: exportfs -ra
    - require:
      - pkg: nfs_server
    - onchanges:
      - file: server_exports

show_exports:
  cmd.run:
    - name: showmount -e 127.0.0.1

{% else %}

hosts_config:
  file.managed:
    - source: salt://install/files/storage/storage.hosts
    - name: /tmp/storage.hosts
    - user: root
    - group: root
    - mode: 777
    - makedirs: True

hosts_rewrite:
  cmd.run:
    - name: cat /tmp/storage.hosts >> /etc/hosts

{% if grains['os_family']|lower == 'redhat' %}
gfs_server:
  pkg.installed:
    - name: glusterfs-fuse
    - unless: rpm -qa | grep glusterfs-fuse
{% endif %}

/etc/fstab:
  file.append:
    - text:
      - "{{ pillar.storage.get('client_args') }}"
    - unless: df -h | grep /grdata

automount:
  cmd.run:
    - name: mount -a
    - unless: df -h | grep /grdata

{% endif %}

write_health_check:
  file.managed:
    - name: /tmp/.check_storage
    - source: salt://install/files/storage/check.sh
    - template: jinja
    - makedirs: True
    - user: root
    - group: root
    - mode: 777

init_health_check:
  cmd.run:
    - name: bash  /tmp/.check_storage
