% different stimulus intensity gives different readout in voltage
load('Z:\Data\Edward\Analysis\2014 September 12\datainfo.mat');
addpath('Z:\Documents\Edward\scripts\NeuroShare\');
addpath('Z:\Documents\Edward\scripts\generic\');
base_dir = 'Z:\Data\Edward\RawData\2014 September 12\';
result_dir = 'Z:\Data\Edward\Analysis\2014 September 12\';

[channellist,~,file_IND] = unique({data_info.StimulationChannel});
elec_data_info = cell(1,length(channellist));
marker_list = {'bo','ro','go','ko','mo','b*','r*','g*','k*','m*','b.','r.','g.','k.','m.'};
NN = 2;
PITCH = 0.2;

%NN_dist = 0.2*sort([1:ceil(NN/2),(1:ceil((NN-1)/2))*sqrt(2)]);
%%
for n = 32:length(channellist)
    %% calculate data
    U = [];
    I = [];
    IND = find(file_IND == n);
    if numel(IND)<2,continue;end
    for m = 1:length(IND)
        if n == 32 && m == 1 %upon first loading
            [MEA,X] = loadMEA(fullfile(base_dir,data_info(IND(m)).DataFileName),...
                'stream_channel',data_info(IND(m)).EventOnsetIndex+[0,1],...
                'verbose',false);
            MAP = flipud(MEA.MapInfo.coord)';
        else%no longer need to get the MEA and map info
            [~,X] = loadMEA(fullfile(base_dir,data_info(IND(m)).DataFileName),...
                'select',{'Electrode'},'stream_channel',...
                data_info(IND(m)).EventOnsetIndex+[0,1],'verbose',false);
        end
        
        if m == 1% upon first loading current electrode
            elec_data_info{n}.elec = data_info(IND(m)).StimulationChannel;
            % find current electrode coordinate
            XY = fliplr(MEA.MapInfo.coord(:,find(ismember(MEA.MapInfo.channelnames,channellist{n})))');
            % find nearest neighbor
            [XY_NN,NN_IND, Nth] = find_nearest_neighbor(MAP, XY, NN);
            NN_channels = MEA.MapInfo.channelnames(NN_IND)';
        end
        % find nearest neighbor's voltage
        U = cat(2,U,diff(X(:,NN_IND),1,1)');
        % find corresponding current injected
        I = [I,data_info(IND(m)).StimulationAmplitude_uA];
    end
    % sorting U according to I
    [I, I_ind] = sort(I);
    U = U(:,I_ind);
    elec_data_info{n}.U = U;
    elec_data_info{n}.I = I;

    %% Do statistical test
    % do anova on ratio I/U
    [elec_data_info{n}.aov_p, elec_data_info{n}.aov_table, ...
        elec_data_info{n}.aov_stats] = anova1(bsxfun(@rdivide,I,4*pi*U)'.^2,[],'on');
    fh = figure(2);
    set(gca,'XTickMode','auto','XTickLabelMode','manual','XTickLabel',cellstr(num2str(Nth)));
    axis2 = get(gca,'children');
    % Copy figures
    figure(3);
    h2 = subplot(2,2,[1,2]);
    copyobj(axis2,h2);
    set(gca,'XTickMode','auto','XTickLabelMode','manual','XTickLabel',cellstr(num2str(Nth)));
    xlabel('Neighbors');
    ylabel('(I_k/4\piU)^2');
    title(['ANOVA p=',num2str(elec_data_info{n}.aov_p)]);
    close(figure(1)); close(figure(2));
    suptitle(['Channel ',elec_data_info{n}.elec,' Voltage vs. Current Diagnostics']);
    
    %% plot V vs I.

    %correct for NN_dist
    %U = bsxfun(@times, U, PITCH * double(ceil(Nth/2).* ~mod(Nth,2)*sqrt(2)+mod(Nth,2)));
    subplot(2,2,3);
    for s = 1:size(U,2)
        plot(repmat(I(s),size(U,1),1),U(:,s),marker_list{s});
        hold on;
    end
    Q = polyfit(reshape(repmat(I,size(U,1),1),numel(U),1),U(:),1);
    x = linspace(min(I(:))-1,max(I(:))+1,50);
    y = Q(1)*x+Q(2);
    plot(x,y,'k');
    hold off;
    xlabel('Current (\muA)');
    ylabel('Voltage (mV)');
    title(sprintf('slope = %.3f, intercept = %.3f',Q(1),Q(2)));
    
    subplot(2,2,4);
    for s = 1:size(U,1)
        plot(I,U(s,:),marker_list{s});
        hold on;
    end
    for s = 1:size(U,1)
        plot(I,U(s,:),marker_list{s}(1));
        hold on;
    end
    hold off;
    xlabel('Current (\muA)');
    ylabel('Voltage (mV)')
    % find local conductance
    G = 1./cellfun(@(x) x(2),cellfun(@(x) polyfit(I,x,1), ...
        mat2cell(U,ones(1,size(U,1)),size(U,2)),'un',0));
    % get a list of legend
    legend_I = cellfun(@(x,y) sprintf('g_{%s} = %.3f',char(x),y),NN_channels,num2cell(G),'un',0);
    legend(legend_I{:},'Location','NorthWest');
    title('Conductance of electrodes (mS)');
    
    %saveas(gcf,fullfile(result_dir,['Channel ',elec_data_info{n}.elec,'.fig']));
    %clear I U P IND x y h axis2 h2;
    
end
save('datainfo.mat','elec_data_info','-append');



















