function IC = myuniqueid(array, varargin)
[~,~,IC] = unique(array, varargin{:});
end