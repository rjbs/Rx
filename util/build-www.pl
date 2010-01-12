#!/usr/bin/perl
use strict;
use warnings;
use autodie;
use File::Find::Rule;
use File::Path;
use JSON 2;
use Text::Template;

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

  my @coretypes = sort map { s{.+/}{}; s{.html}{}; $_ }
                  File::Find::Rule->file->in('www/src/coretype');

  if ($leaf =~ /\.html/) {
    open my $fh, '>', "www/out/$path/$leaf";
    my $content = `cat $file`;
    my %stash = (
      depth     => \(scalar @parts),
      root      => '../' x @parts,
      coretypes => \@coretypes,
      ct_page   => \(scalar $path =~ /coretype$/),
    );

    my $filled_content = Text::Template->fill_this_in(
      $content,
      DELIMITERS => [ '{{', '}}' ],
      HASH       => \%stash
    );
    die "template error: $Text::Template::ERROR" unless $filled_content;

    my $html = $template->fill_in(
      DELIMITERS => [ '{{', '}}' ],
      HASH       => {
        content   => \$filled_content,
        %stash
      }
    );
    die "template error: $Text::Template::ERROR" unless $html;

    print $fh $html;
  } else {
    `cp $file www/out/$path`;
  }
}
