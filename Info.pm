package RIFF::Info;

require 5.005_62;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '1.02';

#is this reasonable?  big fudge factor here.
use constant MAX_HEADER_BYTES => 10240;

sub new {
  my $class = shift;
  my %param = @_;
  my $header_size = $param{-headersize} || MAX_HEADER_BYTES;

  my $self = bless {}, $class;
  $self->handle($param{-file});
  $self->header_size($header_size);

  return $self;
}

sub header_size {
  my($self,$arg) = @_;
  return $self->{header_size} unless defined $arg;
  $self->{header_size} = $arg;
}

sub handle {
  my($self,$file) = @_;

  return $self->{handle} unless defined $file;

  open(F,$file) or die "couldn't open $file: $!";
  $self->{handle} = \*F;
}

sub type      { return shift->{type} }
sub scale     { return shift->{scale} }
sub vrate      { return shift->{vrate} }

sub vcodec    { return shift->{vcodec} }
sub acodecraw { return shift->{acodec} }
sub acodec    { my $self = shift; return $self->codec2str($self->{acodec}) }

sub vstreams  { return shift->{vstreams} }
sub astreams  { return shift->{astreams} }

sub achans    { return shift->{achans} }
sub arate     { return shift->{arate} }

sub fps       { return shift->{fps} }
sub vframes   { return shift->{vframes} }
sub width     { return shift->{width} }
sub height    { return shift->{height} }


sub probe {
  my $self = shift;
  my $fh = $self->handle;

  my $type;
  sysread($fh,$type,12) or die $!;

  notRIFF() if( ($type !~ /^(RIFF)/) && ($type !~ /^(AVI) /) );
  $self->{type} = $1;

  #onward
  my $hdrl_data = undef;

  while(!$hdrl_data){
    my $byte;
    sysread($fh,$byte,8) or die $!;

    if($byte =~ /^LIST/){
      sysread($fh,$byte,4) or die $!;

      if($byte =~ /hdrl/){
        sysread($fh,$hdrl_data,$self->header_size);
      } elsif($byte =~ /movi/){
        ###
      }
    } elsif($byte =~ /^idx1/){
      ###
    }
  }

  my $last_tag = 0;
  for(my $i=0 ; $i < length($hdrl_data) ; $i++){

    my $t = $i;
    my $window = substr($hdrl_data,$t,4);
    if($window eq 'strh'){

      $t += 8;
      $window = substr($hdrl_data,$t,4);

      if($window eq 'vids'){
        $self->{scale} = unpack("L",substr($hdrl_data,$t+20,4));
        $self->{vrate}  = unpack("L",substr($hdrl_data,$t+24,4));
        $self->{fps} = $self->{vrate} / $self->{scale};
        $self->{vframes} = unpack("L",substr($hdrl_data,$t+32,4));
        $self->{vstreams}++;
        $last_tag = 1;

      } elsif($window eq 'auds'){
        $self->{astreams}++;
        $last_tag = 2;

      }
    } elsif($window eq 'strf'){

      $t += 8;
      $window = substr($hdrl_data,$t,4);

      if($last_tag == 1){
        $self->{width}      = unpack("L",substr($hdrl_data,$t+4,4));
        $self->{height}     = unpack("L",substr($hdrl_data,$t+8,4));
        $self->{vcodec} = substr($hdrl_data,$t+16,4);

      } elsif($last_tag == 2){
        $self->{acodec}      = unpack("S",substr($hdrl_data,$t,2));
        $self->{achans}     = unpack("S",substr($hdrl_data,$t+2,2));
        $self->{arate}      = unpack("L",substr($hdrl_data,$t+4,4));

      }

      $last_tag = 0;
    }
  }
  return 1;
}

sub codec2str {
  my $self = shift;
  my $numeric = shift;

  my %codec = (
    1    => 'PCM',
    2    => 'MS ADPCM',
    11   => 'IMA ADPCM',
    31   => 'MS GSM 6.10',
    32   => 'MS GSM 6.10',
    50   => 'MPEG Layer 1/2',
    55   => 'MPEG Layer 3',
    160  => 'DivX WMA',
    161  => 'DivX WMA',
    401  => 'IMC',
    2000 => 'AC3',
  );

  return $codec{$numeric} || 'unknown';
}

sub notRIFF {
  die "not RIFF data";
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

RIFF::Info - Probe DivX, AVI, and ASF files for attributes like:

 -video codec
 -audio codec
 -frame height
 -frame width
 -frame count

and more!

=head1 SYNOPSIS

  use RIFF::Info;

  my $video;

  $video = RIFF::Info->new(-file=>$filename);                          #like this
  $video = RIFF::Info->new(-file=>$filename,-headersize=>$headersize); #or this

  $self->probe;                           #parse the video file
  $video->vcodec;                         #video codec
  $video->acodec;                         #audio codec
  ...

=head1 DESCRIPTION

=head2 METHODS

RIFF::Info has one constructor, new().  It is called as:
  -file       => $filename,   #your RIFF file
  -headersize => $headersize  #optional RIFF header size to parse
Returns a RIFF::Info object if the file was opened successfully.

Call probe() on the RIFF::Info object to parse the file.  This
does a series of sysread()s on the file to figure out what the
properties are.

Now, call one (or more) of these methods to get the low-down on
your file:

 method              returns
 ---------------------------------------------------
 achans()            number of audio channels
 acodec()            audio codec
 acodecraw()         audio codec numeric ID
 arate()             audio bitrate
 astreams()          number of audio streams
 fps()               frames/second
 height()            frame width in pixels
 scale()             video bitrate
 type()              type of file data.  RIFF or AVI.
 vcodec()            video codec
 vframes()           number of frames
 vrate()             video bitrate
 vstreams()          number of video streams
 width()             frame height in pixels

=head1 BUGS

The default header_size() (10K) may not be large enough to 
successfully extract the video/audio attributes for all RIFF 
files.  If this module fails you, consider increasing the RIFF 
header size.  If it still fails, let me know.

Audio codec name mapping is incomplete.  If you know the name
that corresponds to an audio codec ID that I don't, tell me.

=head1 AUTHOR

Allen Day <allenday@ucla.edu>
Copyright (c) 2002, Allen Day

You may enjoy this module under the same terms as Perl itself.

=head1 ACKNOWLEDGMENTS

This was written with liberal snarfing from transcode, a linux
video stream processing tool available from:

http://www.theorie.physik.uni-goettingen.de/~ostreich/transcode/

=cut
