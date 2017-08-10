function setSliders
%set sliders to visible or not

    if get(findobj('tag', 'imageAxis'), 'UserData') > 1
        set(findobj('tag', 'hSlide'), 'Visible', 'on');
        set(findobj('tag', 'vSlide'), 'Visible', 'on');
    else
        set(findobj('tag', 'hSlide'), 'Visible', 'off');
        set(findobj('tag', 'vSlide'), 'Visible', 'off');
    end