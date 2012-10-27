#!/usr/bin/env perl

use strict;
use warnings;
use autodie qw(open close);

use Text::Xslate;
use Data::Section::Simple;
use WWW::Mechanize;
use Date::Simple::D8;
use LWP::Simple qw(getstore);
use Parallel::ForkManager;
use DBI;

use Data::Dumper;
use DDP;

### Zabbix Settings ###
my $username = "";
my $password = "";


### Your Zabbix URL
my $url = 'https://localhost/zabbix';


# oreore certificate file error no
# => verify_hostname => 0
my $mech = WWW::Mechanize->new(ssl_opts => { verify_hostname => 0 }, timeout => 180);

$mech->get($url);
$mech->field(name     => "$username");
$mech->field(password => "$password");
$mech->click('enter');


### MySQL settings ###
my $data_source = "DBI:mysql:zabbix";
my $db_username = "";
my $db_password = "";

sub input_graphid {
    my @recs = ();
    my $graph_category = shift;

    eval {
       my $dbh = DBI->connect($data_source, $db_username, $db_password,
               {RaiseError => 1, PrintError => 0});

       my $sql = "SELECT graphid FROM graphs WHERE name = ?";
           my $sth = $dbh->prepare($sql);
           $sth->execute($graph_category);

       while (my $rec = $sth->fetchrow_arrayref) {
                push(@recs, $rec->[0]);
       }
       $sth->finish;
       $dbh->disconnect;
   };
   die "Error : $@\n" if ($@);
   return @recs;
}

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
);

### CPU = Fork
my $pm = new Parallel::ForkManager(2);



### graph data ###
my $width       = 500;
my $period_day  = 86400;     # 86400 => 1day.
my $period_week = 1209600;   # 1209600 => 2week.


my $time = "090000";   # for time. 09:00:00
my $d8   = Date::Simple::D8->new(); # format %Y%m%d

my %days = (
    today     => $d8 -1  . $time,
    yesterday => $d8 -2  . $time,
    weekly    => $d8 -14 . $time
);

my %since = (
    today     => 86400,
    yesterday => 86400,
    weekly    => 1209600
);

for my $key (keys(%filepath)) {
    my $graph_name = $filepath{$key};

    my @graphid = input_graphid($graph_name);

    # graph uniq number in $graph
    for my $graph (@graphid) {            # => graphid(100, 101, 102)

        for my $day (keys(%days)) {       # => day(today, yesterday)
            $pm->start and next;
            my $graphurl = "$url/chart2.php?graphid=$graph&width=$width&period=$since{$day}&stime=$days{$day}";

            # main system get png image 
            # $mech->get("$graphurl",":content_file" => "png/${graph}_${day}.png");
            print "$graphurl\n";
            $pm->finish;
        }
        $pm->wait_all_children;
    }
}


### Make HTML File Area ###
my $vpath = Data::Section::Simple->new()->get_data_section();
my $tx = Text::Xslate->new(path => [$vpath],);
my $graph_data;

for my $key (keys(%filepath)) {
    my $graph_name = $filepath{$key};

    my @graphid = input_graphid($graph_name);
    my @one   = splice(@graphid, 0, 30);
    my @two   = splice(@graphid, 0, 30);
    my @three = splice(@graphid, 0, 30);
    my @four  = splice(@graphid, 0, 30);
    my @five  = splice(@graphid, 0, 30);
    my @six   = splice(@graphid, 0, 30);
    my @seven = splice(@graphid, 0, 30);
    my @eight = splice(@graphid, 0, 30);
    my @nine  = splice(@graphid, 0, 30);
    my @ten   = splice(@graphid, 0, 30);

    my @num = (\@one, \@two, \@three, \@four, \@five, \@six, \@seven, \@eight, \@nine, \@ten);

    my %number = (
        one   => \@one,
        two   => \@two,
        three => \@three,
        four  => \@four,
        five  => \@five,
        six   => \@six,
        seven => \@seven,
        eight => \@eight,
        nine  => \@nine,
        ten   => \@ten,
    );

    for my $num (keys(%number)) {

        my $graphid_ref = $number{$num};
        $graph_data = $tx->render("template.tx",
            {
                graph_name => $graph_name,
                list       => $graphid_ref, #list -> \@one => graphid
                graph_cate => $key,         #key
                number     => $num,
            }
        );
        open(my $fh, '>', $key."_".$num.".html"); # open ex) $key(cpu)_$num(one).html
        print $fh $graph_data;
        close($fh);
    }
}

my $index_graph_data = $tx->render("template_index.tx");

open(my $fh, '>', 'index.html');
print $fh $index_graph_data;
close($fh);

__DATA__

