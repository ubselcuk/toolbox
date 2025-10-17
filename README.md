<pre>
toolbox/
├─ README.md
├─ .gitignore
├─ database/
│  └─ mssql/
│     ├─ active-sessions.sql
│     ├─ backup.sql
│     ├─ check-version.sql
│     ├─ event-slow-queries.sql
│     ├─ index-fragmentation.sql
│     ├─ list-databases.sql
│     └─ restore-history.sql
├─ docker/
│  ├─ cleanup.sh
│  ├─ install.sh
│  ├─ utility.sh
│  ├─ mssql/
│  │  ├─ backup.env
│  │  ├─ backup.sh
│  │  ├─ restore.sh
│  │  ├─ run.env
│  │  └─ run.sh
│  └─ postgresql/
│     ├─ !env
│     └─ initialize.sh
├─ k6/
│  ├─ crocodiles.js
│  ├─ example.js
│  ├─ quickpizza.js
│  └─ run.sh
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
├─ web/
│  ├─ caddy/
│  │  ├─ Caddyfile
│  │  └─ install-caddy.sh
│  └─ nginx/
│     └─ install-nginx.sh
└─ workflows/
   └─ deployment.yml
</pre>