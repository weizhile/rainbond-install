{% set path = pillar['rbd-path'] %}

{% if grains['id']  == 'manage01' %}
key_build:
  cmd.run:
    - name: ssh-keygen -t rsa -f /root/.ssh/id_rsa -P ""
    - unless: test -f /root/.ssh/id_rsa.pub

key_rsa:
  cmd.run:
    - name: cp -a /root/.ssh/id_rsa /srv/salt/install/files/key
    - unless: test -f /srv/salt/install/files/key/id_rsa
    - require:
      - cmd: key_build

key_pub:
  cmd.run:
    - name: cp -a /root/.ssh/id_rsa.pub /srv/salt/install/files/key
    - unless: test -f /srv/salt/install/files/key/id_rsa.pub
    - require:
      - cmd: key_build

{% else %}

ssh_dir:
  file.directory:
    - name: /root/.ssh
    - user: root
    - group: root
    - makedirs: True
    - mode: 700

key_cp:
  file.managed:
    - source: salt://install/files/key/id_rsa.pub
    - name: /tmp/id_rsa.pub
    - user: root
    - group: root
    - mode: 600
    - makedirs: True
    - unless: test -f /tmp/id_rsa.pub
  cmd.run:
    - name: cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys
    - require:
      - file: ssh_dir

{% endif %}