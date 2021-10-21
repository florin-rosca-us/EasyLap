EasyLap
=======

A iOS client for [easylap-server](https://github.com/florin-rosca-us/easylap-server).

# Background
[Kyosho MiniZ](http://kyosho.com/mini-z-info/) are awesome remote control (RC) cars that [can race](https://www.youtube.com/watch?v=bLIlTpBr_Ls).

RC cars can be equipped with IR transponders that emit unique codes. When the RC cars pass the start line, the code is received by a timing system. A typical timing system sends the codes via a serial connection/USB to a Windows PC. The Windows PC runs a lap counter program such as [ZRound](https://www.zround.com/).

### Idea
Would like to run a lap counter on an phone or iPad, without having to connect a USB cable. Would like to use a Raspberry Pi Zero to send data.

# Implementation
The [server](https://github.com/florin-rosca-us/easylap-server) advertises a UDP service via [Bonjour (mDNS)](https://en.wikipedia.org/wiki/Multicast_DNS), reads from the EasyLAP device and sends data via UDP to registered clients. The client can register new racers and perform timing. The client pings the server periodically so that the client is not discarded and also sends commands such as `LIGHTS ON` / `LIGHTS OFF` / `LIGHTS <value>` used for turning on or off 5 LEDS connected to a GPIO expander. The 5 LEDs mimic the [F1 start sequence](http://www.formula1-dictionary.net/start_sequence.html).

### Challenges
iOS 14 adds an extra level of security that makes it harder for iOS apps to send or listen to UDP broadcast. The workaround is to use unicast to send data to a list of active clients.
