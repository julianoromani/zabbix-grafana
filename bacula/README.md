function_bacula_status_grafana.sql
Create a function on zabbix database (postgresql) and return a table.

|job|bytesFull|bytesIncremental|bytesDifferential|durationFull|durationIncremental|durationDifferential|filesFull|filesIncremental|filesDifferential|lastExecution|status|

To collect bacula jobs status I use https://github.com/julianoromani/zabbix-bacula
