% Use for W estimator correction
function [G, I0] = estimate_conductance(U,J,show_diagnostics, Nth, current_channel, NN_channels)
% Estimate conductivity and leaky current, given measured voltage and
% different current sources / stimuli
%
% Inputs:
%   U: NxM matrix, with N locations/observations, and M current intensities
%   I: 1xM vector, with M current intensities
% Outputs:
%   G: conductance of each locations. Note that unit is I/U.
%   I0: leaky current, same unit as I.
%
% The function will fit a straight line between current and observed
% voltage. The reciprocal of the slope of the fit will be the conductance,
% whereas the intercept will be the leaky current (values of I when U = 0)
%

% Fit the line
P = cell2mat(cellfun(@(x) polyfit(J,x,1),...
    mat2cell(U,ones(1,size(U,1)),size(U,2)),'un',0));
G = 1./P(:,1);
I0 = -P(:,2)./P(:,1);
% plot diagnostics
if ~show_diagnostics, return; end
marker_list = {'bo','ro','go','ko','mo','b*','r*','g*','k*','m*',...
    'b.','r.','g.','k.','m.'};
% Do statistical test
% do anova on ratio J/U
[U_J_diag.aov_p, U_J_diag.aov_table, ...
    U_J_diag.aov_stats] = anova1(bsxfun(@rdivide,J,4*pi*U)'.^2,[],'on');
if nargin<4 || isempty(Nth), Nth = 1:length(G); end
set(gca,'XTickMode','auto','XTickLabelMode','manual','XTickLabel',cellstr(num2str(Nth)));
axis2 = get(gca,'children');
% Copy figures
h = gcf-1;
close(h); figure(h);
h2 = subplot(2,2,[1,2]);
copyobj(axis2,h2);
set(gca,'XTickMode','auto','XTickLabelMode','manual','XTickLabel',cellstr(num2str(Nth)));
xlabel('Neighbors');
ylabel('(J_k/4\piU)^2');
title(['ANOVA p=',num2str(U_J_diag.aov_p)]);
close(h+1);
if nargin<5 || ~isempty(current_channel), current_channel = '';end
suptitle([current_channel,' Voltage vs. Current Diagnostics']);
% plot I/V across all neighboring electrodes
m = [repmat(marker_list,1,floor(size(U,2)/numel(marker_list))),...
    marker_list(1:mod(size(U,2),numel(marker_list)))];
subplot(2,2,3);
for s = 1:size(U,2)
    plot(repmat(J(s),size(U,1),1),U(:,s),m{s});
    hold on;
end
Q = polyfit(reshape(repmat(J,size(U,1),1),numel(U),1),U(:),1);
x = linspace(min(J(:))-1,max(J(:))+1,50);
y = Q(1)*x+Q(2);
plot(x,y,'k');
hold off;
xlabel('Current (\muA)');
ylabel('Voltage (mV)');
grid on;
title(sprintf('slope = %.3f, intercept = %.3f',Q(1),Q(2)));
% plot conductance
%marker list cycle index
m = [repmat(marker_list,1,floor(size(U,1)/numel(marker_list))),...
    marker_list(1:mod(size(U,1),numel(marker_list)))];
subplot(2,2,4);
for s = 1:size(U,1)
    plot(J,U(s,:),m{s});
    hold on;
end
for s = 1:size(U,1)
    plot(J,U(s,:),m{s}(1));
    hold on;
end
hold off;
xlabel('Current (\muA)');
ylabel('Voltage (mV)');
grid on;
% get a list of legend
if nargin<6 || isempty(NN_channels), NN_channels = cellfun(@num2str,num2cell(1:length(G)),'un',0);end
legend_I = cellfun(@(x,y) sprintf('g_{%s} = %.3f',char(x),y),NN_channels(:),num2cell(G),'un',0);
legend(legend_I{:},'Location','SouthEast');
title('Conductance of electrodes (mS)');
drawnow;
end
