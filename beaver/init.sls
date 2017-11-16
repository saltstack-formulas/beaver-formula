{% from "beaver/map.jinja" import beaver with context %}

{% set transport_type = beaver.transport_type|default('stdout') %}
{% set virtualenv = beaver.virtualenv|default(false) %}
{% set logfiles = beaver.logfiles|default(false) %}

{% set beaver_opts = '-c /etc/beaver/beaver.conf -C /etc/beaver/conf.d' %}
{% set beaver_logfile = '/var/log/beaver/beaver.log' %}

{% if virtualenv %}
{% set beaver_path = '/opt/beaver/bin/beaver' %}
{% else %}
{% set beaver_path = '/usr/local/bin/beaver' %}
{% endif %}

beaver_requirements:
  pkg.installed:
    - pkgs:
      - {{ beaver.pip }}
      {% if transport_type == 'zeromq' %}
      - {{ beaver.zmq }}
      {% endif %}
      {% if virtualenv %}
      - {{ beaver['python-virtualenv'] }}
      {% endif %}

{% if virtualenv %}
/opt/beaver:
  virtualenv.managed
{% endif %}

beaver:
  pip.installed:
    - name: beaver
    - pre_releases: True
    - require:
      - pkg: beaver_requirements
    {% if virtualenv %}
      - virtualenv: /opt/beaver
    - bin_env: /opt/beaver
    {% endif %}

  service.running:
    - enable: True
    - watch:
      - file: /etc/beaver/*
    {% if grains['init'] == 'systemd' %}
    - require:
      - file: /etc/systemd/system/beaver.service
    {% else %}
    - require:
      - file: /etc/init.d/beaver
      - file: /var/log/beaver
      - file: /etc/beaver
    {% endif %}

/etc/beaver:
  file.directory:
    - usear: root
    - group: root
    - mode: 755
    - makedirs: True

/etc/beaver/conf.d:
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
        global: {{ beaver.global }}
{% if logfiles %}
        logfiles: {{ beaver.logfiles }}
{% endif %}
    - require:
      - file: /etc/beaver

{% if grains['init'] == 'systemd' %}
/etc/systemd/system/beaver.service:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - source: salt://beaver/files/beaver_systemd.conf
    - context:
        beaver_path: {{ beaver_path }}
        beaver_opts: {{ beaver_opts }}
{% else %}
/etc/init.d/beaver:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - source: salt://beaver/files/beaver_init
    - context:
        beaver_path: {{ beaver_path }}
        beaver_opts: {{ beaver_opts }}
        beaver_logfile: {{ beaver_logfile }}
{% endif %}

