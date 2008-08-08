#!/usr/bin/perl
use strict;
use warnings;
use autodie;
use File::Find::Rule;
use Text::Template;
use File::Path;

my $template = Text::Template->new(
  TYPE   => 'FILE',
  SOURCE => 'www/src/TEMPLATE',
  DELIMITERS => [ qw({{ }}) ],
);

rmtree 'www/out';
mkpath 'www/out';

for my $file (File::Find::Rule->file->in('www/src')) {
  next if $file =~ /TEMPLATE/;
  my @parts = split m{/}, $file;
  my $leaf = pop @parts;
  shift @parts for (1 .. 2);
  my $path = join '/', @parts;
  mkpath "www/out/$path";

  if ($leaf =~ /\.html/) {
    open my $fh, '>', "www/out/$path/$leaf";
    my $content = `cat $file`;
    my $html = $template->fill_in(HASH => { content => \$content });
    print $fh $html;
  } else {
    `cp $file www/out/$path`;
  }
}
