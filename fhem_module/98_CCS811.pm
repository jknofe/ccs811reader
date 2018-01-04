# FHEM CCS811 readout 
# jknofe
# 01-2018
# based on "Hell World example" from https://wiki.fhem.de/wiki/DevelopmentModuleIntro

package main;
use strict;
use warnings;

sub CCS811_Initialize($) {
	my ($hash) = @_;

	$hash->{DefFn}      = 'CCS811_Define';
	$hash->{UndefFn}    = 'CCS811_Undef';
	$hash->{SetFn}      = 'CCS811_Set';
	$hash->{GetFn}      = 'CCS811_Get';
	$hash->{AttrFn}     = 'CCS811_Attr';
	$hash->{ReadFn}     = 'CCS811_Read';
	$hash->{ReadyFn} 	= 'CCS811_Ready';

	$hash->{AttrList} =
		  "formal:yes,no "
		. $readingFnAttributes;
}

sub CCS811_Define($$) {
	my ($hash, $def) = @_;
	my @param = split("[ \t][ \t]*", $def);
	
	if(int(@param) < 3) {
		return "too few parameters: define <name> CCS811 devicename\@baudrate";
	}
	# get name an device and set values in FHEM hash
	my $name = $param[0];
	my $dev = $param[2];
	$hash->{name}  = $name;
	$hash->{DeviceName} = $dev;
	
	# open serial dev with FHEM DivIo Lib
	my $ret = DevIo_OpenDev($hash, 0, "CSS811_DoInit");

	Debug("($name) CCS811_Define(): ".$dev); 

	return $ret;
}

sub CSS811_DoInit($) {
	# do dev init stuff here
	# nothing to do now
	return undef;
}

sub CCS811_Undef($$) {
	my ($hash, $arg) = @_; 
	# undef the device and close
	my $ret = DevIo_CloseDev($hash);
	return $ret;
}

sub CCS811_Read($){	
	my ($hash) = @_;
	my $name = $hash->{NAME};
	# read data from DevIo lib
	my $buf = DevIo_SimpleRead($hash);		
	return "" if ( !defined($buf) );
	# Debug("($name) - CCS811_Read(): ".$buf);
	# apend received data to buffer
	$hash->{helper}{BUFFER} .= $buf;
	# trim whitespaces
	chomp($hash->{helper}{BUFFER});
	#Debug("($name) - CCS811_Read(): ".length($hash->{helper}{BUFFER})." ".$hash->{helper}{BUFFER});
	# msg leng from CCS881 is 36byte, ich buffer exeeds this size evaluate the buffer
	if (length($hash->{helper}{BUFFER}) >= 36) {
		my @RawMsg = split /[\[\]]/, $hash->{helper}{BUFFER};
		if(int(@RawMsg) == 5) {
			# set FHEM readings
			readingsBeginUpdate($hash);
			readingsBulkUpdate($hash, "CO2", $RawMsg[1]);
			readingsBulkUpdate($hash, "VOC", $RawMsg[3]);
			readingsEndUpdate($hash, 1);
		}
		# clear buffer
		$hash->{helper}{BUFFER} = "";	
	}
	return undef;
}

sub CCS811_Ready($)
{
	my ($hash) = @_;
	# open the device if disconnected
	return DevIo_OpenDev($hash, 1, undef ) if ( $hash->{STATE} eq "disconnected" );
	# This is relevant for Windows/USB only
	if(defined($hash->{USBDev})) {
		my $po = $hash->{USBDev};
		my ( $BlockingFlags, $InBytes, $OutBytes, $ErrorFlags ) = $po->status;
		return ( $InBytes > 0 );
	}
}

sub CCS811_Get($@) {
	my ($hash, @param) = @_;
	# nothing to do
	return undef;
}

sub CCS811_Set($@) {
	my ($hash, @param) = @_;
	# nothing to do now
	return undef;
}


sub CCS811_Attr(@) {
	# nothing to do now
	return undef;
}

1;

=pod
=begin html

<a name="CCS811"></a>
<h3>CCS811</h3>
<ul>
	<b>Define</b>
	<ul>
		<code>define &lt;name&gt; CCS811 devicename\@baudrate</code>
		<br><br>
		Example: <code>define AirQuality1 CCS811 \dev\ttyACM0@9600</code>
		<br><br>
	</ul>
	<br>
</ul>

=end html

=cut
