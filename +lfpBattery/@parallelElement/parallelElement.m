classdef parallelElement < lfpBattery.batteryInterface
    %PARALLELELEMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function b = parallelElement(varargin)
            b@lfpBattery.batteryInterface(varargin{:})
        end
        function v = getNewVoltage(b, I, dt)
            % split I evenly across elements
            i = I ./ double(b.nEl);
            v = mean(arrayfun(@(x) getNewVoltage(x, i, dt), b.El));
        end
        function addcurves(b, d, type)
            % pass on to all elements
            arrayfun(@(x) addcurves(x, d, type), b.El)
            b.findImax;
        end
        function it = createIterator(b)
            it = batteryIterator(b);
            % MTODO: create batteryIterator & stack classes
        end
    end
    methods (Access = 'protected')
        function i = findImax(b)
            i = sum(arrayfun(@(x) findImax(x), b.El));
            b.Imax = i;
        end
        function refreshNominals(b)
            b.Vn = mean([b.El.Vn]);
            b.Cn = sum([b.El.Cn]);
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

