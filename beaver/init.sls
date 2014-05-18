{% from "beaver/map.jinja" import beaver with context %}
{% set beaver_config = salt['pillar.get']('beaver', None) %}
{% set server_type = salt['pillar.get']('beaver:global:server_type', None) %}

beaver_requirements:
  pkg.installed:
    - pkgs:
      - {{ beaver.pip }}
      {% if server_type == 'zeromq' %}
      - {{ beaver.zmq }}
      {% endif %}

beaver:
  pip.installed:
    - name: beaver
    - require:
      - pkg: beaver_requirements
  service.running:
    - watch:
      - file: /etc/beaver/beaver.conf
    {% if grains['os_family'] == 'Debian' %}
    - require:
      - file: /etc/init/beaver.conf
    {% endif %}
    {% if grains['os_family'] == 'Redhat' %}
    - require:
      - file: /etc/init.d/beaver.conf
    {% endif %}

/etc/beaver:
  file.directory:
    - usear: root
    - group: root
    - mode: 755
    - makedirs: True

/var/log/beaver:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/etc/beaver/beaver.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://beaver/files/beaver.conf
    - context:
        global: {{ beaver_config.get('global', {}) }}
        logfiles: {{ beaver_config.get('logfiles', {}) }}

{% if grains['os_family'] == 'Redhat' %}
/etc/init.d/beaver.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://beaver/files/beaver_init.conf
{% endif %}

{% if grains['os_family'] == 'Debian' %}
/etc/init/beaver.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://beaver/files/beaver_upstart.conf
{% endif %}

