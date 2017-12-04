function Rin = eph_vclamp_rin(Vs, Is, ts, window)
Rin = (mean(eph_window(Vs, ts, [-50, 0]+window(1))) - mean(eph_window(Vs, ts, [-50, 0]+window(2)))) / ...
(mean(eph_window(Is, ts, [-50, 0]+window(1))) - mean(eph_window(Is, ts, [-50, 0]+window(2)))) * 1000;
end