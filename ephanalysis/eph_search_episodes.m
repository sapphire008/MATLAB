% Provides an example to search for desired episodes

addmatlabpkg('generic');
addmatlabpkg('ephanalysis');

basedir = 'D:/Data/Traces/2016/';

[P, N] = SearchFiles(basedir, '*.*/Data*/*.dat');

%%
Cells = {'Cell', 'Episode', 'numspikes', 'drug', 'sweepWindow'};
for n = 19500:length(P)
    if all(ismember('texCA', P{n})) || all(ismember('PFC', P{n})) || all(ismember('CA1', P{n})) || all(ismember('CA3', P{n}))
        continue;
    end
    zData = loadEpisodeFile(P{n});
    if zData.protocol.drug <1
        continue;
    end
    
    if zData.protocol.sweepWindow<=9000
        continue;
    end
    
    numspikes = eph_count_spikes(zData.VoltA, zData.protocol.msPerPoint, 'MinPeakHeight', 0);
    if numspikes<20 || numspikes > 80
        continue;
    end
    
    if true
        cellname = regexp(N{n}, '\.', 'split');
        Cells{end+1,1} = strjoin(cellname(1:2),'.');
        Cells{end,2} = strjoin(cellname(3:4),'.');
        Cells{end,3} = numspikes;
        Cells{end,4} = zData.protocol.drug;
        Cells{end,5} = zData.protocol.sweepWindow;
    end
    
    if mod(size(Cells, 1), 1000)<1
        disp(size(Cells,1));
    end
end

save('query_05012016_2016.mat');
%%
K = aggregateR(Cells, {'Cell'}, @max, {'drug'});
K = K(find(cell2mat(K(2:end,2))>1)+1,:);

Cells_K = Cells(1,:);
for n = 2:size(Cells,1)
    if ismember(Cells{n,1}, K(:,1))
        Cells_K(end+1,:) = Cells(n,:);
    end
end

K = aggregateR(Cells, {'Cell'}, @min, {'drug'});
K = K(find(cell2mat(K(2:end,2))<2)+1,:);

Cells_K2 = Cells(1,:);
for n = 2:size(Cells_K,1)
    if ismember(Cells_K{n,1}, K(:,1))
        Cells_K2(end+1,:) = Cells_K(n,:);
    end
end


%%
Cells_with_70_Terf = Cells_K2(find(cell2mat(Cells_K2(2:end,3)) == 22 & cell2mat(Cells_K2(2:end,4))==2)+1,1);
Cells_with_65_Terf = Cells_K2(find(cell2mat(Cells_K2(2:end,3)) == 29 & cell2mat(Cells_K2(2:end,4))==2)+1,1);

Cells_with_70_CCh = Cells_K2(find(cell2mat(Cells_K2(2:end,3)) == 48 & cell2mat(Cells_K2(2:end,4))==1)+1,1);


