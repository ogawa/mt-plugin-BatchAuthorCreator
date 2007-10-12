# $Id$
package BatchAuthorCreator::L10N::ja;

use strict;
use base 'BatchAuthorCreator::L10N';
use vars qw( %Lexicon );

our %Lexicon = (
    'BatchAuthorCreator plugin allows you to create multiple users and their personal blogs easily.' => 'BatchAuthorCreatorプラグインを使うと、多数のユーザ(およびユーザの個人用のブログ)を簡単に登録することができます。',
    q(Temporary directory needs to be writable for 'Batch Author Creator' to work correctly.  Please check TempDir configuration directive.) => q(Batch Author Creatorを使用するにはテンポラリディレクトリに書き込みできなければなりません。TempDirの設定を確認してください。),
    q(Author '[_1]' already exists. Skipped to create this author.) => q(ユーザ「[_1]」はすでに存在します。このユーザの作成をスキップします。),
    q(Author '[_1]' doesn't have '[_2]'. Skipped to create this author.) => q(ユーザ「[_1]」の[_2]がありません。このユーザの作成をスキップします。),
    'Configuration file' => '設定ファイル',
);


1;
