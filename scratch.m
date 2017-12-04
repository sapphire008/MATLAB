Base = 'Neocortex N.30May16.S1.E67';
Similar = 'Neocortex N.30May16.S1.E71';
Similar2 = 'Neocortex N.30May16.S1.E58';
Different = 'Neocortex N.30May16.S1.E64';
Different2 = 'Neocortex N.30May16.S1.E68';



Base_spk = get_spike_num(Base);
Similar_spk = get_spike_num(Similar);
[Similar2_spk,Vs] = get_spike_num(Similar2);
Different_spk = get_spike_num(Different);
Different2_spk = get_spike_num(Different);
d = spkd(Base_spk, Similar_spk, 0.1)


[d,scr]=spkd_int_FAST_post(Base_spk,Similar_spk,0.1,2000);