@@ template_index.tx
<!doctype html>
<html>
<head>
<title>Morning Zabbix (Graph) Check System</title>
<link href="./css/bootstrap/docs/assets/css/bootstrap.css" rel="stylesheet">
<link href="./css/bootstrap/docs/assets/css/bootstrap-responsive.css" rel="stylesheet">
</head>

<body>
<div class="navbar navbar-inverse navbar-fixed-top">
<div class="navbar-inner">
<div class="container">
<button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
<span class="icon-bar"></span>
<span class="icon-bar"></span>
<span class="icon-bar"></span>
</button>
<a class="brand" href="./index.html">Mzcs</a>
<div class="nav-collapse collapse">
<ul class="nav">
<li class=""><a href="./cpu_one.html">CPU</a></li>
<li class=""><a href="./memory_one.html">MEMORY</a></li>
<li class=""><a href="./disk_one.html">DISK</a></li>
<li class=""><a href="./swap_one.html">SWAP</a></li>
<li class=""><a href="./loa_one.html">LA</a></li>
<li class=""><a href="./netone_one.html">NET(eth0)</a></li>
<li class=""><a href="./nettwo_one.html">NET(eth1)</a></li>
<li class=""><a href="./query_one.html">QUERY</a></li>
<li class=""><a href="./slave_one.html">SLAVE</a></li>
</ul>
</div>
</div>
</div>
</div>

<script src="./css/bootstrap/docs/assets/js/bootstrap.min.js"></script>

<div class="container-fluid">
<br>
<br>
<br>
<h1><i class="icon-eye-open"></i>&nbsp;&nbsp;&nbsp;Morning Zabbix (Graph) Check System&nbsp;&nbsp;&nbsp;<i class="icon-eye-open"></i></h1><br>
<br>
<br>

<h3>
        Left Graph is Today 24hour Graph Data.<br>
        Center Graph is Yesterday 24hour Graph Data.<br>
        Light Graph is a week before 2weekly Graph Data.<br>

</h3>

</body>
</html>



@@ template.tx
<!doctype html>
<html>
<head>
<title>Morning Zabbix (Graph) Check System</title>
<!-- Le styles -->
<link href="./css/bootstrap/docs/assets/css/bootstrap.css" rel="stylesheet">
<link href="./css/bootstrap/docs/assets/css/bootstrap-responsive.css" rel="stylesheet">
</head>
<body>
<div class="navbar navbar-inverse navbar-fixed-top">
<div class="navbar-inner">
<div class="container">
<button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
<span class="icon-bar"></span>
<span class="icon-bar"></span>
<span class="icon-bar"></span>
</button>
<a class="brand" href="./index.html">Mzcs</a>
<div class="nav-collapse collapse">
<ul class="nav">
:if $graph_cate == "cpu" {
    <li class="active"><a href="./cpu_one.html">CPU</a></li>
:   } else {
    <li class=""><a href="./cpu_one.html">CPU</a></li>
:}
:if $graph_cate == "disk" {
    <li class="active"><a href="./disk_one.html">DISK</a></li>
:   } else {
    <li class=""><a href="./disk_one.html">DISK</a></li>
:}
:if $graph_cate == "memory" {
    <li class="active"><a href="./memory_one.html">MEMORY</a></li>
:   } else {
    <li class=""><a href="./memory_one.html">MEMORY</a></li>
:}
:if $graph_cate == "swap" {
    <li class="active"><a href="./swap_one.html">SWAP</a></li>
:   } else {
    <li class=""><a href="./swap_one.html">SWAP</a></li>
:}
:if $graph_cate == "loa" {
    <li class="active"><a href="./loa_one.html">LA</a></li>
:   } else {
    <li class=""><a href="./loa_one.html">LA</a></li>
:}
:if $graph_cate == "netone" {
    <li class="active"><a href="./netone_one.html">NET(eth0)</a></li>
:   } else {
    <li class=""><a href="./netone_one.html">NET(eth0)</a></li>
:}
:if $graph_cate == "nettwo" {
    <li class="active"><a href="./nettwo_one.html">NET(eth1)</a></li>
:   } else {
    <li class=""><a href="./nettwo_one.html">NET(eth1)</a></li>
:}
:if $graph_cate == "query" {
    <li class="active"><a href="./query_one.html">QUERY</a></li>
:   } else {
    <li class=""><a href="./query_one.html">QUERY</a></li>
:}
:if $graph_cate == "slave" {
    <li class="active"><a href="./slave_one.html">SLAVE</a></li>
:   } else {
    <li class=""><a href="./slave_one.html">SLAVE</a></li>
:}
</ul>
</div>
</div>
</div>
</div>

<script src="./css/bootstrap/docs/assets/js/bootstrap.min.js"></script>


