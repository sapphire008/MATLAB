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

% remove any potential invalid currents
U = U(:,isfinite(J)); J = J(isfinite(J));
% Fit the line
P = cell2mat(cellfun(@(x) [J(isfinite(x))'\x(isfinite(x))', ...
    -mean(J(isfinite(x))'\x(isfinite(x))'*J(isfinite(x))-x(isfinite(x)))], ...
    mat2cell(U,ones(1,size(U,1)),size(U,2)),'un',0));
G = 1./P(:,1);
I0 = -P(:,2)./P(:,1);
% plot diagnostics
if ~show_diagnostics, return; end
marker_list = {'bo','ro','go','ko','mo','b*','r*','g*','k*','m*',...
    'b.','r.','g.','k.','m.'};
% Do statistical test: do anova on ratio J/U
aov_p = anova1(bsxfun(@rdivide,J,4*pi*U)'.^2,[],'off');
if nargin<4 || isempty(Nth), Nth = 1:length(G); end
figure;
boxplot_axis = subplot(2,2,[1,2]);
boxplot(boxplot_axis, bsxfun(@rdivide, J, 4*pi*U)'.^2,'labels',cellstr(num2str(Nth)));
xlabel('Neighbors');    ylabel('(J_k/4\piU)^2');
title(['ANOVA p = ',num2str(aov_p)]);
if nargin<5 || ~isempty(current_channel), current_channel = '';end
suptitle([current_channel,' Voltage vs. Current Diagnostics']);
% plot I/V across all neighboring electrodes
m = [repmat(marker_list,1,floor(size(U,2)/numel(marker_list))),...
    marker_list(1:mod(size(U,2),numel(marker_list)))];
subplot(2,2,3);
for s = 1:size(U,2),plot(repmat(J(s),size(U,1),1),U(:,s),m{s});hold on;end
X = reshape(repmat(J,size(U,1),1),numel(U),1);      Y = U(:);
X = X(isfinite(Y));                                 Y = Y(isfinite(Y));
Q = [X\Y, -mean(X\Y*X-Y)];  % fit a line
x = linspace(min(J(:))-1,max(J(:))+1,50);           y = Q(1)*x+Q(2);
plot(x,y,'k'); %plot fitted line
hold off; xlabel('Current (\muA)'); ylabel('Voltage (mV)'); grid on;
title(sprintf('slope = %.3f, intercept = %.3f',Q(1),Q(2)));
clear X Y Q;
% plot conductance
% marker list cycle index
m = [repmat(marker_list,1,floor(size(U,1)/numel(marker_list))),...
    marker_list(1:mod(size(U,1),numel(marker_list)))];
subplot(2,2,4);
% drawing dots
for s = 1:size(U,1), plot(J,U(s,:),m{s}); hold on; end
for s = 1:size(U,1) % drawing lines
    X = J(isfinite(U(s,:)));  Y = U(s, find(isfinite(U(s,:))));
    plot(X,Y,m{s}(1)); hold on;
end
clear X Y; 
hold off; xlabel('Current (\muA)'); ylabel('Voltage (mV)'); grid on;
% get a list of legend
if nargin<6 || isempty(NN_channels), NN_channels = cellfun(@num2str,num2cell(1:length(G)),'un',0);end
legend_I = cellfun(@(x,y) sprintf('g_{%s} = %.3f',char(x),y),NN_channels(:),num2cell(G),'un',0);
legend(legend_I{:},'Location','SouthEast');
title('Conductance of electrodes (mS)');
drawnow;
end