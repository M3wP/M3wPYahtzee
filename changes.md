# M3wP Yahtzee! Change Log

## CLI Server

* 06NOV2019
	* Fix issue releasing a Connection via DisconnectByIdent

* 03NOV2019
	* Plug potential holes in logic updating a player user name, creating a new room and creating a new game

* 01NOV2019
	* Reinstate software challenges to client to keep alive
	* Revert changes for checking connection and keep-alives - wasn't working according to documents I had read

* 30OCT2019
	* Implement hash bucket workers instead of creating a thread for each connection
	* Check for disconnects according to standards (will also not accept OOB data!)
	* Implement connection "keep-alives" according to standards (Windows, need Linux)
	* Store the connection "ticket" on the player, too
	* Use connection "ticket" for output instead of ident (easier to read)
	* Generate a "ticket" for each connection, based on its "ident" (prepare for client "re-auths")

* 29OCT2019
	* Yahtzee Bonuses only apply when you haven't got a Yahtzee score of 0 and you can only have three of them!

* 28OCT2019
	* Incorporate new TCPServer into code
	* Implement my own TCPServer to handle multiple connections based on Ararat Synapse
	* REMOVE INDY10!  I'm over it.  Too many problems.

* 25OCT2019
	* Work around Indy sometimes not firing OnDisconnect when a connection is "abandonded"
	* Implement ExiprePlayers functionality to ensure release of memory despite behaviour of Connection disconnect - affects all servers
	* Fix bug in PlayersKeepAliveExpire to call correct Remove (of Self) - affects all servers

* 23OCT2019
	* Make CPU usage nicer?

* 22OCT2019
	* Also use the server challenges

* 21OCT2019
	* Fix a number of memory leaks (affects the FMX server, too)


## LCL Client

### Version 0.00.80A

* 01NOV2019
	* Implement LCL client for native Linux solution and testing comparisson


## FMX Server

### Version 0.00.78A

* 29OCT2019
	* Yahtzee Bonuses only apply when you haven't got a Yahtzee score of 0 and you can only have three of them!
	
* 25OCT2019
	* Work around Indy sometimes not firing OnDisconnect when a connection is "abandonded"

* 22OCT2019
	* Fix some FIXMEs (affects all servers)
	* Implement server challenge message when client idle

* 17OCT2019
	* Handle when the currently playing player leaves the game

* 16OCT2019
	* Change Play|Join message to be all text, not mixed text and binary
	* Fix exception when closing if a player is in a game/room
	* Change list message response to Play|List to be all text, not mixed text and binary


## FMX Client

### Version 0.00.78A

* 22OCT2019
	* Implement client keep-alive message in response to server challenge message

* 16OCT2019
	* Change Play|Join message to be all text, not mixed text and binary
	* Change list message handling of Play|List response to expect all text, not mixed text and binary


## C64 Client

### Version 0.00.35A

* 02NOV2019
	* Allow the user to update their user name (still not updating back from server)
	* Don't change the active control when parting a room if in less mode
	* Don't part the room unless we were the one parting
	* Change "their" to "this" score on Detail Page.
	* Clear "their" score when showing your details.
	* Make sure the selection can be properly cleared in the Score Sheet Panel when selecting aces
	* Change ip65 such that it no longer spin waits for no reason on tcp_close
	* Should now be able to try to connect when a connection attempt fails?
	* Flash notify and (when appropriate) disconnect if fail to get new internet send message
	* Provide failure feedback when attempting to get a new internet send message
	* Implement flash notification functionality
	* Use send data metrics to produce a connection health meter
	* Change ip65 to export send data metrics

* 30OCT2019
	* Fixes to ip65 for reading while sending causing disconnects (require modified ip65)
	* Fixes to ip65 for timeouts when sending (require modified ip65)
	* Update to latest ip65 version
	* Work-around inet message send queue overflow

* 26OCT2019
	* Default host name to "PLAY-CLASSICS.NET"!
	* Implement Lobby|Peer message receive
	* Panels must be enabled and visible when finding an element key accelerator
	* Implement Lobby|Join and Lobby|Part functionality (UI and messages)
	* Implement y offset in log panel control
	* (Hopefully) fix default active control assignment in prepare procedure
	* Always prepare all controls on a page (regardless of panel visibility)

* 25OCT2019
	* Actually allocate a byte for the score sheet's "hveprvw" field
	* Try to update the score sheet's selection indicator more accurately
	* Don't update the dice when Play|KeeperPeer message unless viewing the slot's details
	* Refactor clientProcPlayStatGameMsg and clientUpdateSlotState
	* Update game round on Play|Overview page as game plays
	* Update "our" and "their" scores on Play|Detail page as game plays
	* Handle Play|ScoreQuery message send and receive
	* Implement score query display (still need yahtzee/lower bonus display)

### Version 0.00.33A

* 25OCT2019
	* Now show roll number on Play|Detail page roll button
	* Activate Play|Detail roll button when current player gets play status
	* Update Play|Detail player label correctly
	* Output error string for Play|Error messages
	* Play|StatusPeer message handling should be more "reliable" now

* 24OCT2019
	* Fix label accelerators not activate/down "attached" controls

* 20OCT2019
	* Bug fixes for displaying scores on the Play|Detail page
	* Handle send Play|ScorePeer message
	* Handle receive Play|ScorePeer message
	* Display scores from selected detail slot on score sheet control (need yahtzee bonus handling)
	* Further work on Play|Detail page updating
	* Implement Play|KeepersPeer message send and receive
	* Implement Play|Roll message send and receive
	* Update the Play|Detail page when switched to and when receive the Play|StatPeer messages

### Version 0.00.23A

* 20OCT2019
	* Implement OPT_AUTOCHECK functionality for checkbox controls
	* Implement mouse navigation on score sheet control
	* Implement mouse capture functionality
	* Implement score sheet control key press handling to navigate scores

* 19OCT2019
	* Change unused OPT_NOPRESENT to OPT_NOAUTOINVL and don't auto invalidate control when used
	* Dirty implementation of changing the keeper state on the dice
	* Implement (most of) the score sheet control display (still need selection logic)
	* Implement die control
	* Temporarily connect Play|Detail page to Play|Overview page as next page

* 18OCT2019
	* Load the page's tag into a variable when PageSelect
	* Layout for Play|Details page
	* Further Play|StateGame handling
	* Fix UI and inet collision with zp tempdat2

* 17OCT2019
	* Begin Play|Roll message handling
	* Play|Overview|ButtonCntrl interface logic
	* More Play|StateGame message handling
	* Handle Play|StatePeer message

* 16OCT2019
	* Play|Part message handling
	* Begin handling of Play|StateGame message
	* Text|Data message handling for Play|List response
	* Clear last text message ident when get Text|More message with 0 more (done)
	* Fix Text|Data message type identification bug
	* Play|Overview interface init

* 14OCT2019
	* Play|Join message handling

* 13OCT2019
	* Add definitions for game state
	* Only set STATE_DIRTY and generate invalid messages (to present) for elements that are STATE_PREPARED
	* Set/unset STATE_PREPARED on elements when page shown/hidden
	* Stub out control element prepare override functionality (saving just over 100 bytes)
	* Add Game Join functionality in user interface

* 11OCT2019
	* Fix key accelerators working for invisible/inactive controls
	* Make active controls also blink when picked
	* Make CLR_FOCUS controls blink CLR_FACE when picked
	* Add Back and Next buttons for pages
	* Add Play|Overview page and controls
	* Add Play|Game page and controls
	