<div class="container-fluid">
<br>
<br>
<h2><i class="icon-eye-open"></i>&nbsp;&nbsp;&nbsp;Morning Zabbix (Graph) Check System&nbsp;&nbsp;&nbsp;<i class="icon-eye-open"></i></h2>

<blockquote>
<h3><: $graph_name :></h3>
</blockquote>

<ul class="breadcrumb">
<h3>
:if $number == "one" { 
<li class="active">1</li> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_two.html">2</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_three.html">3</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_four.html">4</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_five.html">5</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_six.html">6</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_seven.html">7</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_eight.html">8</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_nine.html">9</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_ten.html">10</a> <span class="divider">/</span></li>
:    } elsif $number == "two" {
<li><a href="<: $graph_cate :>_one.html">1</a> <span class="divider">/</span></li>
<li class="active">2</li> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_three.html">3</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_four.html">4</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_five.html">5</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_six.html">6</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_seven.html">7</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_eight.html">8</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_nine.html">9</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_ten.html">10</a> <span class="divider">/</span></li>
:    } elsif $number == "three" {
<li><a href="<: $graph_cate :>_one.html">1</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_two.html">2</a> <span class="divider">/</span></li>
<li class="active">3</li> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_four.html">4</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_five.html">5</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_six.html">6</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_seven.html">7</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_eight.html">8</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_nine.html">9</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_ten.html">10</a> <span class="divider">/</span></li>
:    } elsif $number == "four" {
<li><a href="<: $graph_cate :>_one.html">1</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_two.html">2</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_three.html">3</a> <span class="divider">/</span></li>
<li class="active">4</li> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_five.html">5</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_six.html">6</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_seven.html">7</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_eight.html">8</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_nine.html">9</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_ten.html">10</a> <span class="divider">/</span></li>
:    } elsif $number == "five" {
<li><a href="<: $graph_cate :>_one.html">1</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_two.html">2</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_three.html">3</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_four.html">4</a> <span class="divider">/</span></li>
<li class="active">5</li> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_six.html">6</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_seven.html">7</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_eight.html">8</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_nine.html">9</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_ten.html">10</a> <span class="divider">/</span></li>
:    } elsif $number == "six" {
<li><a href="<: $graph_cate :>_one.html">1</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_two.html">2</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_three.html">3</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_four.html">4</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_five.html">5</a> <span class="divider">/</span></li>
<li class="active">6</li> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_seven.html">7</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_eight.html">8</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_nine.html">9</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_ten.html">10</a> <span class="divider">/</span></li>
:    } elsif $number == "seven" {
<li><a href="<: $graph_cate :>_one.html">1</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_two.html">2</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_three.html">3</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_four.html">4</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_five.html">5</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_six.html">6</a> <span class="divider">/</span></li>
<li class="active">7</li> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_eight.html">8</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_nine.html">9</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_ten.html">10</a> <span class="divider">/</span></li>
:    } elsif $number == "eight" {
<li><a href="<: $graph_cate :>_one.html">1</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_two.html">2</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_three.html">3</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_four.html">4</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_five.html">5</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_six.html">6</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_seven.html">7</a> <span class="divider">/</span></li>
<li class="active">8</li> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_nine.html">9</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_ten.html">10</a> <span class="divider">/</span></li>
:    } elsif $number == "nine" {
<li><a href="<: $graph_cate :>_one.html">1</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_two.html">2</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_three.html">3</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_four.html">4</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_five.html">5</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_six.html">6</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_seven.html">7</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_eight.html">8</a> <span class="divider">/</span></li>
<li class="active">9</li> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_ten.html">10</a> <span class="divider">/</span></li>
:    } elsif $number == "ten" {
<li><a href="<: $graph_cate :>_one.html">1</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_two.html">2</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_three.html">3</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_four.html">4</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_five.html">5</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_six.html">6</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_seven.html">7</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_eight.html">8</a> <span class="divider">/</span></li>
<li><a href="<: $graph_cate :>_nine.html">9</a> <span class="divider">/</span></li>
<li class="active">10</li> <span class="divider">/</span></li>
:}
</h3>
</ul>

: for $list -> $graph {
<p>
<a href="./png/<: $graph :>_today.png"><img src="./png/<: $graph :>_today.png" width="300"  ></a>&nbsp;&nbsp;&nbsp;
<a href="./png/<: $graph :>_yesterday.png"><img src="./png/<: $graph :>_yesterday.png" width="300" ></a>&nbsp;&nbsp;&nbsp;
<a href="./png/<: $graph :>_weekly.png"><img src="./png/<: $graph :>_weekly.png" width="300" ></a>
<br>
</p>
: }

</body>
</html>
