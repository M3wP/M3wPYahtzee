# M3wP Yahtzee! Change Log

## FMX Server

### Version 0.00.78A

*17OCT2019
	* Handle when the currently playing player leaves the game

*16OCT2019
	* Change Play|Join message to be all text, not mixed text and binary
	* Fix exception when closing if a player is in a game/room
	* Change list message response to Play|List to be all text, not mixed text and binary


## FMX Client

### Version 0.00.78A

*16OCT2019
	* Change Play|Join message to be all text, not mixed text and binary
	* Change list message handling of Play|List response to expect all text, not mixed text and binary


## C64 Client

### Version 0.00.23A

*18OCT2019	
	* Further Play|StateGame handling
	* Fix UI and inet collision with zp tempdat2

*17OCT2019
	* Begin Play|Roll message handling
	* Play|Overview|ButtonCntrl interface logic
	* More Play|StateGame message handling
	* Handle Play|StatePeer message

*16OCT2019
	* Play|Part message handling
	* Begin handling of Play|StateGame message
	* Text|Data message handling for Play|List response
	* Clear last text message ident when get Text|More message with 0 more (done)
	* Fix Text|Data message type identification bug
	* Play|Overview interface init

*14OCT2019
	* Play|Join message handling

*13OCT2019
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
	