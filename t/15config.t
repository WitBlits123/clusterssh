use strict;
use warnings;

use FindBin qw($Bin $Script);
use lib "$Bin/../lib";

use Test::More;
use Test::Trap;
use File::Which qw(which);
use File::Temp qw(tempdir);

use Readonly;

BEGIN { use_ok("App::ClusterSSH::Config")  || BAIL_OUT('failed to use module')}

my $config;

$config = App::ClusterSSH::Config->new();
isa_ok( $config, 'App::ClusterSSH::Config' );

Readonly::Hash my %default_config => {
    terminal                   => "xterm",
    terminal_args              => "",
    terminal_title_opt         => "-T",
    terminal_colorize          => 1,
    terminal_bg_style          => 'dark',
    terminal_allow_send_events => "-xrm '*.VT100.allowSendEvents:true'",
    terminal_font              => "6x13",
    terminal_size              => "80x24",

    use_hotkeys             => "yes",
    key_quit                => "Control-q",
    key_addhost             => "Control-Shift-plus",
    key_clientname          => "Alt-n",
    key_history             => "Alt-h",
    key_retilehosts         => "Alt-r",
    key_paste               => "Control-v",
    mouse_paste             => "Button-2",
    auto_quit               => "yes",
    window_tiling           => "yes",
    window_tiling_direction => "right",
    console_position        => "",

    screen_reserve_top    => 0,
    screen_reserve_bottom => 60,
    screen_reserve_left   => 0,
    screen_reserve_right  => 0,

    terminal_reserve_top    => 5,
    terminal_reserve_bottom => 0,
    terminal_reserve_left   => 5,
    terminal_reserve_right  => 0,

    terminal_decoration_height => 10,
    terminal_decoration_width  => 8,

    rsh_args    => "",
    telnet_args => "",
    ssh_args    => "",

    extra_cluster_file => "",

    unmap_on_redraw => "no",

    show_history   => 0,
    history_width  => 40,
    history_height => 10,

    command             => q{},
    max_host_menu_items => 30,

    max_addhost_menu_cluster_items => 6,
    menu_send_autotearoff          => 0,
    menu_host_autotearoff          => 0,

    send_menu_xml_file => $ENV{HOME} . '/.csshrc_send_menu',

    # other bits inheritted from App::ClusterSSH::Base
    debug => 0,
    lang  => 'en',

};
my %expected = %default_config;
is_deeply( $config, \%expected, 'default config is correct' );

$config = App::ClusterSSH::Config->new();
trap {
    $config = $config->validate_args(
        whoops       => 'not there',
        doesnt_exist => 'whoops',
    );
};
isa_ok( $trap->die, 'App::ClusterSSH::Exception::Config' );
is( $trap->die,
    'Unknown configuration parameters: doesnt_exist,whoops',
    'got correct error message'
);
is_deeply(
    $trap->die->unknown_config,
    [ 'doesnt_exist', 'whoops' ],
    'Picked up unknown config array'
);
isa_ok( $config, "App::ClusterSSH::Config" );

$expected{extra_cluster_file}             = '/etc/filename';
$expected{rsh_args}                       = 'some args';
$expected{max_addhost_menu_cluster_items} = 120;
trap {
    $config = $config->validate_args(
        extra_cluster_file             => '/etc/filename',
        rsh_args                       => 'some args',
        max_addhost_menu_cluster_items => 120,
    );
};
is( $trap->die, undef, 'validated ok' );
isa_ok( $config, "App::ClusterSSH::Config" );
is_deeply( $config, \%expected, 'default config is correct' );

$config   = App::ClusterSSH::Config->new();
%expected = %default_config;

my $file = "$Bin/$Script.doesntexist";
trap {
    $config = $config->parse_config_file( $file, );
};
isa_ok( $trap->die, 'App::ClusterSSH::Exception::Config' );
is( $trap->die,
    "File $file does not exist or cannot be read",
    'got correct error message'
);

