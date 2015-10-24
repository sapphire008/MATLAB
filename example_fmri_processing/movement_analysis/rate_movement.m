function [RMS_disp_ratings,RMS_speed_ratings] = rate_movement(RMS_disp_vect,RMS_speed_vect)
% Setting up rules for rating
%   Rating              RMS_disp                RMS_speed

%   Superb(A+)          rms<=0.1                rms<0.01
%   Splendid(A)         0.1<rms<=0.4            0.01<rms<0.04
%   Excellent(A-)       0.4<rms<=0.5            0.04<rms<=0.09
%   Very Good(B+)       0.5<rms<=0.6            0.09<rms<=0.15
%   Good(B)             0.6<rms<=0.9            0.15<rms<=0.20
%   Satisfactory(B-)    0.9<rms<=1.0            0.20<rms<=0.25
%   Clean(C+)           1.0<rms<=1.1            0.25<rms<=0.30
%   Acceptable(C)       1.1<rms<=1.9            0.30<rms<=0.35
%   Okay(C-)            1.9<rms<=2.0            0.35<rms<=0.40
%   Bad(F)              rms>2.0                 rms>0.40

% set up rating dictionary based on the rules for rating
RatingDictionary = {...
    'Superb',         'A+',     [0,0.1],            [0,0.01];...
    'Splendid',       'A',      [0.1,0.4],          [0.01,0.04];...
    'Excellent',      'A-',     [0.4,0.5],          [0.04,0.09];...
    'VeryGood',       'B+',     [0.5,0.6],          [0.09,0.15];...
    'Good',           'B',      [0.6,0.9],          [0.15,0.20];...
    'Satisfactory',   'B-',     [0.9,1.0],          [0.20,0.25];...
    'Clean',          'C+',     [1.0,1.1],          [0.25,0.30];...
    'Acceptable',     'C',      [1.1,1.9],          [0.30,0.35];...
    'Okay',           'C-',     [1.9,2.0],          [0.35,0.40];...
    'Bad',            'F',      [2.0,Inf],          [0.40,Inf]...           
    };

% do ratings based on the dictionary
[~,RMS_disp_ratings] = do_ratings(RMS_disp_vect,RatingDictionary(:,1:3));
[~,RMS_speed_ratings] = do_ratings(RMS_speed_vect,RatingDictionary(:,[1:2,4]));

end

function [ratings_name,ratings_rank]=do_ratings(vector,RatingDictionary)
%In the rating dictionary, assuming the first column is rating name and
%secnod column is rating rank (A+,B-), and the third column is the range of
%each rank

%place holding
ratings_name = cell(length(vector),1);
ratings_rank = cell(length(vector),1);

for n = 1:length(vector)
    IND = find(cellfun(@(x) x(1)<vector(n) && x(end)>=vector(n),RatingDictionary(:,3)));
    ratings_name{n} = RatingDictionary{IND,1};
    ratings_rank{n} = RatingDictionary{IND,2};
end
end
