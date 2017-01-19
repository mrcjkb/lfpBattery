classdef parallelElement < lfpBattery.batCircuitElement
    %PARALLELELEMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function b = parallelElement(varargin)
            b@lfpBattery.batCircuitElement(varargin{:})
        end
        function v = getNewVoltage(b, I, dt)
            % split I evenly across elements
            i = I ./ double(b.nEl);
            v = mean(getNewVoltage@lfpBattery.batCircuitElement(b, i, dt));
        end
    end
    methods (Access = 'protected')
        function i = findImax(b)
            i = sum(findImax@lfpBattery.batCircuitElement(b));
            b.Imax = i;
        end
        %% Implementation of dependent getters & setters overload
        function v = getV(b)
            v = mean([b.El.V]);
        end
        function c = getCd(b)
            c = sum([b.El.Cd]);
        end
        function setV(b, v)
            % Pass v on to all elements to account for self-balancing
            % nature of parallel config
            [b.El.V] = deal(v);
        end
        function setCd(b, c)
            % Pass equal amount of discharge capacity to each element
            % to account for self-balancing nature of parallel config
            [b.El.Cd] = deal(1./double(b.nEl) .* c);
        end
    end
    
end