$file = "$Bin/$Script.file1";
note("using $file");
$config                          = App::ClusterSSH::Config->new();
%expected                        = %default_config;
$expected{screen_reserve_left}   = 100;
$expected{screen_reserve_right}  = 100;
$expected{screen_reserve_top}    = 100;
$expected{screen_reserve_bottom} = 160;
trap {
    $config = $config->parse_config_file( $file, );
};
is( $trap->leaveby, 'return', 'returned ok' );
is( $trap->die,     undef,    'returned ok' );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, q{}, 'Expecting no STDERR' );
is_deeply( $config, \%expected, 'amended config is correct' );

$file = "$Bin/$Script.file2";
note("using $file");
$config   = App::ClusterSSH::Config->new();
%expected = %default_config;
trap {
    $config = $config->parse_config_file( $file, );
};
is( $trap->leaveby, 'die', 'died ok' );
isa_ok( $trap->die, 'App::ClusterSSH::Exception::Config' );
is( $trap->die,
    'Unknown configuration parameters: missing,rubbish',
    'die message correct'
);
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, q{}, 'Expecting no STDERR' );
is_deeply( $config, \%expected, 'amended config is correct' );

$file = "$Bin/$Script.file3";
note("using $file");
$config   = App::ClusterSSH::Config->new();
%expected = %default_config;
trap {
    $config = $config->parse_config_file( $file, );
};

is( $trap->leaveby, 'return', 'returned ok' );
is( $trap->die,     undef,    'returned ok' );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
{
    local $TODO = "deal with cluster definitions in config file";
    is( $trap->stderr, q{}, 'Expecting no STDERR' );
}

note('find_binary tests');
my $path;
$config = App::ClusterSSH::Config->new();
trap {
    $path = $config->find_binary();
};
is( $trap->leaveby, 'die', 'died ok' );
isa_ok( $trap->die, 'App::ClusterSSH::Exception::Config' );
isa_ok( $config,    "App::ClusterSSH::Config" );
is( $trap->die, 'argument not provided', 'die message correct' );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, q{}, 'Expecting no STDERR' );
is_deeply( $config, \%expected, 'amended config is correct' );

trap {
    $path = $config->find_binary('missing');
};
is( $trap->leaveby, 'die', 'died ok' );
isa_ok( $trap->die, 'App::ClusterSSH::Exception::Config' );
isa_ok( $config,    "App::ClusterSSH::Config" );
is( $trap->die, '"missing" binary not found - please amend $PATH or the cssh config file', 'die message correct' );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, q{}, 'Expecting no STDERR' );
is_deeply( $config, \%expected, 'amended config is correct' );

trap {
    $path = $config->find_binary('ls');
};
is( $trap->leaveby, 'return', 'returned ok' );
isa_ok( $config,    "App::ClusterSSH::Config" );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, q{}, 'Expecting no STDERR' );
is_deeply( $config, \%expected, 'amended config is correct' );
is($path, which('ls'), 'Found correct path to "ls"');

note('Checks on loading configs');
note('empty dir');
$ENV{HOME} = tempdir( CLEANUP => 1 );
$config = App::ClusterSSH::Config->new();
trap {
    $config->load_configs();
};
is( $trap->leaveby, 'return', 'returned ok' );
isa_ok( $config,    "App::ClusterSSH::Config" );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->die, undef, 'die message correct' );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, q{}, 'Expecting no STDERR' );
#note(qx/ls -laR $ENV{HOME}/);
ok( -d $ENV{HOME}.'/.clusterssh', '.clusterssh dir exists');
ok( -f $ENV{HOME}.'/.clusterssh/config', '.clusterssh config file exists');
is_deeply( $config, \%expected, 'amended config is correct' );
$ENV{HOME} = undef;

note('.csshrc warning');
$ENV{HOME} = tempdir( CLEANUP => 1 );
open(my $csshrc, '>', $ENV{HOME}.'/.csshrc');
print $csshrc 'auto_quit = no', $/;
close($csshrc);
$expected{auto_quit}='no';
$config = App::ClusterSSH::Config->new();
trap {
    $config->load_configs();
};
is( $trap->leaveby, 'return', 'returned ok' );
isa_ok( $config,    "App::ClusterSSH::Config" );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->die, undef, 'die message correct' );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, 'NOTICE: '.$ENV{HOME}.'/.csshrc is no longer used - please see documentation and remove'.$/, 'Got correct STDERR output for .csshrc' );
ok( -d $ENV{HOME}.'/.clusterssh', '.clusterssh dir exists');
ok( -f $ENV{HOME}.'/.clusterssh/config', '.clusterssh config file exists');
is_deeply( $config, \%expected, 'amended config is correct' );

