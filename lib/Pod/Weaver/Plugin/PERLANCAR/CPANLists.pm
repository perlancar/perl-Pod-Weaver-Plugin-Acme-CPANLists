package Pod::Weaver::Plugin::PERLANCAR::CPANLists;

# DATE
# VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

use Markdown::To::POD;

sub _process_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    # XXX handle dynamically generated module (if there is such thing in the
    # future)
    local @INC = ("lib", @INC);

    {
        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";
        require $package_pm;
    }

    my $found;

    my $author_lists = \@{"$package\::Author_Lists"};
    for my $list (@$author_lists) {
        $found++;
        my $text = "=head2 $list->{summary}\n\n";
        $text .= Markdown::To::POD::markdown_to_pod($list->{description})."\n\n"
            if $list->{description};
        $text .= "=over\n\n";
        for my $ent (@{ $list->{entries} }) {
            $text .= "=item * L<".($ent->{summary} ? "$ent->{summary}|" : "$ent->{author}|")."https://metacpan.org/author/$ent->{author}>\n\n";
            $text .= Markdown::To::POD::markdown_to_pod($ent->{description})."\n\n"
                if $ent->{description};
        }
        $text .= "=back\n\n";
        $self->add_text_to_section($document, $text, 'AUTHOR LISTS');
    }

    my $module_lists = \@{"$package\::Module_Lists"};
    for my $list (@$module_lists) {
        $found++;
        my $text = "=head2 $list->{summary}\n\n";
        $text .= Markdown::To::POD::markdown_to_pod($list->{description})."\n\n"
            if $list->{description};
        $text .= "=over\n\n";
        for my $ent (@{ $list->{entries} }) {
            $text .= "=item * L<$ent->{module}>".($ent->{summary} ? " - $ent->{summary}" : "")."\n\n";
            $text .= Markdown::To::POD::markdown_to_pod($ent->{description})."\n\n"
                if $ent->{description};
        }
        $text .= "=back\n\n";
        $self->add_text_to_section($document, $text, 'MODULE LISTS');
    }

    if ($found) {
        $self->log(["Generated POD for '%s'", $filename]);
    }
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;
        $self->_process_module($document, $input, $package);
    }
}

1;
# ABSTRACT: Generate POD for @Author_Lists and @Module_Lists

=for Pod::Coverage weave_section

=head1 SYNOPSIS

In your C<weaver.ini>:

 [-PERLANCAR::CPANLists]


=head1 DESCRIPTION
