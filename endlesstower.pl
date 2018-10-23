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
    ['AI_pre/manual', \&on_ai],
    ['Network::stateChanged',\&stateChanged]
);
my $delay = .5;
my $bus_message_received;

if ($::net) {
    if ($::net->getState() > 1) {
        $bus_message_received = $bus->onMessageReceived->add(undef, \&bus_message_received);
        Plugins::delHook($networkHook);
        undef $networkHook;
    }
}

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
                # debugger($player->{jobID});
                my $skill = new Skill(auto => "ALL_RESURRECTION", level => "4");
                $taskManager->add(Task::UseSkill->new(
                    skill => $skill,
                    actor => $skill->getOwner,
                    target => $player,
                    priority => Task::HIGH_PRIORITY,
                    actorList => $playersList
                )) if($player->{dead});
            }
            # foreach (@monstersID) {
            #     my $monster = $monsters{$_};
            #     # debugger($monster);
            # }
            my $onBragi = 0;
            foreach (@spellsID) {
                my $spell = $spells{$_};
                $onBragi = 1 if(getSpellName($spell->{type}) eq "Magic Strings"
                                && $char->{pos_to}{x} eq $spell->{pos}{x}
                                && $char->{pos_to}{y} eq $spell->{pos}{y});
            }
            my $isActive = ($char->{statuses}{"EFST_POEMBRAGI"}) ? 1 : 0;
            $char->setStatus("EFST_POEMBRAGI", $onBragi) if(($isActive eq 1 && $onBragi eq 0) ||
                                                            ($isActive eq 0 && $onBragi eq 1));
        }
        # Eske specific MVPs
        if($char->{jobID} eq 4049) {
            # 4049: Soul Linker
            @mobs = (1832, 1873, 1874,1751, 1957, 1931, 1956);
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
        # SP Controller
        if($char->{jobID} ne 4017) {
            return if (!main::timeOut($time, 1)); # 1 seconds delay
            my $ssp = int($char->{'sp'} / $char->{'sp_max'} * 100);
            $bus->send('endlesstower', $char->{accountID}) if($ssp < 10);
        }
    }
    else {
        # @TODO: When moving, cancel AI and all tasks (but move, obviously)
    }
    $time = time;
}
sub bus_message_received {
    my (undef, undef, $msg) = @_;
    if ($msg->{messageID} eq 'endlesstower' && $char) {
        my $ssp = int($char->{'sp'} / $char->{'sp_max'} * 100);
        my $giveSP = Actor::get($msg->{args});
        if($giveSP
           && $ssp > 99
           && $char->{jobID} eq 4017
           && distance(calcPosition($char), calcPosition($giveSP)) <= 5) {
            my $skill = new Skill(auto => PF_SOULCHANGE, level => 1);
            my $identify = $giveSP->{nameID} . $skill->{idn};
            unless ($taskManager->countTasksByName($identify)) {
                $taskManager->add(Task::UseSkill->new(
                    name => $identify,
                    skill => $skill,
                    actor => $skill->getOwner,
                    target => $giveSP,
                    actorList => $playersList,
                    priority => Task::HIGH_PRIORITY
                ));
            }
        }
    }
}
sub stateChanged {
    return if ($::net->getState() == 1);
    if (!$bus) {
        my @message = (
            "You MUST start BUS server and configure each bot to use it in order to use this plugin.",
            "Open and edit line bus 0 to bus 1 inside control/sys.txt"
        );
        die("\n$message[0] $message[1]\n", 3, 0);
    }
    if (!$bus_message_received) {
        $bus_message_received = $bus->onMessageReceived->add(undef, \&bus_message_received);
        Plugins::delHook('Network::stateChanged', $hooks);
    }
}
# debugger($monster->statusesString);
# eval use Data::Dumper; message Dumper($char->{statuses});
sub debugger {
    my $datetime = localtime time;
    message Dumper($_[0]);
    # message "[MCA] $datetime: $_[0].\n";
}
return 1;
