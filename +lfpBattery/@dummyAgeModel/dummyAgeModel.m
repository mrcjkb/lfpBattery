classdef dummyAgeModel < lfpBattery.batteryAgeModel
    %DUMMYAGEMODEL: This is a dummy age model that implements the
    %batteryAgeModel interface. All methods are overloaded to do nothing.
    %This age model can be used if no aging is to be modelled.
    %
    %SEE ALSO: lfpBattery.batteryAgeModel lfpBattery.eoAgeModel
    %lfpBattery.cycleCounter lfpBattery.dambrowskiCounter
    
    methods
        function b = dummyAgeModel(varargin)
            b@lfpBattery.batteryAgeModel(varargin{:})
        end
    end
    methods (Access = 'protected')
        function addAging(d, ~, ~) %#ok<*INUSD>
        end
    end
end

