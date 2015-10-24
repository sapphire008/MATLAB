function p = eph_RV_curve(V, Rin, p0, niter, sd, zfactor)
% Fit a curve between voltage (resting membrane potential) and input
% resistance (R_in)
% Based on: Gruhn, M., Guckenheimer, J., Land, B., Harris-Warrick, R.M.
% Dopamine modulation of two deplayed rectifier potassium currents in small
% neural network. J. Neurophysiol. 94 (4): 2888-2900 (2005). 
% DOI: 10.1152/jn.00434.2005
%
% Weblink on cornell.edu
% http://people.ece.cornell.edu/land/PROJECTS/MKG23curvefit/index.html
%
% We needed to estimate a set of parameters and their errors for a 
% nonlinear curve fit of cellular conductance data. The conductance was a 
% function of voltage and was modeled as a Boltzmann term, an exponential 
% term, and a constantx
%
% r = p3/(1+exp(v-p1)/p2) + p5*exp(v-45)/p6) + p4
%
% Since the paper showed an increase in conductance when voltage increases,
% whereas current observation is that increase in voltage decreases
% conductance (increase in input resistance). The model will use input
% resistance instead.

% define a starting point for curve fit
if nargin<3, p0 = [-10 -7 -0.2 -.01 0.2 8 ]; end
% number of iterations to fit
if nargin<4, niter = 100; end 
%each parameter is varied by a normal distribution with
%mean equal to the starting guess and std.dev. equal to
%sd*mean
if nargin<5, sd = 0.3; end
%histogram zoom factor (how many std dev to show)
if nargin<6, zfactor = 2; end

% define the target function
func = @(p,v) p(3)./(1+exp((v-p(1))/p(2))) + p(5)*exp((v-52)/p(6));

for n = 1:niter
    % Randomly adjust the starting point
    p = p0.*(1+sd*randn(1,length(p0)));
    %do the fit
    [p,r,j] = nlinfit(V,Rin,func,p);
    %get parameter errors
    c95 = nlparci(p,r,j);
    %conductance errors
    [yp, ci] = nlpredci(func,x,p,r,j);
    
    %plot the fit
    figure(1)
    errorbar(V,func(p,V),ci,ci,'-');
    hold on
    plot(V, Rin,'ro');
end



end

function program()
%%
%Program for Matt Gruhn
%Written by Bruce Land, BRL4@cornell.edu
%May 20, 2004
%===================
%curve fit of 6 parameter conductance function of voltage
%Formula from Matt:
%g=	(m3/((1+exp((m0-m1)/m2))^(1)))+(m4)+(m5*exp((m0-45)/m6)); 
%need to get parameters and their error range
%--Then separately plot the "boltzmann" and exponential parts separately
%===================

% clear all
% %total fit
% figure(1)
% clf
% %part fit
% figure(2)
% clf
% %parameter histograms
% figure(3)
% clf

%========================================================
%START settable inputs
%========================================================
%data set 1 from Matt-- cell f 
%the voltages
[x, y] = tuple(R(:,1),R(:,2));
% x=[-30.3896
%     -25.2314
%     -20.0655
%     -14.9218
%     -9.82205
%     -4.71594
%     0.380856
%     5.53925
%     10.749
%     15.8878
%     21.0423
%     26.154
%     31.3026
%     36.3964
%     41.4244
%     46.3951
% ];
% 
% %the measured conductances
% y=[0.01428535
%     0.032721504
%     0.06306213
%     0.099658404
%     0.134567811
%     0.162306115
%     0.181366575
%     0.196532089
%     0.20765796
%     0.218294045
%     0.22529785
%     0.235617098
%     0.250215255
%     0.268659046
%     0.294750456
%     0.331398216
% ];

%estimate of error in conductance measurement
%Currently set to 2%
dy = y*0.02;

%formula converted to
%The inline version
func = inline('p(3)./(1+exp((x-p(1))/p(2))) + p(5)*exp((x-45)/p(6)) + p(4)','p','x');  
%initial parameter guess
p0 = [-10 -7 -0.2 -.01 0.2 8 ];

