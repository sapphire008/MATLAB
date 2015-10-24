% scratch
filename = 'X:\Edward\Data\Traces\Data 24 Mar 2015\Neocortex B.24Mar15.S1.E23.dat';
zData = eph_loadEpisodeFile(filename);
Vs = zData.VoltA;
ts = zData.protocol.msPerPoint/1000;


