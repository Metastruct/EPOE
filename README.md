EPOE
=======================

[![Build Status](https://travis-ci.org/Metastruct/EPOE.svg?branch=master)](https://travis-ci.org/Metastruct/EPOE)


(Enhanced Perception Of Errors) is a debugging console for Garry's Mod servers. It taps into the Lua print and error system of gmod to relay messages to admins. 
Think of it as server side console on client although technically it isn't one.

Uses:

 - Track lua errors
 - Monitor server activity through debug messages
 - See debug printing from addons
 - Run lua on server and see results
 - See players joins, leaves if you add custom printing for them.


***Screenshots***

![](http://i.imgur.com/k1rhz3b.png)

![](http://i.imgur.com/SyuCR5i.png)

***Installation***

 - Download/clone EPOE to an addon folder
 - copy the dlls inside ```epoe/lua/bin``` to ```garrysmod/lua/bin``` 
(since they can't be loaded from addons folders)

 Now you should have folder similar to ``` garrysmod/addons/epoe/lua/ ``` and file ``` garrysmod/lua/bin/gmsv_...dll ```

***Usage***

 * Bind key: ```bind x +epoe```
 * Hold the key, click ```login``` (and optionally tick ```autologin```) or EPOE won't do anything.
 * When you hold the key you can resize/move/change settings on the EPOE UI.

Tips:

 - double tap the bind to prevent EPOE from hiding
 - All epoe console commands start with epoe_, feel free to explore them


***Enginespew Source***: svn://svn.metastruct.net/gbins/enginespew

***Other features***

 - parses links from the output and makes them clickable. You could for example print a person's steam profile url when they spawn and click to see a questionable profile for example.
 - Flood protection
 - Can be hidden from screenshots
 - Obeys HUDPaint
 - Translates parameters to more useful format. For example print({"asd","dsa"}) with print the content of the table. Colors, vectors and so forth are also supported.
 - Lightweight on bandwidth: uses one byte overhead for any message, doesn't flood clients and doesn't transfer duplicate spam.
 - Login/logout from the stream and autologin with support for delayed admin rights (SQL Based Administration for example)


**Latest changes**

 - Moved to net messages.
 - Bugfixed MsgC

***Warning***

EPOE ships with [Enginespew](http://www.facepunch.com/threads/859870), which is a module that shouldn't crash, but MAY crash.
I haven't managed to replicate **even a single crash** on our servers or my testing server from the few that I have been reported though. EPOE will work *in limited mode without the module* though.

EPOE itself is written to crash as gracefully as possible in the case of a such event, circular crash is almost guaranteed to not happen. 
EPOE also can't flood admins out with spam as the speed is limited and in the case of excessive spam from server console epoe shuts down for a brief period and clears the sending stack from messages.

***TLDR:*** EPOE won't harm your server or clients or hinder performance except in very special cases. It's supposed to help you hunt down bugs, not create them.


***More?***

EPOE comes with hook "EPOE". This hook is called every time a message is relayed. 

The hook is used by the UI and the console printing to tap into the epoe stream. You can do the same and for example create logging module for epoe.

EPOE supports explicit clientside printing of data too, so you can use it on clientside too, just prefix your prints with epoe.Print for example. epoe.Msg,MsgC,Err,AddText are also supported.
Example:
```epoe.AddText(Color(255,0,255),"Wow clientside spam\n")```


**Bugs**

 - UI Resizing is a bit fuzzy
 - Legacy code in some places
 - Links are partially broken due to a bug in RichText, resizing the control usually helps

**Other bugs**

Are you sure you're using the latest version? 
If so, come join [Our servers](http://metastruct.net) and report your problem.

**Credits**
 - **CapsAdmin** Tweaks
 - **Garry** Adding more binds to make the UI possible
 - **Developers of ENEZ (Declan?)** Inspiration
 - **Chrisaster** Enginespew
 - **Agent 47** LuaError2
 - **Animorten** Improvements
 - **Syranide** and **Divran** 80% of EPOE1.0 UI.
 - **Noiwex** Fixes
 - **PotcFdk** Maintenance
 - **Psihusky** Sex and the code
 - **Collision (co2)** Fixes
 - **Python1320** Codes

***License***
