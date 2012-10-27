Mzcs (Moring Zabbix (Graph) Check Scirpt)
==============================

### mokuji
---
1. [What is this](#what-is-this)  
2. [Mzcs View Zabbix metrics Graph](#mzcs-view-zabbix-metrics-graph)  
3. [View](#view)  
4. [How To Use](#how-to-use)  
5. [Settings](#settings)

---

What is this?
---

Mzcs is Zabbix Graph Output Tool.

You will arrive at the office in the morning,
check the metrics for each server Zabbix.

Mzcs will help you to check the metrics
Morning, gives you time to drink another glass of coffee:)


Mzcs View Zabbix metrics Graph
---

    Past <------------------->  Today
    1. [ x x x x x x x x x x x o o ] 
    2. [ x x x x x x x x x x o o x ]
    3. [ o o o o o o o o o o o o o ]


> 1. [now] ---------- [24hour ago]
> 2. [24hour ago] --- [48hour ago]
> 3. [now] ------- [two weeks ago]


### I think, if there are these "three case",
### understand most things


View
---

### Top
![image] (https://dl.dropbox.com/u/5390179/Mzcs-view3.png)

### Header
![image] (https://dl.dropbox.com/u/5390179/Mzcs-view2.png)

### Graphs 
![image] (https://dl.dropbox.com/u/5390179/Mzcs-view.png)


## How to use

Pleas reading this code.

customize area.

### 1. Zabbix Passwrod

```
### Zabbix Settings ###
my $username = "";
my $password = "";
```

### 2. Zabbix URL
```
### Your Zabbix URL
my $url = 'https://localhost/zabbix';
```

### 3. Zabbix DATABASE

```
### MySQL settings ###
my $data_source = "DBI:mysql:zabbix";
my $db_username = "";
my $db_password = "";
```

DBI:mysql:YOURZABBIX_DATABASE

### 4. Your Zabbix Graph Choice Name
```

my @graph_category = (
    "CPU Utilization",
    "DiskUsage",
    "Load Average",
    "Memory Utilization",
    "Swap Utilization",
    "Network Traffic (eth0)",
    "Network Traffic (eth1)",
    "MySQL queries",
    "MySQL slave delay"
);

my %filepath = (
    cpu    => "CPU Utilization",
    disk   => "DiskUsage",
    memory => "Memory Utilization",
    swap   => "Swap Utilization",
    loa    => "Load Average",
    netone => "Network Traffic (eth0)",
    nettwo => "Network Traffic (eth1)",
    query  => "MySQL queries",
    slave  => "MySQL slave delay",
    slave  => "MySQL slave delay"
);

```

**@graph_category** is
Zabbix Graph Name.
pull out ID from Zabbix database using the name of this Graph Name.

**@filepath** is
A name of the index of each graph.
Look View => Header.

### 5. CPU Fork

```
### CPU = Fork
my $pm = new Parallel::ForkManager(2);
```
set your CPU Core.


### 6. Graph Set Time

```
my $time = "090000";   # for time. 09:00:00
```

default 09:00 ~ 09:00


Settings
---

1. git clone git://github.com/kenjiskywalker/Mzcs.git 
   at your WebServer's DucumentRoot.

2. Look "How To Use" => I confirm "customize are",
   and please change it for one's setting.

3. this script run!run!run!
   exp) *"1 9 * * **  perl Mzcs.pl @ cron

4. this script download graphs.
   so access your WebServer.
   Look Mzcs Directory /index.html to go!

Debug
---

```
       my $sql = "SELECT graphid FROM graphs WHERE name = ?";
```

debug time

```
       my $sql = "SELECT graphid FROM graphs WHERE name = ? LIMIT 1";
```

:)

enjoy.


License
---

The MIT License (MIT)
Copyright (c) 2012, kenjiskywalker All rights reserved.

Also, "css/bootsrap" (Twitter Bootstrap), is  The Apache License, Version 2.0

