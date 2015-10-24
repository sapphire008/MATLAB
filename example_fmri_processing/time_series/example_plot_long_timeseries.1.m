% example plot long timeseries

TS.signal = randn(2,114);
TS.sample_rate = 1/3;

EVENT = load('/nfs/jong_exp/midbrain_pilots/frac_back/behav/MP021_051713/block1_vectors.mat');
EVENT.labels = {'I','0','1','2','F'};

[TS,EVENT,OPT] = time_series_plot_event_signal(TS,EVENT);