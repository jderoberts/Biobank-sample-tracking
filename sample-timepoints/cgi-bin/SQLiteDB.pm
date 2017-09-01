package SQLiteDB;

use strict;
use DBI;
use Carp;
use Iterator;

#SQLiteDB new()

sub new {
    my $class = shift;
    my $self = {};
    my $db="../sqlite/samples.db";
    my $userid="";
    my $passwd="";
    my $connectionInfo="dbi:SQLite:dbname=$db";
    my $dbh = DBI->connect($connectionInfo,$userid,$passwd) 
              or die "Can't connect to SQLite database:\n".$DBI::errstr;
    $self->{DB} = $dbh;
    bless $self, $class;
    return $self;
}

sub getDB {
    my $self = shift;
    return $self->{DB};
}

sub getVersion {
    my $self = shift;
    my $dbh  = $self->{DB};
    my $sth = $dbh->prepare("SELECT SQLITE_VERSION()");
    $sth->execute();
    my $ver = $sth->fetch();
    return $ver;
}

sub disconnect {
    my $self = shift;
    my $dbh  = $self->{DB};
    $dbh->disconnect();
}

# String doSingle(String sql, String colName)
# Returns the column name of the first row of the query
sub doSingle {
        my $self    = shift;
        my $sql     = shift;
        my $colName = shift;

        my @rec = $self->doSQL($sql);
        my $res = $rec[0]->{$colName};

        return $res;
}

# ArrayArray doSQLCol(String SQL)
sub doSQLCol {
        my $self = shift;
        my $sql  = shift;
        my $dbh = $self->{DB};
        my @ret;
        my $sth = $dbh->prepare($sql);

        $sth->execute() 
          or do {print "Execute Failed --- [$sql]\n"; return @ret;};
        my $count = 0;
        while( my @row = $sth->fetchrow_array()) {
                push @ret, @row;
        }

        $sth->finish();
        return @ret;
}

# Array doSQLSingleCol(String sql)
sub doSQLSingleCol {
        my $self = shift;
        my $sql  = shift;
        my $dbh = $self->{DB};
        my @ret;
        my $sth = $dbh->prepare($sql);

        $sth->execute() 
          or do {print "Execute Failed --- [$sql]\n"; return @ret;};
        my $count = 0;
        while( my @row = $sth->fetchrow_array()) {
                push @ret, $row[0];
        }

        $sth->finish();
        return @ret;
}

# HashArray doSQL(String SQL)
sub doSQL {
        my $self = shift;
        my $sql  = shift;
        my $dbh = $self->{DB};
        my @ret;
        my $sth = $dbh->prepare($sql); 
        $sth->execute()
          or do {print "Execute Failed --- [$sql]\n"; return @ret;};
        my $count = 0;
        while( my $row = ($sth->fetchrow_hashref()) ) {
                push @ret, $row;
        }

        $sth->finish();
        return @ret;
}

sub execute {
        my $self = shift;
        my $sql  = shift;
        my $dbh = $self->{DB};
        my $ret = $dbh->do($sql)
          or die "Can't execute $sql:\n".$dbh->errstr."\n";
        return $ret;
}

# void insert(String sql)
sub insert {
        my $self = shift;
        my $sql  = shift;
        my $dbh = $self->{DB};
        my $ret = $dbh->do($sql)
          or die "Can't execute $sql:\n$dbh->errstr\n";
        $dbh->do("commit") or die "Can't execute commit ".$dbh->errstr."\n";
        return $ret;
}

# void update(String sql)
sub update {
        my $self = shift;
        my $sql  = shift;

        return $self->insert($sql);
}

sub sampleExists {
        my $self = shift;
        my $cloneID = shift;
        my $sql = "select count(*) k from sample_data where sample_id='$cloneID'";
        my $rows = $self->doSingle($sql,'k');
        return 1 unless $rows==0;
        return 0;
}

# Iterator getSQLIterator(String sql)
sub getSQLIterator {
        my $self = shift;
        my $sql  = shift;
        my $i = new Iterator();
        $i->getData($self,$sql);

        return $i;
}

1;
