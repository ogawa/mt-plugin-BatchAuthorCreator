# $Id$

package BatchAuthorCreator::CMS;
use strict;
use base 'MT::App';

sub start_create_authors {
    my $app = shift;
    return $app->trans_error("Permission denied.")
	unless $app->user->is_superuser;

    my $plugin = MT::Plugin::BatchAuthorCreator->instance;

    my (@error_loop);
    my $tmp = $app->config('TempDir');
    unless ((-d $tmp) && (-w $tmp)) {
	push @error_loop, {
	    message => $plugin->translate(q(Temporary directory needs to be writable for 'Batch Author Creator' to work correctly.  Please check TempDir configuration directive.))
	};
    }

    my $tmpl = $plugin->load_tmpl('batch_author_creator.tmpl');
    $tmpl->text($plugin->translate_templatized($tmpl->text));
    return $app->build_page($tmpl, {
	@error_loop ? (error_loop => \@error_loop) : ()
    });
}

sub create_authors {
    my $app = shift;
    return $app->trans_error("Permission denied.")
	unless $app->user->is_superuser;
    $app->validate_magic() or return;

    my $plugin = MT::Plugin::BatchAuthorCreator->instance;

    my $q = $app->param;
    my ($yaml);
    if ($ENV{MOD_PERL}) {
	my $upload = $q->upload('file');
	if ($upload && $upload->size) {
	    my $fh = $upload->fh;
	    $yaml = join('', <$fh>);
	    close $fh;
	}
    } else {
	my $fh = $q->upload('file');
	if ($fh) {
	    $yaml = join('', <$fh>);
	    close $fh;
	}
    }

    my (@success_loop, @error_loop);
    if ($yaml) {
	use YAML::Tiny;
	$yaml = YAML::Tiny->read_string($yaml);
	shift @$yaml while @$yaml && (ref($yaml->[0]) ne 'HASH');
	$yaml = $yaml->[0];

	for my $name (keys %$yaml) {
	    if (create_author($app, $name, $yaml->{$name})) {
		push @success_loop, {
		    message => $plugin->translate("Author '[_1]' added.", $name)
		};
	    } else {
		push @error_loop, {
		    message => $app->errstr
		};
	    }
	}
    }

    my $tmpl = $plugin->load_tmpl('batch_author_creator.tmpl');
    $tmpl->text($plugin->translate_templatized($tmpl->text));
    return $app->build_page($tmpl, {
	@success_loop ? (success_loop => \@success_loop) : (),
	@error_loop   ? (error_loop   => \@error_loop  ) : (),
    });
}

sub create_author {
    my ($app, $author_name, $param) = @_;
    return $app->trans_error("Permission denied.")
	unless $app->user->is_superuser;

    my $plugin = MT::Plugin::BatchAuthorCreator->instance;

    if (MT::Author->count({ name => $author_name })) {
	return $app->error($plugin->translate("Author '[_1]' already exists. Skipped to create this author.", $author_name));
    }

    # check mandatory fields
    for my $opt (qw/email password hint/) {
	return $app->error($plugin->translate("Author '[_1]' doesn't have '[_2]'. Skipped to create this author.", $author_name, $opt))
	    unless exists $param->{$opt};
    }

    my $author = MT::Author->new;

    # set defaults
    $author->type(MT::Author::AUTHOR());
    $author->auth_type($app->config->AuthenticationModule);

    # set mandatory fields
    $author->name($author_name);
    $author->email($param->{email});
    $author->set_password($param->{password});
    $author->hint($param->{hint});

    # set optional fields
    for my $opt (qw/nickname url preferred_language text_format api_password/) {
	$author->$opt($param->{$opt})
	    if exists $param->{$opt};
    }

    # permissions
    my $sys_perms = MT::Permission->perms('system');
    $param->{can_modify_password} = MT::Auth->password_exists;
    $param->{can_recover_password} = MT::Auth->can_recover_password;
    foreach (@$sys_perms) {
	my $name = 'can_' . $_->[0];
	$name = 'is_superuser' if $name eq 'can_administer';
	if (exists $param->{system_permissions}->{$name}) {
	    $author->$name($param->{system_permissions}->{$name});
	} else {
	    $author->$name(0);
	}
    }

    # entry_prefs
    my $delim = $param->{tag_delim};
    if ( $delim =~ m/comma/i ) {
	$delim = ord(',');
    } elsif ( $delim =~ m/space/i ) {
	$delim = ord(' ');
    } else {
	$delim = ord(',');
    }
    $author->entry_prefs('tag_delim' => $delim);

    # created_by
    $author->created_by($app->user->id);

    $author->save
	or return $app->error($app->translate("Saving object failed: [_1]" . $author->errstr));

    $app->log({
	message  => $app->translate("User '[_1]' (ID:[_2]) created by '[_3]'", $author->name, $author->id, $app->user->name),
	level    => MT::Log::INFO(),
	class    => 'author',
	category => 'new',
    });
    $author->add_default_roles;

    # provision a personal blog for a new user
    if ($param->{create_personal_weblog} ||
	    $app->config->NewUserAutoProvisioning) {
	$app->run_callbacks('new_user_provisioning', $author);
    }

    1;
}

1;
