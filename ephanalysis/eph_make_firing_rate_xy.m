function [x,y] = eph_make_firing_rate_xy(spike_time)
spike_time = spike_time(:);
x = mean([spike_time(1:end-1), spike_time(2:end)],2);
x = x-x(1)/1000;
y = 1./diff(spike_time)*1000;
end