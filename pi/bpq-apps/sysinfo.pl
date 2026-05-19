#!/usr/bin/perl -w
#
# Copyright (c) 2002-2005 David Rudie
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# Several additions and fixes to this script were contributed by Travis
# Morgan and therefore are Copyright (c) 2003-2006 Travis Morgan
#
# If you notice any bugs including spacing issues, wrong detection of hardware,
# obvious features missing, etc, we both want to hear about them.  If you make
# this script work on other operating systems and/or architectures please send
# either of us your patches.  My e-mail address is d.rudie@gmail.com and
# Travis Morgan's e-mail address is imbezol@criticaldamage.com
#
# The latest version can be obtained from either http://www.inexistent.com/ or
# http://imbezol.org/sysinfo/
#
# Now maintained (as of 2020) by Danyal Samak (int16h@gmail.com / meep@cryogenix.org)
#
# You can also reach Travis in #crd on efnet.

use POSIX qw(floor);
use strict;
use warnings;

# Set up the arrays and variables first.
my @arr;
my @arr1;
my @arr2;
my $cpu;
my @cpu;
my @cpuinfo;
my $data;
my $distro;
my $distrov;
my @distros;
my @data;
my $df;
my $vgs;
my @dmesgboot;
my @hinv;
my @meminfo;
my $mhz;
my @mhz;
my $model;
my @netdev;
my @netstat;
my @nic;
my @nicname;
my $realdistro;
my $smp;
my @smp;
my $stream;
my $sysctl;
my @uptime;
my $var;
my $vara;
my $varb;
my $varc;
my $vard;
my $varh;
my $varm;
my $varp;
my $varx;
my $vary;
my $varz;
my $col1;
my $col2;

# Specify your NIC interface name (eth0, rl0, fxp0, etc) and a name for it.
#
# Example: @nic          = ('eth0', 'eth1');
#                                       @nicname = ('External', 'Internal');
#
# NOTE: If you set one then you HAVE to set the other.
@nic     = ('');
@nicname = ('');

$col1 = '';
$col2 = '';

# These are the default settings for which information gets displayed.
# 0 = Off; 1 = On
my $useShortHostname = 1;

my $showHostname       = 1;
my $showOS             = 1;
my $showCPU            = 1;
my $showProcesses      = 1;
my $showUptime         = 1;
my $showUsers          = 1;
my $showLoadAverage    = 1;
my $showBattery        = 0;  # Requires APM and /proc/apm or /proc/acpi/battery/
my $showMemoryUsage    = 1;
my $showDiskUsage      = 1;
my $showLVMUsage       = 0;
my $showNetworkTraffic = 0;
my $showDistro         = 1;

###############################################
### Nothing below here should need changed. ###
###############################################

my $sysinfoVer  = '2.81.21';
my $sysinfoDate = 'Sep 7, 2012, 21:43 MDT';

my $os  = run_command_scalar('uname -s') // 'Unknown';
my $osn = run_command_scalar('uname -n') // '';
if ( $useShortHostname && $osn ne '' ) {
    $osn =~ s/([^\.]*).*/$1/;
}
my $osv   = run_command_scalar('uname -r') // '';
my $osm   = run_command_scalar('uname -m') // '';
my $uname = "$os $osv/$osm";

my $darwin    = 1 if $os =~ /^Darwin$/;
my $freebsd   = 1 if $os =~ /^FreeBSD$/;
my $dragonfly = 1 if $os =~ /^DragonFly$/;
my $linux     = 1 if $os =~ /^Linux$/;
my $netbsd    = 1 if $os =~ /^NetBSD$/;
my $openbsd   = 1 if $os =~ /^OpenBSD$/;
my $irix      = 1 if $os =~ /^IRIX$/;
my $irix64    = 1 if $os =~ /^IRIX64$/;
my $sun       = 1 if $os =~ /^SunOS$/;

my $alpha    = 1 if $osm =~ /^alpha$/;
my $arm      = 1 if $osm =~ /^arm$/;
my $i586     = 1 if $osm =~ /^i586$/;
my $i686     = 1 if $osm =~ /^i686$/;
my $ia64     = 1 if $osm =~ /^ia64$/;
my $mips     = 1 if $osm =~ /^mips$/;
my $parisc   = 1 if $osm =~ /^parisc$/;
my $parisc64 = 1 if $osm =~ /^parisc64$/;
my $ppc      = 1 if $osm =~ /^ppc$/;
my $ppc64    = 1 if $osm =~ /^ppc64$/;
my $s390     = 1 if $osm =~ /^s390$/;
my $s390x    = 1 if $osm =~ /^s390x$/;
my $sh       = 1 if $osm =~ /^sh/;
my $sparc    = 1 if $osm =~ /^sparc$/;
my $sparc64  = 1 if $osm =~ /^sparc64$/;
my $x86_64   = 1 if $osm =~ /^x86_64$/;

