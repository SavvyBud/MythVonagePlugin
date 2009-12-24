#!/usr/bin/perl
use strict;
use Env qw(HOME);
use Getopt::Std;
use lib $ENV{HOME} . '/opt/site_perl';
use Vonage::Click2Call;
use Data::Dumper;
our($opt_x, $opt_y);
my %opts;

getopt('p:',\%opts);
{
	package SoftSwitch;
	sub trim($)
	{
		my $self = shift;
		my $string = shift;
		$string =~ s/^\s+//;
		$string =~ s/\s+$//;
		return $string;
	}

	sub place_call(){
		my ($self,$ph) = @_;
		my %config;
		my $file = $ENV{'HOME'} . "/.vonage/config";
		open(my $fh, "<",$file) or die $!;
		while (my $line = readline($fh)){
			my @cfg = split('=',$line);
			my $str = $self->trim($cfg[1]);
			$config{$cfg[0]} = $str;
		}
		close($fh);
		#print "$config{'login'} $config{'password'} $config{'call_from'}\n";
		my $vonage = Vonage::Click2Call->new(login => $config{'login'},
			password => $config{'password'},
			no_https_check => 1, # wasteful after the first time. turn it off.
		);
		if (! $vonage) {
      	die "Failed during initilization : " . $Vonage::Click2Call::errstr;
		}
		print "calling: $ph\n";
		my $rc = $vonage->call($config{'call_from'},$ph);
		if (! $rc) {
      	die "Failed to place a call : " . $vonage->errstr;
		}
	}

	sub print_header(){
		print "<mythmenu name=\"Vonage\">\n";
	}

	sub print_footer(){
		print "</mythmenu>\n";
	}
	
	sub print_name(){
		my $self = shift;
		my $name = shift;
		my $ph = shift;
		print "\t<button>\n";
		print "\t\t<type>VIDEO_BROWSER</type>\n";
		print "\t\t<text><![CDATA[$name ($ph)]]></text>\n";
		print "\t\t<action><![CDATA[~/bin/vonage.pl -p $ph]]></action>\n";
		print "\t</button>\n";
	}

	sub xml(){
		my $self = shift;
		my $file = $ENV{'HOME'} . "/.vonage/phone_list";
		open(my $fh, "<",$file) or die $!;
		my $line;
		$self->print_header();
		while ($line = readline($fh)){
			my @ph = split(' ',$line);
			$self->print_name($ph[0],$ph[2]);
		}
		$self->print_footer();
		close($fh);
	}

	sub new(){
		my $class = shift;
		my $self = {};
		bless $self, $class;
		return $self;
	}
	sub run(){
		my $self = shift;
		my $ph=$opts{'p'};
		if(defined($ph)){
			$self->place_call($ph);
		}else {
			$self->xml();
		}
	}
};

my $vonage = SoftSwitch->new();
$vonage->run();
