adBoard.analogIn = analoginput('nidaq', 'Dev1');
addchannel(adBoard.analogIn, 0);
adBoard.analogIn.SamplesPerTrigger = inf;
adBoard.analogIn.TriggerType = 'Immediate';
adBoard.analogIn.ExternalTriggerDriveLine = 'PFI0';

adBoard.analogOut = analogoutput('nidaq', 'Dev1');
addchannel(adBoard.analogOut, 0);
adBoard.analogOut.TriggerType = 'HwDigital';
adBoard.analogOut.TriggerCondition = 'PositiveEdge';
adBoard.analogOut.HwDigitalTriggerSource = 'PFI0';

adBoard.digitalIO = digitalio('nidaq', 'Dev1');
addline(adBoard.digitalIO, 0, 'out');

putsample(adBoard.analogOut, 0);
putdata(adBoard.analogOut, rand(1000,1));

start(adBoard.analogOut);
start(adBoard.analogIn);

wait([adBoard.analogIn,adBoard.analogOut],2);
[data,time] = getdata(adBoard.analogIn);