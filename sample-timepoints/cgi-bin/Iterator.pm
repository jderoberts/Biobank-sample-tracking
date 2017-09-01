package Iterator;

#Iterator new(ParentClass object, int size, String type)
sub new {
    my $class = shift;
	my $self  = {};
	$self->{PARENT} = shift;
	$self->{SIZE}  = shift;
	$self->{TYPE} = shift;
	$self->{NEXT} = 0;
	
	bless $self, $class;
}

#boolean hasMore()
sub hasMore {
    my $self = shift;
	return ($self->{NEXT} < $self->{SIZE});
}

#ParentClass nextObject()
sub nextObject {
	my $self = shift;
	my $next = $self->{NEXT};
	$self->{NEXT} = $next + 1;
	my $parent = $self->{PARENT};
	my $prefix = $self->{TYPE};
	return $parent->_getObject($next, $self->{TYPE});
}

sub getData {
    my $self = shift;
	my $db = shift;
	my $sql = shift;
	my @vals = $db->doSQL($sql);
	$self->{VALS} = \@vals;
	$self->{PARENT} = $self;
	$self->{SIZE} = $#vals + 1;
	
}

sub getDataSingle {
    my $self = shift;
	my $db = shift;
	my $sql = shift;
	my @ret = $db->doSQL($sql);
	my @vals;
	foreach my $row (@ret) {
    	my $val;
    	foreach my $col (keys %{$row}) {
    		$val = $row->{$col};
		}
		push @vals, $val;
	}
	
	$self->{VALS} = \@vals;
	$self->{PARENT} = $self;
	$self->{SIZE} = $#vals + 1;
	
}

sub _getObject {
	my $self = shift;
	my $index = shift;
	my @vals = @{$self->{VALS}};
	return $vals[$index];
}

sub rewind {
	my $self = shift;
	$self->{NEXT} = 0;
}

1;