note('.csshrc warning and .clusterssh dir plus config');
open($csshrc, '>', $ENV{HOME}.'/.clusterssh/config');
print $csshrc 'window_tiling = no', $/;
close($csshrc);
$expected{window_tiling}='no';
$config = App::ClusterSSH::Config->new();
trap {
    $config->load_configs();
};
is( $trap->leaveby, 'return', 'returned ok' );
isa_ok( $config,    "App::ClusterSSH::Config" );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->die, undef, 'die message correct' );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, 'NOTICE: '.$ENV{HOME}.'/.csshrc is no longer used - please see documentation and remove'.$/, 'Got correct STDERR output for .csshrc' );
ok( -d $ENV{HOME}.'/.clusterssh', '.clusterssh dir exists');
ok( -f $ENV{HOME}.'/.clusterssh/config', '.clusterssh config file exists');
is_deeply( $config, \%expected, 'amended config is correct' );

note('no .csshrc warning and .clusterssh dir');
unlink($ENV{HOME}.'/.csshrc');
$expected{auto_quit}='yes';
$config = App::ClusterSSH::Config->new();
trap {
    $config->load_configs();
};
is( $trap->leaveby, 'return', 'returned ok' );
isa_ok( $config,    "App::ClusterSSH::Config" );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->die, undef, 'die message correct' );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, '', 'Expecting no STDERR' );
ok( -d $ENV{HOME}.'/.clusterssh', '.clusterssh dir exists');
ok( -f $ENV{HOME}.'/.clusterssh/config', '.clusterssh config file exists');
is_deeply( $config, \%expected, 'amended config is correct' );

note('no .csshrc warning, .clusterssh dir plus config + extra config');
open($csshrc, '>', $ENV{HOME}.'/clusterssh.config');
print $csshrc 'terminal = something', $/;
close($csshrc);
$expected{terminal}='something';
$config = App::ClusterSSH::Config->new();
trap {
    $config->load_configs($ENV{HOME}.'/clusterssh.config');
};
is( $trap->leaveby, 'return', 'returned ok' );
isa_ok( $config,    "App::ClusterSSH::Config" );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->die, undef, 'die message correct' );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, '', 'Expecting no STDERR' );
ok( -d $ENV{HOME}.'/.clusterssh', '.clusterssh dir exists');
ok( -f $ENV{HOME}.'/.clusterssh/config', '.clusterssh config file exists');
is_deeply( $config, \%expected, 'amended config is correct' );

note('no .csshrc warning, .clusterssh dir plus config + more extra configs');
open($csshrc, '>', $ENV{HOME}.'/.clusterssh/config_ABC');
print $csshrc 'ssh_args = something', $/;
close($csshrc);
$expected{ssh_args}='something';
$config = App::ClusterSSH::Config->new();
trap {
    $config->load_configs($ENV{HOME}.'/clusterssh.config', 'ABC');
};
is( $trap->leaveby, 'return', 'returned ok' );
isa_ok( $config,    "App::ClusterSSH::Config" );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->die, undef, 'die message correct' );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, '', 'Expecting no STDERR' );
ok( -d $ENV{HOME}.'/.clusterssh', '.clusterssh dir exists');
ok( -f $ENV{HOME}.'/.clusterssh/config', '.clusterssh config file exists');
is_deeply( $config, \%expected, 'amended config is correct' );

