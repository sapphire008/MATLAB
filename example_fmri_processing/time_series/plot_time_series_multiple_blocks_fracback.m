% plot time series with multiple blocks frackback

% Frac back 
base_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/analysis/ROI_timeseries/unseparated_timeseries/baselined/';
timeseries = ReadTable('/nfs/jong_exp/midbrain_pilots/frac_back/analysis/ROI_timeseries/unseparated_timeseries/baselined/mean_baselined.csv');
vect_ext = '_estimated_vectors.mat';
Label_Dictionary{1} = {'InstructionBlock', 'ZeroBack','OneBack','TwoBack','NULL'};
Label_Dictionary{2} = {'I','0','1','2','F'};


% change the name to labels

for n = 5:7 %2:4
    EVENT = load(fullfile(base_dir,[timeseries{n,3},vect_ext]));
    % create labels
    EVENT.labels = cellfun(@(x) regexprep(x,Label_Dictionary{1},Label_Dictionary{2}),EVENT.names,'un',0);
    TS.signal = cell2mat(timeseries([n,n+6],4:end));
    TS.sample_rate = 1/3;
    switch timeseries{n,3}
        case 'block1'
            figure;
            subplot(3,1,1);
            time_series_plot_event_signal(TS,EVENT,'xlabel','',...
                'ylabel','% BOLD Signal Change','title',timeseries{n,3},'legend',{'C','SZ'});
            set(gca,'TickLength',[0,0]);
        case 'block2'
            subplot(3,1,2);
            time_series_plot_event_signal(TS,EVENT,'xlabel','',...
                'ylabel','% BOLD Signal Change','title',timeseries{n,3},'legend',...
                {'C','SZ'});
            set(gca,'TickLength',[0,0]);
        case 'block3'
            subplot(3,1,3);
            time_series_plot_event_signal(TS,EVENT,'xlabel','TR = 3s',...
                'ylabel','% BOLD Signal Change','title',timeseries{n,3},'legend',{'C','SZ'});
            set(gca,'TickLength',[0,0]);
            % get title
            suptitle([timeseries{n,2},' % BOLD Signal time series']);
    end
end