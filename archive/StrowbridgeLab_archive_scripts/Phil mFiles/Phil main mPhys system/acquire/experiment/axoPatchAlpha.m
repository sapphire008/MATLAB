    function alphaFactor = axoPatchAlpha(magFactor, alphaData)
        % converts axoPatch gain telegraph to multiplier
%         disp(sprintf('%5.0f', alphaData));
        if isempty(alphaData) || alphaData < 200 || alphaData > 3400
            alphaFactor = 1;
            warning('axoPatchAlpha:TelegraphOutOfRange', 'Gain telegraph value out of range')                            
        else
            alphaValue = [0.5 1 2 5 10 20 50 100]; % reading of the gain telegraph
            alphaFactor = alphaValue(fix((alphaData + 201) / 403));
        end
        alphaFactor = magFactor / alphaFactor;        