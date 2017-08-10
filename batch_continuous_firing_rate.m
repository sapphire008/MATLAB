% batch continuous firing rate
addmatlabpkg('generic');
addmatlabpkg('ephanalysis');

base_dir = 'D:/Data/2015/08.August/';
result_dir = 'C:/Users/Edward/Documents/Assignments/Case Western Reserve/StrowbridgeLab/Projects/TeA Persistence Cui and Strowbridge 2015/analysis/Ca modulation of firing rate -09102015/';

%%
Cell(1).name = 'Data 21 Aug 2015/Neocortex I.21Aug15.S1.E%d.dat';
Cell(1).eps = 12;
Cell(1).condition = '1mM Ca^{2+}';


Cell(2).name = 'Data 21 Aug 2015/Neocortex D.21Aug15.S1.E%d.dat';
Cell(2).eps = 14:15;
Cell(2).condition = '4mM Ca^{2+}';

Cell(3).name = 'Data 21 Aug 2015/Neocortex E.21Aug15.S1.E%d.dat';
Cell(3).eps = 16:17;
Cell(3).condition = '4mM Ca^{2+}';

Cell(4).name = 'Data 21 Aug 2015/Neocortex H.21Aug15.S1.E%d.dat';
Cell(4).eps = 17;
Cell(4).condition = '1mM Ca^{2+}';

Cell(5).name = 'Data 21 Aug 2015/Neocortex H.21Aug15.S1.E%d.dat';
Cell(5).eps = 21;
Cell(5).condition = '1mM Ca^{2+}';

Cell(6).name = 'Data 3 Sep 2015/Neocortex H.03Sep15.S1.E%d.dat';
Cell(6).eps = 18;
Cell(6).condition = '2.5mM Ca^{2+}';
Cell(7) = Cell(6); Cell(7).eps = 20;
Cell(8) = Cell(7); Cell(8).eps = 21;

Cell(9).name = 'Data 4 Sep 2015/Neocortex D.04Sep15.S1.E%d.dat';
Cell(9).eps = 14;
Cell(9).condition = '2.5mM Ca^{2+}';
for n = 10:13
    Cell(n) = Cell(n-1);
    Cell(n).eps = Cell(n-1).eps+1;
end
Cell(13).eps = 19;

%%

for c = 1:length(Cell)
    figure;
    Vs = [];
    for epi = 1:length(Cell(c).eps)
        filename = fullfile(base_dir, sprintf(Cell(c).name, Cell(c).eps(epi)));
        zData = loadEpisodeFile(filename);
        Vs = [Vs; zData.VoltA];
    end
    ts = zData.protocol.msPerPoint/1000;
    t_vect = 0:ts:(length(Vs)-1)*ts;
    R = eph_firing_rate(Vs, ts, 'gaussian', 0.3);
    plot(t_vect, R);
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    title(Cell(c).condition);
    set(gcf, 'Position', [610,686,1193,267]);
    [~,cellname, ~] = fileparts(filename);
    fname = fullfile(result_dir, cellname);
    saveasfigure(gcf, [fname,'.tif'], '.tif')
    close(gcf);
end

