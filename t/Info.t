#!/usr/bin/perl

use lib './blib/lib';
use strict;

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    if( $@ ) { 
	use lib 't';
    }
    use Test;
    plan tests => 23 }

print "Loading RIFF::Info...\n";
use RIFF::Info;
ok(1);

my $file = RIFF::Info->new(-file=>'eg/simpson.avi',-headersize=>10240);
ok $file;
ok $file->filename     eq 'eg/simpson.avi';
ok $file->probe;
ok $file->achans       == 1;
ok $file->acodec       eq 'MS ADPCM';
ok $file->acodecraw    == 2;
ok $file->arate        == 89240;
ok $file->astreams     == 1;
ok int($file->fps)     == 12;
ok $file->height       == 180;
ok $file->scale        == 83255;
ok $file->type         eq 'RIFF';
ok $file->vcodec       eq 'cvid';
ok $file->vframes      == 349;
ok $file->vrate        == 1_000_000;
ok $file->vstreams     == 1;
ok $file->width        == 240;
ok int($file->duration)== 29;
ok $file->fourcc       eq 'cvid';
ok $file->afrequency   == 22_050;
ok $file->expectedsize == 2_457_646;
ok $file->filesize,    == 188_443;
