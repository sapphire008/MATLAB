%plot movement
save_dir='/nfs/r21_gaba/image_reg/mprage_corrl_analysis/Time_Series/movement_plot/';
srate=5;
data_cell=database.MOD;%time series data used
data_summary=database.SUMMARY;
for n = 2:size(data_cell,1)
    figure;
    set(gcf,'Position',[100 100 1200 600]);
    subplot(2,1,1);
    plot([1:length(data_cell{n,4})]./srate,data_cell{n,4},'b');
    hold on;
    plot([1:length(data_cell{n,5})]./srate,data_cell{n,5},'r');
    plot([1:length(data_cell{n,6})]./srate,data_cell{n,6},'g');
    title(strrep(['{',data_cell{n,1},'}-{',data_cell{n,2},'}-movment vs. Time (s)'],'_','-'));
    xlabel(['Time [s], Mean-Mag: ',num2str(data_summary{n,8}),', RMS-Mag: ',num2str(data_summary{n,30})]);
    ylabel('Displacement(mm)');
    axis([0 400 -10 10]);
    legend('X','Y','Magnitude');
    hold off;
    
    subplot(2,1,2);
    plot([1:(length(data_cell{n,7}))]./srate,data_cell{n,7}*srate,'b');
    hold on;
    plot([1:(length(data_cell{n,8}))]./srate,data_cell{n,8}*srate,'r');
    plot([1:(length(data_cell{n,9}))]./srate,data_cell{n,9}*srate,'g');
    xlabel(['Time [s], Mean-Mag: ',num2str(data_summary{n,11}),', RMS-Mag: ',num2str(data_summary{n,33})]);
    ylabel('Speed(mm/s)');
    axis([0 400 -10 10]);
    legend('X','Y','Magnitude');
    hold off;
    
    saveas(gcf,[save_dir,data_cell{n,1},'-',data_cell{n,2},'.tif'],'tiff');
    close all;
end