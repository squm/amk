#!/usr/bin/perl
use utf8;
use strict;
use warnings;
use Data::Dumper qw/Dumper/;
# binmode STDOUT, ':encoding(UTF-8)';

my %amk = (
  header => 'id',
	number => 'code',
	title => 'desc'
);

my $maxdepth = 8;
my $verbose = 0;

my $json_text = json2Dict(get_json());
my $json_dict;
eval("\$json_dict = $json_text");
# print Dumper @{$json_dict->{group}[0]{subgroup}[0]{codes}};

my @amk;
print list_api($json_dict, "", 1);

print Dumper @amk;

sub list_api {
	my ($ref, $history, $depth) = @_;
	my $preamble = "         $depth)";
	print "\nlist_api $depth) in ", get_type($ref), "\n" if ($verbose);

	if ($depth > $maxdepth) {
		print "Error: maxdepth $maxdepth\n";
		return;
	}
	if (isDict($ref)) {
		if (defined $ref->{$amk{header}}) {
			$history .= ": $ref->{$amk{header}}";
		}

		for my $key (keys %{$ref}) {
			print "$preamble key $key -> ", get_type($ref->{$key}), "\n" if ($verbose);

			# ignore scalar
			if (isArray($ref->{$key})) {
				list_api($ref->{$key}, $history, $depth + 1);
			}
			elsif (isDict($ref->{$key})) {
				# TODO: make robust
				print "Error: HoH\n";
			}
			elsif ($key eq $amk{number}) {
				# leaf node
				# $history .= ": $ref->{$amk{title}}";
				# print "$ref->{$amk{number}}\t $history\n";
				print "$preamble leaf $key $ref->{$key}\n" if ($verbose);
				print "$preamble leaf history: ($history)\n" if ($verbose);
				push @amk, {
					p1 => $ref->{$amk{number}},
					p2 => $history,
					p3 => $ref->{$amk{title}}
				};
			}
		}
	}
	elsif (isArray($ref)) {
		# Dict inside array.
		$history .= ":" if ($verbose);
		for my $item (@{$ref}) {
			print "$preamble item ", get_type($item), "\n" if ($verbose);
			list_api($item, $history, $depth + 1);
		}
	}

	# print "$preamble exit\n\n";
}
sub get_type {
	my $ref = shift;

	if (ref $ref eq 'HASH') {
		my @items = keys %{$ref};
		return "HASH ", scalar keys %{$ref}, ": (@items)";
	}

	if (ref $ref eq 'ARRAY') {
		my @items = @{$ref};
		# return "ARRAY ", scalar @{$ref}, ": (@items)";
		return "ARRAY ", scalar @{$ref};
	}

	unless (ref $ref) {
		return "NOT REF"
	}

	return ref $ref;
}
sub isDict {
	return ref shift eq 'HASH';
}
sub isArray {
	return ref shift eq 'ARRAY';
}
sub slurp {
	my $filename = shift;
	use open ":encoding(utf8)";
	local $/;
	open my $fh, "< $filename" or die "Can't open $filename: $!\n";
	<$fh>;
}
sub json2Dict {
	$_ = shift;
	s/:/=>/sg;
	return "{$_}";
}
sub get_json {
	return <<JSON
	"group" : [
		{
			"subgroup" : [
				{
					"codes" : [
						{ "code" : 111, "desc" : "export"	},
						{ "code" : 112, "desc" : "avans"	},
						{ "code" : 151, "desc" : "pererabotka"	},
						{ "code" : 160, "desc" : "remont"	},
						{ "code" : 190, "desc" : "torgovoe"	}
					]
				}
			],
			"id" : "tovary"
		},
		{
			"subgroup" : [
				{
					"codes" : [
						{ "code" : 207, "desc" : "passazhiry"	},
						{ "code" : 209, "desc" : "other"	}
					],
					"id" : "sea transport" 
				},
				{
					"codes" : [
						{ "code" : 211, "desc" : "passengers"	},
						{ "code" : 212, "desc" : "gruzi"	},
						{ "code" : 213, "desc" : "other"	}
					],
					"id" : "air transport"
				}
			],
			"id" : "perevozki"
		}
	]
JSON
}
