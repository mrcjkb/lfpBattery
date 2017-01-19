classdef seriesElement < lfpBattery.batCircuitElement
    %SERIESELEMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = 'protected')
        vProps;
    end
    
    methods
        function b = seriesElement(varargin)
            b@lfpBattery.batCircuitElement(varargin{:})
        end
        function v = getNewVoltage(b, I, dt)
            v = sum(getNewVoltage@lfpBattery.batCircuitElement(b, I, dt));
        end
    end
    
    methods (Access = 'protected')
        function i = findImax(b)
            i = min(findImax@lfpBattery.batCircuitElement(b));
            b.Imax = i;
        end
        function v = getV(b)
            vv = [b.El.V]; % vector of voltages
            v = sum(vv); % total
            b.vProps = v ./ vv; % save proportions
        end
        function c = getCd(b)
            c = max([b.El.Cd]);
        end
        function setV(b, v)
            b.V = b.vProps .* v; % set voltages according to proportions saved by last call
        end
    end
end

