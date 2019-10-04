# M3wP Yahtzee!

## Introduction
Hello and welcome to the **M3wP Yahtzee!** read me!

I have developed a multi-platform client/server version of the Hasbro game Yahtzee!  It is currently in development and quite crude but should be playable on PC, Android, iOS and Mac.  The client will eventually even be available for the humble Commodore 64 and compatibles (because I love that platform).   

At this point in time, I am only going to be providing binaries for PC and Android because I don't have the required development tools for iOS and Mac and the C64 version is rather unfinished.

## Download and Installation
The Windows x86 (32 bit) binaries are available in the bin/Win32 folder as compressed files.  You will need to decompress them before you can run them.

The Android client binary (I have not compiled or tested the server on this platform) is available in the bin/Android folder.  It is currently compiled only for debugging and you will need to manually install it using adb.

The Commodore64 binaries are available in the bin/C64 folder.  It is only available as a test right now and the game is not yet playable on this platform.

## Compiling
The PC, Android, iOS and Mac versions require Delphi FMX.  I am using Delphi XE8 at the present time.  You should find all you need in the _src_ folder.

The C64 version is a bit more complicated.  You need the cc65 toolchain, the ip65 library and some makefiles.  I will document this further and provide more detail when the client matures a little more.

## Playing the Game
You will need to have a server running somewhere.  Then, get your friends together and each of you fire up an instance of the client.

You will need to supply the Host address or name and a unique User Name (which should be no more than 8 characters long, with no spaces and only ASCII characters).  Clicking "Connect" will connect your client to the server.  If you have connection difficulties, it is most likely that your User Name is incorrect or already in use.  Try changing it and clicking the "Update" button.

Once connected, you will be in the Lobby.  You can create Chat "Rooms" from where you can talk to the other connected users from the Chat tab.  Try using the "List" button to show the currently available Rooms.  Type in the name of a Room to join and click "Join" to enter that room.  Use the navigation buttons to change between the Room conversation and control tabs.  Click the "Members" button to show the users presently in the same Room.  Clicking the "Part" button makes you leave the Room.

When you are ready, go to the Play tab where you can create and list Games much as you do with Rooms.  Join a Game like you do with a Room and navigate to the Overview tab with the navigation buttons.

You will need to inform the rest of the Players that you are Ready to play by clicking the Ready button.  If you are waiting for other Players, don't click it yet.  When everyone is Ready, you must Roll For First by clicking the button (which has now changed).  New Players cannot join the game at this point.  The Player with the highest roll will go first and the icons will show that they have the dice and that the other Players are now waiting.

Clicking on a Player will show that Player's Score Card.  If that Player is the one with the dice, you can click the "Follow Active" check box to always show the player with the dice.  This is recommended if you want to follow the game play.  Alternatively, use the navigation buttons to show the desired information.

If it is your turn, you must now click on the "Roll" button to roll the dice.  Click on each Die to mark it as a "Keeper" or not.  Keepers are shown below the ones that will be re-rolled if the Roll button is clicked again.  You can Roll Dice up to 3 times.

Once you are finished you must place a score on your Score Card.  Clicking a Score Cell on the Score Card will show you what score you will get for that position.  Chose wisely!  When you are satisfied with your selection, click the "Score" button and the Dice will be passed to the next Player.

Play continues in this fashion until each player has filled their Score Card for a total of 13 rounds.  The Winner is the Player with the highest Score.

When you are finished playing, click the "Part" button to leave the game.  You are ready to start again!

**Note:**  The C64 client usage will be a little different to this but you should get the idea.

## Future Development
There are many planned features for the game and the apps (both client and server) will be enhanced to be prettier and show more information.  The project is currently in an Alpha state but should be playable for the most part.

## Contact
Please feel free to contact me for further information.  You can reach me at:
	
	mewpokemon {at} hotmail {dot} com

Please include the string "M3wPYahtzee!" in the subject line or your mail might get lost.