classdef curvefitCollection < lfpBattery.sortedFunctions
    %CURVEFITCOLLECTION sorted collection of curveFit objects. Uses
    %interplation to extract data between two curve fits according to z
    %value
    %
    %curvefitCollection Properties:
    %
    %   xydata - curve fit objects (should implement curveFitInterface)
    %   z      - z data at which the respective curve measurements were
    %            recorded (i. e. temperature, current,...)
    %
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         January 2017
    properties
    end
    
    methods
        function c = curvefitCollection(varargin)
            for i = 1:numel(varargin)
                lfpBattery.commons.validateInterface(varargin{i}, 'lfpBattery.curveFitInterface')
            end
            c@lfpBattery.sortedFunctions(varargin{:})
        end
    end
    
end

