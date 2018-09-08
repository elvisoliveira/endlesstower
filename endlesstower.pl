package endlesstower;

use Globals;
use Plugins;
use Data::Dumper;
use Log qw(message);
use Misc qw(whenGroundStatus getSpellName);
use Utils;
use Skill;
use Task::UseSkill;

Plugins::register('endlesstower', '', \&on_unload, \&on_reload);

my $hooks = Plugins::addHooks(
    ['AI_pre', \&on_ai],
    ['AI_pre/manual', \&on_ai]
);
my $delay = 2;

sub on_unload {
    Plugins::delHooks($hooks);
}
sub on_reload {
    message "endlesstower plugin reloading\n";
    Plugins::delHooks($hooks);
}
sub on_ai {
    return if (!main::timeOut($time, $delay));
    return if($char->{dead});
    if(!AI::inQueue("move", "route")
       && AI::action ne "move"
       && AI::action ne "route") {
        # Check and set ground condition, keep on "Magic Strings"
        if($char->{jobID} eq 19 ||
           $char->{jobID} eq 4020) {
            # 19 Bard
            # 4020 Menestrel
            my $play = 1;
            my $skill = new Skill(auto => "BA_POEMBRAGI", level => "10");
            foreach (@spellsID) {
                my $spell = $spells{$_};
                $play = 0 if(getSpellName($spell->{type}) eq "Poem of Bragi"
                             && $char->{pos}{x} eq $spell->{pos}{x}
                             && $char->{pos}{y} eq $spell->{pos}{y});
            }
            $taskManager->add(Task::UseSkill->new(
                skill => $skill,
                actor => $skill->getOwner,
                target => $char,
                priority => Task::HIGH_PRIORITY
            )) if($play);
        }
        # Keep on Ressurrecting, Status Recovery and Cure
        if($char->{jobID} eq 8 ||
           $char->{jobID} eq 4009) {
            # 8 Priest
            # 4009 High Priest
            foreach (@playersID) {
                my $player = $players{$_};
                my $skill = new Skill(auto => "ALL_RESURRECTION", level => "4");
                $taskManager->add(Task::UseSkill->new(
                    skill => $skill,
                    actor => $skill->getOwner,
                    target => $player,
                    priority => Task::HIGH_PRIORITY,
                    actorList => $playersList
                )) if($player->{dead});
            }
            my $onBragi = 0;
            foreach (@spellsID) {
                my $spell = $spells{$_};
                $onBragi = 1 if(getSpellName($spell->{type}) eq "Poem of Bragi"
                                && $char->{pos_to}{x} eq $spell->{pos}{x}
                                && $char->{pos_to}{y} eq $spell->{pos}{y});
            }
            my $isActive = ($char->{statuses}{"EFST_POEMBRAGI"}) ? 1 : 0
            $char->setStatus("EFST_POEMBRAGI", $onBragi) if(($isActive eq 1 && $onBragi eq 0) ||
                                                            ($isActive eq 0 && $onBragi eq 1));
        }
        # Eske specific MVPs
        if($char->{jobID} eq 4049) {
            # 4049: Soul Linker
            @mobs = (1832, 1873, 1100);
            foreach (@monstersID) {
                my $monster = $monsters{$_};
                if(grep {$_ eq $monster->{type}} @mobs) {
                    my $skill = new Skill(auto => "SL_SKE", level => "3");
                    $taskManager->add(Task::UseSkill->new(
                        skill => $skill,
                        actor => $skill->getOwner,
                        target => $monster,
                        priority => Task::HIGH_PRIORITY,
                        actorList => $monstersList
                    ));
                }
            }
        }
    }
    else {
        # @TODO: When moving, cancel AI and all tasks (but move, obviously)
    }
    $time = time;
}
# debugger($monster->statusesString);
# eval use Data::Dumper; message Dumper($char->{statuses});
sub debugger {
    my $datetime = localtime time;
    message Dumper($_[0]);
    # message "[MCA] $datetime: $_[0].\n";
}
return 1;
