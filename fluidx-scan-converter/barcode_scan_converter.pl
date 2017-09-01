#!/usr/bin/perl -w
#James Roberts, 2016
#jde.roberts3@gmail.com
use strict;
use warnings;
use Tk;
use OLE;
use Win32::OLE;
use Win32::OLE::Const 'Microsoft Excel';
use Cwd 'abs_path';
use File::Basename;

my $scriptDir = dirname(abs_path($0));
my $infilepath='';
my $ErrorLabel= 'Please select a file to convert.';

our $mw = MainWindow->new;
$mw->configure(-title => "Convert FluidX scans for database upload");
$mw->configure(-bg => '#334353');
$mw->optionAdd('*font', 'Helvetica 14');
$mw->toplevel->iconbitmap($scriptDir.'\\icon.ico');
$mw->geometry("+250+200");

my $frame = $mw->Frame->pack(-fill => 'x', -pady => 20, -ipadx=> 10, -ipady=> 5);
my $subframe1 = $frame->Frame->pack(-fill => 'x');
$subframe1->Label(-text => "Filename:")
          ->pack(-side => 'left', -anchor => 'w', -pady => 20, -padx => 10);
$subframe1->Entry(-textvariable => \$infilepath)
          ->pack(-side => 'left', -anchor => 'w', -fill => 'x', -expand => 1, , -pady => 20, -padx => 10);
my $subframe2 = $frame->Frame->pack(-fill => 'x');
$subframe2->Button(-text => " Select File ", -command => \&open_file)
          ->grid(-row => 1, -column => 1, -padx => 20, -pady => 10);
$subframe2->Button(-text => " Convert File ", -command => \&convertCSVtoXLS)
          ->grid(-row => 1, -column => 2, -padx => 20, -pady => 10);
$subframe2->Label(-textvariable => \$ErrorLabel)
          ->grid(-row => 2, -column => 1, -columnspan => 2, -padx => 20, -pady => 10);	
	
sub open_file {
   my @types =
       (["CSV files", [qw/.csv /]],
        ["All files",        '*'],
       );
   $infilepath= $subframe2->getOpenFile(-filetypes => \@types,-initialdir =>$scriptDir);
}

sub convertCSVtoXLS {
	if ((not defined $infilepath)||($infilepath eq '')) {
		$ErrorLabel = 'No file selected.';
		return;
	}
	
	my $excel = Win32::OLE->new('Excel.Application', 'Quit');
	$excel -> {Visible} = 0;
	
	my $templatefilepath = $scriptDir."\\docs\\fluidX_upload_template.xls";
	
	#using regexp to extract rack ID, box barcode, scan date
	my $rackidDB;
	my $rackidFluidX;
	my $scandate;
	$infilepath =~ /^.*\/([A-Z]{2,6}[0-9]{6})_.*\.csv$/;
	$scandate = substr($infilepath, -23, 15);
	$scandate = substr($scandate, 4, 4)."-".substr($scandate, 2, 2)."-".substr($scandate, 0, 2).", ".substr($scandate, 9, 2).":".substr($scandate, 11, 2).":".substr($scandate, 13, 2);
			
	if ($1 =~ /^DNA|^RNA/) {
		if (substr($infilepath,-33,1) eq '_') {
			$rackidDB = substr($infilepath, -42, 9) ;
		} else {
			$rackidDB = substr($infilepath, -44, 9);
		}
	} elsif ($1 =~ /^SERUM/) {
		if (substr($infilepath,-33,1) eq '_') {
			$rackidDB = substr($infilepath, -44, 11);
		} else {
			$rackidDB = substr($infilepath, -46, 11);
		};
	} elsif ($1 =~ /^PLASMA/) {
		if (substr($infilepath,-33,1) eq '_') {
			$rackidDB = substr($infilepath, -45, 12);
		} else {
			$rackidDB = substr($infilepath, -47, 12);
		}
	}
	
	my $csv = $excel    -> Workbooks -> Open($infilepath);
	my $csvsheet    = $csv -> Worksheets(1);
	$csvsheet                -> Activate;
	

	#empty positions to bring index into line with row number in destination file
	my @wellRefFluidX = ('','');
	my @wellRefDB = ('','');
	my @tubeCodeFluidX = ('','');

	my $last_row = $csvsheet -> UsedRange -> Find({What => "*", SearchDirection => xlPrevious, SearchOrder => xlByRows})    -> {Row};

	for (my $i = 1; $i <= $last_row; $i++) {
		if ($csvsheet -> Range("A".$i) -> {Value} eq 'RACK ID') {
			$rackidFluidX = $csvsheet -> Range("B".$i) -> {Value};
			$rackidFluidX =~ s/ //;
		} elsif (($csvsheet -> Range("A".$i) -> {Value} eq '')||($csvsheet -> Range("A".$i) -> {Value} eq 'WELL')) {
			next;
		} elsif ($csvsheet -> Range("B".$i) -> {Value} eq 'NO TUBE') {
			next;
		} elsif ($csvsheet -> Range("B".$i) -> {Value} eq 'NO READ') {
			$ErrorLabel = "Selected file contains 'NO READ' values.\nPlease decode all tubes.";
			return;
		} else {
			push @wellRefFluidX, ($csvsheet -> Range("A".$i) -> {Value});
			push @wellRefDB, convertWellRef($csvsheet -> Range("A".$i) -> {Value});
			push @tubeCodeFluidX, ($csvsheet -> Range("B".$i) -> {Value});
		}
	}

	$csv -> Close;
		
	my $workbook = $excel -> Workbooks -> Open($templatefilepath);
	my $worksheet = $workbook -> Worksheets(1);
	$worksheet -> Activate;
		
	for (my $i = 2; $i < (scalar @wellRefFluidX); $i++) {
		my $trimmedTubeCodeFluidX = $tubeCodeFluidX[$i];
		$trimmedTubeCodeFluidX =~ s/ //;
		$worksheet -> Range("B".$i) -> {Value} = $rackidFluidX;
		$worksheet -> Range("C".$i) -> {Value} = $wellRefFluidX[$i];
		$worksheet -> Range("D".$i) -> {Value} = $trimmedTubeCodeFluidX;
		$worksheet -> Range("E".$i) -> {Value} = $rackidDB;
		$worksheet -> Range("F".$i) -> {Value} = $wellRefDB[$i];
		$worksheet -> Range("I".$i) -> {Value} = $scandate;
	};

	if (not defined $rackidDB) {
		$ErrorLabel = "Unable to extract DB rack name from filename. ";
	} 

	$excel    -> {DisplayAlerts} = 0; 
	# turns off "file already exists" message.
	$workbook -> SaveAs ($scriptDir."\\output\\fluidX_upload_$rackidDB.xls");
	if (not defined $rackidDB) {
		$ErrorLabel .= "\nFile saved as 'fluidX_upload_' in destination folder, \nplease add DB rack to file contents manually.";
	} else {
		$ErrorLabel = "File saved in destination folder as\n fluidX_upload_$rackidDB.xls";
	}
	$excel    -> Quit;
	undef $workbook;
	undef $csv;
	undef $excel;
	reset 'a-z';  
	reset;
};

sub convertWellRef {
	my $wellRef = shift(@_);
	my $row = substr($wellRef,0,1);
	my $col = substr($wellRef,1);
	my $paddedCol = sprintf("%02d", $col);
	my $convertedWellRef = $row.$paddedCol;
	return $convertedWellRef;
};


MainLoop;