my $d7 = 1 if $darwin && $osv =~ /^7\.\d+\.\d+/;
my $d8 = 1 if $darwin && $osv =~ /^8\.\d+\.\d+/;
my $d9 = 1 if $darwin && $osv =~ /^9\.\d+\.\d+/;
my ( $linux_major, $linux_minor ) = ( 0, 0 );
if ( $linux && $osv =~ /^(\d+)\.(\d+)/ ) {
    $linux_major = $1;
    $linux_minor = $2;
}
my $linux_modern =
  $linux && ( $linux_major > 2 || ( $linux_major == 2 && $linux_minor >= 6 ) );
my $l26   = 1 if $linux && $linux_major == 2 && $linux_minor == 6;
my $l3    = 1 if $linux_modern;
my $f_old = 1
  if $freebsd && $osv =~ /^4\.1-/
  || $osv             =~ /^4\.0-/
  || $osv             =~ /^3/
  || $osv             =~ /^2/;

my $progArgs = $ARGV[0];
if ($progArgs) {
    if ( $progArgs eq '-v' || $progArgs eq '--version' ) {
        print "SysInfo v$sysinfoVer   $sysinfoDate\n";
        print
"Written by David Rudie <d.rudie\@gmail.com> and Travis Morgan <imbezol\@criticaldamage.com>\n";
        exit -1;
    }
}

if ($linux) {
    @cpuinfo = &openfile("/proc/cpuinfo");
    @meminfo = &openfile("/proc/meminfo");
    @netdev  = &openfile("/proc/net/dev");
    @uptime  = &openfile("/proc/uptime");

    $df = 'df -lkP';
    $vgs =
'vgs --trustcache --unbuffered --noheadings -o vg_size,vg_free --nosuffix --units k 2>&1 | grep -v WARNING';

    if ($showDistro) {
        $distro  = "";
        $distrov = "";

        my $os_release = parse_os_release('/etc/os-release');
        if ($os_release) {
            if ( $$os_release{'PRETTY_NAME'} ) {
                $distro = $$os_release{'PRETTY_NAME'};
            }
            elsif ( $$os_release{'NAME'} ) {
                $distro = $$os_release{'NAME'};
                if ( $$os_release{'VERSION'} ) {
                    $distrov = $$os_release{'VERSION'};
                }
                elsif ( $$os_release{'VERSION_ID'} ) {
                    $distrov = $$os_release{'VERSION_ID'};
                }
            }
            if ( $distro ne "" && $distrov eq "" && $$os_release{'VERSION_ID'} )
            {
                $distrov = $$os_release{'VERSION_ID'};
            }
        }

        if ( $distro eq "" ) {
            @distros = (
                "Arch",        "/etc/arch-release",
                "Gentoo",      "/etc/gentoo-release",
                "Fedora Core", "/etc/fedora-release",
                "SUSE",        "/etc/SuSE-release",
                "Slackware",   "/etc/slackware-version",
                "Cobalt",      "/etc/cobalt-release",
                "Debian",      "/etc/debian_version",
                "Mandrake",    "/etc/mandrake-release",
                "Mandrake",    "/etc/mandrakelinux-release",
                "Yellow Dog",  "/etc/yellowdog-release",
                "OpenFiler",   "/etc/distro-release",
                "Red Hat",     "/etc/redhat-release"
            );
            while (@distros) {
                my $candidate    = shift @distros;
                my $release_file = shift @distros;
                last unless defined $release_file;
                next unless -e $release_file;
                my $release_line = read_first_line($release_file);
                next unless defined $release_line;
                $distro  = $candidate;
                $distrov = $release_line;
                $distrov =~ s/[^0-9]*([0-9.]+)[^0-9.]{0,1}.*/$1/;
                last if length $distro > 0;
            }
        }

        if ( $distro eq "Debian" ) {
            if ( -e "/etc/lsb-release" ) {
                $realdistro = "";
                if ( open( my $fh, '<', "/etc/lsb-release" ) ) {
                    while ( my $line = <$fh> ) {
                        if ( $line =~ /^DISTRIB_DESCRIPTION=\"?(.*?)\"?$/ ) {
                            chomp($line);
                            $realdistro = $1;
                            last;
                        }
                    }
                    close($fh);
                }
                if ( $realdistro ne "" ) {
                    $distro  = $realdistro;
                    $distrov = $realdistro;
                    $distro  =~ s/ [0-9.]+.*$//;
                    $distrov =~ s/$distro //;
                }
            }
        }
        if ( $distro eq "Red Hat" ) {
            $realdistro = read_first_line("/etc/redhat-release") // "";
            if ( $realdistro =~ "^CentOS" ) {
                $distro = "CentOS";
            }
        }
        if ( $distro eq "SUSE" ) {
            $realdistro = read_first_line("/etc/SuSE-release") // "";
            if ( $realdistro =~ "^openSUSE" ) {
                $distro = "openSUSE";
            }
            elsif ( $realdistro =~ "^SUSE Linux Enterprise Server" ) {
                $distro = "SLES";
            }
            elsif ( $realdistro =~ "^SUSE Linux Enterprise Desktop" ) {
                $distro = "SLED";
            }
        }
    }
}
elsif ( $irix || $irix64 ) {
    @hinv = run_command_lines('hinv');
}
else {
    @dmesgboot = &openfile("/var/run/dmesg.boot");
    if ($sun) {
        @netstat = run_command_lines('netstat -in');
    }
    else {
        @netstat = run_command_lines('netstat -ibn');
    }
    if ($darwin) {
        $sysctl = '/usr/sbin/sysctl';
    }
    else {
        $sysctl = '/sbin/sysctl';
    }
    if ($arm) {
        $df = 'df -k';
    }
    elsif ($f_old) {
        $df = 'df -k';
    }
    else {
        $df = 'df -lk';
    }

}

