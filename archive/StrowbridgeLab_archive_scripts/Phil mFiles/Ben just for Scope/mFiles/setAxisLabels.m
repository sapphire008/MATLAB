function setAxisLabels(axisHandle)

	if nargin < 1
		axisHandle = gca;
	end
	
	mSecs = get(axisHandle, 'xtick');
	
	numDigits = -(fix(log((mSecs(2) - mSecs(1))/1000) / log(10))) + 1;
	if numDigits < 1
		numDigits = 0;
	end
	if mSecs(end) > 100000
		% minutes
		for i = 1:size(mSecs, 2)
			if numDigits > 0
				timeFormat{i, :} =  [sprintf('%0.0f', fix(mSecs(i) / 60000)) ':' sprintf(['%0' num2str(3 + numDigits) '.' num2str(numDigits) 'f'], mod(mSecs(i), 60000) / 1000)];
			else
				timeFormat{i, :} =  [sprintf('%0.0f', fix(mSecs(i) / 60000)) ':' sprintf('%02.0f', mod(mSecs(i), 60000) / 1000)];
			end
		end
		timeFormat{end} = ['            ' timeFormat{end} ' minutes'];
	elseif mSecs(end) > 1000
		% seconds
		for i = 1:size(mSecs, 2)
			timeFormat{i, :} =  sprintf(['%' num2str(2 + numDigits) '.' num2str(numDigits) 'f'], mSecs(i) / 1000);
		end			
		timeFormat{end} = ['             ' timeFormat{end} ' seconds'];
	else
		% msecs
		numDigits = numDigits - 3;
		if numDigits < 0
			numDigits = 0;
		end
		for i = 1:size(mSecs, 2)
			timeFormat{i, :} =  sprintf(['%0.' num2str(numDigits) 'f'], mSecs(i));
		end	
		timeFormat{end} = ['         ' timeFormat{end} ' msec'];
	end
	set(axisHandle, 'xticklabel', timeFormat)