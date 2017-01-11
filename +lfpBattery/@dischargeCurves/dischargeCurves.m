classdef dischargeCurves < lfpBattery.curvefitCollection
    %DISCHARGECURVES class for storing curveFit
    
    properties
        interpMethod = 'spline';
    end
    properties (Access = 'protected')
        minFuns = 3; % Minimum number of functions permitted
    end
    
    methods
        function d = dischargeCurves(varargin)
            d@lfpBattery.curvefitCollection(varargin{:})
        end
    end
    methods (Access = 'protected')
        function v = interp(d, i, c_dis)
            % MTODO implement this function
            
        end
    end
    
end