if ($showCPU) {
    if ( $freebsd || $dragonfly ) {
        if ($alpha) {
            @cpu = grep( /^COMPAQ/, @dmesgboot );
            $cpu = join( "\n", $cpu[0] );
        }
        else {
            @cpu = grep( /CPU: /, @dmesgboot );
            $cpu = join( "\n", @cpu );
            $cpu =~ s/Warning:.*disabled//;
            @cpu = split( /CPU: /, $cpu );
            $cpu = $cpu[1];
            $cpu =~ s/\s\d\.\d\dGHz//g;
            $cpu =~ s/\s*[^\s]*-class CPU//gi;
            $cpu =~ s/(\S*)-MHz/$1 MHz/gi;
            $cpu =~ s/@\s+//;
            chomp($cpu);
            my $ncpu_output = run_command_scalar("$sysctl -n hw.ncpu");

            if ( defined $ncpu_output ) {
                $smp = $ncpu_output;
                if ( $smp eq "1" ) {
                    $smp = "";
                }
            }
        }
    }
    if ($netbsd) {
        if ($alpha) {
            my @alpha_cpu_lines = grep( /^COMPAQ/, @dmesgboot );
            $cpu                = join( "\n", $alpha_cpu_lines[0] // '' );
            my @alpha_parts     = split( /, /, $cpu );
            $cpu                = $alpha_parts[0] // $cpu;
        }
        else {
            my ($cpu_line) =
              grep { /^v?cpu0.*MHz/ && !/apic/ } @dmesgboot;
            if ( defined $cpu_line ) {
                my ( undef, $cpu_details ) = split( /: /, $cpu_line, 2 );
                if ( defined $cpu_details ) {
                    $cpu_details =~ s/, id.*//;
                    my $local_mhz;
                    if ( $cpu_details =~ /([.0-9]+)\s*MHz/ ) {
                        $local_mhz = $1;
                    }
                    $cpu_details =~ s/,.*//;
                    $cpu = defined $local_mhz
                      ? "$cpu_details ($local_mhz MHz)"
                      : $cpu_details;
                }
            }

            if ( !defined $cpu || $cpu eq '' ) {
                my $brand = run_command_scalar("$sysctl -n machdep.cpu_brand");
                $brand = run_command_scalar("$sysctl -n machdep.cpu_name")
                  unless defined $brand && $brand ne '';
                $brand = run_command_scalar("$sysctl -n machdep.cpu_model")
                  unless defined $brand && $brand ne '';
                if ( defined $brand && $brand ne '' ) {
                    $cpu = $brand;
                }
                my $freq_hz = run_command_scalar("$sysctl -n machdep.tsc_freq");
                if ( defined $freq_hz && $freq_hz =~ /^\d+$/ && $freq_hz > 0 ) {
                    my $local_mhz = sprintf( "%.2f", $freq_hz / 1_000_000 );
                    $cpu =
                      defined $cpu && $cpu ne ''
                      ? "$cpu ($local_mhz MHz)"
                      : "$local_mhz MHz";
                }
            }
        }

        $cpu = 'Unknown CPU' unless defined $cpu && $cpu ne '';

        my $ncpu_output = run_command_scalar("$sysctl -n hw.ncpu");

        if ( defined $ncpu_output ) {
            $smp = $ncpu_output;
            if ( $smp eq "1" ) {
                $smp = "";
            }
        }
    }
    if ($openbsd) {
        @cpu = grep( /cpu0: /,  @dmesgboot );
        @cpu = grep( /[M|G]Hz/, @cpu );
        $cpu = join( "\n", @cpu );
        @cpu = split( /: /, $cpu );
        $cpu = $cpu[1];
        $cpu =~ s/, / /;
        $cpu =~ s/([0-9.]* [MG]Hz)$/($1)/;
        my $ncpu_output = run_command_scalar("$sysctl -n hw.ncpu");

        if ( defined $ncpu_output ) {
            $smp = $ncpu_output;
            if ( $smp eq "1" ) {
                $smp = "";
            }
        }
    }
    if ( $irix || $irix64 ) {
        @cpu = grep( /CPU:/, @hinv );
        $cpu = join( "\n", @cpu );
        $cpu =~ s/^.*(R[0-9]*) .*$/$1/;
        @mhz = grep( /MHZ/, @hinv );
        $mhz = join( "\n", @mhz );
        $mhz = $mhz[0];
        $mhz =~ s/^.* ([0-9]*) MHZ.*$/$1/;
        @smp = grep( / IP/, @hinv );
        $smp = $smp[0];
        $smp =~ s/^([0-9]*) .*$/$1/;
        chomp($smp);
        chomp($cpu);
        chomp($mhz);
        $cpu = "MIPS $cpu ($mhz MHz)";
    }
    if ($linux) {
        if ($alpha) {
            $cpu   = &cpuinfo("cpu\\s+: ");
            $model = &cpuinfo("cpu model\\s+: ");
            $model = "$model (" . &cpuinfo("system type") . ")";
            $mhz   = &cpuinfo("cycle frequency \\[Hz\\]\\s+: ");
            $mhz   = ( $mhz / 1000000 );
            $mhz   = sprintf( "%.2f", $mhz );
            $cpu   = "$cpu $model ($mhz MHz)";
            $smp   = &cpuinfo("cpus detected\\s+: ");
        }
        if ($arm) {
            $cpu = &cpuinfo("Processor\\s+: ");
        }
        if ( $i686 || $i586 || $x86_64 ) {
            $cpu = &cpuinfo("model name\\s+: ");
            $cpu =~ s/(.+) CPU family\t+\d+MHz/$1/g;

            #$cpu           =~ s/(.+) CPU .+GHz/$1/g;
            $mhz = &cpuinfo("cpu MHz\\s+: ");
            $mhz =~ s/^\s*//g;
            $cpu = "$cpu ($mhz MHz)";
            @smp = grep( /processor\s+: /, @cpuinfo );
            $smp = scalar @smp;
        }
        if ($ia64) {
            $cpu   = &cpuinfo("vendor\\s+: ");
            $model = &cpuinfo("family\\s+: ");
            $mhz   = &cpuinfo("cpu MHz\\s+: ");
            $mhz   = sprintf( "%.2f", $mhz );
            $cpu   = "$cpu $model ($mhz MHz)";
            @smp   = grep( /processor\s+: /, @cpuinfo );
            $smp   = scalar @smp;
        }
        if ($mips) {
            $cpu   = &cpuinfo("cpu\\s+: ");
            $model = &cpuinfo("cpu model\\s+: ");
            $cpu   = "$cpu $model";
        }
        if ( $parisc || $parisc64 ) {
            $cpu   = &cpuinfo("cpu\\s+: ");
            $model = &cpuinfo("model name\\s+: ");
            $mhz   = &cpuinfo("cpu MHz\\s+: ");
            $mhz   = sprintf( "%.2f", $mhz );
            $cpu   = "$model $cpu ($mhz MHz)";
            @smp   = grep( /processor\s+: /, @cpuinfo );
            $smp   = scalar @smp;
        }
        if ( $ppc || $ppc64 ) {
            $cpu = &cpuinfo("cpu\\s+: ");
            $mhz = &cpuinfo("clock\\s+: ");
            $mhz =~ s/^(\d+\.\d{3})\d*\s*MHz/$1 MHz/;
            $cpu =~ s/, altivec supported//;
            if ( $cpu =~ /^(PPC)*9.+/ ) {
                $model = "IBM PowerPC G5";
            }
            elsif ( $cpu =~ /^74.+/ ) {
                $model = "Motorola PowerPC G4";
            }
            else {
                $model = "IBM PowerPC G3";
            }
            $cpu = "$model $cpu ($mhz)";
            my @processor_entries = grep { /^processor\s*:\s*[0-9]+/ } @cpuinfo;
            $smp = scalar @processor_entries;
        }
        if ( $s390 || $s390x ) {
            $cpu = &cpuinfo("vendor_id\\s+: ");
            $smp = &cpuinfo("processors\\s+: ");
        }
        if ($sh) {
            $cpu   = &cpuinfo("cpu family\\s+: ");
            $model = &cpuinfo("cpu type\\s+: ");
            $mhz   = &cpuinfo("cpu_clk\\s+: ");
            $cpu   = "$cpu $model ($mhz MHz)";
        }

        if ( $sparc || $sparc64 ) {
            $cpu   = &cpuinfo("cpu\\s+: ");
            $model = &cpuinfo("type\\s+: ");
            $cpu   = "$model $cpu";
            $mhz   = &cpuinfo("Cpu0ClkTck\\s+: ");
            $mhz   = ( hex($mhz) / 1000000 );
            $cpu   = "$cpu ($mhz MHz)";
            $smp   = &cpuinfo("ncpus active\\s+: ");
        }
    }
    elsif ($sun) {
        my $osp = run_command_scalar('uname -p') // "";
        if ( $osv =~ /^5\.11/ || ( $osv =~ /^5\.10/ && $osp =~ /i386/ ) ) {
            my @psrinfo_lines = run_command_lines('/usr/sbin/psrinfo -vp');
            if (@psrinfo_lines) {
                $cpu = $psrinfo_lines[-1];
                my ($frequency_line) = grep { /MHz/ } @psrinfo_lines;
                $mhz = "";
                if ( $frequency_line && $frequency_line =~ /([0-9]+)\s+MHz/ ) {
                    $mhz = "($1 MHz)";
                    $cpu = "$cpu $mhz";
                }
                $cpu =~ s/^\s*// if defined $cpu;
            }
            my $physical_count = run_command_scalar('/usr/sbin/psrinfo -p');
            $smp = $physical_count if defined $physical_count;
        }
        if ( $osp =~ /sparc/ ) {
            my @diag_lines =
              run_command_lines("/usr/platform/${osm}/sbin/prtdiag");
            if (@diag_lines) {
                $cpu = $diag_lines[0];
                $cpu =~ s/.*${osm} //;
            }
            my @psrinfo_all = run_command_lines('/usr/sbin/psrinfo');
            if (@psrinfo_all) {
                $smp = scalar @psrinfo_all;
            }
        }
    }
    elsif ($darwin) {
        my @hostinfo_lines = run_command_lines('hostinfo');
        my ($processor_line) = grep { /Processor type/ } @hostinfo_lines;
        if ( defined $processor_line ) {
            $processor_line =~ s/.*:\s*//;
            $processor_line =~ s/^\s*(.+)\s*$/$1/;
            $cpu = $processor_line;
        }
        if ( $cpu =~ /^ppc7.+/ ) {
            $cpu = "Motorola PowerPC G4";
        }
        if ( $cpu =~ /^ppc970/ ) {
            $cpu = "Motorola PowerPC G5";
        }
        if ( $cpu =~ /^i486/ ) {
            my $brand_string =
              run_command_scalar("$sysctl -n machdep.cpu.brand_string");
            $cpu = $brand_string
              if defined $brand_string && $brand_string ne "";
        }
        my $frequency_hz = run_command_scalar("$sysctl -n hw.cpufrequency");
        if ( defined $frequency_hz && $frequency_hz =~ /^[0-9]+$/ ) {
            $mhz = sprintf( "%.2f", $frequency_hz / 1000000 );
            $cpu = "$cpu ($mhz MHz)";
        }
        my ($available_line) = grep { /physically available/ } @hostinfo_lines;
        if ( defined $available_line ) {
            $available_line =~ s/ .*//;
            $smp = $available_line;
        }
        else {
            my $physical_cpu = run_command_scalar("$sysctl -n hw.physicalcpu");
            $smp = $physical_cpu if defined $physical_cpu;
        }
    }
    $smp = detect_cpu_count($smp);
    if ( $smp && $smp gt 1 ) {
        $cpu = "$smp x $cpu";
    }
    $cpu =~ s/\s*@\s*\d*\.\d*\s*GHz//;
    $cpu =~ s/^\s+//;
    $cpu =~ s/\(R\)//gi;
    $cpu =~ s/\(tm\)//gi;
    $cpu =~ s/\([^(]*GenuineIntel[^)]*\)//;
    $cpu =~ s/\s*processor//gi;
    $cpu =~ s/\s*CPU//gi;
    $cpu =~ s/ +/ /g;
}

sub batteryacpi {
    my $data = "";
    my ( $bfull, $bcur, @dirs, $dir );

    if ( opendir( DIR, '/proc/acpi/battery/' ) ) {
        @dirs = grep { !/^\./ } readdir(DIR);
        closedir(DIR);
        foreach $dir (@dirs) {
            $bfull = "";
            $bcur  = "";
            if ( open( FD, '/proc/acpi/battery/' . $dir . '/info' ) ) {
                while (<FD>) {
                    if (/^last full capacity:\ +([0-9]+)/) {
                        $bfull = $1;
                    }
                }
                close(FD);
            }
            if ( open( FD, '/proc/acpi/battery/' . $dir . '/state' ) ) {
                while (<FD>) {
                    if (/^remaining capacity:\ +([0-9]+)/) {
                        $bcur = $1;
                    }
                }
                close(FD);
            }
            if ( $bfull ne "" ) {
                if ( $data ne "" ) {
                    $data = $data . " ";
                }
                $data = $data . sprintf( "%.0f", ( $bcur / $bfull * 100 ) );
                $data = $data . "%";
            }
        }
    }
    return $data;
}

sub battery {
    $data = "";

    if ( -f '/proc/apm' ) {
        if ( open( FD, '/proc/apm' ) ) {
            while ( $stream = <FD> ) {
                $data .= $stream;
                @data = split( /\n/, $data );
            }
            close(FD);
        }
        $data = $data[0];
        $data =~ s/.+\s(\d+%).+/$1/;
    }
    elsif ( -d '/proc/acpi/battery' ) {
        $data = &batteryacpi;
    }
    return $data;
}

sub cpuinfo {
    my $pattern = shift;
    my @matches = grep( /$pattern/, @cpuinfo );
    return "" unless @matches;
    my ( undef, $value ) = split( /: /, $matches[0], 2 );
    return $value // "";
}

sub diskusage {
    if ( $irix || $irix64 ) {
        $vara =
          `$df | grep dev | awk '{ sum+=\$3 / 1024 / 1024}; END { print sum }'`;
        chomp($vara);
        $vard =
          `$df | grep dev | awk '{ sum+=\$4 / 1024 / 1024}; END { print sum }'`;
        chomp($vard);
    }
    elsif ($sun) {
        $vara =
`$df | grep -v swap | grep -v libc | awk '{ sum+=\$2 / 1024 / 1024}; END { print sum }'`;
        chomp($vara);
        $vard =
`$df | grep -v swap | grep -v libc | awk '{ sum+=\$3 / 1024 / 1024}; END { print sum }'`;
        chomp($vard);
    }
    else {
        $vara =
`$df | awk '/dev|rpool/ { sum+=\$2 / 1024 / 1024 } END { print sum }'`;
        chomp($vara);
        $vard =
`$df | awk '/dev|rpool/ { sum+=\$3 / 1024 / 1024 } END { print sum }'`;
        chomp($vard);
    }
    if ( $vara eq "" or $vara == 0 ) {
        return "0GB/0GB (0%)";
    }
    else {
        $varp = sprintf( "%.2f", $vard / $vara * 100 );
        $vara = sprintf( "%.2f", $vara );
        $vard = sprintf( "%.2f", $vard );
        return $vard . "GB/" . $vara . "GB ($varp%)";
    }
}

sub lvmusage {
    $vara = 0;

    if ($linux) {
        $vara = `$vgs | awk '{ sum+=\$1 / 1024 / 1024}; END { print sum }'`;
        chomp($vara);
        $vard =
`$vgs | awk '{ used =\$1-\$2; sum+=used / 1024 / 1024}; END { print sum }'`;
        chomp($vard);
    }

    if ( $vara eq "" or $vara == 0 ) {
        return "0GB/0GB (0%)";
    }
    else {
        $varp = sprintf( "%.2f", $vard / $vara * 100 );
        $vara = sprintf( "%.2f", $vara );
        $vard = sprintf( "%.2f", $vard );
        return $vard . "GB/" . $vara . "GB ($varp%)";
    }
}

sub loadaverage {
    my $uptime_output = run_command_scalar('uptime');
    return "" unless defined $uptime_output;
    my @parts = split( /averages*: /, $uptime_output, 2 );
    return "" unless @parts > 1;
    my @load_parts;
    if ($darwin) {
        @load_parts = split( / +/, $parts[1], 2 );
    }
    else {
        @load_parts = split( /, /, $parts[1], 2 );
    }
    return $load_parts[0] // "";
}

sub meminfo {
    my $string  = shift;
    my @matches = grep( /^$string/, @meminfo );
    return 0 unless @matches;
    my $line = $matches[0];
    chomp($line);
    my @fields = split( /\s+/, $line );
    return $fields[1] // 0;
}

sub memoryusage {
    if ($linux) {
        if ($linux_modern) {
            $vara = &meminfo("MemTotal:") * 1024;
            $varb = &meminfo("Buffers:") * 1024;
            $varc = &meminfo("Cached:") * 1024;
            $vard = &meminfo("MemFree:") * 1024;
        }
        else {
            @arr  = grep( /Mem:/, @meminfo );
            $var  = join( "\n", @arr );
            @arr  = split( /\s+/, $var );
            $vara = $arr[1];
            $varb = $arr[5];
            $varc = $arr[6];
            $vard = $arr[3];
        }
        if ( !$vara ) {
            return "0MB/0MB (0%)";
        }
        $vard = ( $vara - $vard ) - $varb - $varc;
    }
    elsif ($darwin) {
        $vard = `vm_stat | grep 'Pages active' | awk '{print \$3}'` * 4096;
        $vara = `$sysctl -n hw.memsize`;
    }
    elsif ($sun) {
        $vara =
          `/usr/sbin/prtconf | grep "Mem" | awk '{print \$3}'` * 1024 * 1024;
        $vard = `/bin/vmstat 1 2 | tail -1 | awk '{print \$5 * 1024}'`;
        $vard = $vara - $vard;
    }
    elsif ( $irix || $irix64 ) {
        $var = `top -d1 | grep Memory`;
        chomp($var);
        $vara = $var;
        $vard = $var;
        $vara =~ s/^.* ([0-9]*)M max.*$/$1/;
        $vara *= 1024 * 1024;
        $vard =~ s/^.* ([0-9]*)M free,.*$/$1/;
        $vard = $vara - ( $vard * 1024 * 1024 );
    }
    elsif ($netbsd) {
        $vard = `vmstat -t | tail -n 1 | awk '{print \$8}'`;
        $vard = $vard * 4096;
        $vara = `sysctl -n hw.physmem`;
    }
    else {
        $vard = `vmstat -s | grep 'pages active' | awk '{print \$1}'` *
          `vmstat -s | grep 'per page' | awk '{print \$1}'`;
        $vara = `$sysctl -n hw.physmem`;
    }
    $varp = sprintf( "%.2f", $vard / $vara * 100 );
    $vara = sprintf( "%.2f", $vara / 1024 / 1024 );
    $vard = sprintf( "%.2f", $vard / 1024 / 1024 );
    return $vard . "MB/" . $vara . "MB ($varp%)";
}

sub networkinfobsd {
    $varc = shift;
    $vard = shift;
    @arr  = grep( /$varc/, @netstat );
    @arr  = grep( /Link/,  @arr );
    $var  = join( "\n", @arr );
    @arr  = split( /\s+/, $var );
    $var  = $arr[$vard] / 1024 / 1024;
    $var  = sprintf( "%.2f", $var );
    return $var;
}

sub networkinfolinux {
    my ( $interface, $field_index ) = @_;
    my @device_lines = grep { /^\s*\Q$interface\E:/ } @netdev;
    return 0 unless @device_lines;
    my @parts = split( /:\s*/, $device_lines[0], 2 );
    return 0 unless @parts > 1;
    my @fields = split( /\s+/, $parts[1] );
    return 0 unless defined $fields[$field_index];
    my $value = $fields[$field_index] / 1024 / 1024;
    return sprintf( "%.2f", $value );
}

sub networktraffic {
    my $index            = 0;
    my $formatted_output = "";
    my $interface_count  = scalar @nic;
    while ( $index < $interface_count ) {
        my $interface       = $nic[$index]     // "";
        my $interface_label = $nicname[$index] // "";
        if ( $interface ne "" ) {
            if ( $formatted_output eq "" ) {
                $formatted_output = $col2 . " - " . $col1;
            }
            my ( $incoming, $outgoing ) = ( 0, 0 );
            if ( $darwin || $freebsd || $dragonfly ) {
                $incoming = &networkinfobsd( $interface, 6 );
                $outgoing = &networkinfobsd( $interface, 9 );
            }
            if ( $netbsd || $openbsd ) {
                $incoming = &networkinfobsd( $interface, 4 );
                $outgoing = &networkinfobsd( $interface, 5 );
            }
            if ($sun) {
                $incoming = &networkinfobsd( $interface, 4 );
                $outgoing = &networkinfobsd( $interface, 6 );
            }
            if ($linux) {
                $incoming = &networkinfolinux( $interface, 0 );
                $outgoing = &networkinfolinux( $interface, 8 );
            }
            $formatted_output .=
                $interface_label
              . " Traffic ("
              . $interface . ")"
              . $col2 . ": "
              . $col1
              . $incoming
              . "MB In/"
              . $outgoing
              . "MB Out - ";
        }
        $index++;
    }
    return $formatted_output if $formatted_output ne "";
    return;
}

sub run_command_scalar {
    my $command = shift;
    my $output  = qx{$command};
    return if $? != 0;
    chomp($output);
    return $output;
}

sub run_command_lines {
    my $command = shift;
    my @output  = qx{$command};
    return if $? != 0;
    chomp(@output);
    return @output;
}

sub parse_os_release {
    my $path = shift;
    return unless -r $path;
    my %values;
    if ( open( my $fh, '<', $path ) ) {
        while ( my $line = <$fh> ) {
            chomp($line);
            next if $line     =~ /^\s*#/;
            next unless $line =~ /=/;
            my ( $key, $value ) = split( /=/, $line, 2 );
            next unless defined $key;
            $value //= '';
            $value =~ s/^\"//;
            $value =~ s/\"$//;
            $value =~ s/\\(.)/$1/g;
            $values{$key} = $value;
        }
        close($fh);
    }
    return \%values;
}

sub read_first_line {
    my $path = shift;
    return unless -r $path;
    open( my $fh, '<', $path ) or return;
    my $line = <$fh>;
    close($fh);
    return unless defined $line;
    chomp($line);
    return $line;
}

sub detect_cpu_count {
    my $fallback = shift;
    my $output   = run_command_scalar('getconf _NPROCESSORS_CONF 2>/dev/null');
    if ( defined $output && $output =~ /^\d+$/ && $output > 0 ) {
        return $output;
    }
    return $fallback;
}

sub openfile {
    my $path = shift;
    my @lines;
    if ( open( my $fh, '<', $path ) ) {
        while ( my $line = <$fh> ) {
            chomp($line);
            push @lines, $line;
        }
        close($fh);
    }
    return @lines;
}

sub processes {
    my $command       = ( $irix || $irix64 || $sun ) ? 'ps -e' : 'ps ax';
    my @process_lines = run_command_lines($command);
    return 0 unless @process_lines;
    my $count = scalar @process_lines;
    $count-- if $process_lines[0] =~ /PID/;
    return $count;
}

sub uptime {
    if ( $irix || $irix64 || $d9 || $sun ) {
        my $uptime_text = run_command_scalar('uptime');
        return "" unless defined $uptime_text;
        if ( $uptime_text =~ /([0-9]+)\s+day.* ([0-9]+):([0-9]+),/ ) {
            return "$1d $2h $3m";
        }
        elsif ( $uptime_text =~ /([0-9]+)\s+min/ ) {
            return "0d 0h $1m";
        }
        elsif ( $uptime_text =~ /([0-9]+):([0-9]+),/ ) {
            return "0d $1h $2m";
        }
        return $uptime_text;
    }

    my $seconds_up;
    if ($linux) {
        my @uptime_fields = split( / /, $uptime[0] // "" );
        $seconds_up = $uptime_fields[0] if @uptime_fields;
    }
    else {
        my $boot_info = run_command_scalar("$sysctl -n kern.boottime");
        if ( defined $boot_info ) {
            my $boot_epoch;
            if ( $boot_info =~ /sec\s*=\s*([0-9]+)/ ) {
                $boot_epoch = $1;
            }
            elsif ( $boot_info =~ /^([0-9]+)/ ) {
                $boot_epoch = $1;
            }
            if ( defined $boot_epoch ) {
                $seconds_up = time() - $boot_epoch;
            }
        }
    }
    return "" unless defined $seconds_up;

    my $days = floor( $seconds_up / 86400 );
    $seconds_up %= 86400;
    my $hours = floor( $seconds_up / 3600 );
    $seconds_up %= 3600;
    my $minutes = floor( $seconds_up / 60 );

    my @components;
    push @components, $days . 'd'    if $days > 0;
    push @components, $hours . 'h'   if $hours > 0;
    push @components, $minutes . 'm' if $minutes > 0;
    my $formatted = join( ' ', @components );
    $formatted = '0m' if $formatted eq '';
    return $formatted;
}

sub users {
    my $uptime_output = run_command_scalar('uptime');
    return "" unless defined $uptime_output;
    $uptime_output =~ s/^.* +(.*) user.*$/$1/;
    return $uptime_output;
}

my $output;
if ($showHostname) {
    $output = $col1 . "Hostname" . $col2 . ": " . $col1 . $osn . $col2 . " - ";
}
if ($showOS) {
    $output .= $col1 . "OS" . $col2 . ": " . $col1 . $uname . $col2 . " - ";
}
if ( $linux && $showDistro && length $distro > 0 ) {
    $output .= $col1 . "Distro" . $col2 . ": " . $col1 . $distro;
    if ( length $distrov > 0 ) {
        $output .= " " . $distrov;
    }
    $output .= $col2 . " - ";
}
if ($showCPU) {
    $output .= $col1 . "CPU" . $col2 . ": " . $col1 . $cpu . $col2 . " - ";
}
if ($showProcesses) {
    $output .=
      $col1 . "Processes" . $col2 . ": " . $col1 . &processes . $col2 . " - ";
}
if ($showUptime) {
    $output .=
      $col1 . "Uptime" . $col2 . ": " . $col1 . &uptime . $col2 . " - ";
}
if ($showUsers) {
    $output .= $col1 . "Users" . $col2 . ": " . $col1 . &users . $col2 . " - ";
}
if ($showLoadAverage) {
    $output .=
        $col1
      . "Load Average"
      . $col2 . ": "
      . $col1
      . &loadaverage
      . $col2 . " - ";
}
if ($showBattery) {
    $output .=
      $col1 . "Battery" . $col2 . ": " . $col1 . &battery . $col2 . " - ";
}
if ($showMemoryUsage) {
    $output .=
        $col1
      . "Memory Usage"
      . $col2 . ": "
      . $col1
      . &memoryusage
      . $col2 . " - ";
}
if ($showDiskUsage) {
    $output .=
      $col1 . "FS Usage" . $col2 . ": " . $col1 . &diskusage . $col2 . " - ";
}
if ($showLVMUsage) {
    $output .= $col1 . "LVM Usage" . $col2 . ": " . $col1 . &lvmusage;
}
if ($showNetworkTraffic) { $output .= &networktraffic; }
$output =~ s/ - $//g;
print "$output\n";
