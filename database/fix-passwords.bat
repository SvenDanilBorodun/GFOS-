@echo off
set PGPASSWORD=ideaboard123
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U ideaboard_user -h localhost -d ideaboard -f "c:\GGFF\GFOS-\database\fix-passwords.sql"
