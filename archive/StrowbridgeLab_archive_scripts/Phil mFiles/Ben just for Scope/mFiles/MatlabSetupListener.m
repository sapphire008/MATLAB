import TheCodeKing.Net.Messaging.*
mess=NET.addAssembly('d:\XDMessaging.dll');
Listener =List1.CreateListener(XDTransportMode.MailSlot);
addlistener(Listener,'MessageReceived',@MessageHere);
Listener.RegisterChannel('ToMatlab');