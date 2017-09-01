#!/usr/bin/perl -w

use strict;
use warnings;

use CGI::Carp ('fatalsToBrowser');
use CGI;
use SQLiteDB;

my $form=new CGI;
my $db = new SQLiteDB();
my $title = 'Patient Timepoint Search';

print $form->header(),
      $form->start_html(-style=>[{-src=>'/css/search_flex.css'},
                                 {-src=>'/css/hor-minimalist-table.css'},
                                 {-src=>'/css/selectize.custom.css'}],
                        -title=>$title,
                        -script=>[{-src=>'https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js'},
                                  {-src=>'/js/selectize.js'},
                                  {-src=>'/js/timepoints_defaults.js'}]);
print "<div class='flexRow'>",$form->img({-src => '/images/logo.png', -alt => 'LOGO', -height=>'100', -width=>'200'}),
          $form->h2({-id=>'page_title'},$title),"</div>";
print $form->start_form(-method=>'post', -name=>'entryform');

my $action = $form->param('submit');
$action = '' unless defined $action;
$action = uc($action);
if($action eq 'SEARCH') {
    runReport();
} else {
    getParams();
}

print $form->end_form(),
      $form->end_html();
      
sub getParams {

    print "<div class='flexRow'>",$form->h3("Select from suggested defaults or customise below:&nbsp;"),
          "<select id='defaultSelect' style='padding:1px;height:30px;'><option>Please Choose</option><option>MPN</option><option>MDS</option>",
          "<option>Other myeloid</option><option>B-LPD</option><option>Other lymphoid</option></select></div>";
    print "<input type='text' id='select-tumour' name='select-tumour'></input>";
    print "<br><input type='text' id='select-constitutional' name='select-constitutional'></input>";
    print "<p style='font-size:14px'>Existing stored DNA is displayed if available, otherwise cellular products from which it can be extracted:</p>";
    print "<p style='font-size:14px'>DNA lysates are preferentially displayed, then RNA lysates / cell pellets if they are the only material available.</p>";
    print $form->start_table({-border=>'0', -id=>'DATA_INPUT'});
    print $form->Tr([$form->th({-colspan=>3,-align=>'left'},'Enter patient identifiers separated by spaces:'),
          $form->td({-colspan=>3,-align=>'left'},[$form->textarea(-name=>'upin_list',-rows=>10, -cols=>80)])]);
    print $form->Tr($form->th({-colspan=>2,-align=>'left'},'Or upload a comma-separated list of identifiers (CSV format):'),
                    $form->td({-rowspan=>2,-valign=>'middle'}, $form->submit(-name=>'submit',-value=>'Search')));
    print $form->Tr($form->td({-align=>'center'},"Filename: "),
                    $form->td($form->filefield('uploaded_file','starting value',50,80)));
    print $form->end_table();

}

