package endlesstower;

use Globals;
use Plugins;
use Data::Dumper;
use Log qw(message);
use Misc qw(whenGroundStatus getSpellName);
use Utils;

Plugins::register('endlesstower', '', \&on_unload, \&on_reload);

my $hooks = Plugins::addHooks(
    ['AI_pre', \&on_ai],
    ['AI_pre/manual', \&on_ai]
);
my $delay = 2;
my $range = 9;

sub on_unload {
    Plugins::delHooks($hooks);
}
sub on_reload {
    message "endlesstower plugin reloading\n";
    Plugins::delHooks($hooks);
}
sub on_ai {
    return if (!main::timeOut($time, $delay));
    if(!AI::inQueue("move", "route")
       && AI::action ne "move"
       && AI::action ne "route") {
       # All classes: Ask for SP (use Bus)
       # Bard: Check and set ground condition, keep on "Magic Strings"
       # Priest: Keep on Ressurrecting, Status Recovery and Cure
       # Sage: Recover SP (use bus)
       # Soul Linker: Eske specific MVPs
        if(exists($flags{"keep"})) {}
    }
    else {
        # @TODO: When moving, cancel AI and all tasks (but move, obviously)
    }
    $time = time;
}
return 1;
