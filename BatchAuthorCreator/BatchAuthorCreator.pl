# BatchAuthorCreator
#
# $Id$
#
# This software is provided as-is. You may use it for commercial or 
# personal use. If you distribute it, please keep this notice intact.
#
# Copyright (c) 2007 Hirotaka Ogawa

package MT::Plugin::BatchAuthorCreator;
use strict;
use base qw(MT::Plugin);

use MT;

our $VERSION = '0.01';

my $plugin = __PACKAGE__->new({
    id          => 'batch_author_creator',
    name        => 'BatchAuthorCreator',
    description => q(<MT_TRANS phrase="BatchAuthorCreator plugin allows you to create multiple users and their personal blogs easily.">),
    doc_link    => 'http://code.as-is.net/public/wiki/BatchAuthorCreator',
    author_name => 'Hirotaka Ogawa',
    author_link => 'http://as-is.net/blog/',
    version     => $VERSION,
    l10n_class  => 'BatchAuthorCreator::L10N',
});
MT->add_plugin($plugin);

sub instance { $plugin }

sub init_registry {
    my $plugin = shift;
    $plugin->registry({
	applications => {
	    cms => {
		menus => {
		    'tools:batch_author_creator' => {
			label => $plugin->translate('Batch Author Creator'),
			order => 900,
			permission => 'administer',
			view => 'system',
			mode => 'start_create_authors',
		    },
		    'system:batch_author_creator' => {
			label => $plugin->translate('Batch Author Creator'),
			order => 900,
			system_permission => 'administer',
			mode => 'start_create_authors',
		    },
		},
		methods => {
		    'start_create_authors' => 'BatchAuthorCreator::CMS::start_create_authors',
		    'create_authors'       => 'BatchAuthorCreator::CMS::create_authors',
		}
	    }
	}
    });
}

1;