sub runReport {
    initialiseDb();
    
    my $tumour = $form->param('select-tumour');
    my $constitutional = $form->param('select-constitutional');
    print $form->br(), $form->submit(-value=>"New Search", -name=>'submit');

    my $filename = $form->param('uploaded_file');
    my $upin_list = $form->param('upin_list');
    my @upin_array;
    #exit if no file selected
    if ($upin_list ne '') {
        #upin list field has text in it
        #convert all whitespace to spaces, remove non alphanum chars (commas etc)
        #split list and call funct on it
        $upin_list =~ tr/\r\n/ /d;
        $upin_list =~ s/[^a-zA-Z0-9]/:/g;
        @upin_array = split( /:+/, $upin_list);
        processUPINs(@upin_array);
    } else {
        if ((not defined $filename)||($filename eq '')) {
            print $form->h2("Text field empty and no file selected. Please provide a list of UPINs.");
            return;
        } else {
            #import file
            @upin_array = importFile($filename);
            #call funct on upins
            processUPINs(@upin_array);
        }
    }
    #check what isn't in table:  make list of input upins and delete initial upins
    my @valid_upin_array = $db->doSQLSingleCol("select distinct upin from timepoint_search order by id;");
    my %invalid_upin_hash;
    @invalid_upin_hash{ @upin_array } = undef;
    delete @invalid_upin_hash{ @valid_upin_array };
    my @invalid_upin_array = keys  %invalid_upin_hash;
    if (scalar(@valid_upin_array) == 0) {
        print $form->h2("No valid UPINs were found, make sure you are using the main/final UPIN in each case.");
        return;
    };
    #now print out tables into divs
    #then tabs to display one of two divs:

    print "<div class='tabs'>";
    print "<div id = 'summary_tab' class='tab is-tab-selected' onclick='showhide".'("summary")'."'>Summary</div>";
    print "<div id = 'details_tab' class='tab' onclick='showhide".'("details")'."'>Timepoint Details</div>";
    print "</div>";

    print "<div id='summary' class='results'>";
    timepointSummary(@valid_upin_array);
    if (scalar(@invalid_upin_array) > 0 ) {
        print $form->p("The following UPINs were not found.  Make sure you are using the final UPIN in each case:");
        print $form->h3(join(", ", @invalid_upin_array));
    };
    print "</div>";
    print "<div id='details' class='results' style='display:none;'>";
    timepointDetails(@valid_upin_array);
    print "</div>";
}

sub initialiseDb {
    $db->execute('drop table if exists timepoint_search;');
    my $sql_table = 'create table timepoint_search (id integer PRIMARY KEY, upin text, record_type text, dx text, sample_id text, dos text, trial_number text, sample_type text, cell_type text, media_type text, dna text);';
    $db->execute($sql_table);
}

sub importFile {
    my $safe_filename_characters = "a-zA-Z0-9_.-";
    my $upload_dir ="/tmp/";
    my $filename = shift;

    my ( $name, $path, $extension ) = fileparse ( $filename, '..*' );
    $filename = $name . $extension;
    $filename =~ tr/ /_/;
    $filename =~ s/[^$safe_filename_characters]//g;
    if ( $filename =~ /^([$safe_filename_characters]+)$/ ) {
        $filename = $1;
    } else {
        die "Filename contains invalid characters";
    }
    my $upload_filehandle = $form->upload("uploaded_file");
    open ( UPLOADFILE, ">$upload_dir/$filename" ) or die "Cannot open $filename";
    binmode UPLOADFILE;
    while ( <$upload_filehandle> ) {
        print UPLOADFILE;
    }
    close UPLOADFILE;
    print $form->end_html();

    my @upin_array = readCSV($upload_dir . $filename);
    #this will delete the file from the Uploaded directory once action completed. Saves space on server.
    unlink  $upload_dir.$filename;
    return @upin_array
}

sub readCSV {
    my $csv_file = shift;
    my @upin_array;
    open ( CSVFILE, "<$csv_file" ) or die "Cannot open file";
    while (my $line = <CSVFILE> ) {
        chomp $line;
        my @csvFields = split(/,+/,$line);
        foreach my $field (@csvFields) {
            $field =~ tr/\r\n\s//d;
            push( @upin_array, $field ) if $field ne '';
        }
    }
    close ( CSVFILE );
    return @upin_array
}

sub checkUPIN {
    my $ptID = shift;
    my $ret = 0;
    my $sql = "select * from sample_patient where upin='$ptID' or alias='$ptID'";
    my @res = $db->doSQLSingleCol($sql);
    if (scalar @res != 0) {
        $ret = 1;
    }
    return $ret;
}

