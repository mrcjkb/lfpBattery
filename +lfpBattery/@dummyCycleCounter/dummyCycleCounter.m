classdef dummyCycleCounter < lfpBattery.cycleCounter
    %DUMMYCYCLECOUNTER This is a dummy cycle model that implements the
    %cycleCounter interface. All methods are overloaded to do nothing.
    %This class can be used to replace the cycle counter if no aging is to be modelled.
    %
    %SEE ALSO: lfpBattery.batteryAgeModel lfpBattery.eoAgeModel
    %lfpBattery.cycleCounter lfpBattery.dambrowskiCounter
    
    methods
        function d = dummyCycleCounter(varargin)
            d@lfpBattery.cycleCounter(varargin{:})
        end
        function lUpdate(d, ~, ~) %#ok<*INUSD>
        end
        function update(d, ~)
        end
        function count(d) %#ok<MANU>
        end
    end
    methods (Access = 'protected')
        function addSoC(d, ~)
        end
        function imax = iMaxima(~)
            imax = [];
        end % iMaxima
    end % protected methods
end

