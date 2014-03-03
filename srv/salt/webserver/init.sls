apache2:
  pkg:
    - installed
  service:
    - running
    - watch:
      - file: /etc/apache2/apache2.conf
      - file: /etc/apache2/mods-enabled/headers.load

/etc/apache2/mods-enabled/headers.load:
  file.symlink:
    - target: /etc/apache2/mods-available/headers.load
    - require:
      - pkg: apache2

/etc/apache2/apache2.conf:
  file.managed:
    - source: salt://webserver/apache2.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: apache2

/var/www/index.html:
  file.managed:
    - source: salt://webserver/index.html
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: apache2