sub processUPINs {
    my @upin_array = @_;
    my %processed_upins;

    foreach my $upin (@upin_array) {
        #check if in hash of processed upins. if already checked go to next,
        #if not add to hash and proceed
        if (exists($processed_upins{$upin})) {
            next;
        } else {
            $processed_upins{$upin} = 1;
        }

        #check if upin exists
        if (not checkUPIN($upin)) {
            next;
        }
        
        my @upin_2s = $db->doSQLSingleCol("select distinct alias from sample_patient where upin = '$upin' and alias != '';");
        my @upin_3s = $db->doSQLSingleCol("select distinct upin from sample_patient where alias = '$upin';");

        my @upins_combined = ($upin);
        foreach my $uid ((@upin_2s,@upin_3s)) {
            unless ($uid ~~ @upins_combined) {
                push @upins_combined, $uid;
            }
        }
        getTimepoints(@upins_combined);
    }
}

sub getTimepoints {
    my @upins = @_;
    my $upin_check = "'".join("','",@upins)."'";

    my $buccalQuery =<< "ENDBUCCALQUERY";
SELECT product_barcode FROM sample_patient sp LEFT JOIN molecular_products mp ON sp.sample_id = mp.sample_id 
WHERE upin IN ($upin_check) AND cell_type = 'BUCCAL' AND product_type = 'DNA' AND available = 1;
ENDBUCCALQUERY

    my $cd3Query =<< "ENDCD3QUERY";
SELECT CASE
WHEN m_av = 1 THEN 'DNA'
WHEN c_av = 1 THEN 'DL'
ELSE '' END AS type
FROM (
SELECT upin, cp.available c_av, mp.available m_av
FROM sample_patient sp
LEFT JOIN cellular_products cp ON sp.sample_id = cp.sample_id
LEFT JOIN molecular_products mp ON cp.product_barcode = mp.parent_barcode
WHERE upin in ($upin_check) AND
cp.cell_type = 'CD3+' AND cp.product_type = 'DL') AS qry
ORDER BY type desc;
ENDCD3QUERY

    my $exTQuery =<< "ENDEX_TQUERY";
SELECT CASE
WHEN m_av = 1 THEN 'DNA'
WHEN c_av = 1 THEN 'DL'
ELSE '' END AS type
FROM (
SELECT upin, cp.available c_av, mp.available m_av
FROM sample_patient sp
LEFT JOIN cellular_products cp ON sp.sample_id = cp.sample_id
LEFT JOIN molecular_products mp ON cp.product_barcode = mp.parent_barcode
WHERE upin in ($upin_check) AND
cp.cell_type = 'ExT' AND cp.product_type = 'DL') AS qry
ORDER BY type desc;
ENDEX_TQUERY

    my $tumour = $form->param('select-tumour');
    my $constitutional = $form->param('select-constitutional');
    my @tumour_selected = split(/,/,$tumour);
    my @wb_types;
    my @bm_types;
    foreach my $option (@tumour_selected) {
        if (substr($option,0,2) eq 'WB') {
            push(@wb_types,substr($option,3,6))
        }
        if (substr($option,0,2) eq 'BM') {
            push(@bm_types,substr($option,3,6))
        }
    }
    my $wb_types = "'".join ("','",@wb_types)."'";
    my $bm_types = "'".join ("','",@bm_types)."'";
    my @const_selected = split(/,/,$constitutional);
    my $buccal = '';
    my $cd3 = '';
    my $exT = '';
    my $opt1 = '';
    my $opt2 = '';

    foreach my $option (@const_selected) {
        if ($option eq 'Buccal') {
            my $buccalCheck = $db->doSingle($buccalQuery, 'product_barcode');
            if ($buccalCheck ne '') {
                $buccal = 'Buccal';
            }
        } elsif ($option eq 'WB T cells') {
            my @cd3Check = $db->doSQL($cd3Query);
            if ($cd3Check[0]->{'type'} =~ /DNA/) {
                $cd3 = 'CD3+ DNA';
            } elsif ($cd3Check[0]->{'type'} =~ /DL/)  {
                $cd3 = 'CD3+ DL';
            }
        } elsif ($option eq 'WB cultured T cells') {
            my @exTCheck = $db->doSQL($exTQuery);
            if ($exTCheck[0]->{'dna'} =~ /DNA/) {
                $exT = 'ExT DNA';
            } else {
                $exT = 'ExT DL';
            }
        } else {
            my ($sample, $cell) = split(/\s/,$option);
            my $customQuery =<< "ENDCUSTOMQUERY";
SELECT CASE
WHEN m_av = 1 THEN 'DNA'
WHEN c_av = 1 THEN 'DL'
ELSE '' END AS type
FROM (
SELECT upin, cp.available c_av, mp.available m_av
FROM sample_patient sp
LEFT JOIN sample_data sd ON sp.sample_id = sd.sample_id
LEFT JOIN cellular_products cp ON sp.sample_id = cp.sample_id
LEFT JOIN molecular_products mp ON cp.product_barcode = mp.parent_barcode
WHERE 
upin in ($upin_check) AND
sd.sample_type = '$sample' AND
cp.cell_type = '$cell' AND 
cp.product_type = 'DL') AS qry
ORDER BY type desc;
ENDCUSTOMQUERY
            my @customCheck = $db->doSQL($customQuery);
            if ($customCheck[0]->{'type'} =~ /DNA/) {
                if ($opt1 eq '') {
                    $opt1 = "$option DNA";
                } else {
                    $opt2 = "$option DNA";
                }
            } elsif ($customCheck[0]->{'type'} =~ /DL/) {
                if ($opt1 eq '') {
                    $opt1 = "$option DL";
                } else {
                    $opt2 = "$option DL";
                }
            }
        }
    }
    my $aliases = "'".join(", ",@upins[1..$#upins])."'";
    $db->doSQL("insert into timepoint_search (upin, record_type, dx) values ('$upins[0]','patient',$aliases);");

    $db->doSQL("insert into timepoint_search (upin, record_type, trial_number, sample_type, cell_type, media_type, dna) values ('$upins[0]','constitutional','$opt1','$buccal','$cd3','$exT','$opt2');");

    my $wbtimepointQuery =<< "ENDWBTIMEPOINTQUERY";
SELECT 
sample_id, 
diagnosis,
sample_date,
trial_number,
cell_type,
GROUP_CONCAT( DISTINCT product_type) media,
CASE WHEN MAX(mp_av) THEN mp_bc ELSE '' END AS dna,
cp_available
FROM
(SELECT *, 
cp.available cp_available, mp.available mp_av, mp.product_barcode mp_bc
FROM sample_patient sp
LEFT JOIN sample_data sd ON sp.sample_id = sd.sample_id
LEFT JOIN cellular_products cp ON sp.sample_id = cp.sample_id
LEFT JOIN molecular_products mp ON cp.product_barcode = mp.parent_barcode
WHERE upin in ($upin_check)
AND sd.sample_type = 'WB'
AND cp.cell_type IN ($wb_types)
AND (cp_available = 1 OR mp_av = 1)
AND (mp.product_type IS NULL OR mp.product_type = 'DNA')
) AS qry
GROUP BY sample_id, cell_type ORDER BY sample_date;
ENDWBTIMEPOINTQUERY

    my $bmtimepointQuery =<< "ENDBMTIMEPOINTQUERY";
SELECT
sample_id,
diagnosis,
sample_date,
trial_number,
cell_type,
GROUP_CONCAT( DISTINCT product_type) media,
CASE WHEN MAX(mp_av) THEN mp_bc ELSE '' END AS dna,
cp_available
FROM
(SELECT *,
cp.available cp_available, mp.available mp_av, mp.product_barcode mp_bc
FROM sample_patient sp
LEFT JOIN sample_data sd ON sp.sample_id = sd.sample_id
LEFT JOIN cellular_products cp ON sp.sample_id = cp.sample_id
LEFT JOIN molecular_products mp ON cp.product_barcode = mp.parent_barcode
WHERE upin in ($upin_check) 
AND sd.sample_type = 'BM'
AND cp.cell_type IN ($bm_types)
AND (cp_available = 1 OR mp_av = 1)
AND (mp.product_type IS NULL OR mp.product_type = 'DNA')
) AS qry
GROUP BY sample_id, cell_type ORDER BY sample_date;
ENDBMTIMEPOINTQUERY

    if (scalar @wb_types > 0) {
        my $timepointIterator = $db->getSQLIterator($wbtimepointQuery);
        while($timepointIterator->hasMore()) {
            my $row = $timepointIterator->nextObject();
            my $sampleid = $row->{'sample_id'};
            my $dx = $row->{'diagnosis'};
            my $dos = $row->{'sample_date'};
            my $tnumber = $row->{'trial_number'};
            my $cell_type = $row->{'cell_type'};
            my $media_type = $row->{'media'};
            my $dna = $row->{'dna'};
            my $available = $row->{'cp_available'};

            if ($dna eq '' ) {
                $dna = $available;
            }
            #If date is '' convert into empty date 0000-00-00
            my $date = '0000-00-00';
            if ($dos ne '') {
                $date = $dos;
            }
            $db->doSQL("insert into timepoint_search (upin, record_type, dx, sample_id, dos, trial_number, sample_type, cell_type, media_type,dna) values ('$upins[0]','timepoint','$dx','$sampleid','$date','$tnumber','WB','$cell_type','$media_type','$dna');")
        }
    }

    if (scalar @bm_types > 0) {
        my $timepointIterator = $db->getSQLIterator($bmtimepointQuery);
        while($timepointIterator->hasMore()) {
            my $row = $timepointIterator->nextObject();
            my $sampleid = $row->{'sample_id'};
            my $dx = $row->{'diagnosis'};
            my $dos = $row->{'sample_date'};
            my $tnumber = $row->{'trial_number'};
            my $cell_type = $row->{'cell_type'};
            my $media_type = $row->{'media'};
            my $dna = $row->{'dna'};
            my $available = $row->{'cp_available'};

            if ($dna eq '' ) {
                $dna = $available;
            }
            #as above, convert empty dos to 0000-00-00
            my $date = '0000-00-00';
            if ($dos ne '') {
                $date = $dos;
            }


            $db->doSQL("insert into timepoint_search (upin, record_type, dx, sample_id, dos, trial_number, sample_type, cell_type, media_type,dna) values ('$upins[0]','timepoint','$dx','$sampleid','$dos','$tnumber','BM','$cell_type','$media_type','$dna');")
        }
    }
}

sub timepointSummary {
    my @upin_array = @_;

    print $form->start_table({-border=>'0', -id=>'hor-minimalist-table-b'});
    print $form->Tr($form->th(['UPIN', 'AKA','Dx', 'Const.</br>Material', 'All</br>Timepoints', 'Timepoints with</br>existing DNA']));
    #start table then for each upin read values into row
    foreach my $upin (@upin_array) {
        my $aliases = $db->doSingle("select dx from timepoint_search where upin = '$upin' and record_type ='patient';", 'dx');
        my $dx = $db->doSingle("select dx from timepoint_search where upin = '$upin' order by id desc;", 'dx');
        my @const;
        my $buccal = $db->doSingle("select sample_type from timepoint_search where upin = '$upin' and record_type ='constitutional';", 'sample_type');
        my $cd3 = $db->doSingle("select cell_type from timepoint_search where upin = '$upin' and record_type ='constitutional';", 'cell_type');
        my $exT = $db->doSingle("select media_type from timepoint_search where upin = '$upin' and record_type ='constitutional';", 'media_type');
        my $opt1 = $db->doSingle("select trial_number from timepoint_search where upin = '$upin' and record_type ='constitutional';", 'trial_number');
        my $opt2 = $db->doSingle("select dna from timepoint_search where upin = '$upin' and record_type ='constitutional';", 'dna');
        foreach my $con ($buccal,$cd3,$exT,$opt1,$opt2) {
            push (@const, $con) unless $con eq '';
        }
        my $timepointCount = $db->doSingle("select count(distinct dos) timepointCount from timepoint_search where upin = '$upin' and record_type = 'timepoint' and dna != 0;", 'timepointCount');
        my $dnaTimepointCount = $db->doSingle("select count(distinct dos) timepointCount from timepoint_search where upin = '$upin' and record_type = 'timepoint' and dna is not null and dna != '' and dna != 0 and dna != 1;", 'timepointCount');
        print $form->Tr($form->td([$upin,$aliases,$dx,join(',</br>',@const), $timepointCount,$dnaTimepointCount]));
	    }
    print $form->end_table();
    print "</br>";
}


sub timepointDetails {
    my @upin_array = @_;

    foreach my $upin (@upin_array) {
        print $form->h2($upin);
        my $aliases = $db->doSingle("select dx from timepoint_search where upin = '$upin' and record_type ='patient';", 'dx');
        if (length ($aliases) > 0 ) {
            print $form->h3("AKA: $aliases");
        }
        my @const;
        my $buccal = $db->doSingle("select sample_type from timepoint_search where upin = '$upin' and record_type ='constitutional';", 'sample_type');
        my $cd3 = $db->doSingle("select cell_type from timepoint_search where upin = '$upin' and record_type ='constitutional';", 'cell_type');
        my $exT = $db->doSingle("select media_type from timepoint_search where upin = '$upin' and record_type ='constitutional';", 'media_type');
        my $opt1 = $db->doSingle("select trial_number from timepoint_search where upin = '$upin' and record_type ='constitutional';", 'trial_number');
        my $opt2 = $db->doSingle("select dna from timepoint_search where upin = '$upin' and record_type ='constitutional';", 'dna');
        foreach my $con ($buccal,$cd3,$exT,$opt1,$opt2) {
            push (@const, $con) unless $con eq '';
        }
        if (scalar(@const) > 0 ) {
            print $form->h3("Constitutional material: ".join(', ',@const));
        } else {
            print $form->h3("No constitutional material found");
        }
        print $form->start_table({-border=>'0', -id=>'hor-minimalist-table-b'});
        print $form->Tr($form->th(['Timepoint', 'Dx', 'Date', 'Sample</br>ID', 'Trial</br>Number', 'Sample</br>Type', 'Cell</br>Type', 'Media</br>Type']));
        my $timepointCounter = 0;
        my $timepointDateCheck;
        my $timepointOutputQuery = "select * from timepoint_search where upin = '$upin' and record_type = 'timepoint' and dna != 0 order by dos, id;";
        my $timepointOutputIterator = $db->getSQLIterator($timepointOutputQuery);
        while($timepointOutputIterator->hasMore()) {
            my $row = $timepointOutputIterator->nextObject();
            my $dx = $row->{'dx'};
            my $dos = $row->{'dos'};
            my $sample_id = $row->{'sample_id'};
            my $trial_number = $row->{'trial_number'};
            my $sample_type = $row->{'sample_type'};
            my $cell_type = $row->{'cell_type'};
            my $media_type = $row->{'media_type'};
            my $dna = $row->{'dna'};
            my $media = $media_type;
            if($media_type =~ /DL/) {
                $media = 'DL';
            }
            if ($dna ne 0 && $dna ne 1) {
                $media = "DNA";
            }
            #if two samples from same date, e.g. WB + BM, considered same timepoint
            if ($dos ne $timepointDateCheck) {
                $timepointCounter++;
            }
            print $form->Tr($form->td([$timepointCounter,$dx,$dos,$sample_id,$trial_number,$sample_type,$cell_type,$media]));
            $timepointDateCheck = $dos;
        }
        print $form->end_table();
        print "</br><hr>";
    }
}
