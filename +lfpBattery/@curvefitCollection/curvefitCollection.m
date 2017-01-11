classdef curvefitCollection < lfpBattery.sortedCollection
    %CURVEFITCOLLECTION sorted collection of curveFit objects. Uses
    %interplation to extract data between two curve fits according to z
    %value
    
    properties
    end
    
    methods
        function c = curvefitCollection(varargin)
            c@lfpBattery.sortedCollection(varargin{:})
        end
    end
    
end

