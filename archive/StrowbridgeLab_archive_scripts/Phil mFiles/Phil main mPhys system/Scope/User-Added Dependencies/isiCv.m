function cvValue = isiCv(inData)
% calculates the coefficient of variation for the inter-spike interval
%                               standard deviation
% Coefficient_of_Variation =    ------------------
%                                       mean

ISI = diff(inData);

if numel(ISI) > 1
    cvValue = std(ISI(ISI < 2000)) / mean(ISI(ISI < 2000));
else
    cvValue = nan;
end

if nargout == 0
	figure('numberTitle', 'off', 'name', ['ISI CV = ' sprintf('%0.2f', cvValue)])
	hist(ISI)
end