note('check .clusterssh file is an error');
$ENV{HOME} = tempdir( CLEANUP => 1 );
open($csshrc, '>', $ENV{HOME}.'/.clusterssh');
print $csshrc 'should_be_dir_not_file = PROBLEM', $/;
close($csshrc);
$config = App::ClusterSSH::Config->new();
trap {
    $config->write_user_config_file();
};
is( $trap->leaveby, 'die', 'died ok' );
isa_ok( $trap->die, 'App::ClusterSSH::Exception::Config' );
isa_ok( $config,    "App::ClusterSSH::Config" );
is( $trap->die, 'Unable to create directory $HOME/.clusterssh: File exists', 'die message correct' );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, q{}, 'Expecting no STDERR' );

note('check failure to write default config is caught');
$ENV{HOME} = tempdir( CLEANUP => 1 );
mkdir($ENV{HOME}.'/.clusterssh');
mkdir($ENV{HOME}.'/.clusterssh/config');
$config = App::ClusterSSH::Config->new();
trap {
    $config->write_user_config_file();
};
is( $trap->leaveby, 'die', 'died ok' );
isa_ok( $trap->die, 'App::ClusterSSH::Exception::Config' );
isa_ok( $config,    "App::ClusterSSH::Config" );
is( $trap->die, 'Unable to write default $HOME/.clusterssh/config: Is a directory', 'die message correct' );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, q{}, 'Expecting no STDERR' );

note('check .clusterssh errors via load_configs are not fatal');
$ENV{HOME} = tempdir( CLEANUP => 1 );
open($csshrc, '>', $ENV{HOME}.'/.clusterssh');
print $csshrc 'should_be_dir_not_file = PROBLEM', $/;
close($csshrc);
$config = App::ClusterSSH::Config->new();
trap {
    $config->load_configs();
};
is( $trap->leaveby, 'return', 'died ok' );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, q{Unable to create directory $HOME/.clusterssh: File exists}.$/, 'Expecting no STDERR' );

note('check failure to write default config is caught');
$ENV{HOME} = tempdir( CLEANUP => 1 );
mkdir($ENV{HOME}.'/.clusterssh');
mkdir($ENV{HOME}.'/.clusterssh/config');
$config = App::ClusterSSH::Config->new();
trap {
    $config->load_configs();
};
is( $trap->leaveby, 'return', 'returned ok' );
isa_ok( $config,    "App::ClusterSSH::Config" );
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->stdout, q{}, 'Expecting no STDOUT' );
is( $trap->stderr, q{Unable to write default $HOME/.clusterssh/config: Is a directory}.$/, 'Expecting no STDERR' );

note('Checking dump');
$config = App::ClusterSSH::Config->new();trap {
    $config->dump();
};
my $expected=<<'EOF';
# Configuration dump produced by "cssh -u"
terminal_reserve_top=5
terminal_bg_style=dark
window_tiling_direction=right
screen_reserve_left=0
window_tiling=yes
key_addhost=Control-Shift-plus
max_addhost_menu_cluster_items=6
key_clientname=Alt-n
terminal_allow_send_events=-xrm '*.VT100.allowSendEvents:true'
debug=0
menu_host_autotearoff=0
console_position=
lang=en
terminal_colorize=1
unmap_on_redraw=no
terminal_reserve_left=5
screen_reserve_right=0
key_retilehosts=Alt-r
rsh_args=
history_height=10
key_quit=Control-q
screen_reserve_top=0
send_menu_xml_file=/home/dferguson/.csshrc_send_menu
use_hotkeys=yes
terminal_decoration_height=10
menu_send_autotearoff=0
terminal_args=
terminal_decoration_width=8
auto_quit=yes
terminal=xterm
command=
telnet_args=
mouse_paste=Button-2
key_history=Alt-h
terminal_reserve_right=0
show_history=0
terminal_font=6x13
terminal_reserve_bottom=0
history_width=40
extra_cluster_file=
ssh_args=
terminal_title_opt=-T
screen_reserve_bottom=60
max_host_menu_items=30
key_paste=Control-v
terminal_size=80x24
EOF
isa_ok( $config, "App::ClusterSSH::Config" );
is( $trap->die, undef, 'die message correct' );
is( $trap->stdout, $expected, 'Expecting no STDOUT' );
is( $trap->stderr, q{}, 'Expecting no STDERR' );

done_testing();
