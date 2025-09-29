<pre>
toolbox/
├─ README.md
├─ .gitignore
├─ database/
│  └─ mssql/
│     ├─ active-sessions.sql
│     ├─ check-version.sql
│     └─ list-databases.sql
├─ docker/
│  ├─ cleanup.sh
│  ├─ install.sh
│  └─ mssql/
│     └─ docker-compose.yml
├─ lib/
│  └─ common.sh
├─ system/
│  ├─ firewall/
│  │  └─ configure-ufw.sh
│  ├─ logging/
│  │  └─ setup-rsyslog.sh
│  ├─ security/
│  │  └─ configure-fail2ban.sh
│  ├─ shell/
│  │  └─ configure-bashrc.sh
│  └─ time/
│     └─ configure-timezone.sh
└─ web/
   └─ nginx/
      └─ install-nginx.sh
</pre>