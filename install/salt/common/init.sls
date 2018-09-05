include:
{% if "manage" in grains['id']%}
  - common.key
  - common.user
  - common.limits
#  - common.swap
  - common.create_dir
  - common.service
  - common.plugins
  - common.gr_bin
  - common.dns
  - common.pkg
  - common.envs
  - common.health
{% if grains['id'] == pillar['master-hostname'] %}
  - common.domain
{% endif %} 
{% else %}
  - common.user
  - common.create_dir
#  - common.swap
  - common.limits
  - common.service
  - common.key
  - common.gr_bin
  - common.dns
  - common.pkg
  - common.envs
  - common.health
{% endif %}