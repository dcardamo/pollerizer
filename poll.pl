#!/usr/bin/perl

####################################################################
#
# Dan Cardamore <dcardamo@novas.cx>
#
# Pollerizer  version 1.0
#
# This program gets a users input as part of a poll, and then prints
# a webpage with the results.
#
# The questions_file should have the following format:
#	<number of questions>
#	<Question in human terms>
#	<Each option on its own line>
#
####################################################################

########  BEGIN USER CONFIGURATION #################################
$url = "http://www.novas.cx/";
$server_root = "/home/httpd/html";
$path_from_root = "/index/poll";
$me = $url . $path_from_root . "/poll.pl";
$questions_file = $server_root . $path_from_root . "/questions.dat";
$ip_file = $server_root . $path_from_root . "/remote_ips.dat";
$results_file = $server_root . $path_from_root . "/results.dat";
$poll_image = $path_from_root . "/poll.gif";
########  DONE USER CONFIGURATION ##################################


&Parse_Form;

$remote_ip = $ENV{'REMOTE_ADDR'};
$choice = $formdata{'choice'};

if ($remote_ip eq "")
{
	die "There was an error retrieving your IP\n";
}

if ($choice ne "")
{
	# Add the IP to the ip_file
	open (IP_FILE, ">>$ip_file") || die "There was an error opening the ip log file.\n";
	flock (IP_FILE, 2);	# Lock the file
	print IP_FILE "$remote_ip\n";
	flock (IP_FILE, 8);	# Unlock the file
	close (IP_FILE);

	# Add the choice to the other results
	open (RESULTS, ">>$results_file") || die "Could not open the results file.\n";
	print RESULTS "$choice~$remote_ip\n";
	close (RESULTS);
	print "Location: $url\n\n";
}

# Test to see if the visitor has already voted.
open (IP_FILE, "<$ip_file") || die "There was an error opening the ip log file.\n";
@addresses = <IP_FILE>;
close (IP_FILE);

$type_of_page = "get";
foreach $index (@addresses)
{
	chop $index;
	if ($remote_ip eq $index)
	{
		$type_of_page = "print";
	}
}


if ($type_of_page eq "get")
{
	open (QUESTIONS, "<$questions_file") || die "Could not open the questions file\n";
	@q_file = <QUESTIONS>;
	close (QUESTIONS);

	print "<FORM ACTION=\"$me\" METHOD=POST>\n";
	print "<font size=-1>\n";
	print "<b>$q_file[1]</b><br>\n";	# print the question

	$number_of_questions = $q_file[0];
	
	for ($i = 0; $i < $number_of_questions; $i++)
	{
		print "<INPUT TYPE=\"radio\" NAME=\"choice\" VALUE=\"$i\">$q_file[$i + 2]<br>\n";
	}
	print "<INPUT TYPE=\"submit\" VALUE=\"Vote\">\n";
	print "</font>\n";
	print "</FORM>\n";
}

if ($type_of_page eq "print")
{
	open (QUESTIONS, "<$questions_file") || die "Could not get the questions file\n";
	@q_file = <QUESTIONS>;
	close (QUESTIONS);
	
	$number = $q_file[0];
	
	# clear the array
	for ($i = 0; $i < $number; $i++)
	{
		$tally[$i] = 0;
	}

	open (RESULTS, "<$results_file") || die "Could not get the results\n";
	@data = <RESULTS>;
	close (RESULTS);

	$total_votes = 0;
	foreach $index (@data)
	{
		@line = split(/~/, $index);
		$tally[$line[0]]++;
		$total_votes++;
	}
	print "<font size=-1>\n";
	print "<b>$q_file[1]</b><br>\n";
	for ($i = 0; $i < $number; $i++)
	{
		$percent = $tally[$i] / $total_votes * 100;
		$width = $percent * 0.3;
		$percent = sprintf("%.1f", $percent);
		print "$q_file[$i + 2] <IMG SRC=\"$poll_image\" height=5 width=$percent>$percent\%<br>\n";
	}
	print "<B>Total votes: $total_votes</B><br>\n";
	print "</font>\n";
}

sub Parse_Form {
        if ($ENV{'REQUEST_METHOD'} eq 'GET') {
                @pairs = split(/&/, $ENV{'QUERY_STRING'});
        } elsif ($ENV{'REQUEST_METHOD'} eq 'POST') {
                read (STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
                @pairs = split(/&/, $buffer);
                
                if ($ENV{'QUERY_STRING'}) {
                        @getpairs =split(/&/, $ENV{'QUERY_STRING'});
                        push(@pairs,@getpairs);
                        }
        } else {
                print "Content-type: text/html\n\n";
                print "<P>Use Post or Get";
        }

        foreach $pair (@pairs) {
                ($key, $value) = split (/=/, $pair);
                $key =~ tr/+/ /;
                $key =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
                $value =~ tr/+/ /;
                $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        
                $value =~s/<!--(.|\n)*-->//g;
        
                if ($formdata{$key}) {
                        $formdata{$key} .= ", $value";
                } else {
                        $formdata{$key} = $value;
                }
        }
}       