%To detect the sensitivity of the fit to starting parameter guess,
%the fit is run a number of times.
%each fit is plotted and each parameter plotted as a histogram
Nrepeat=100;
%each parameter is varied by a normal distribution with
%mean equal to the starting guess and std.dev. equal to
%sd*mean
sd = 0.3;
%histogram zoom factor (how many std dev to show)
zfactor = 2;
%parameter outlier cuttoff: lowest and highest N estimates are removed
outcut=10;
%========================================================
%END settable inputs
%========================================================

%list of all parameter outputs to use in histogram
pList=zeros(Nrepeat,6);

for rep =1:Nrepeat
    
    %form the new randomized start vector
    p = [p0(1)*(1+sd*randn), p0(2)*(1+sd*randn), p0(3)*(1+sd*randn),...
            p0(4)*(1+sd*randn), p0(5)*(1+sd*randn), p0(6)*(1+sd*randn)];
    %do the fit
    [p,r,j] = nlinfit(x,y,func,p);
    %copy fit to list
    pList(rep,:) = p';
    
    %get parameter errors
    c95 = nlparci(p,r,j);
    %conductance errors
    [yp, ci] = nlpredci(func,x,p,r,j);
    
    %plot the fit
    figure(1)
    errorbar(x,func(p,x),ci,ci,'b-');
    hold on
    errorbar(x,y,dy,dy,'ro')
    
    %plot the separated fits
    figure(2)
    subplot(2,1,1)
    hold on
    errorbar(x, y-func(p,x)+ p(5)*exp((x-45)/p(6)),dy,dy,'rx')
    %plot(x, (y-func(p,x)+ p(5)*exp((x-45)/p(6))),'ro')
    errorbar(x, p(5)*exp((x-45)/p(6)), 2*ci, 2*ci,'bx-')
    title('Exponential fit')
    
    subplot(2,1,2)
    hold on
    %plot(x, (y-func(p,x)+ p(3)./(1+exp((x-p(1))/p(2)))),'ro')
    errorbar(x, y-func(p,x)+ p(3)./(1+exp((x-p(1))/p(2))),dy,dy,'rx')
    errorbar(x, p(3)./(1+exp((x-p(1))/p(2))), 2*ci, 2*ci,'bx-')
    title('Boltzmann fit')
    
    %drawnow
end

figure(3)
%plot and print parameter table
fprintf('\r\rFit parameters and 95percent confidence range\r')
for i=1:6
    subplot(6,1,i)
    lowerLimit = mean(pList(:,i))-zfactor*std(pList(:,i));
    upperLimit = mean(pList(:,i))+zfactor*std(pList(:,i));
    hist(pList(:,i),linspace(lowerLimit,upperLimit,30))
    %
    fprintf('%7.3f\t +/- %7.3f \r',...
        mean(pList(:,i)),...
        max(2*std(pList(:,i)),mean(pList(:,i))-c95(i,1)));
end

fprintf('\r\rFit parameters omitting outliers\r')
for i=1:6
    %get rid of outliers
    pup = sort(pList(:,i));
    pup = pup(outcut:end-outcut);
    %print again
    fprintf('%7.3f\t +/- %7.3f \r',...
        mean(pup),...
        max(2*std(pup),mean(pup)-c95(i,1)));
    pbest(i)=mean(pup);
end

%print conductance table
%based on best parameters
v = [-30:5:45];
clear yp ci
[yp,ci] = nlpredci(func,x,pbest,r,j);
fprintf('\rVolt \t Total g\t Boltz\t Exp \r')
for i=1:length(v)
    fprintf('%7.3f\t%7.3f\t%7.3f\t%7.3f\r',...
        v(i),...
        yp(i),...
        pbest(3)./(1+exp((v(i)-pbest(1))/pbest(2))),...
        pbest(5)*exp((v(i)-45)/pbest(6)));
end
end