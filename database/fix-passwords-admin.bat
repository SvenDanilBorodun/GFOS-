@echo off
set PGPASSWORD=17918270
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -d ideaboard -f "c:\GGFF\GFOS-\database\fix-passwords.sql"
